//
//  Response.swift
//  demonosuke
//
//  Created by 佐竹映季 on 2017/06/10.
//  Copyright © 2017年 佐竹映季. All rights reserved.
//

import Foundation

enum AuthStatusType : String {
    case LoggedIn
    case Expired
    case LoggedOut
    case Unknown
}

enum AuthStatusError: Error {
    case FailedOfCreatingRequest(String?)
    case InvalidRequest(String?)
    case Server(String?)
    case Unknown(String?)
}

enum LoginError: Error {
    case FailedOfCreatingRequest(String?)
    case InvalidRequest(String?)
    case Server(String?)
    case Unknown(String?)
}

enum NewsError: Error {
    case FailedOfCreatingRequest(String?)
    case InvalidRequest(String?)
    case Server(String?)
    case Unknown(String?)
}

enum BarcodeError: Error {
    case FailedOfCreatingRequest(String?)
    case InvalidRequest(String?)
    case Server(String?)
    case Unknown(String?)
}

enum ImageError: Error {
    case FailedOfCreatingRequest(String?)
    case InvalidRequest(String?)
    case Server(String?)
    case Unknown(String?)
}


