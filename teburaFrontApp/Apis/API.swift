//
//  DemosukeAPI.swift
//  demonosuke
//
//  Created by 佐竹映季 on 2017/06/09.
//  Copyright © 2017年 佐竹映季. All rights reserved.
//


import Foundation
import RxCocoa
import RxSwift
import Unbox
import UIKit
import Alamofire

class API {
    
    static let endPoint: String = {
        return Config.endPoint
    }()
    
    private let manager: SessionManager = {
        return SessionManager.default
    }()
    
    init() {
        
    }
    
    func request(_ urlRequest: URLRequest) -> DataRequest {
        return self.manager.request(urlRequest)
    }
    
    func request(_ urlRequestConvertible: Alamofire.URLRequestConvertible) -> DataRequest {
        return self.manager.request(urlRequestConvertible)
    }
    
    /**
     * 認証ステータス取得
     * このAPIだけResourceではなくAuthStatusTypeを直接返す。
     */
    func authStatus() -> Observable<AuthStatusType> {
        print("hogehoge2")
        
        let observable:Observable<AuthStatusType> = Observable.create { [unowned self] observer in
            print("demosuke.authstatus")
            
            guard let request = self.makeAuthStatusRequest() else {
                print("demosuke.authstatus error")
                
                observer.onError(AuthStatusError.FailedOfCreatingRequest(nil))
                return Disposables.create()
            }
            
            self.request(request).validate().responseJSON { response in
                switch response.result {
                case .success(_):
                    observer.onNext(.LoggedIn)
                    observer.onCompleted()
                case .failure:
                    if let failureResponse = response.response {
                        switch failureResponse.statusCode {
                        case 401:
                            observer.onNext(.Expired)
                        case 400...499:
                            observer.onError(AuthStatusError.InvalidRequest(nil))
                        case 500...599:
                            observer.onError(AuthStatusError.Server(nil))
                        default:
                            observer.onError(AuthStatusError.Unknown(nil))
                        }
                    } else {
                        observer.onError(AuthStatusError.Unknown(nil))
                    }
                }
            }
            
            return Disposables.create()
        }
        return observable
    }
    
    /*
     * ログイン
     */
    func login(email: String, password: String) -> Observable<LoginResource> {
        let observable:Observable<LoginResource> = Observable.create { [unowned self] observer in
            guard let request = self.makeAuthRequest(email, password: password) else {
                observer.onError(LoginError.FailedOfCreatingRequest(nil))
                return Disposables.create()
            }
            
            let _request = self.request(request).validate().responseJSON { response in
                switch response.result {
                case .success(let data):
                    print("demosukeAPI",data)
                    guard
                        let json = data as? UnboxableDictionary,
                        let resource: LoginResource = try? unbox(dictionary: json)
                        else {
                            print("parse 失敗")
                            observer.on(.error(LoginError.Server(nil)))
                            return
                    }
                    print("demosukeAPI resource",resource)
                    observer.on(.next(resource))
                    observer.on(.completed)
                    
                case .failure(_):
                    print("demosukeAPI error")
                    if let failureResponse = response.response {
                        switch failureResponse.statusCode {
                        case 401:
                            observer.on(.error(LoginError.InvalidRequest(nil)))
                        case 500...599:
                            observer.on(.error(LoginError.Server(nil)))
                        default:
                            observer.on(.error(LoginError.Unknown(nil)))
                        }
                    } else {
                        observer.onError(LoginError.Unknown(nil))
                    }
                }
            }
            print(_request.debugDescription)
            
            return Disposables.create()
        }
        return observable
    }
    
    /*
     * ログアウト
     */
    func logout() -> Observable<Bool> {
        print("logoutAPI")
        let observable:Observable<Bool> = Observable.create { [unowned self] observer in
            
            guard let request = self.makeLogoutRequest() else {
                observer.onError(LoginError.FailedOfCreatingRequest(nil))
                return Disposables.create()
            }
            
            let _request = self.request(request).validate().responseJSON { response in
                switch response.result {
                case .success(let data):
                    
                    guard
                        let json = data as? UnboxableDictionary,
                        let _: LogoutResource = try? unbox(dictionary: json)
                        else {
                            observer.on(.error(LoginError.Server(nil)))
                            return
                    }
                    
                    observer.on(.next(true))
                    observer.on(.completed)
                    
                case .failure(_):
                    if let failureResponse = response.response {
                        switch failureResponse.statusCode {
                        case 401:
                            observer.on(.error(LoginError.InvalidRequest(nil)))
                        case 500...599:
                            observer.on(.error(LoginError.Server(nil)))
                        default:
                            observer.on(.error(LoginError.Unknown(nil)))
                        }
                    } else {
                        observer.onError(LoginError.Unknown(nil))
                    }
                }
            }
            print(_request.debugDescription)
            
            return Disposables.create()
        }
        return observable
    }
    
    /*
     * バーコードupdate用
     */
    func barcodeUpdate(itemId:String) -> Observable<BarcodeResource> {
        typealias listError = BarcodeError
        print("barcodeUpdate発動1")
        
        let observable:Observable<BarcodeResource> =  Observable.create { [unowned self] observer in
            print("barcodeUpdate発動2")
            
            guard let request = self.makeBarcodeRequest(itemId: itemId) else {
                observer.onError(BarcodeError.FailedOfCreatingRequest(nil))
                return Disposables.create()
            }
            
            print("barcodeUpdate発動3")
            
            let _request = self.request(request).validate().responseJSON { response in
                print("barcodeUpdate発動4",response)
                
                switch response.result {
                case .success(let data):
                    
                    guard
                        let json = data as? UnboxableDictionary,
                        let resource: BarcodeResource = try? unbox(dictionary: json)
                        else {
                            print("パース失敗")
                            observer.onError(NewsError.Server(nil))
                            return
                    }
                    
                    observer.onNext(resource)
                    observer.onCompleted()
                    
                case .failure(let error):
                    print("barcode error",error)
                    if let failureResponse = response.response {
                        switch failureResponse.statusCode {
                        case 401:
                            observer.on(.error(BarcodeError.InvalidRequest(nil)))
                        case 500...599:
                            observer.on(.error(BarcodeError.Server(nil)))
                        default:
                            observer.on(.error(BarcodeError.Unknown(nil)))
                        }
                    } else {
                        observer.onError(BarcodeError.Unknown(nil))
                    }
                }
            }
            
            
            _request.resume()
            print(_request.debugDescription)
            
            return Disposables.create {
                _request.cancel()
            }
        }
        return observable
    }
    
    //ログイン用URLRequestを作成
    private func makeAuthRequest(_ email: String, password: String) -> URLRequest? {
        let userDefaults = UserDefaults.standard
        
        guard let deviceToken = userDefaults.string(forKey: "deviceToken") else {
            return nil
        }
        
        let builder = HttpRequestBuilder(requestModel: UserAuthRequestModel(email: email, password: password, deviceToken: deviceToken))
        return try? builder.build(encord: .Json)
    }
    
    //ログアウト用URLRequestを作成
    private func makeLogoutRequest() -> URLRequest? {
        let builder = HttpRequestBuilder(requestModel: UserLogoutRequestModel())
        guard let user = self.loadUser() else {
            return nil
        }
        builder.addHeader(key: "Authorization", value:"Bearer " + user.token)
        return try? builder.build(encord: .Json)
    }
    
    //認証ステータス確認用URLRequestを作成
    private func makeAuthStatusRequest() -> URLRequest? {
        let builder = HttpRequestBuilder(requestModel: AuthStatusRequestModel())
        
        guard let user = self.loadUser() else {
            print("noUserDefault")
            return nil
        }
        builder.addHeader(key: "Accept", value:"application/json")
        builder.addHeader(key: "Authorization", value:"Bearer " + user.token)
        return try? builder.build(encord: .Json)
    }
    
    
    
    //バーコード用URLRequestを作成
    private func makeBarcodeRequest(itemId:String) -> URLRequest? {
        let builder = HttpRequestBuilder(requestModel: BarcodeRequestModel(itemId: itemId))
        
        //        guard let user = self.loadUser() else {
        //            return nil
        //        }
        
        //        builder.addHeader(key: "Accept", value:"application/json")
        //        builder.addHeader(key: "Authorization", value:"Bearer " + user.token)
        return try? builder.build()
    }
    
    private func loadUser() -> User? {
        return di.resolve(AuthService.self)!.user
    }
}


