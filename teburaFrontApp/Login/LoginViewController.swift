//
//  LoginViewController.swift
//  demonosuke
//
//  Created by 佐竹映季 on 2017/06/09.
//  Copyright © 2017年 佐竹映季. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import UIKit
import GradientCircularProgress

class LoginViewController : UIViewController {
    @IBOutlet weak var viewBorderTop: UIView!
    @IBOutlet weak var viewBorderBottom: UIView!
    
    @IBOutlet weak var mailAddressField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    private let bag = DisposeBag()
    private var progressView: UIView?
    private var viewModel: LoginViewModel!
    
    var progress: GradientCircularProgress!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewBorderTop.backgroundColor = UIColor(patternImage: UIImage(named: "border.png")!)
        viewBorderBottom.backgroundColor = UIColor(patternImage: UIImage(named: "border.png")!)
        
        self.mailAddressField.text = Config.testMailAddress
        self.passwordField.text = Config.testPassword
        
        //パスワードを伏字にする
        self.passwordField.isSecureTextEntry = true
        
        //controllerとmodelを結びつける
        //orEmptyは空文字やnilはオブザーブしない機能
        viewModel = di.resolve(LoginViewModel.self, arguments:
            self.mailAddressField.rx.text.orEmpty.asObservable(),
                               self.passwordField.rx.text.orEmpty.asObservable(),
                               self.loginButton.rx.tap.asObservable()
        )
        
        //ログインボタンが押せるかどうかを判定
        viewModel.loginEnabled.bind { [unowned self] valid in
            self.loginButton.isHighlighted = !valid
            self.loginButton.isEnabled = valid
            }
            .disposed(by: bag)
        
        //ログインボタン押したときの挙動
        viewModel.loginTapStarted
            .subscribe(onNext: { [unowned self] _ in
                //読み込みインジゲーターを発動
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                self.showProgressIndicator()
            })
            .disposed(by: bag)
        
        //ログインAPIレスポンス後の挙動
        viewModel.login
            .subscribe(
                onNext: { [unowned self] isLoggedin in
                    //読み込みインジゲーターをストップする
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    self.dismisProgressIndicator()
                    
                    //ログイン判定
                    if !isLoggedin {
                        self.showInvalidUserDataAlert()
                    } else {
                        self.performSegue(withIdentifier: "toTop", sender: nil)
                    }
                }
            )
            .disposed(by: bag)
    }
    
    //セグエ
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }
    
    //ログインインジケータ
    private func showProgressIndicator() {
        //DIContainerにてLoginViewControllerにprogressをinjectionする必要がある
        if !self.progress.isAvailable {
            let frame = self.view.frame
            self.progressView = self.progress
                .show(frame: frame, message: "ログイン", style: Config.IndicatorOriginalStyle())
            self.view.addSubview((self.progressView)!)
        }
    }
    
    private func dismisProgressIndicator() {
        if self.progress.isAvailable {
            self.progress.dismiss(progress: self.progressView!)
        }
    }
    
    private func showInvalidUserDataAlert() {
        let alert = UIAlertController(title: "確認", message: "ユーザー名かパスワードが違います。", preferredStyle: .alert)
        let close = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil)
        alert.addAction(close)
        self.present(alert, animated: false, completion:nil)
    }
    
    @IBAction func unwindToLogin(_ segue: UIStoryboardSegue) {
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
}

extension LoginViewController : UIBarPositioningDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}


extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}


