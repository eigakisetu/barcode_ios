//
//  BarcodeViewController.swift
//  demonosuke
//
//  Created by 佐竹映季 on 2017/06/20.
//  Copyright © 2017年 佐竹映季. All rights reserved.
//

import UIKit
import AVFoundation
import RxCocoa
import RxSwift
import GradientCircularProgress
import AudioToolbox

class BarcodeViewController: UIViewController , AVCaptureMetadataOutputObjectsDelegate {
    
    @IBOutlet weak var previewView: UIView!
    
    private var viewModel: BarcodeViewModel!
    private let bag = DisposeBag()
    
    private var progressView: UIView?
    var progress: GradientCircularProgress!
    
    // セッションのインスタンス生成
    var captureSession : AVCaptureSession!
    var videoLayer: AVCaptureVideoPreviewLayer!
    var videoDevice:AVCaptureDevice!
    var videoInput:AVCaptureInput!
    var metadataOutput:AVCaptureMetadataOutput!
    
    // プライバシーと入出力のステータス
    var authStatus:AuthorizedStatus = .authorized
    var inOutStatus:InputOutputStatus = .ready
    
    // 認証のステータス
    enum AuthorizedStatus {
        case authorized
        case notAuthorized
        case failed
    }
    
    // 入出力のステータス
    enum InputOutputStatus {
        case ready
        case notReady
        case failed
    }
    
    // 通知センターを作る
    let notification = NotificationCenter.default
    
    //エラー処理条件 todo:errer type
    enum BarcodeError: String {
        case shop = "利用可能店舗不一致エラー"
        case period = "利用期間外エラー"
        case qr = "読み取れないQRコードエラー"
        case used = "使用済みエラー"
        case communicate = "通信エラー"
        
        func getMessage() -> String {
            switch self {
            case .shop:
                return "読み取りしたQRコードは、利用可能店舗と一致しません。利用者へ確認をお願いします。"
            case .period:
                return "読み取りしたQRコードは、既に利用可能な期間を過ぎているようです。利用者へその旨お伝え下さい。"
            case .qr:
                return "読み取りしたQRコードが、読み取れません。再度読み込みをお願いします。何度も同じ症状の場合は、利用できないQRコードの可能性があります。"
            case .used:
                return "読み取りしたQRコードは、既に使用済みです。配布されたQRコードが使用できるのは1回限りです。利用者へその旨お伝え下さい。"
            case .communicate:
                return "通信エラーです。当該アプリを使用しているネットワーク環境（Wifi等）を確認し、再度読み取りを行って下さい。"
            }
        }
    }
    
    // カメラのプライバシー認証確認
    func cameraAuth(){
        let status = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        switch status {
        case .notDetermined:
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo,
                                          completionHandler: { [unowned self] authorized in
                                            if authorized {
                                                self.authStatus = .authorized
                                            } else {
                                                self.authStatus = .notAuthorized
                                            }})
        case .restricted, .denied:
            authStatus = .notAuthorized
        case .authorized:
            authStatus = .authorized
        }
    }
    
    // 入出力の設定
    func setupInputOutput(){
        self.captureSession = AVCaptureSession()
        do {
            
            // 入力（背面カメラ）
            self.videoDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
            self.videoInput = try AVCaptureDeviceInput.init(device: self.videoDevice)
            
            if captureSession.canAddInput(self.videoInput){
                captureSession.addInput(self.videoInput)
            } else {
                inOutStatus = .notReady
                return
            }
        } catch  _ as NSError {
            inOutStatus = .notReady
            return
        }
        
        
        // 出力
        self.metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(self.metadataOutput) {
            captureSession.addOutput(self.metadataOutput)
            
            // QRコードを検出した際のデリゲート設定
            self.metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            // QRコードの認識を設定
            self.metadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
            
            
        } else {
            inOutStatus = .notReady
            return
        }
    }
    
    // プライバシー認証のアラートを表示する
    func showAlert(appName:String){
        let aTitle = appName + "のプライバシー認証"
        let aMessage = "設定＞プライバシー＞" + appName + "で利用を許可してください。"
        let alert = UIAlertController(title: aTitle, message: aMessage, preferredStyle: .alert)
        
        // 設定を開くボタン
        alert.addAction(
            UIAlertAction(
                title: "設定を開く",style: .default,
                handler:  { action in
                    UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
            })
        )
        // アラートを表示する
        self.present(alert, animated: false, completion:nil)
    }
    
    //エラーアラートを出す
    func showErrorAlert(title:String = "エラー",message:String = "エラーが発生しました。"){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        // 閉じるボタン
        let close = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: {
            (action: UIAlertAction!) in
            
            for output in self.captureSession.outputs {
                self.captureSession.removeOutput(output as? AVCaptureOutput)
            }
            
            for input in self.captureSession.inputs {
                self.captureSession.removeInput(input as? AVCaptureInput)
            }
            self.captureSession = nil
            self.videoDevice = nil
            
            self.cameraAuth()
            self.setupInputOutput()
            if (self.authStatus == .authorized)&&(self.inOutStatus == .ready){
                self.setPreviewLayer()
                self.captureStart()
            }
        })
        
        alert.addAction(close)
        
        self.present(alert, animated: false, completion:nil)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.layer.masksToBounds = false
        self.navigationController?.navigationBar.layer.shadowColor = UIColor.lightGray.cgColor
        self.navigationController?.navigationBar.layer.shadowOpacity = 0.8
        self.navigationController?.navigationBar.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        self.navigationController?.navigationBar.layer.shadowRadius = 2
        
        //DI
        viewModel = di.resolve(BarcodeViewModel.self)
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewView.frame = self.view.bounds
        self.videoLayer?.frame = self.view.bounds
    }
    
    // ビューが表示された直後に実行
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        cameraAuth()
        setupInputOutput()
        
        if (authStatus == .authorized)&&(inOutStatus == .ready){
            setPreviewLayer()
            captureStart()
        } else {
            showAlert(appName: "カメラ")
        }
        
        //向きを整える
        switch UIDevice.current.orientation {
        case .portrait:
            self.videoLayer?.connection.videoOrientation = .portrait
        case .portraitUpsideDown:
            self.videoLayer?.connection.videoOrientation = .portraitUpsideDown
        case .landscapeLeft:
            self.videoLayer?.connection.videoOrientation = .landscapeRight
        case .landscapeRight:
            self.videoLayer?.connection.videoOrientation = .landscapeLeft
        default:
            break
        }
        
        // デバイスが回転したときに通知するイベントハンドラを設定する
        notification.addObserver(self,
                                 selector: #selector(self.changedDeviceOrientation(_:)),
                                 name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }
    
    // デバイスの向きが変わったときにカメラの向きを変える
    func changedDeviceOrientation(_ notification :Notification) {
        guard (self.videoDevice) != nil else{
            return
        }
        
        switch UIDevice.current.orientation {
        case .portrait:
            self.videoLayer?.connection.videoOrientation = .portrait
        case .portraitUpsideDown:
            self.videoLayer?.connection.videoOrientation = .portraitUpsideDown
        case .landscapeLeft:
            self.videoLayer?.connection.videoOrientation = .landscapeRight
        case .landscapeRight:
            self.videoLayer?.connection.videoOrientation = .landscapeLeft
        default:
            break
        }
    }
    
    // メモリ解放
    override func viewDidDisappear(_ animated: Bool) {
        // camera stop メモリ解放
        for output in captureSession.outputs {
            self.captureSession.removeOutput(output as? AVCaptureOutput)
        }
        
        for input in captureSession.inputs {
            self.captureSession.removeInput(input as? AVCaptureInput)
        }
        self.captureSession = nil
        self.videoDevice = nil
    }
    
    // プレビューレイヤの設定
    func setPreviewLayer(){
        self.videoLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        guard self.videoLayer != nil else {
            return
        }
        
        self.videoLayer?.frame = self.view.bounds
        self.videoLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        previewView.layer.addSublayer(videoLayer!)
    }
    
    func captureStart(){
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }
    
    var barcodeCount = 0
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        self.captureSession.stopRunning();
        
        //読み込みインジゲーターを発動
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        self.showProgressIndicator()
        
        if metadataObjects == nil || metadataObjects.count == 0 {
            let aTitle = "読み取り成功"
            let aMessage = "成功"
            let alert = UIAlertController(title: aTitle, message: aMessage, preferredStyle: .alert)
            
            // 設定を開くボタン
            alert.addAction(
                UIAlertAction(
                    title: "設定を開く",style: .default,
                    handler:  { action in
                        UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
                })
            )
            // アラートを表示する
            self.present(alert, animated: false, completion:nil)
            return
        }
        
        let metadata: AVMetadataMachineReadableCodeObject = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        // QRコードのデータかどうかの確認
        if metadata.type == AVMetadataObjectTypeQRCode {

                if metadata.stringValue != nil {
                    self.barcodeCount+=1
                    
                    self.viewModel
                        .fetch(itemId: metadata.stringValue)
                        .bind { [unowned self] result in
                            print("barcodeviewmodel result",result)
                            self.barcodeCount -= 1
                            if self.barcodeCount <= 0 {
                                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                                self.dismisProgressIndicator()
                                
                                let alert = UIAlertController(title: "完了", message: "決済が完了しました。", preferredStyle: .alert)
                                
                                // 閉じるボタン
                                let close = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: {
                                    (action: UIAlertAction!) in
                                    
                                    for output in self.captureSession.outputs {
                                        self.captureSession.removeOutput(output as? AVCaptureOutput)
                                    }
                                    
                                    for input in self.captureSession.inputs {
                                        self.captureSession.removeInput(input as? AVCaptureInput)
                                    }
                                    self.captureSession = nil
                                    self.videoDevice = nil
                                    
                                    self.cameraAuth()
                                    self.setupInputOutput()
                                    if (self.authStatus == .authorized)&&(self.inOutStatus == .ready){
                                        self.setPreviewLayer()
                                        self.captureStart()
                                    }
                                })
                                
                                alert.addAction(close)
                                
                                self.present(alert, animated: false, completion:nil)
                            }
                        }
                        .disposed(by: bag)
                    
                    AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                    
                    let soundIdRing: SystemSoundID = 1002
                    AudioServicesPlaySystemSound(soundIdRing)
                }
            }
    }
    
    //ログインインジケータ
    private func showProgressIndicator() {
        if !self.progress.isAvailable {
            let frame = self.view.frame
            self.progressView = self.progress
                .show(frame: frame, message: "決済中", style: Config.IndicatorOriginalStyle())
            self.view.addSubview((self.progressView)!)
        }
    }
    
    private func dismisProgressIndicator() {
        if self.progress.isAvailable {
            self.progress.dismiss(progress: self.progressView!)
        }
    }
}


