//
//  UserLocalDefaults.swift
//  demonosuke
//
//  Created by 佐竹映季 on 2017/06/10.
//  Copyright © 2017年 佐竹映季. All rights reserved.
//


import Foundation
import UIKit

class UserLocalDefaults {
    
    /**
     * 下位バージョンとの互換性維持のために値はそのままにする。
     * (以前のバージョンとキーが変わってしまうとバージョンアップ時にうまく動作しなくなるので)
     **/
    enum LocalStoreKeys: String {
        case token
        case UserAuthStatusType
        case id
        case name
        case email
    }
    
    //userDefaults定義
    private let localStore: UserDefaults
    
    //todo:localstoreにUserDefaultsをインスタンス化させてinit
    static let instance: UserLocalDefaults = {
        let userDefaults = UserDefaults.standard
        return UserLocalDefaults(localStore: userDefaults)
    }()
    
    private init(localStore: UserDefaults) {
        self.localStore = localStore
    }
    
    func storeAuthStatus(_ status: AuthStatusType) {
        self.localStore.set(status.rawValue, forKey: LocalStoreKeys.UserAuthStatusType.rawValue)
        self.localStore.synchronize()
    }
    
    func authStatus() -> AuthStatusType? {
        if let statusRawValue = self.localStore.string(forKey: LocalStoreKeys.UserAuthStatusType.rawValue) {
            return AuthStatusType(rawValue: statusRawValue)
        }
        
        return nil
    }
    
    func storeUser(_ user: User) {
        self.localStore.set(user.token, forKey: LocalStoreKeys.token.rawValue)
        self.localStore.set(user.id, forKey: LocalStoreKeys.id.rawValue)
        self.localStore.set(user.name, forKey: LocalStoreKeys.name.rawValue)
        self.localStore.set(user.email, forKey: LocalStoreKeys.email.rawValue)
        self.localStore.synchronize()
    }
    
    func removeUser() {
        self.localStore.removeObject(forKey: LocalStoreKeys.token.rawValue)
        self.localStore.removeObject(forKey: LocalStoreKeys.id.rawValue)
        self.localStore.removeObject(forKey: LocalStoreKeys.name.rawValue)
        self.localStore.removeObject(forKey: LocalStoreKeys.email.rawValue)
        self.localStore.synchronize()
    }
    
    //アプリinit時にログイン状態を保持していた場合、user()でユーザー情報を返す
    func user() -> User? {
        let userDefaults = self.localStore
        
        if let token = userDefaults.string(forKey: LocalStoreKeys.token.rawValue),
            let id = userDefaults.string(forKey: LocalStoreKeys.id.rawValue),
            let name = userDefaults.string(forKey: LocalStoreKeys.name.rawValue),
            let email = userDefaults.string(forKey: LocalStoreKeys.email.rawValue)
        {
            return self.makeUserInstance(token,id: id,name:name, email:email)
        } else {
            return nil
        }
    }
    
    private func makeUserInstance(_ token: String, id: String, name: String, email: String) -> User {
        return User(token: token, id: id, name:name, email:email)
    }
}


