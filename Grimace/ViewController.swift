//
//  ViewController.swift
//  Grimace
//
//  Created by Alexei Baboulevitch on 7/12/25.
//

import Cocoa
internal import UniformTypeIdentifiers

class ViewController: NSViewController {

    @IBOutlet var pathControl: NSPathControl!
    @IBOutlet var textField: NSTextField!
    @IBOutlet var picker: NSPopUpButton!
    @IBOutlet var listButton: NSButton!
    @IBOutlet var applyButton: NSButton!
    @IBOutlet var clearButton: NSButton!
    
    var selectedDirectory: URL? {
        return self.pathControl.url
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.textField.stringValue = "hand.side.pinch"
        self.refreshView()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        self.view.window?.isMovableByWindowBackground = true
    }
    
    func tryWithError(_ block:() throws -> (), ignoreBlock: ((_ error: Error)->Bool)? = nil) {
        do {
            try block()
        } catch {
            if ignoreBlock == nil || ignoreBlock!(error) == false {
                NSAlert(error: error).runModal()
            }
        }
    }
    
    @IBAction func didPickDirectory(_: NSPathControl) {
        refreshView()
    }
    
    @IBAction func didClickList(_: NSButton?) {
        if let directory = self.selectedDirectory {
            tryWithError {
                let attributes = try Attributes.attributes(for: directory)
                for attribute in attributes {
                    let data = try Attributes.data(forAttribute: attribute, for: directory)
                    var dataDescription = NSString.init(data: data, encoding: NSUTF8StringEncoding) ?? ""
                    if dataDescription.length == 0 || dataDescription.character(at: 0) == 0 {
                        dataDescription = ((data as NSData).debugDescription as NSString)
                    }
                    
                    print("Data for \(attribute): \(dataDescription)")
                    
                    let alert = NSAlert()
                    alert.messageText = "\(attribute)"
                    alert.informativeText = "\(dataDescription)"
                    alert.runModal()
                }
            } ignoreBlock: { error in
                if (error as NSError).domain == NSPOSIXErrorDomain && (error as NSError).code == ENOATTR {
                    return true
                } else {
                    return false
                }
            }
        }
    }
    
    @IBAction func didClickApply(_: NSButton?) {
        if let directory = self.selectedDirectory {
            tryWithError {
                if self.picker.selectedTag() == 1 {
                    try Attributes.setSymbolIcon(with: self.textField.stringValue, for: directory)
                } else if self.picker.selectedTag() == 2 {
                    try Attributes.setTextIcon(with: self.textField.stringValue, for: directory)
                }
            }
        }
    }
    
    @IBAction func didClickClear(_: NSButton?) {
        if let directory = self.selectedDirectory {
            tryWithError {
                try Attributes.removeIconAttributes(from: directory)
            }
        }
    }
    
    func refreshView() {
        #if DEBUG
        self.listButton.isHidden = false
        #else
        self.listButton.isHidden = true
        #endif
        
        if let directory = self.selectedDirectory, directory != URL.init(filePath: "/") {
            self.listButton.isEnabled = true
            self.applyButton.isEnabled = true
            self.clearButton.isEnabled = true
        } else {
            self.listButton.isEnabled = false
            self.applyButton.isEnabled = false
            self.clearButton.isEnabled = false
        }
    }
}
