//
//  AppDelegate.swift
//  Grimace
//
//  Created by Alexei Baboulevitch on 7/12/25.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return false
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        if let controller = NSApplication.shared.mainWindow?.contentViewController as? ViewController {
            if urls.count > 0, let url = urls.first, url.hasDirectoryPath {
                controller.pathControl.url = url
            }
        }
    }
}
