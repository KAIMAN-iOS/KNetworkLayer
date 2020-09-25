//
//  ViewController.swift
//  iOS Example
//
//  Created by GG on 24/09/2020.
//

import UIKit
import KNetworkLayer
import PromiseKit
import Alamofire

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        AppAPI
            .shared
            .retrievePost(nb: 10)
            .done({ posts in
                if let post = posts.first {
                    let alertController = UIAlertController(title: post.title, message: post.body, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { [weak self] _ in
                        self?.dismiss(animated: true, completion: nil)
                    }))
                    self.present(alertController, animated: true, completion: nil)
                }
            })
            .catch { error in
                
            }
    }


}

