import RxSwift
import SwiftyJSON
import UIKit

let MEMBER_LIST_URL = "https://my.api.mockaroo.com/members_with_avatar.json?key=44ce18f0"

// MARK: 2. Swift with Task Class

class 나중에생기는데이터<T> { // RxSwift: Observable<T>
	private let task: (@escaping (T) -> Void) -> Void
	
	init(task: @escaping (@escaping (T) -> Void) -> Void) {
		self.task = task
	}
	
	func 나중에오면(_ f: @escaping (T) -> Void) { // RxSwift: func subscribe
		task(f)
	}
}

class ViewController: UIViewController {
	@IBOutlet
	var timerLabel: UILabel!
	@IBOutlet
	var editView: UITextView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
			self?.timerLabel.text = "\(Date().timeIntervalSince1970)"
		}
	}
	
	private func setVisibleWithAnimation(_ v: UIView?, _ s: Bool) {
		guard let v = v else { return }
		UIView.animate(withDuration: 0.3, animations: { [weak v] in
			v?.isHidden = !s
		}, completion: { [weak self] _ in
			self?.view.layoutIfNeeded()
		})
	}
	
	// Swift with closure
	func downloadJsonWithClosure(_ url: String, _ completion: ((String?) -> Void)?) {
		DispatchQueue.global().async {
			let url = URL(string: url)!
			let data = try! Data(contentsOf: url)
			let json = String(data: data, encoding: .utf8)
			DispatchQueue.main.async {
				completion?(json)
			}
		}
	}
	
	// Swift with Task Class
	func downloadJsonWithTaskClass(_ url: String) -> 나중에생기는데이터<String?> {
		나중에생기는데이터 { f in
			DispatchQueue.global().async {
				let url = URL(string: url)!
				let data = try! Data(contentsOf: url)
				let json = String(data: data, encoding: .utf8)
				DispatchQueue.main.async {
					f(json)
				}
			}
		}
	}
	
	// RxSwift
	// PromiseKit, Bolt: 나중에오면 -> then
	// RxSwift: 나중에생기는데이터 -> Observable, 나중에오면 -> subscribe, f(T) -> f.onNext(T)
	// Observable Lifecycle: Create -> Subscribe(Execution!) -> onNext -> onCompleted / onError -> Disposed
	// End condition: onComplete / onError / dispose on subscribe(재사용 불가)
	func downloadJsonWithRxSwift(_ url: String) -> Observable<String?> {
		// 3-1. 비동기로 생기는 데이터를 Observable로 감싸서 리턴하는 방법
		
		// Example above
		//		return Observable.create { f in
		//			DispatchQueue.global().async {
		//				let url = URL(string: url)!
		//				let data = try! Data(contentsOf: url)
		//				let json = String(data: data, encoding: .utf8)
		//				DispatchQueue.main.async {
		//					f.onNext(json)
		//					f.onCompleted()
		//				}
		//			}
		//
		//			return Disposables.create()
		//		}
		
		// Example 1: Simple
		//		return Observable.create() { emitter in
		//			emitter.onNext("Hello")
		//			emitter.onNext("World")
		//			emitter.onCompleted()
		//
		//			return Disposables.create()
		//		}
		
		// Example 2: Well-structured logic
		Observable.create { emitter in // emitter: Event<String?>
			let url = URL(string: url)!
			let task = URLSession.shared.dataTask(with: url) { data, _, err in
				guard err == nil else {
					emitter.onError(err!)
					return
				}
				
				if let data = data, let json = String(data: data, encoding: .utf8) {
					emitter.onNext(json)
				}
				
				emitter.onCompleted()
			}
			
			task.resume()
			
			return Disposables.create {
				task.cancel()
			}
		}
	}
	
	// RxSwift: Creation
	func downloadJsonWithRxSwiftSimpleCreation(singleSource: Bool) -> Observable<String?> {
		if singleSource {
			// [just]: Create -> onNext -> onCompleted
			return Observable.just("Hello world")
		} else {
			// [from]: Create -> (multiple) onNext -> onCompleted
			// onNext multiple times by array of data
			return Observable.from(["Hello", "World"])
		}
	}
	
	// MARK: SYNC
	
	private let disposeBag = DisposeBag()
	private let method = 8
	
	@IBOutlet
	var activityIndicator: UIActivityIndicatorView!
	
	@IBAction
	func onLoad() {
		editView.text = ""
		setVisibleWithAnimation(activityIndicator, true)
		
		switch method {
			// MARK: 1. Swift with closure
			case 1:
				downloadJsonWithClosure(MEMBER_LIST_URL) {
					self.editView.text = $0
					self.setVisibleWithAnimation(self.activityIndicator, false)
				}
				
			// MARK: 2. Swift with Task Class
			case 2:
				let json: 나중에생기는데이터<String?> = downloadJsonWithTaskClass(MEMBER_LIST_URL)
				json.나중에오면 {
					self.editView.text = $0
					self.setVisibleWithAnimation(self.activityIndicator, false)
				}
				
			// MARK: 3. RxSwift
			case 3:
				// 3-2. Observable로 오는 데이터를 받아서 처리하는 방법 (기본 사용법)
				let observable = downloadJsonWithRxSwift(MEMBER_LIST_URL) // 일반적으로 observable을 위한 변수 선언하지 않음
				let disposable = observable
					.debug()
					.subscribe { event in // Observable closure 실행 시점
						switch event {
							case let .next(json):
								DispatchQueue.main.async {
									self.editView.text = json
									self.setVisibleWithAnimation(self.activityIndicator, false)
								}
							case .completed: break
							case .error: break
						}
					}
				disposable.disposed(by: disposeBag)
				
				// dispose immediately
//				disposable.dispose()
				
				// 재사용 시 subscribe 새로 생성
//				disposable.dispose() // subscribe end. cannot be reused
//
//				observable.subscribe { event in
//					switch event {
//						case let .next(json):
//							print(json ?? "")
//						case .completed: print("complete")
//						case .error: print("error")
//					}
//				}
				
			// MARK: 4. RxSwift: Just
			case 4:
				_ = downloadJsonWithRxSwiftSimpleCreation(singleSource: true)
					.subscribe { event in
						switch event {
							case let .next(t): print(t ?? "")
							case .completed: print("Completed")
							case .error: print("Error")
						}
					}
				
			// MARK: 5. RxSwift: From with convenient subscribe closure
			case 5:
				_ = downloadJsonWithRxSwiftSimpleCreation(singleSource: false)
					// 5-1. All case
					//				.subscribe { print($0 ?? "") }
					//					onError: { _ in print("Error") }
					//					onCompleted: { print("Completed")}
					//					onDisposed: { print("Disposed") }
					// 5-2. Only onNext
					.subscribe(onNext: { print($0 ?? "") })
				
			// MARK: 6. RxSwift: Scheduler
			case 6:
				_ = downloadJsonWithRxSwift(MEMBER_LIST_URL)
					.observeOn(MainScheduler.instance)
					.subscribe(onNext: {
						self.editView.text = $0
						self.setVisibleWithAnimation(self.activityIndicator, false)
					})
				
			// MARK: 7. RxSwift: (Sugar) Operator(http://reactivex.io/documentation/ko/operators.html)
			case 7:
				_ = downloadJsonWithRxSwift(MEMBER_LIST_URL)
					.subscribeOn(ConcurrentDispatchQueueScheduler(qos: .default))
					// Start: operators
					.map { $0?.count ?? 0 }
					.filter { $0 > 0 }
					.map { "\($0)" }
					// End: operators
					.observeOn(MainScheduler.instance)
					.subscribe(onNext: {
						self.editView.text = $0
						self.setVisibleWithAnimation(self.activityIndicator, false)
					})
				
			// MARK: 8. RxSwift: Merge(zip) Operators
			case 8:
				let jsonObservable = downloadJsonWithRxSwift(MEMBER_LIST_URL)
				let helloObservable = Observable.just("Hello World")
				
				Observable.zip(jsonObservable, helloObservable) { $1 + "\n" + ($0 ?? "") }
					.observeOn(MainScheduler.instance)
					.subscribe(onNext: {
						self.editView.text = $0
						self.setVisibleWithAnimation(self.activityIndicator, false)
					})
					.disposed(by: disposeBag)
			
			default:
				break
		}
	}
}
