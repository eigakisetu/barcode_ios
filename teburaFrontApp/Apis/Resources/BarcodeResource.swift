//
//  BarcodeResource.swift
//  demonosuke
//
//  Created by 佐竹映季 on 2017/06/21.
//  Copyright © 2017年 佐竹映季. All rights reserved.
//

import Foundation
import Unbox

struct BarcodeResource {
    let status: String
}

extension BarcodeResource : Unboxable {
    init(unboxer: Unboxer) throws {
        self.status = try unboxer.unbox(key: "status")
    }
}



