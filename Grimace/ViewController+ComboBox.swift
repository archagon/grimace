//
//  ViewController+ComboBox.swift
//  Grimace
//
//  Created by Alexei Baboulevitch on 7/22/25.
//

import AppKit

extension ViewController : NSComboBoxDataSource {
    
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        return self.privateSymbols.count
    }

    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        let symbol = self.privateSymbols[index]
        
        let imageAttachment = NSTextAttachment()
        let selector = NSSelectorFromString("imageWithPrivateSystemSymbolName:")
        let symbolImage = NSImage.perform(selector, with: symbol).takeUnretainedValue() as? NSImage
        imageAttachment.image = symbolImage

        let fullString = NSMutableAttributedString()
        fullString.append(NSAttributedString(attachment: imageAttachment))
        fullString.append(NSAttributedString(string: "\t"))
        fullString.append(NSAttributedString(string: symbol))
        
        return fullString
    }
}
