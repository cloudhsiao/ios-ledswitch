//
//  ViewModel.swift
//  LEDSwitch
//
//  Created by Cloud Hsiao on 5/6/16.
//  Copyright © 2016 ThroughTek. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import RxAlamofire
import Alamofire

class ViewModel : TunnelBrainDelegate{
  
  private let disposeBag = DisposeBag()
  private let tunnel = TunnelBrain.sharedInstance
  
  var rx_sessionID = BehaviorSubject<Int>(value: -1)
  
  private var sessionID: Int? {
    didSet {
      if let sid = sessionID {
        rx_sessionID.onNext(sid)
      }
    }
  }
  
  init(text: Observable<String>, buttonTap: Observable<Void>, switchTap: Observable<Bool>) {
    tunnel.delegate = self
    
    buttonTap
      .flatMapLatest { text.take(1) }
      .flatMapLatest { [unowned self] uid in
        return self.connect(uid, mappingLocalPort: 8080, toRemotePort: 8080)
      }
      .subscribeNext { [unowned self] sid in
        self.sessionID = sid
      }
      .addDisposableTo(disposeBag)
    
    switchTap
      .skip(1)
      .flatMapLatest { val in
        return Manager.sharedInstance.rx_string(.GET, "http://127.0.0.1:8080/led/\(val ? "on" : "off" )")
      }
      .observeOn(MainScheduler.instance)
      .subscribeNext {
        print($0)
      }
      .addDisposableTo(disposeBag)
  }
  
  func connect(uid: String, mappingLocalPort localPort: UInt16, toRemotePort remotePort: UInt16) -> Observable<Int> {
    return Observable<Int>.create { [unowned self] observer in
      self.tunnel.connect(uid, withUsername: "Tutk.com", andPassword: "P2P Platform") { sid in
        let map = self.tunnel.addPortMapping(uid, AtLocalPort: localPort, ToRemotePort: remotePort)
        if sid >= 0 && map.0 {
          observer.onNext(Int(sid))
        } else {
          observer.onNext(-1)
        }
      }
      return AnonymousDisposable {
        self.tunnel.clearPortMapping(uid)
        self.tunnel.disconnect(uid)
      }
    }
  }
  
  @objc func Tunnel(UID: String, didChangeStatus status: Int32, atSessionID sessionID: Int32) {
    if status == TUNNEL_ER_DISCONNECTED {
      self.sessionID = -1
    }
  }
}