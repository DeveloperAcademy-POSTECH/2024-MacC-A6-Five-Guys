//
//  NavigationRootView.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/6/24.
//

import SwiftUI

struct NavigationRootView: View {
    @State private var coordinator = NavigationCoordinator()
    
    var body: some View {
        NavigationStack(path: $coordinator.paths) {
            
            coordinator.navigate(to: .mainHome)
                .navigationDestination(for: Screens.self) { screen in
                    coordinator.navigate(to: screen)
                }
        }
        .environment(coordinator)
    }
}

#Preview {
    NavigationRootView()
}
