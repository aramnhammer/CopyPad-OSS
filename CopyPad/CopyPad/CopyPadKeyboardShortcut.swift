//
//  KeyboardShortcuts.swift
//  CopyPad
//
//  Created by aram on 8/19/24.
//

import Foundation
import SwiftUI
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let showFloatingPannel = Self("showFloatingPannel")
}

struct KeyboardShortcutsSettingsScreen: View {
    var body: some View {
        Form {
            VStack{
                KeyboardShortcuts.Recorder("Show floating pannel:", name: .showFloatingPannel)
            }
        }
    }
}
