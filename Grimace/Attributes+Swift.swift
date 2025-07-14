//
//  Attributes+Swift.swift
//  Grimace
//
//  Created by Alexei Baboulevitch on 7/13/25.
//

extension Attributes {
    class func removeIconAttributes(from url: URL) throws {
        do {
            try self.removeAttribute(kAttributeFolderIcon, from: url)
            //try self.removeAttribute(kAttributeFinderInfo, from: url)
            //try self.removeAttribute(kAttributeUserTags, from: url)
        } catch {
            if (error as NSError).domain == NSPOSIXErrorDomain && (error as NSError).code == ENOATTR {
                // continue
            } else {
               throw error
            }
        }
    }
    
    class func setSymbolIcon(with symbolName: String, for url: URL) throws {
        try prepareSetIcon(for: url)
        let attributeData = folderIconAttribute(withSymbolName: symbolName)
        try setData(attributeData, forAttribute: kAttributeFolderIcon, for: url)
    }
    
    class func setTextIcon(with text: String, for url: URL) throws {
        try prepareSetIcon(for: url)
        let attributeData = folderIconAttribute(withText: text)
        try setData(attributeData, forAttribute: kAttributeFolderIcon, for: url)
    }
    
    private class func prepareSetIcon(for url: URL) throws {
        var existingAttribute: Data? = nil
        
        do {
            existingAttribute = try data(forAttribute: kAttributeFinderInfo, for: url)
        } catch {
            if (error as NSError).domain == NSPOSIXErrorDomain && (error as NSError).code == ENOATTR {
            } else {
                throw error
            }
        }
        
        if existingAttribute == nil {
            existingAttribute = Data([UInt8](repeating: 0, count: 32))
        }
        
        let newAttribute = try finderInfoAttributeToShowIcon(withExistingFinderInfoAttribute: existingAttribute!)
        
        if existingAttribute != newAttribute {
            try setData(newAttribute, forAttribute: kAttributeFinderInfo, for: url)
        }
    }
}
