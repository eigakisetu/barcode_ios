//
//  LoginResource.swift
//  demonosuke
//
//  Created by 佐竹映季 on 2017/06/11.
//  Copyright © 2017年 佐竹映季. All rights reserved.
//

import Foundation
import Unbox

struct LoginResource {
    let token: String
    let id: String
    let name: String
    let email: String
}

extension LoginResource : Unboxable {
    init(unboxer: Unboxer) throws {
        self.token = try unboxer.unbox(key: "token")
        self.id = try unboxer.unbox(keyPath: "user.id")
        self.name = try unboxer.unbox(keyPath: "user.name")
        self.email = try unboxer.unbox(keyPath: "user.email")
    }
}


