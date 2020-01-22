//
//  ViewController.swift
//  AlamofireURLCache
//
//  Created by Jinkey on 01/21/2020.
//  Copyright (c) 2020 Jinkey. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireURLCache

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        Alamofire.request(URL(string: "https://jinkey.ai")!).cache(maxAge: 3600, isPrivate: true, ignoreServer: true).response { (resp) in
            print("Status Code: \(resp.response?.statusCode ?? 0)")
        }
    }

}

