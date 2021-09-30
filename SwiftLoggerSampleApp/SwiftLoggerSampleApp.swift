//
//  SwiftLoggerSampleApp.swift
//  SwiftLoggerSampleApp
//
//  Created by Dagy Tran on 28.09.2021.
//

import SwiftUI

@main
struct SwiftLoggerSampleApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            NavigationView {
                FileLogsTable()
            }
        }
    }
}
