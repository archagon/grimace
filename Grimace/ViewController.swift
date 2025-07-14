//
//  ViewController.swift
//  Grimace
//
//  Created by Alexei Baboulevitch on 7/12/25.
//

import Cocoa
internal import UniformTypeIdentifiers

class ViewController: NSViewController {

    @IBOutlet var dropTarget: DragDroppableView!
    @IBOutlet var imageWell: NSImageView!
    @IBOutlet var textField: NSTextField!
    @IBOutlet var picker: NSPopUpButton!
    @IBOutlet var listButton: NSButton!
    @IBOutlet var applyButton: NSButton!
    @IBOutlet var clearButton: NSButton!
    
    var selectedDirectory: URL? {
        didSet {
            refreshView()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.textField.stringValue = "hand.side.pinch"
        self.refreshView()
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
                }
            } ignoreBlock: { error in
                if (error as NSError).domain == NSPOSIXErrorDomain && (error as NSError).code == ENOATTR {
                    print("Attribute not found, skipping...")
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
        
        if let directory = self.selectedDirectory {
            self.listButton.isEnabled = true
            self.applyButton.isEnabled = true
            self.clearButton.isEnabled = true
            
            let icon = NSWorkspace.shared.icon(forFile: directory.path())
            self.imageWell.image = icon
            self.imageWell.image = NSWorkspace.shared.icon(for: .folder)
        } else {
            self.listButton.isEnabled = false
            self.applyButton.isEnabled = false
            self.clearButton.isEnabled = false
            
            self.imageWell.image = nil
        }
    }
}

extension ViewController: DraggityDropDestination {
    
    func dropperShouldBegin(_ dropper: NSView) -> Bool {
        return true
    }
    
    func dropperSupportedFiletypes(_ dropper: NSView) -> [NSPasteboard.PasteboardType] {
        return [.fileURL]
    }
    
    func dropperDraggingEntered(_ dropper: NSView) {
        print("Entered!")
    }
    
    func dropperDraggingExited(_ dropper: NSView) {
        print("Exited!")
    }
    
    func dropperDraggingEnded(_ dropper: NSView) {
        print("Ended!")
    }
    
    func dropperDidGetFiles(_ dropper: NSView, files: [URL]) -> Bool {
        print("Got: \(files)")
        
        if files.count == 1 {
            let url = files.first!
            
            if url.hasDirectoryPath {
                self.selectedDirectory = files.first
                return true
            } else {
                print("Wrong type")
                return false
            }
        } else {
            print("Wrong file count")
            return false
        }
    }
    
}
