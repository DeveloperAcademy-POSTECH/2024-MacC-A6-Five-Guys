//
//  Router.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 10/13/24.
//

import SwiftUI

enum ChatViewRoute: Hashable {
    case photo
    case emotion
    case complete
}

class NavigationRouter<Path: Hashable>: ObservableObject {
    
    @Published public var paths: [Path] = []
    
    func push(_ path: Path) {
        paths.append(path)
    }
    
    func pop() {
        paths.removeLast()
    }
    
    func reset() {
        paths.removeLast(paths.count)
    }
    
    func popToRoot() {
        paths.removeAll()
    }
}
