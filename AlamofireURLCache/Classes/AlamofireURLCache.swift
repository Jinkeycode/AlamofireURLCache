//
//  AlamofireURLCache.swift
//  AlamofireURLCache
//
//  Created by Jinkey on 2020/1/20.
//  Copyright © 2020年 Bytell. All rights reserved.
//
import Foundation
import CoreFoundation
import Alamofire

public struct AlamofireURLCache {
    public static var HTTPVersion = "HTTP/1.1" {
        didSet {
            if self.HTTPVersion.contains("1.0") {
                self.isCanUseCacheControl = false
            }
        }
    }
    
    fileprivate static var isCanUseCacheControl = true
    
    fileprivate enum RefreshCacheValue:String {
        case refreshCache = "refreshCache"
        case useCache = "useCache"
    }
    fileprivate static let refreshCacheKey = "refreshCache"
    fileprivate static let frameworkName = "AlamofireURLCache"
}

public struct Alamofire {
    @discardableResult
    public static func request(
        _ url: URLConvertible,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = URLEncoding.default,
        headers: HTTPHeaders? = nil,
        refreshCache:Bool = false)
        -> DataRequest
    {
        return SessionManager.default.request(
            url,
            method: method,
            parameters: parameters,
            encoding: encoding,
            headers: headers,
            refreshCache: refreshCache
        )
    }
    
    public static func clearCache(request:URLRequest,urlCache:URLCache = URLCache.shared) {
        if let cachedResponse = urlCache.cachedResponse(for: request) {
            if let httpResponse = cachedResponse.response as? HTTPURLResponse {
                let newData = cachedResponse.data
                guard let newURL = httpResponse.url else { return }
                guard let newHeaders = (httpResponse.allHeaderFields as NSDictionary).mutableCopy() as? NSMutableDictionary else { return }
                if AlamofireURLCache.isCanUseCacheControl {
                    DataRequest.addCacheControlHeaderField(headers: newHeaders, maxAge: 0, isPrivate: false)
                } else {
                    DataRequest.addExpiresHeaderField(headers: newHeaders, maxAge: 0)
                }
                if let newResponse = HTTPURLResponse(url: newURL, statusCode: httpResponse.statusCode, httpVersion: AlamofireURLCache.HTTPVersion, headerFields: newHeaders as? [String : String]) {
                    
                    let newCacheResponse = CachedURLResponse(response: newResponse, data: newData, userInfo: ["framework":AlamofireURLCache.frameworkName], storagePolicy: URLCache.StoragePolicy.allowed)
                    
                    urlCache.storeCachedResponse(newCacheResponse, for: request)
                }
            }
        }
    }
    
    public static func clearCache(dataRequest:DataRequest,urlCache:URLCache = URLCache.shared) {
        if let httpRequest = dataRequest.request {
            self.clearCache(request: httpRequest, urlCache: urlCache)
        }
    }
    
    public static func clearCache(url:String,parameters:[String:Any]? = nil, headers:[String:String]? = nil,urlCache:URLCache = URLCache.shared) {
        if var urlRequest = try? URLRequest(url: url, method: HTTPMethod.get, headers: headers) {
            urlRequest.cachePolicy = .reloadIgnoringLocalCacheData
            if let newRequest = try? URLEncoding().encode(urlRequest, with: parameters) {
                self.clearCache(request: newRequest, urlCache: urlCache)
            }
        }
    }
}

public extension SessionManager {

    @discardableResult
    public func request(
        _ url: URLConvertible,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = URLEncoding.default,
        headers: HTTPHeaders? = nil,
        refreshCache:Bool = false)
        -> DataRequest
    {
        var newHeaders = headers
        if method == .get {
            if refreshCache {
                if newHeaders == nil {
                    newHeaders = HTTPHeaders()
                }
                if AlamofireURLCache.isCanUseCacheControl {
                    newHeaders?["Cache-Control"] = "no-cache"
                } else {
                    newHeaders?["Pragma"] = "no-cache"
                }
                newHeaders?[AlamofireURLCache.refreshCacheKey] = AlamofireURLCache.RefreshCacheValue.refreshCache.rawValue
                
            }
        }
        return request(url, method: method, parameters: parameters, encoding: encoding, headers: newHeaders)
    }
}

public extension DataRequest {
    
    // MARK: - Public method
    @discardableResult
    public func cache(maxAge:Int,isPrivate:Bool = false,ignoreServer:Bool = true)
        -> Self
    {
        if maxAge <= 0 {
            return self
        }
        var useServerButRefresh = false
        if let newRequest = self.request {
            if !ignoreServer {
                if newRequest.allHTTPHeaderFields?[AlamofireURLCache.refreshCacheKey] == AlamofireURLCache.RefreshCacheValue.refreshCache.rawValue {
                    useServerButRefresh = true
                }
            }
            
            if newRequest.allHTTPHeaderFields?[AlamofireURLCache.refreshCacheKey] != AlamofireURLCache.RefreshCacheValue.refreshCache.rawValue {
                if let urlCache = self.session.configuration.urlCache {
                    if let value = (urlCache.cachedResponse(for: newRequest)?.response as? HTTPURLResponse)?.allHeaderFields[AlamofireURLCache.refreshCacheKey] as? String {
                        if value == AlamofireURLCache.RefreshCacheValue.useCache.rawValue {
                            return self
                        }
                    }
                }
            }
            
        }
        
        return response { [unowned self](defaultResponse) in
            
            if defaultResponse.request?.httpMethod != "GET" {
                debugPrint("Non-GET requests do not support caching!")
                return
            }
            

            if defaultResponse.error != nil {
                debugPrint(defaultResponse.error!.localizedDescription)
                return
            }

            if let httpResponse = defaultResponse.response {
                guard let newRequest = defaultResponse.request else { return }
                guard let newData = defaultResponse.data else { return }
                guard let newURL = httpResponse.url else { return }
                guard let urlCache = self.session.configuration.urlCache else { return }
                guard let newHeaders = (httpResponse.allHeaderFields as NSDictionary).mutableCopy() as? NSMutableDictionary else { return }
                
                if AlamofireURLCache.isCanUseCacheControl {
                    if httpResponse.allHeaderFields["Cache-Control"] == nil || (httpResponse.allHeaderFields["Cache-Control"] != nil && ( (httpResponse.allHeaderFields["Cache-Control"] as! String).contains("no-cache")
                         || (httpResponse.allHeaderFields["Cache-Control"] as! String).contains("no-store"))) || ignoreServer || useServerButRefresh {
                        if ignoreServer {
                            if newHeaders["Vary"] != nil { // http 1.1
                                newHeaders.removeObject(forKey: "Vary")
                            }
                            if newHeaders["Pragma"] != nil {
                                newHeaders.removeObject(forKey: "Pragma")
                            }
                        }
                        DataRequest.addCacheControlHeaderField(headers: newHeaders, maxAge: maxAge, isPrivate: isPrivate)
                    } else {
                        return
                    }
                } else {
                    if httpResponse.allHeaderFields["Expires"] == nil || ignoreServer || useServerButRefresh {
                        DataRequest.addExpiresHeaderField(headers: newHeaders, maxAge: maxAge)
                        if ignoreServer {
                            if httpResponse.allHeaderFields["Pragma"] != nil {
                                newHeaders["Pragma"] = "cache"
                            }
                            if newHeaders["Cache-Control"] != nil {
                                newHeaders.removeObject(forKey: "Cache-Control")
                            }
                        }
                    } else {
                        return
                    }
                }
                newHeaders[AlamofireURLCache.refreshCacheKey] = AlamofireURLCache.RefreshCacheValue.useCache.rawValue
                if let newResponse = HTTPURLResponse(url: newURL, statusCode: httpResponse.statusCode, httpVersion: AlamofireURLCache.HTTPVersion, headerFields: newHeaders as? [String : String]) {
                    
                    let newCacheResponse = CachedURLResponse(response: newResponse, data: newData, userInfo: ["framework":AlamofireURLCache.frameworkName], storagePolicy: URLCache.StoragePolicy.allowed)
                    
                    urlCache.storeCachedResponse(newCacheResponse, for: newRequest)
                }
            }
            
        }
        
    }
    
    @discardableResult
    public func response<T: DataResponseSerializerProtocol>(
        queue: DispatchQueue? = nil,
        responseSerializer: T,
        completionHandler: @escaping (DataResponse<T.SerializedObject>) -> Void,
        autoClearCache:Bool)
        -> Self
    {
        let myCompleteHandler:((DataResponse<T.SerializedObject>) ->Void) = {
            dataResponse in
            if dataResponse.error != nil && autoClearCache {
                if let request = dataResponse.request {
                    Alamofire.clearCache(request: request)
                }
            }
            completionHandler(dataResponse)
        }
       
        return response(queue: queue, responseSerializer:responseSerializer ,completionHandler: myCompleteHandler)
    }

    @discardableResult
    public func responseData(
        queue: DispatchQueue? = nil,
        completionHandler: @escaping (DataResponse<Data>) -> Void,
        autoClearCache:Bool)
        -> Self
    {
        return response(
            queue: queue,
            responseSerializer: DataRequest.dataResponseSerializer(),
            completionHandler: completionHandler,
            autoClearCache:autoClearCache
        )
    }
    
    @discardableResult
    public func responseString(
        queue: DispatchQueue? = nil,
        encoding: String.Encoding? = nil,
        completionHandler: @escaping (DataResponse<String>) -> Void,
        autoClearCache:Bool)
        -> Self
    {
        return response(
            queue: queue,
            responseSerializer: DataRequest.stringResponseSerializer(encoding: encoding),
            completionHandler: completionHandler,
            autoClearCache:autoClearCache
        )
    }
    
    @discardableResult
    public func responseJSON(
        queue: DispatchQueue? = nil,
        options: JSONSerialization.ReadingOptions = .allowFragments,
        completionHandler: @escaping (DataResponse<Any>) -> Void,
        autoClearCache:Bool)
        -> Self
    {
        return response(
            queue: queue,
            responseSerializer: DataRequest.jsonResponseSerializer(options: options),
            completionHandler: completionHandler,
            autoClearCache:autoClearCache
        )
    }
    
    // MARK: - Private method
    fileprivate static func addCacheControlHeaderField(headers:NSDictionary,maxAge:Int,isPrivate:Bool) {
        var cacheValue = "max-age=\(maxAge)"
        if isPrivate {
            cacheValue += ",private"
        }
        headers.setValue(cacheValue, forKey: "Cache-Control")
    }
    
    fileprivate static func addExpiresHeaderField(headers:NSDictionary,maxAge:Int) {
        guard let dateString = headers["Date"] as? String else { return }
        let formate = DateFormatter()
        formate.dateFormat = "E, dd MMM yyyy HH:mm:ss zzz"
        formate.timeZone = TimeZone(identifier: "UTC")
        guard let date = formate.date(from: dateString) else { return }
        let expireDate = Date(timeInterval: TimeInterval(maxAge), since: date)
        let cacheValue = formate.string(from: expireDate)
        headers.setValue(cacheValue, forKey: "Expires")
    }

}
