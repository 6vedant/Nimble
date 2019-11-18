//
//  AppDelegate.swift
//  Nimble
//
//  Created by Grigory Markin on 03.03.19.
//  Copyright © 2019 SCADE. All rights reserved.
//

import Cocoa
import NimbleCore

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
      
  func applicationWillFinishLaunching(_ notification: Notification) {
    
  }
  
  func applicationWillTerminate(_ aNotification: Notification) {
    
  }
  
  func application(_ sender: NSApplication, openFile filename: String) -> Bool {
    if let path = Path(filename) {
      ///TODO:  implement opening files/folders
      NSDocumentController.shared.openDocument(withContentsOf: path.url,
                                               display: true,
                                               completionHandler: {_, _, _ in return})
    } else {
      ///TODO:  show error and open an empty project
    }
        
    return true
  }
    
}
