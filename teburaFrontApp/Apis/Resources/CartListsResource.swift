//
//  CartListsResource.swift
//
//  Created by 佐竹映季 on 2017/07/31.
//  Copyright © 2017年 佐竹映季. All rights reserved.
//


import Foundation
import Unbox

struct CartListsResource {
    let data:[Items]
    
    struct Items {
        let id: String
        let title: String
        let image: String
        let price: Int
    }
}

extension CartListsResource : Unboxable {
    init(unboxer: Unboxer) throws {
        self.data = try unboxer.unbox(key: "data")
    }
}

extension CartListsResource.Items : Unboxable {
    init(unboxer: Unboxer) throws {
        self.id = try unboxer.unbox(key: "Id")
        self.title = try unboxer.unbox(keyPath: "Item__r.Name")
        self.image = try unboxer.unbox(keyPath: "Item__r.Image__c")
        self.price = try unboxer.unbox(keyPath: "Item__r.Price__c")
    }
}
