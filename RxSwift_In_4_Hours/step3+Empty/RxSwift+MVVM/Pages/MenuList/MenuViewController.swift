//
//  ViewController.swift
//  RxSwift+MVVM
//
//  Created by iamchiwon on 05/08/2019.
//  Copyright © 2019 iamchiwon. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class MenuViewController: UIViewController {
    // MARK: - Life Cycle
	
	let cellId = "MenuItemTableViewCell"
	
	let viewModel = MenuListViewModel()
	let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
		
		viewModel.menuObservable
			.bind(to: tableView.rx.items(cellIdentifier: cellId,
										 cellType: MenuItemTableViewCell.self)) { index, item, cell in
				cell.title.text = item.name
				cell.price.text = "\(item.price)"
				cell.count.text = "\(item.count)"
				
				cell.onChange = { [weak self] increase in
					self?.viewModel.changeCount(item: item, increase: increase)
				}
			}
			.disposed(by: disposeBag)
		
		viewModel.itemsCount
			.map { "\($0)" }
//			.observeOn(MainScheduler.instance)
//			.catchErrorJustReturn("")
//			.bind(to: itemCountLabel.rx.text)
			// MARK: IMPORTANT ON UI: NEVER disconnect stream, ONLY run on main thread
			// Must deal with error (Never die)
			// Instead observeOn(Main), catchError, bind,
			.asDriver(onErrorJustReturn: "")
			.drive(itemCountLabel.rx.text)
			.disposed(by: disposeBag)
		
		viewModel.totalPrice
			.map { $0.currencyKR() }
			.observeOn(MainScheduler.instance)
			.bind(to: totalPrice.rx.text)
			.disposed(by: disposeBag)
		
		// MARK: Timer/Delay Logic
		_ = Observable.just(1)
			.delay(.seconds(10), scheduler: MainScheduler.instance)
			.take(1)
			.subscribe(onNext: { _ in print("Timer/Delay process") })
		
		// MARK: Example: Auto Dismiss by Delay
		_ = Observable.just(1)
			.flatMap { _ in self.showAlert() }
			.delay(.seconds(3), scheduler: MainScheduler.instance)
			.take(1)
			.subscribe(onNext: { $0.dismiss(animated: true, completion: nil)})
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let identifier = segue.identifier ?? ""
        if identifier == "OrderViewController",
            let orderVC = segue.destination as? OrderViewController {
            // TODO: pass selected menus
        }
    }

    func showAlert(_ title: String, _ message: String) {
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertVC, animated: true, completion: nil)
    }
	
	func showAlert() -> Observable<UIAlertController> {
		let alert = UIAlertController(title: "Auto Dismiss", message: "Wait for it", preferredStyle: .alert)
		present(alert, animated: true, completion: nil)
		return Observable.just(alert)
	}

    // MARK: - InterfaceBuilder Links

    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var itemCountLabel: UILabel!
    @IBOutlet var totalPrice: UILabel!

    @IBAction func onClear() {
		viewModel.clearAllItemSelections()
    }

    @IBAction func onOrder(_ sender: UIButton) {
        // TODO: no selection
        // showAlert("Order Fail", "No Orders")
//        performSegue(withIdentifier: "OrderViewController", sender: nil)
		
		viewModel.order()
    }
	
}
