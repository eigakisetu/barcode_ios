//
//  loginViewModel.swift
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


class LoginViewModel {
    
    private let email: Observable<String>
    private let password: Observable<String>
    private let loginTaps: Observable<Void>
    private let authService: AuthService
    
    let loginTapStarted: Observable<(String, String)>
    let loginEnabled: Observable<Bool>
    let login: Observable<Bool>
    
    //DIControllerでLoginViewControllerと結びついている
    //DIControllerにて初期値実装
    //initでObservaleを定義するとつどつどメソッドが呼ばれるたびにObservableを生成しなくてすむ
    init(
        input: (
        email: Observable<String>,
        password: Observable<String>,
        loginTaps: Observable<Void>
        ),
        authService: AuthService
        ) {
        self.email = input.email
        self.password = input.password
        self.loginTaps = input.loginTaps
        self.authService = authService
        
        //combineLatest : ２つのObsrvablesの内どちらかから１つのアイテムが送信される時、指定された関数によって、各Observableから送信される最新のアイテムを結合し、この関数の評価に基づいたアイテムを送信する。
        //distinctUntilChanged : Observableによって送信される重複するアイテムを除去する [1, 2, 3, 1, 1, 4]→1, 2, 3, 1,4
        //shareReplayはcoldをhotにする
        self.loginEnabled = Observable
            .combineLatest(self.email, self.password) {//
                $0.characters.count > 0 && $1.characters.count > 0
            }
            .distinctUntilChanged()
            .shareReplay(1)
        
        
        //todo:なにをやっているのか聞く
        //直前の値と異なる値ではないときにtrueとなってかえる？
        let emailWithPassword = Observable
            .combineLatest(self.email, self.password) { ($0, $1) }
            .distinctUntilChanged { lhs, rhs -> Bool in
                return lhs.0 == rhs.0 && lhs.1 == rhs.1
        }
        
        
        self.loginTapStarted = self.loginTaps
            .withLatestFrom(emailWithPassword)
            .shareReplay(1)
        
        self.login = self.loginTapStarted
            .flatMapLatest {
                authService.login(email: $0, password: $1)
            }
            .shareReplay(1)
        
    }
    
}


