//
//  LinearGradient+Extension.swift
//  FiveGuyes
//
//  Created by zaehorang on 10/12/24.
//

import SwiftUI

extension LinearGradient {
    
    static var headerGradient: LinearGradient {
        return LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color.black, location: 0.32),
                .init(color: Color.black.opacity(0), location: 1.0)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    static var footerGradient: LinearGradient {
        return LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color.black.opacity(0), location: 0.0),
                .init(color: Color.black, location: 1.0)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    static var chatGradient: LinearGradient {
        return LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color.white, location: 0.55),
                .init(color: Color.white.opacity(0), location: 1.0)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
