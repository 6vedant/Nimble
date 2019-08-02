//
//  ProjectDocument.swift
//  Nimble
//
//  Created by Danil Kristalev on 31/07/2019.
//  Copyright © 2019 SCADE. All rights reserved.
//

import Cocoa
import NimbleCore

class ProjectDocument : NSDocument {
  
  var project = ProjectManager.shared.currentProject
  
  override init() {
    super.init()
  }
  
  // MARK: - Enablers
  
  // This enables auto save.
  override class var autosavesInPlace: Bool {
    return true
  }
  
  // This enables asynchronous-writing.
  override func canAsynchronouslyWrite(to url: URL, ofType typeName: String, for saveOperation: NSDocument.SaveOperationType) -> Bool {
    return true
  }
  
  // This enables asynchronous reading.
  override class func canConcurrentlyReadDocuments(ofType: String) -> Bool {
    return ofType == "com.scade.nimble.project"
  }
  
  // MARK: - User Interface
  
  /// - Tag: makeWindowControllersExample
  override func makeWindowControllers() {
    // Returns the storyboard that contains your document window.
    let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
    if let windowController =
      storyboard.instantiateController(
        withIdentifier: NSStoryboard.SceneIdentifier("Document Window Controller")) as? NSWindowController {
      addWindowController(windowController)
      // Set the view controller's represented object as your document.
//      if let contentVC = windowController.contentViewController as? WorkbenchViewController {
//      }
    }
  }

  
  // MARK: - Reading and Writing
  
  /// - Tag: readExample
  override func read(from data: Data, ofType typeName: String) throws {
    project.read(from: data)
  }
  
  /// - Tag: writeExample
  override func data(ofType typeName: String) throws -> Data {
    return project.data()!
  }
  
}
