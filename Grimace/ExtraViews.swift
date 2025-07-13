//
//  ExtraViews.swift
//  Grimace
//
//  Created by Alexei Baboulevitch on 7/12/25.
//

import AppKit

@objc protocol DraggityDropDestination {
    func dropperShouldBegin(_ dropper: NSView) -> Bool
    func dropperSupportedFiletypes(_ dropper: NSView) -> [NSPasteboard.PasteboardType]
    func dropperDraggingEntered(_ dropper: NSView)
    func dropperDraggingExited(_ dropper: NSView)
    func dropperDraggingEnded(_ dropper: NSView)
    func dropperDidGetFiles(_ dropper: NSView, files: [URL]) -> Bool
}

class DragDroppableView : NSView {
    @IBOutlet weak var delegate: DraggityDropDestination? {
        didSet {
            if let delegate = self.delegate {
                self.registerForDraggedTypes(delegate.dropperSupportedFiletypes(self))
            }
        }
    }
    
    var enabled: Bool = true
    
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return self.enabled && self.delegate?.dropperShouldBegin(self) ?? false
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if self.enabled {
            self.delegate?.dropperDraggingEntered(self)
            return NSDragOperation.copy
        }
        else {
            return []
        }
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        if self.enabled {
            self.delegate?.dropperDraggingExited(self)
        }
    }
    
    override func draggingEnded(_ sender: NSDraggingInfo?) {
        if self.enabled {
            self.delegate?.dropperDraggingEnded(self)
        }
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        if !self.enabled {
            return false
        }
        
        let classArray: [AnyClass] = [ NSURL.self ]
        let returnArray = sender.draggingPasteboard.readObjects(forClasses: classArray, options: [ NSPasteboard.ReadingOptionKey.urlReadingFileURLsOnly : true ])
        
        if let urlArray = returnArray as? [URL], let delegate = self.delegate {
            return delegate.dropperDidGetFiles(self, files: urlArray)
        }
        else {
            return false
        }
    }
}
