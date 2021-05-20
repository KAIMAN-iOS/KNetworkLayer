//
//  ViewController.swift
//  iOS Example
//
//  Created by GG on 24/09/2020.
//

import UIKit
import kPromiseNetworkLayer
import PromiseKit
import Alamofire
import KCombineNetworkLayer
import Combine

class ViewController: UIViewController {

    private var subscriptions = Set<AnyCancellable>()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
//        AppAPI
//            .shared
//            .retrievePost(nb: 1)
//            .done({ posts in
//                if let post = posts.first {
//                    let alertController = UIAlertController(title: post.title, message: post.body, preferredStyle: .alert)
//                    alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { [weak self] _ in
//                        self?.dismiss(animated: true, completion: nil)
//                    }))
//                    self.present(alertController, animated: true, completion: nil)
//                }
//            })
//            .catch { error in
//
//            }
        
        AppAPI
            .shared
            .authRetrievePost(nb: 1)
            .sink { completion in
                print("completion \(completion)")
            } receiveValue: { posts in
                if let post = posts.first {
                    let alertController = UIAlertController(title: post.title, message: post.body, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { [weak self] _ in
                        self?.dismiss(animated: true, completion: nil)
                    }))
                    self.present(alertController, animated: true, completion: nil)
                }
            }
            .store(in: &subscriptions)
    }


}

