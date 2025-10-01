//
//  AppPermissions.swift
//  CopyPad
//
//  Created by aram on 8/19/24.
//

import Foundation
import Cocoa
import SwiftUI


struct PermissionsView: View {
    var permissionsPoller: ()->()
    var restartApp: ()->()
    
    func openSystemPreferences() {
        permissionsPoller()
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }
    
    func quit(){
        NSApplication.shared.terminate(nil)
    }
    
    var body: some View {
        VStack {
            Text("Permissions Required 🔐")
                .font(.title)
                .multilineTextAlignment(.leading)
                .padding(.bottom, 20)
            
            Text("Your mac requires that this app has accessibility permissions in order to use keyboard shortcuts.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.bottom, 5)
            Text("Please open the system preferences with the button below, find CopyPad.app in the Applications folder, add it to Accessibility and enable it.")
                .font(.body)
                .bold()
                .multilineTextAlignment(.center)
            Button("Open System Preferences", action: openSystemPreferences)
            Button("Quit", action: quit)
        }
        .padding(.all, 10)
    }
}

final class Permissions: ObservableObject {
    @Published var areAccessibilityPermissionsEnabled: Bool = AXIsProcessTrusted()
    
    init(areAccessibilityPermissionsEnabled: Bool) {
        self.areAccessibilityPermissionsEnabled = areAccessibilityPermissionsEnabled
        self.pollAccessibilityPermissions()
    }
    
    func pollAccessibilityPermissions() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.areAccessibilityPermissionsEnabled = AXIsProcessTrusted()
            
            if !self.areAccessibilityPermissionsEnabled {
                self.pollAccessibilityPermissions()
            }
        }
    }
    
    private func checkAccessibilityPermissions(completion: @escaping () -> Void) {
        if self.areAccessibilityPermissionsEnabled {
            completion()
        } else {
            DispatchQueue.global().async {
                while !self.areAccessibilityPermissionsEnabled {
                    self.areAccessibilityPermissionsEnabled = AXIsProcessTrusted()
                    // Add a small delay to avoid high CPU usage in the loop
                    usleep(100000) // 100 milliseconds
                }
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
    }
    static func getAccessibilityPermissions() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true]
        return AXIsProcessTrustedWithOptions(options)
    }
}
