//
//  CartListsViewModel
//  demonosuke
//
//  Created by 佐竹映季 on 2017/06/14.
//  Copyright © 2017年 佐竹映季. All rights reserved.
//

import Foundation
import UIKit
import RxCocoa
import RxSwift
import Kingfisher
import Unbox
import CoreImage

class CartListsViewModel {
    private let api: API
    
    typealias Items = CartListsResource.Items
    let items = Variable([Items]())
    
    let refreshStarted: Observable<Void>
    let modelSelected: Observable<Items>
    
    private let localStore:UserLocalDefaults
    private(set) var user: User?
    
    init(
        api: API,
        refreshStarted: Observable<Void>,
        selected: Observable<Items>,
        localStore: UserLocalDefaults
        ) {
        self.api = api
        self.refreshStarted = refreshStarted.shareReplay(1)
        self.modelSelected = selected.shareReplay(1)
        self.localStore = localStore
    }
    
    func fetch() -> Observable<Bool>  {
        return api.itemListsContents()
            .subscribeOn(MainScheduler.asyncInstance)
            .map { [unowned self] items in
                //value Variableでイベントを発行する
                self.items.value = items.data
                return true
            }
            .catchErrorJustReturn(false)
    }
    
    func buildCell(_ cell: CartListsTableViewCell, element: Items, row: Int) {
//        let image_url:String = element.image
//        cell.thumbnailView.kf.setImage(with: URL(string: image_url),options:[.transition(ImageTransition.fade(0.6))])
//        var url = element.id
//
//        //String から NSDataへ変換
//        let data = url.data(using: String.Encoding.utf8)!
//
//        // QRコード生成のフィルター
//        // NSData型でデーターを用意
//        // inputCorrectionLevelは、誤り訂正レベル
//        let qr = CIFilter(name: "CIQRCodeGenerator", withInputParameters: ["inputMessage": data, "inputCorrectionLevel": "M"])!
//
//
//        let sizeTransform = CGAffineTransform(scaleX: 10, y: 10)
//        let qrImage = qr.outputImage!.applying(sizeTransform)
//
////                let image_url:String = element.image
//
//        cell.thumbnailView.image = UIImage(CIImage: qrImage)

        let image = generateQRCode(from: element.id)
        cell.thumbnailView.image = image
        
        cell.titleLabel.text = element.title
        cell.priceLabel.text = String(element.price) + "円"
    }
    
    func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)
        
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 3, y: 3)
            
            if let output = filter.outputImage?.applying(transform) {
                return UIImage(ciImage: output)
            }
        }
        
        return nil
    }
}

