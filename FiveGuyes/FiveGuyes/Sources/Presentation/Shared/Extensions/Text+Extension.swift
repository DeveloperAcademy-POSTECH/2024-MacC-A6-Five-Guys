//
//  Text+Extension.swift
//  FiveGuyes
//
//  Created by Shim Hyeonhee on 11/28/24.
//

import SwiftUI

extension Text {
    func alertFontStyle(_ style: FontStyle, weight: Font.Weight = .regular) -> Text {
        self
            .font(.system(size: style.size, weight: weight))
    }
}
