//
//  Extensions.swift
//  CopyPad
//
//  Created by aram on 8/19/24.
//

import Foundation
import SwiftUI
import ServiceManagement
import Cocoa


// the observable object of the launch controller
extension LaunchOnLoginToggle {
    final class Observable: ObservableObject {
        var isEnabled: Bool {
            get { LaunchOnLoginToggle.isEnabled }
            set {
                LaunchOnLoginToggle.isEnabled = newValue
            }
        }
    }
}

// create a custom toggle for UI from Toggle
extension LaunchOnLoginToggle {
    public struct Toggle<Label: View>: View {
        
        @ObservedObject var login_launcher = LaunchOnLoginToggle.observable
        private let label: Label
        
        public var body: some View {
            SwiftUI.Toggle(isOn: $login_launcher.isEnabled) { label }
                .toggleStyle(.checkbox)
        }
        
        public init(@ViewBuilder label: () -> Label) {
            self.label = label()
        }
        
        
    }
}

extension LaunchOnLoginToggle.Toggle<Text> {
    public init() {
        self.label = Text("Launch on login")
    }
}

// Enumerator to observe the launch controller, state, and virtual function to get/set state
public enum LaunchOnLoginToggle {
    fileprivate static let observable = LaunchOnLoginToggle.Observable() // LoginLaunchController
    public static var isEnabled: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            do {
                
                observable.objectWillChange.send()
                if newValue {
                    if SMAppService.mainApp.status == .enabled {
                        try? SMAppService.mainApp.unregister()
                    }
                    
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to \(newValue ? "enable" : "disable") launch at login: \(error.localizedDescription)")
            }
        }
    }
}
