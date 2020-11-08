//
//  MenuListViewModel.swift
//  RxSwift+MVVM
//
//  Created by Kaden Kim on 2020-11-07.
//  Copyright © 2020 iamchiwon. All rights reserved.
//

import Foundation
import RxSwift
import RxRelay

class MenuListViewModel {
	// MARK: IMPORTANT on UI: NEVER disconnect stream
	// Subject is possible to terminate
	// On UI, use Relay instead of Subject
	var menuObservable = BehaviorRelay<[Menu]>(value: [])
	
	lazy var itemsCount = menuObservable.map {
		$0.map { $0.count }.reduce(0, +)
	}
	lazy var totalPrice = menuObservable.map {
		$0.map { $0.price * $0.count }.reduce(0, +)
	}
	
	init() {
		_ = APIService.fetchAllmenusRx()
			.map { data -> [MenuItem] in
				struct Response: Decodable {
					let menus: [MenuItem]
				}
				let response = try! JSONDecoder().decode(Response.self, from: data)
				
				return response.menus
			}
			.map { menuItems -> [Menu] in
				var menus: [Menu] = []
				menuItems.enumerated().forEach {
					menus.append(Menu.fromMenuItems(id: $0, item: $1))
				}
				return menus
			}
			.take(1)
			.bind(to: menuObservable)
	}
	
	func clearAllItemSelections() {
		_ = menuObservable
			.map { menus in
				menus.map {
					Menu(id: $0.id, name: $0.name, price: $0.price, count: 0)
				}
			}
			.take(1)
			.subscribe(onNext: {
				self.menuObservable.accept($0)
			})
	}
	
	func changeCount(item: Menu, increase: Int) {
		_ = menuObservable
			.map { menus in
				menus.map { menu in
					if menu.id == item.id {
						return Menu(id: menu.id,
									name: menu.name,
									price: menu.price,
									count: max(menu.count + increase, 0))
					} else {
						return menu
					}
				}
			}
			.take(1)
			.subscribe(onNext: {
				self.menuObservable.accept($0)
			})
	}
	
	func order() {
		
	}
	
}
