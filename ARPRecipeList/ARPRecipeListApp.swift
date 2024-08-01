//
//  ARPRecipeListApp.swift
//  ARPRecipeList
//
//  Created by Arturo Rivera Paniza on 23/6/2024.
//

import SwiftUI
import UIKit
import Firebase

@main
struct ARPRecipeList: App {
    // Register AppDelegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
