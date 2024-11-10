//
//  NavigationRootView.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/6/24.
//

import SwiftUI

struct NavigationRootView: View {
    @State private var coordinator = NavigationCoordinator()
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationStack(path: $coordinator.paths) {
            
            coordinator.navigate(to: .mainHome)
                .navigationDestination(for: Screens.self) { screen in
                    coordinator.navigate(to: screen)
                }
        }
        .background(.white)
        .environment(coordinator)
    }
}

#Preview {
    NavigationRootView()
}
