//
//  ViewController.swift
//  LEDSwitch
//
//  Created by Cloud Hsiao on 5/6/16.
//  Copyright © 2016 ThroughTek. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ViewController: UIViewController {

  @IBOutlet weak var textFieldUID: UITextField!
  @IBOutlet weak var btnConnect: UIButton!
  @IBOutlet weak var switchLED: UISwitch!
  
  let uidMaxLength = 20
  let disposeBag = DisposeBag()
  var viewModel: ViewModel!

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    
    viewModel = ViewModel(text: textFieldUID.rx_text.asObservable(),
                          buttonTap: btnConnect.rx_tap.asObservable(),
                          switchTap: switchLED.rx_value.asObservable())
    
    let textFieldValid = textFieldUID.rx_text
      .map { $0.characters.count == 20 }
      .shareReplay(1)
    
    let buttonValid = viewModel.rx_sessionID
      .map { $0 < 0 }
      .shareReplay(1)
    
    let switchValid = viewModel.rx_sessionID
      .map { $0 >= 0 }
      .shareReplay(1)
    
    Observable
      .combineLatest(textFieldValid, buttonValid) { $0 && $1 }
      .shareReplay(1)
      .bindTo(btnConnect.rx_enabled)
      .addDisposableTo(disposeBag)
    
    Observable
      .combineLatest(textFieldValid, switchValid) { $0 && $1 }
      .shareReplay(1)
      .bindTo(switchLED.rx_enabled)
      .addDisposableTo(disposeBag)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

}

extension ViewController: UITextFieldDelegate {
  func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
    guard let text = textField.text else {
      return true
    }
    let newLength = text.characters.count + string.characters.count - range.length
    return newLength <= uidMaxLength
  }
}

