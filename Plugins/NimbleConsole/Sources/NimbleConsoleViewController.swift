//
//  NimbleConsoleViewController.swift
//  NimbleConsole
//
//  Created by Danil Kristalev on 10/10/2019.
//  Copyright © 2019 Scade. All rights reserved.
//

import Cocoa
import NimbleCore

class NimbleConsoleViewController: NSViewController, ConsoleController {
  
  @IBOutlet var textView: NSTextView!
  
  @IBOutlet weak var consoleSelectionButton: NSPopUpButton!
  
  private var consolesStorage : [String: NimbleTextConsole] = [:]
  
  private func handler(fileHandle: FileHandle) {
    let data = fileHandle.availableData
    if let string = String(data: data, encoding: String.Encoding.utf8) {
      DispatchQueue.main.async {
        self.textView.string += string
      }
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.view.setBackgroundColor(.white)
    
  }
  
  func createConsole(title: String, show: Bool) -> Console {
    let consoleName = improveName(title)
    let newConsole = NimbleTextConsole(title: consoleName)
    consoleSelectionButton.addItem(withTitle: newConsole.title)
    if (show) {
      textView.string = newConsole.contents
      consoleSelectionButton.selectItem(withTitle: newConsole.title)
    }
    newConsole.outputPipe.fileHandleForReading.readabilityHandler = handler(fileHandle:)
    consolesStorage[newConsole.title] = newConsole
    return newConsole
  }
  
  private func improveName(_ title: String) -> String {
    var count = 0
    var result = title
    while (consolesStorage[result] != nil)  {
      count = count + 1
      result = "\(title) \(count)"
    }
    return result
  }
  
  func open(console title: String) {
    guard let console = consolesStorage[title] else {
      return
    }
    console.outputPipe.fileHandleForReading.readabilityHandler = handler(fileHandle:)
    consoleSelectionButton.selectItem(withTitle: console.title)
    textView.string = console.contents
  }
  
  @IBAction func selectionDidChange(_ sender: NSPopUpButton) {
    guard let title  = sender.selectedItem?.title else {
      return
    }
    open(console: title)
  }
}

class NimbleTextConsole: Console {
  private var innerContent: String
  
  var contents: String{
    return innerContent
  }
  
  var title: String
  
  var input: Pipe {
    return inputPipe
  }
  
  let inputPipe = Pipe()
  let outputPipe = Pipe()
  
  init(title: String){
    self.title = title
    self.innerContent = ""
    // Set up a read handler which fires when data is written to our inputPipe
    inputPipe.fileHandleForReading.readabilityHandler = { [weak self] fileHandle in
      guard let strongSelf = self else { return }
      
      let data = fileHandle.availableData
      if let string = String(data: data, encoding: .utf8) {
        strongSelf.innerContent += string
      }
      strongSelf.outputPipe.fileHandleForWriting.write(data)
    }
  }
  
  
  func write(data: Data) -> Console {
    self.outputPipe.fileHandleForWriting.write(data)
    return self
  }
  
  
}


