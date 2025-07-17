//
//  Attributes+Swift.swift
//  Grimace
//
//  Created by Alexei Baboulevitch on 7/13/25.
//

extension Attributes {
    
    class func ignoringNoAttr(_ block: () throws ->()) throws {
        do {
            try block()
        } catch {
            if (error as NSError).domain == NSPOSIXErrorDomain && (error as NSError).code == ENOATTR {
                // continue
            } else {
               throw error
            }
        }
    }
    
    class func removeIconAttributes(from url: URL) throws {
        try ignoringNoAttr {
            try self.removeAttribute(kAttributeFolderIcon, from: url)
        }

        /// If we don't also reset `kAttributeFinderInfo`, then the folder appearance won't change to look full when it contains files.
        /// Note: this issue does not seem to occur when the folder has a color tag.
        try setCustomIconBit(for: url, to: false)
    }
    
    class func setSymbolIcon(with symbolName: String, for url: URL) throws {
        try setCustomIconBit(for: url, to: true)
        let attributeData = folderIconAttribute(withSymbolName: symbolName)
        try setData(attributeData, forAttribute: kAttributeFolderIcon, for: url)
    }
    
    class func setTextIcon(with text: String, for url: URL) throws {
        try setCustomIconBit(for: url, to: true)
        let attributeData = folderIconAttribute(withText: text)
        try setData(attributeData, forAttribute: kAttributeFolderIcon, for: url)
    }
    
    private class func setCustomIconBit(for url: URL, to enable: Bool) throws {
        var existingAttribute: Data? = nil
        try ignoringNoAttr {
            existingAttribute = try data(forAttribute: kAttributeFinderInfo, for: url)
        }
        
        if enable {
            existingAttribute = existingAttribute ?? Data(count: 32)
        }
        
        if let existingAttribute {
            let newAttribute = try finderInfoAttribute(fromExistingAttribute: existingAttribute, withCustomIconEnabled: enable)
            
            if existingAttribute != newAttribute {
                if newAttribute == Data(count: 32) {
                    try ignoringNoAttr {
                        try removeAttribute(kAttributeFinderInfo, from: url)
                    }
                } else {
                    try setData(newAttribute, forAttribute: kAttributeFinderInfo, for: url)
                }
            }
        }
    }
}
