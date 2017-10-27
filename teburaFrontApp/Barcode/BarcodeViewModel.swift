//
//  BarcodeViewModel.swift
//  demonosuke
//
//  Created by 佐竹映季 on 2017/06/20.
//  Copyright © 2017年 佐竹映季. All rights reserved.
//

import Foundation
import UIKit
import RxCocoa
import RxSwift
import Kingfisher
import Unbox

class BarcodeViewModel {
    private let api: API
    
    //DIControllerにて初期値実装
    //initでObservaleを定義するとつどつどメソッドが呼ばれるたびにObservableを生成しなくてすむ
    init(
        api: API) {
        self.api = api
    }
    
    func fetch(itemId:String) -> Observable<Bool>  {
        return api.barcodeUpdate(itemId: itemId)
            .map { result in
                print("BarcodeViewModel result",result)
                return true
            }
            .catchErrorJustReturn(false)
    }
}


