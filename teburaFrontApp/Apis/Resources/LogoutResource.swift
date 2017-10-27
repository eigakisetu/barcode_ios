//
//  LogoutResource.swift
//  demonosuke
//
//  Created by 佐竹映季 on 2017/07/25.
//  Copyright © 2017年 佐竹映季. All rights reserved.
//

import Foundation
import Unbox

struct LogoutResource {
    let status: String
}

extension LogoutResource : Unboxable {
    init(unboxer: Unboxer) throws {
        self.status = try unboxer.unbox(key: "status")
    }
}


