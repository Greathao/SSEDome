//
//  ViewController.swift
//  SSE_Dome
//
//  Created by mac on 12/23/25.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var button: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }


    @IBAction func touchButton(_ sender: Any) {
        self.navigationController?.pushViewController(ArticlesViewController(), animated: true)
    }
}

