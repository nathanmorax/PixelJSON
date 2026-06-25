//
//  PixelJSONApp.swift
//  PixelJSON
//
//  Created by Satori Tech 341 on 23/06/26.
//

import SwiftUI
import AppKit


@main
struct PixelJSONApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let hotkeyManager = HotkeyManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        hotkeyManager.register()
    }
}
