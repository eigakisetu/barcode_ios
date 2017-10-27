//
//  DIContainer.swift
//  demonosuke
//
//  Created by 佐竹映季 on 2017/06/09.
//  Copyright © 2017年 佐竹映季. All rights reserved.
//
import Foundation
import Swinject
import SwinjectStoryboard
import KeychainSwift
import RxCocoa
import RxSwift
import GradientCircularProgress

let di: Container = {
    
    Container.loggingFunction = nil
    
    let c: Container = Container()
    
    c.register(API.self) { container in
        API()
        }
        .inObjectScope(.container)
    
    c.register(AuthService.self) { container in
        AuthService(
            localStore: UserLocalDefaults.instance,
            api: container.resolve(API.self)!
        )
        }
        .inObjectScope(.container)
    
    c.register(UserLocalDefaults.self) { container in
        UserLocalDefaults.instance
        }
        .inObjectScope(.container)
    
    c.register(LoginViewModel.self)
    { (container: Resolver, email: Observable<String>, password: Observable<String>, loginTaps: Observable<Void>) in
        LoginViewModel(
            input:(
                email: email,
                password: password,
                loginTaps: loginTaps
            ),
            authService: container.resolve(AuthService.self)!
        )
    }
    
    c.register(BarcodeViewModel.self)
    { (container: Resolver) in
        BarcodeViewModel(
            api: container.resolve(API.self)!
        )
    }
    
    return c
    
}()

extension SwinjectStoryboard {
    class func setup() {
        defaultContainer.storyboardInitCompleted(LoginViewController.self, initCompleted: { (r, vc) in
            vc.progress =  GradientCircularProgress()
        })
        defaultContainer.storyboardInitCompleted(BarcodeViewController.self, initCompleted: { (r, vc) in
            vc.progress =  GradientCircularProgress()
        })
    }
}

