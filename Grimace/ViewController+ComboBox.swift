//
//  ViewController+ComboBox.swift
//  Grimace
//
//  Created by Alexei Baboulevitch on 7/22/25.
//

import AppKit

extension ViewController : NSComboBoxDataSource, NSComboBoxDelegate {
    
    func numberOfItems(in comboBox: NSComboBox) -> Int {
        return self.comboBoxContents.count
    }

    func comboBox(_ comboBox: NSComboBox, objectValueForItemAt index: Int) -> Any? {
        let symbol = self.comboBoxContents[index]
        
        let imageAttachment = NSTextAttachment()
        let selector = NSSelectorFromString("imageWithPrivateSystemSymbolName:")
        
        if let symbolImage = NSImage.perform(selector, with: symbol).takeUnretainedValue() as? NSImage {
            imageAttachment.image = symbolImage
            
            let maxDimension = 14.0
            let aspectRatio = symbolImage.size.width / symbolImage.size.height
            
            if aspectRatio >= 1 {
                imageAttachment.bounds = .init(origin: .zero, size: .init(width: maxDimension, height: maxDimension/aspectRatio))
            } else {
                imageAttachment.bounds = .init(origin: .zero, size: .init(width: maxDimension*aspectRatio, height: maxDimension))
            }
            
            let fullString = NSMutableAttributedString()
            fullString.append(NSAttributedString(attachment: imageAttachment))
            fullString.append(NSAttributedString(string: "\t"))
            fullString.append(NSAttributedString(string: symbol))
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = .byTruncatingMiddle
            let range = NSRange(location: 0, length: fullString.mutableString.length)
            fullString.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
            
            return fullString
        } else {
            return "\(symbol)"
        }
    }
    
    func controlTextDidChange(_ obj: Notification) {
        print("Did change")
        
        var regexString = "^.*"
        for char in self.comboBox.stringValue {
            regexString.append("\(char).*")
        }
        regexString.append(".*$")

        do {
            let regex = try Regex(regexString)
            print(regex)
            
            let allSymbols = self.publicSymbols + self.privateSymbols
            self.comboBoxContents = try allSymbols.filter { symbol in
                try regex.wholeMatch(in: symbol) != nil
            }
            self.comboBox.reloadData()
        } catch {
            print(error)
        }
    }
}
