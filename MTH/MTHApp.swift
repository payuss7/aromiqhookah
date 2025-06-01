//
//  MTHApp.swift
//  MTH
//
//  Created by Ilya Payusov on 13.04.2025.
//

import SwiftUI

@main
struct MTHApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(MixViewModel())
        }
    }
}
