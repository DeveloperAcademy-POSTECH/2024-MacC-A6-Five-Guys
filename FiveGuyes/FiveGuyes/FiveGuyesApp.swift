//
//  FiveGuyesApp.swift
//  FiveGuyes
//
//  Created by zaehorang on 10/3/24.
//

import SwiftData
import SwiftUI

@main
struct FiveGuyesApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationRootView()
                .modelContainer(for: UserBook.self)
        }
    }
}
