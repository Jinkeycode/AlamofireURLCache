# AlamofireURLCache

AlamofireURLCache for CocoaPods

The mirror of [kenshincui/AlamofireURLCache](https://github.com/kenshincui/AlamofireURLCache) which unsupported [CocoaPods](https://cocoapods.org/)

You can install by
```
pod 'AlamofireURLCache'
```

# Contact me

[QQ](https://im.qq.com/download/) Group 706964206

# Usage

## Cache and refresh

You can use the *cache()* method to save cache for this request, and set the request with the *refreshCache* parameter to re-initiate the request to refresh the cache data.

* Simply cache data

```swift
Alamofire.request("https://myapi.applinzi.com/url-cache/no-cache.php").responseJSON(completionHandler: { response in
    if response.value != nil {
        self.textView.text = (response.value as! [String:Any]).debugDescription
    } else {
        self.textView.text = "Error!"
    }
    
}).cache(maxAge: 10)
```

* Refresh cache

```swift
Alamofire.request("https://myapi.applinzi.com/url-cache/no-cache.php",refreshCache:true).responseJSON(completionHandler: { response in
    if response.value != nil {
        self.textView.text = (response.value as! [String:Any]).debugDescription
    } else {
        self.textView.text = "Error!"
    }
    
}).cache(maxAge: 10)
```

## Ignore server-side cache configuration

By default, if the server is configured with cache headers, the server-side configuration is used, but you can use the custom cache age and ignore this configuration by setting the *ignoreServer* parameter。

```swift
Alamofire.request("https://myapi.applinzi.com/url-cache/default-cache.php",refreshCache:false).responseJSON(completionHandler: { response in
    if response.value != nil {
        self.textView.text = (response.value as! [String:Any]).debugDescription
    } else {
        self.textView.text = "Error!"
    }
    
}).cache(maxAge: 10,isPrivate: false,ignoreServer: true)
```

## Clear cache

Sometimes you need to clean the cache manually rather than refresh the cache data, then you can use AlamofireURLCache cache cache API. But for network requests error, serialization error, etc. we recommend the use of *autoClearCache* parameters Automatically ignores the wrong cache data.

```swift
Alamofire.clearCache(dataRequest: dataRequest) // clear cache by DataRequest
Alamofire.clearCache(request: urlRequest) // clear cache by URLRequest

// ignore data cache when request error
Alamofire.request("https://myapi.applinzi.com/url-cache/no-cache.php",refreshCache:false).responseJSON(completionHandler: { response in
    if response.value != nil {
        self.textView.text = (response.value as! [String:Any]).debugDescription
    } else {
        self.textView.text = "Error!"
    }
    
},autoClearCache:true).cache(maxAge: 10)
```

> When using AlamofireURLCache, we recommend that you add the *autoClearCache* parameter in any case.
