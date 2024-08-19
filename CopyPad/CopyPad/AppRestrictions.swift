//
//  AppRestrictions.swift
//  CopyPad
//
//  Created by aram on 8/19/24.
//

import Foundation
import SwiftUI

// MARK: App Restrictions
class InstalledAppModel: ObservableObject, Identifiable, Codable{
    let id: UUID
    let name: String
    let url: URL
    @Published var isEnabled: Bool
    
    enum CodingKeys: String, CodingKey {
            case id
            case name
            case url
            case isEnabled
        }
    
    init(id: UUID=UUID(), name: String, url: URL, isEnabled: Bool) {
        self.id = id
        self.name = name
        self.url = url
        self.isEnabled = isEnabled
    }
    
    required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(UUID.self, forKey: .id)
            name = try container.decode(String.self, forKey: .name)
            url = try container.decode(URL.self, forKey: .url)
            isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        }
        
    func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(name, forKey: .name)
            try container.encode(url, forKey: .url)
            try container.encode(isEnabled, forKey: .isEnabled)
        }
}

struct ApplicationToggleView: View {
    @StateObject var app:InstalledAppModel
    
    var body: some View {
        VStack(spacing: 0) {
            Toggle(app.name, isOn: $app.isEnabled)
        }
        .padding(.horizontal)
    }
}

// ViewModel to manage the list and persistence
class ApplicationRestrictionController: ObservableObject {
    @Published var applications: [InstalledAppModel] = []
    
    private let userDefaultsKey = "ApplicationsToggleState"
    
    init() {
        loadApplications()
        loadToggleState()
    }
    
    func loadApplications() {
        let fileManager = FileManager.default
        let applicationsPath = "/Applications"
        
        do {
            let applicationPaths = try fileManager.contentsOfDirectory(atPath: applicationsPath)
                            .filter { $0.hasSuffix(".app") }
                            .map { applicationsPath + "/" + $0 }
            
            applications = applicationPaths.map { path in
                let name = (path as NSString).lastPathComponent.replacingOccurrences(of: ".app", with: "")
                return InstalledAppModel(name: name, url: URL(fileURLWithPath: path), isEnabled: false)
            }
        } catch {
            print("Failed to load applications: \(error.localizedDescription)")
        }
    }
    
    func loadToggleState() {
        if let savedData = UserDefaults.standard.data(forKey: userDefaultsKey),
           let savedApplications = try? JSONDecoder().decode([InstalledAppModel].self, from: savedData){
            let savedApplicationsDict = Dictionary(uniqueKeysWithValues: savedApplications.map { ($0.name, $0) })
            // Merge with the current applications list to ensure newly installed apps are added
            for a in applications{
                if let app = savedApplicationsDict[a.name] {
                    a.isEnabled = app.isEnabled
                }
            }
        }
    }
    
    func saveToggleState() {
        if let savedData = try? JSONEncoder().encode(applications) {
            UserDefaults.standard.setValue(savedData, forKey: self.userDefaultsKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    func returnRestrictedApplicationURLs() -> [URL]{
        return self.applications.filter { $0.isEnabled }.map { $0.url }
    }
    
    func getApplicationsOrderedByToggleState() -> [InstalledAppModel] {
        return self.applications.sorted(by: {$0.isEnabled && $1.isEnabled})
    }
}

struct AppRestrictionsView: View {
    @State var viewModel: ApplicationRestrictionController
    @Binding var showAppRestrictionsView: Bool
    
    init(viewModel: ApplicationRestrictionController, showAppRestrictionsView: Binding<Bool>) {
        self.viewModel = viewModel
        self._showAppRestrictionsView = showAppRestrictionsView
        self.viewModel.loadToggleState()
    }

    var body: some View {
        HStack {
                        Button {
                            viewModel.saveToggleState()
                            observableItemList.reloadRestrictedURLS()
                            self.showAppRestrictionsView = false
                        } label: {
                            Image(systemName: "chevron.backward")
                        }
                        .padding(.leading, 10)
                        
                        Spacer()
                    }
        Divider()
        List {
            ForEach($viewModel.applications) { $app in
                ApplicationToggleView(app: app)
            }
        }
        .navigationTitle("Installed Applications")
    }
}
