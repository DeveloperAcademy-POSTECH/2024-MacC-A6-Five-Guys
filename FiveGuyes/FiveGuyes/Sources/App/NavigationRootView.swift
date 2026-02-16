//
//  NavigationRootView.swift
//  FiveGuyes
//
//  Created by zaehorang on 11/6/24.
//

import SwiftData
import SwiftUI

struct NavigationRootView: View {
    @State private var coordinator: NavigationCoordinator

    init(appDependencies: AppDependencies) {
        _coordinator = State(
            initialValue: NavigationCoordinator(appDependencies: appDependencies)
        )
    }

    var body: some View {
        NavigationStack(path: $coordinator.paths) {

            coordinator.navigate(to: .mainHome)
                .navigationDestination(for: Screens.self) { screen in
                    coordinator.navigate(to: screen)
                }
        }
        .background(Color.Fills.white)
        .environment(coordinator)
    }
}

#Preview {
    if let container = try? ModelContainer(for: UserBookSchemaV2.UserBookV2.self) {
        let dependencies = AppDependencies(modelContainer: container)
        NavigationRootView(appDependencies: dependencies)
            .environment(dependencies)
    } else {
        Text("Preview unavailable")
    }
}
