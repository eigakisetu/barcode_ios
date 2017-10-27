//
//  RequestsResource.swift
//  demonosuke
//
//  Created by 佐竹映季 on 2017/06/11.
//  Copyright © 2017年 佐竹映季. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import Alamofire

//型のエイリアスを作る
//http://qiita.com/yosan/items/5e2708d149b859662540
typealias HTTPHeaders = Alamofire.HTTPHeaders
typealias HTTPMethod = Alamofire.HTTPMethod
typealias Parameters = Alamofire.Parameters
typealias URLEncoding = Alamofire.URLEncoding

protocol HttpRequestModel {
    var method: HTTPMethod {get}
    var path: String {get}
    var httpHeaders: HTTPHeaders? { get }
    var url: URL {get}
    var parameters: Parameters? {get}
    var encoding: URLEncoding? {get}
}

enum EncodeType : String {
    case Url
    case Json
}

extension HttpRequestModel {
    var httpHeaders: HTTPHeaders? {
        return nil
    }
    
    var parameters: Parameters? {
        return nil
    }
    
    var encoding: URLEncoding? {
        return nil
    }
}

class HttpRequestBuilder {
    private (set) var allHttpHeaders: HTTPHeaders
    
    private var requestModel: HttpRequestModel
    private var baseHttpHeaders: HTTPHeaders
    private var overrideHeaders: HTTPHeaders
    
    init(requestModel: HttpRequestModel) {
        self.requestModel = requestModel
        self.baseHttpHeaders = [:]
        self.overrideHeaders = [:]
        self.allHttpHeaders = [:]
        self.allHttpHeaders = self.buildHttpHeaders()
    }
    
    func setRequestModel(_ requestModel: HttpRequestModel) {
        self.requestModel = requestModel
    }
    
    func setBaseHttpHeaders(_ baseHttpHeaders: HTTPHeaders) {
        self.baseHttpHeaders = baseHttpHeaders
        self.updateAllHttpHeaders()
    }
    
    func setOverrideHttpHeaders(_ overrideHttpHeaders: HTTPHeaders) {
        self.overrideHeaders = overrideHttpHeaders
        self.updateAllHttpHeaders()
    }
    
    func addHeader(key: String, value: String) {
        self.overrideHeaders[key] = value
        self.updateAllHttpHeaders()
    }
    
    func addHeaders(_ headers: HTTPHeaders) {
        headers.forEach { (key: String, value: String) in
            self.overrideHeaders[key] = value
        }
        
        self.updateAllHttpHeaders()
    }
    
    private func updateAllHttpHeaders() {
        let headers = self.buildHttpHeaders()
        self.allHttpHeaders = headers
    }
    
    private func buildHttpHeaders() -> HTTPHeaders {
        var buildingHeaders: HTTPHeaders = [:]
        
        self.baseHttpHeaders.forEach({ (key: String, value: String) in
            buildingHeaders[key] = value
        })
        
        if let headers = self.requestModel.httpHeaders {
            headers.forEach({ (key: String, value: String) in
                buildingHeaders[key] = value
            })
        }
        
        self.overrideHeaders.forEach({ (key: String, value: String) in
            buildingHeaders[key] = value
        })
        
        return buildingHeaders
    }
    
    func build(encord:EncodeType = .Url) throws -> URLRequest {
        self.updateAllHttpHeaders()
        
        var urlReq = URLRequest(url: self.requestModel.url)
        urlReq.httpMethod = self.requestModel.method.rawValue.uppercased()
        
        if self.allHttpHeaders.count > 0 {
            urlReq.allHTTPHeaderFields = self.allHttpHeaders
        }
        
        if let params = self.requestModel.parameters{
            
            if encord == .Json{
                return try JSONEncoding.default.encode(urlReq, with: params)
            } else {
                return try URLEncoding.httpBody.encode(urlReq, with: params)
            }
        }
        
        return urlReq
    }
    
    func clearAllHttpHeaders() {
        self.allHttpHeaders.removeAll()
    }
}

/// ログインステータスの確認
class AuthStatusRequestModel: HttpRequestModel {
    var method: HTTPMethod {
        return .post
    }
    
    var path: String {
        return "api/user"
    }
    
    var url : URL {
        return URL(string: API.endPoint)!.appendingPathComponent(self.path)
    }
}

/// ユーザー認証
class UserAuthRequestModel: HttpRequestModel {
    let email: String
    let password: String
    let deviceToken: String
    
    var method: HTTPMethod {
        return .post
    }
    
    var path: String {
        return "api/login"
    }
    
    var url: URL {
        return URL(string: API.endPoint)!.appendingPathComponent(self.path)
    }
    
    var parameters: Parameters? {
        return [
            "email": self.email,
            "password": self.password,
            "deviceToken": self.deviceToken
        ]
    }
    
    init(email: String, password: String,deviceToken: String) {
        self.email = email
        self.password = password
        self.deviceToken = deviceToken
    }
}

/// ログアウト
class UserLogoutRequestModel: HttpRequestModel {
    var method: HTTPMethod {
        return .post
    }
    
    var path: String {
        return "api/logout"
    }
    
    var url: URL {
        return URL(string: API.endPoint)!.appendingPathComponent(self.path)
    }
    
    //    var encoding: URLEncoding? {
    //        return URLEncoding.httpBody
    //    }
}

//バーコード 決済デモ
class BarcodeRequestModel: HttpRequestModel {
    var itemId: String
    
    var method: HTTPMethod {
        return .post
    }
    
    var parameters: Parameters? {
        return [
            "item_id": self.itemId,
            "sf_id":"0037F00000EJmnW"
        ]
    }
    
    var path: String {
        return "api/cart"
    }
    
    var url : URL {
        return URL(string: API.endPoint)!.appendingPathComponent(self.path)
    }
    
    init(itemId: String) {
        self.itemId = itemId
    }
}





