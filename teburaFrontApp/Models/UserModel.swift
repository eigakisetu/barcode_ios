//
//  UserModel.swift
//  demonosuke
//
//  Created by 佐竹映季 on 2017/06/11.
//  Copyright © 2017年 佐竹映季. All rights reserved.
//

import Foundation

class User {
    let  token: String
    let  id: String
    let  name: String
    let  email: String
    
    init(token: String,id:String,name:String,email:String) {
        self.token = token
        self.id = id
        self.name = name
        self.email = email
    }
    
    static func from(loginResource resource: LoginResource) -> User? {
        guard let token:String = resource.token,
            let id:String = resource.id,
            let name:String = resource.name,
            let email:String = resource.email
            else {
                return nil
        }
        
        return User(token: token, id: id,name:name,email:email)
    }
}




