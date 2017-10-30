//
//  ItemListsViewController.swift
//  demonosuke
//
//  Created by 佐竹映季 on 2017/06/14.
//  Copyright © 2017年 佐竹映季. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import UIKit
import PureLayout
import Alamofire

class CartListsViewController: UIViewController{
    weak private var indicator: UIActivityIndicatorView!
    weak private var refreshControl: UIRefreshControl!
    
    private var viewModel: CartListsViewModel!
    private let bag = DisposeBag()
    
    @IBOutlet weak var CartListsTableView: UITableView!
    
    override func loadView() {
        super.loadView()
        let refresh = UIRefreshControl()
        CartListsTableView.addSubview(refresh)
        self.refreshControl = refresh
        self.automaticallyAdjustsScrollViewInsets = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        self.indicator = self.setUpIndicatorView()
        self.indicator.startAnimating()
        self.CartListsTableView.isUserInteractionEnabled = false
        
        //カスタムセル登録
        self.registerTableViewCell()
        
        self.CartListsTableView.rowHeight = UITableViewAutomaticDimension //needed for autolayout
        self.CartListsTableView.estimatedRowHeight = 75.0 //needed for autolayout
        self.CartListsTableView.separatorStyle = .none
        
        viewModel = di.resolve(CartListsViewModel.self, arguments:
            self.refreshControl.rx.controlEvent(.valueChanged).asObservable(),
                               CartListsTableView.rx.modelSelected(CartListsResource.Items.self).asObservable()
        )
        
        viewModel
            .fetch()
            .bind { _ in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self.indicator.stopAnimating()
                self.CartListsTableView.isUserInteractionEnabled = true
            }
            .disposed(by: bag)
        
        viewModel
            .items
            .asObservable()
            .bind(to: CartListsTableView.rx.items(cellIdentifier: "CartListsTableViewCell", cellType: CartListsTableViewCell.self)) { (row, element, cell) -> Void in
                self.viewModel.buildCell(cell, element: element, row: row)
            }
            .disposed(by: bag)
        
        viewModel
            .refreshStarted
            .flatMap { [unowned self] _ -> Observable<Bool>  in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                self.CartListsTableView.isUserInteractionEnabled = false
                return self.viewModel.fetch()
            }
            .bind { [unowned self] result in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self.CartListsTableView.isUserInteractionEnabled = true
                self.refreshControl.endRefreshing()
            }
            .disposed(by: bag)
                
        print("viewModel.user",viewModel.user?.email);
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    private func setUpIndicatorView() -> UIActivityIndicatorView {
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        indicator.hidesWhenStopped = true
        
        self.view.addSubview(indicator)
        
        indicator.autoCenterInSuperview()
        
        return indicator
    }
    
    private func registerTableViewCell() {
        self.CartListsTableView.register(
            UINib(nibName: "CartListsTableViewCell", bundle: nil),
            forCellReuseIdentifier: "CartListsTableViewCell"
        )
    }
}

