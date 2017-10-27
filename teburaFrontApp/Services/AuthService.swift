//
//  AuthSerice.swift
//  demonosuke
//
//  Created by 佐竹映季 on 2017/06/09.
//  Copyright © 2017年 佐竹映季. All rights reserved.
//


import Foundation
import UIKit
import RxCocoa
import RxSwift
import Alamofire
//import Kingfisher

class AuthService {
    
    private let localStore: UserLocalDefaults
    private let api: API
    
    //private(set) 外部からの代入は受け付けない
    private(set) var user: User?
    private(set) var status: AuthStatusType = .Unknown //ログイン状態
    
    private let didLogInStream = PublishSubject<User>()//Observable でありつつ、イベントを発生させるための onNext/onError/onCompleted メソッドを提供
    let didLogIn: Observable<User>
    
    private let didLogOutStream = PublishSubject<User>()//Observable でありつつ、イベントを発生させるための onNext/onError/onCompleted メソッドを提供
    let didLogOut: Observable<User>
    
    private let disposeBag: DisposeBag
    
    init(localStore: UserLocalDefaults, api: API) {
        self.disposeBag = DisposeBag()
        self.localStore = localStore
        self.api = api
        self.didLogIn = didLogInStream
            .asObserver()
            .shareReplay(1)
        
        self.didLogOut = didLogOutStream
            .asObserver()
            .shareReplay(1)
        
        self.status = self.loadStatus()
        
        //ログイン状態じゃなかったらuserdefaultからログイン状態を取得
        if self.status == .LoggedIn {
            self.user = self.loadUser()
            
        }
        
        didLogInStream.disposed(by: disposeBag)
        didLogOutStream.disposed(by: disposeBag)
    }
    
    //ステータス確認
    private func loadStatus() -> AuthStatusType {
        //userdefaultからステータス状態を返す
        if let status = self.localStore.authStatus() {
            return status
        }
        return .Unknown
    }
    
    private func loadUser() -> User? {
        return self.localStore.user()
    }
    
    /**
     * ログインできたらtrue
     */
    //Boolで返す
    func login(email: String, password: String) -> Observable<Bool>  {
        return api.login(email: email, password: password)
            .map { [unowned self] in self.loggedIn($0) } //DemosukeAPIで返されたLoginResourceをここでBoolに変換 mapはObservableの型を変換できる
            .catchErrorJustReturn(false)// エラーをfalseに変換
            .subscribeOn(MainScheduler.asyncInstance)//メインスレッドで非同期で実行
            .observeOn(MainScheduler.instance)
            .do(onNext: { [unowned self] result in
                if result {
                    self.fireEvent(target: .LoggedIn, user: self.user!)
                }
            })
    }
    
    //ログアウト
    func logout() -> Observable<Bool> {
        return api.logout()
            .subscribeOn(MainScheduler.asyncInstance)//メインスレッドで非同期で実行
            .observeOn(MainScheduler.instance)
            .catchErrorJustReturn(false)
            .do(onNext: { [unowned self] result in
                print("authservice logout",result)
                if result {
                    if self.status == .LoggedIn {
                        let user = self.user!
                        self.loggedOut()
                        self.fireEvent(target: .LoggedOut, user: user)
                    }
                }
            })
    }
    
    //ログアウト トークンを消すのみのバージョン
    //    func logout() {
    //        if self.status == .LoggedIn {
    //            let user = self.user!
    //            self.loggedOut()
    //            self.fireEvent(target: .LoggedOut, user: user)
    //        }
    //    }
    
    //ログインフラグ
    enum Events {
        case LoggedIn
        case LoggedOut
    }
    
    private func fireEvent(target event: Events, user: User){
        switch event {
        case .LoggedIn:
            self.didLogInStream.onNext(user)
        case .LoggedOut:
            self.didLogOutStream.onNext(user)
        }
    }
    
    //demosukeAPIからLoginResourceが引き上がってくるのでここでuserクラスに格納
    private func loggedIn(_ resource: LoginResource) -> Bool {
        if let user = User.from(loginResource: resource) {//User.from でUserクラスの変数にLoginResourceの値を格納
            self.localStore.storeUser(user)////userdefaultにtokenを格納する
            self.updateStatus(.LoggedIn)//userdefaultのログインステータスを.LoggedInにする
            self.user = user
            return true
        }
        return false
    }
    
    func loggedOut() {
        self.localStore.removeUser()
        self.updateStatus(.LoggedOut)
        self.user = nil
    }
    
    func updateStatus(_ status: AuthStatusType) {
        self.localStore.storeAuthStatus(status)
        self.status = status
    }
    
    private func updateAuthStatus(_ status: AuthStatusType) -> AuthStatusType {
        if status == .LoggedIn {
            self.status = status
            self.updateStatus(.LoggedIn)
            return .LoggedIn
        }
        if status == .Expired {
            self.status = status
            self.updateStatus(.Expired)
            return .Expired
        }
        self.updateStatus(.Unknown)
        return .Unknown
    }
    
    func authStatus() -> Observable<AuthStatusType>  {
        return api.authStatus().subscribeOn(MainScheduler.asyncInstance).catchErrorJustReturn(.Unknown)
    }
    
}


