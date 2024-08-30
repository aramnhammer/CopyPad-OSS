//
//  Created by aram on 11/16/22.
//

import SwiftUI
import ServiceManagement
import Cocoa
import Carbon.HIToolbox
import KeyboardShortcuts

// MARK: Singletons
var appRestrictionsController = ApplicationRestrictionController()
var observableItemList = ObservableItemList()

// MARK: Constants
let floatingWindowName = "floatingWindow"
let tutorialWindowName = "tutorialWindowName"
let appVersion = Bundle.main.releaseVersionNumber
let appBuild = Bundle.main.buildVersionNumber


extension Bundle {
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    var buildVersionNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
}

extension String {
    func truncate(to length: Int, addEllipsis: Bool = false) -> String {
        if self.count > length {
            let endIndex = self.index(self.startIndex, offsetBy: length)
            let truncated = self[..<endIndex]
            return String(addEllipsis ? truncated + "..." : truncated)
        } else {
            return self
        }
    }
}


extension Notification.Name {
    static let escKeyPressed = Notification.Name("escKeyPressed")
}

struct Item: Identifiable{
    let id = UUID()
    var alias: String
    var data: [NSPasteboard.PasteboardType:Data?]
    var thumbNail: NSImage?
    var rawValue: String?
    @State var isPinned: Bool = false
    
    mutating func MediaCoppied(){
        let date = Date.now
        let dateFormatter = DateFormatter()
        dateFormatter.string(from: date)
        self.alias = "Media copied on \(date)"
    }
    
    
    mutating func UpdateTypeData(type: NSPasteboard.PasteboardType, data: Data, finished: ()-> Void){
        switch type {
        case NSPasteboard.PasteboardType.URL:
            self.data[NSPasteboard.PasteboardType.URL] = data
            
        case NSPasteboard.PasteboardType.fileContents:
            self.data[NSPasteboard.PasteboardType.fileContents] = data
            
        case NSPasteboard.PasteboardType.fileURL:
            let str_path = String(decoding: data , as: UTF8.self ).removingPercentEncoding!
            self.alias = (str_path as NSString).lastPathComponent.truncate(to: 50)
            self.data[NSPasteboard.PasteboardType.fileURL] = data
            
        case NSPasteboard.PasteboardType.html:
            self.data[NSPasteboard.PasteboardType.html] = data
        case NSPasteboard.PasteboardType.pdf:
            self.data[NSPasteboard.PasteboardType.pdf] = data
        case NSPasteboard.PasteboardType.png:
            self.data[NSPasteboard.PasteboardType.tiff] = data
            self.MediaCoppied()
        case NSPasteboard.PasteboardType.rtf:
            self.data[NSPasteboard.PasteboardType.rtf] = data
        case NSPasteboard.PasteboardType.rtfd:
            self.data[NSPasteboard.PasteboardType.rtfd] = data
        case NSPasteboard.PasteboardType.sound:
            self.data[NSPasteboard.PasteboardType.sound] = data
            
        case NSPasteboard.PasteboardType.string:
            if self.alias == "N/A" {
                self.alias = String(decoding: data, as: UTF8.self).truncate(to: 50).trimmingCharacters(in: .newlines).replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\t", with: "")
            }else if self.alias == ""{
                self.MediaCoppied()
            }
            self.data[NSPasteboard.PasteboardType.string] = data
        case NSPasteboard.PasteboardType.tabularText:
            self.data[NSPasteboard.PasteboardType.tabularText] = data
        case NSPasteboard.PasteboardType.tiff:
            self.data[NSPasteboard.PasteboardType.tiff] = data
        case  NSPasteboard.PasteboardType.color:
            self.data[NSPasteboard.PasteboardType.color] = data
        case NSPasteboard.PasteboardType.findPanelSearchOptions:
            self.data[NSPasteboard.PasteboardType.findPanelSearchOptions] = data
        case NSPasteboard.PasteboardType.font:
            self.data[NSPasteboard.PasteboardType.font] = data
        case NSPasteboard.PasteboardType.multipleTextSelection:
            self.data[NSPasteboard.PasteboardType.multipleTextSelection] = data
        case NSPasteboard.PasteboardType.ruler:
            self.data[NSPasteboard.PasteboardType.ruler] = data
        case NSPasteboard.PasteboardType.textFinderOptions:
            self.data[NSPasteboard.PasteboardType.textFinderOptions] = data
        default: break
        }
        finished()
    }
    func getTypeImage() -> Image{
        if self.data.keys.contains([NSPasteboard.PasteboardType.fileURL]){
            return Image(systemName: "doc")
                .symbolRenderingMode(.monochrome)
            
        }
        else if self.data.keys.contains([NSPasteboard.PasteboardType.URL]){
            return Image(systemName: "link")
                .symbolRenderingMode(.monochrome)
            
        }

        else if self.data.keys.contains([NSPasteboard.PasteboardType.sound]){
            return Image(systemName: "music.note")
        }
        else if self.data.keys.contains([NSPasteboard.PasteboardType.rtf]){
            return Image(systemName: "text.alignleft")
        }
        else if self.data.keys.contains([NSPasteboard.PasteboardType.tiff]) || self.data.keys.contains([NSPasteboard.PasteboardType.png]){
            return Image(systemName: "photo")
        }
        else {
            return Image(systemName: "text.alignleft")
        }
    }
    func getItemURL()-> Optional<URL> {
        if self.data.keys.contains(NSPasteboard.PasteboardType.fileURL) {
            let data = self.data[NSPasteboard.PasteboardType.fileURL]
            return URL(dataRepresentation: data!!, relativeTo: nil)
        }
        return nil
    }
    func getAbsolutePath() -> Optional<String> {
        // if we have a file type we should strip the `file://` prefix and use the path
        if self.data.keys.contains(NSPasteboard.PasteboardType.fileURL) {
            let path_data: Data = (
                String(decoding: self.data[NSPasteboard.PasteboardType.fileURL]!! , as: UTF8.self )
                    .replacingOccurrences(of: "file://", with: "")
                    .removingPercentEncoding!.data(using: .utf8))!
            return String(decoding: path_data, as: UTF8.self)
        }
        return nil
    }
    mutating func togglePin(){
        self.isPinned.toggle()
    }
}

class ObservableItemList : ObservableObject {
    @Published var items = [Item]()
    private let clipBoard = NSPasteboard.general
    let acceptedTypes = [
        NSPasteboard.PasteboardType.URL,
        NSPasteboard.PasteboardType.fileContents,
        NSPasteboard.PasteboardType.fileURL,
        NSPasteboard.PasteboardType.html,
        NSPasteboard.PasteboardType.pdf,
        NSPasteboard.PasteboardType.png,
        NSPasteboard.PasteboardType.rtf,
        NSPasteboard.PasteboardType.rtfd,
        NSPasteboard.PasteboardType.sound,
        NSPasteboard.PasteboardType.string,
        NSPasteboard.PasteboardType.tabularText,
        NSPasteboard.PasteboardType.tiff,
        NSPasteboard.PasteboardType.color,
        NSPasteboard.PasteboardType.findPanelSearchOptions,
        NSPasteboard.PasteboardType.font,
        NSPasteboard.PasteboardType.multipleTextSelection,
        NSPasteboard.PasteboardType.ruler,
        NSPasteboard.PasteboardType.textFinderOptions
    ]
    @Published var restrictedAppURLS: [URL]? = []
    var changeCount = 0
    private var timer: Timer!
    private var mem_size_timer: Timer!
    
    init(){
        self.changeCount = self.clipBoard.changeCount
        self.timer = Timer.scheduledTimer(timeInterval: TimeInterval(0.3), target: self, selector: #selector(self.pollPasteBoard(_:)), userInfo: nil, repeats: true)
    }
    
    func reloadRestrictedURLS() {
        self.restrictedAppURLS = appRestrictionsController.returnRestrictedApplicationURLs()
    }
    
    func getLastPinnedPos() -> Optional<Int> {
        return self.items.lastIndex(where: { $0.isPinned == true })
    }
    
    func getFirstUnpinnedPos() -> Optional<Int> {
        return self.items.firstIndex(where: {$0.isPinned == false})
    }
    
    func insertItem(item: Item){
        let existingItem = self.hasItem(item: item)
        if existingItem == nil{
            let last_pinned_idx = 	getLastPinnedPos()
            if last_pinned_idx == nil {
                self.items.insert(item, at: 0)
            } else {
                self.items.insert(item, at: last_pinned_idx! + 1)
            }
        }else{
            let last_pinned_idx = getLastPinnedPos()
            guard let idx = self.items.firstIndex(where: { $0.data == item.data }) else { return  }
            let new_item = Item(alias: item.alias, data: item.data, isPinned: false)
            self.items.remove(at: idx)
            if last_pinned_idx == nil{
                self.items.insert(new_item, at: 0)
            }else{
                self.items.insert(new_item, at: last_pinned_idx! + 1)
            }
        }
    }
    
    func hasItem(item: Item) -> Int? {
        return items.firstIndex { $0.alias == item.alias }
    }
    
    @objc func pollPasteBoard(_ sender: Any){
        self._pollPasteBoard()
    }
    
    func _pollPasteBoard(){
        if clipBoard.changeCount != changeCount {
            if let source = NSWorkspace.shared.frontmostApplication?.bundleURL{
                if self.restrictedAppURLS?.contains(where: { $0 == source }) == true {
                        return
                    }
            }
            changeCount = clipBoard.changeCount
            var item = Item(alias: "N/A",
                            data: [:])
            for t in acceptedTypes{
                if let data = clipBoard.data(forType: t) {
                    item.UpdateTypeData(type: t, data: data, finished: {}) // Note: this `finished` closure ensures item.data field is updated before anything else is done
                }
            }
            insertItem(item: item)
        }
    }
    func writePasteBoard(item: Item, overrideData: [NSPasteboard.PasteboardType: Data]) {
        clipBoard.clearContents()
        changeCount += 1
        if overrideData.isEmpty {
            for (t, d) in item.data{
                // test to see if we don't insert anything but a string type,
                // will it paste the string value only... Confirmed, it will paste the string value
                clipBoard.setData(d, forType: t)
            }
        }else{
            for (t, d) in overrideData {
                // test to see if we don't insert anything but a string type,
                // will it paste the string value only... Confirmed, it will paste the string value
                clipBoard.setData(d, forType: t)
            }
        }
        
        
    }
    func deletePasteBoard(item: Item) {
        for (idx, ii) in items.enumerated() {
            if item.alias == ii.alias {
                items.remove(at: idx)
                return
            }
        }
    }
    
    func clear(){
        clipBoard.clearContents()
        self.changeCount = self.clipBoard.changeCount
        items.removeAll(where: {!$0.isPinned})
    }
    
    func togglePinning(item: Item) {
        // FIXME: there is probably a better way to do this
        if !item.isPinned {
            guard let idx = self.items.firstIndex(where: { $0.id == item.id }) else { return  }
            let pinned_item = Item(alias: item.alias, data: item.data, isPinned: true)
            self.items.remove(at: idx)
            self.items.insert(pinned_item, at: 0)
        } else {
            let unpinned_item = Item(alias: item.alias, data: item.data, isPinned: false)
            self.items.insert(unpinned_item, at: getFirstUnpinnedPos() ?? self.items.count)
            guard let idx = self.items.firstIndex(where: { $0.id == item.id }) else { return  }
            self.items.remove(at: idx)
        }
        
    }
}


struct SettingsContextMenuButtonStyle: ButtonStyle {
    @State private var hovered = false

    func makeBody(configuration: Configuration) -> some View {
        VStack {
            configuration.label
                .foregroundColor(.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .background(configuration.isPressed ? Color.gray.opacity(0.2) : Color.clear)
                .cornerRadius(5)
                .background(Color(hovered ? .systemBlue : .clear))
                .onHover { isHovered in
                    self.hovered = isHovered
                }
                .animation(.default, value: hovered)
                .clipShape(RoundedRectangle(cornerRadius:10))
                .font(.callout)
                .cornerRadius(1)
        }
    }
}



struct CopyPadView: View {
    @Environment(\.openWindow) var openWindow
    @State private var showingPopover = false
    @State var currentNumber: String = "1"
    @ObservedObject var itemsView: ObservableItemList
    @State private var searchText = ""
    @State private var firstItem: Item?
    @State private var search_box_disabled: Bool = true
    @ObservedObject var permissionsService: Permissions
    @ObservedObject var appRestrictions: ApplicationRestrictionController
    @Environment(\.colorScheme) var colorScheme

    @State var showAppRestrictionsView: Bool = false
    @State var showingPanel = false
    @State var showingKBSettings = false
    @State var showFloatingWindow = false
    @State var showThirdPartySoftware = false
    let restartFunc: ()->()
    
    init(itemsView: ObservableItemList,
         restart: @escaping ()->(),
         permissionsService: Permissions,
         appRestrictions: ApplicationRestrictionController
    ){
        self.itemsView = itemsView
        self.restartFunc = restart
        self.permissionsService = permissionsService
        self.appRestrictions = appRestrictions
    }
    
    var body: some View {
        if !self.permissionsService.areAccessibilityPermissionsEnabled {
            PermissionsView(permissionsPoller: self.permissionsService.pollAccessibilityPermissions, restartApp: self.restartFunc)
        }
        else{
            VStack{
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("Search ...", text: $searchText)
                        .onSubmit {
                            if !itemsView.items.isEmpty
                            {
                                itemsView.writePasteBoard(item: firstItem!, overrideData: [:])
                            }
                        }
                        .disabled(search_box_disabled)
                        .onAppear {
                            DispatchQueue.main.async {
                                search_box_disabled = false
                            }
                        }
                }
            }
            .cornerRadius(100)
            .padding()
            if self.showingKBSettings {
                VStack{
                    KeyboardShortcutsSettingsScreen()
                    Divider()
                    Button("Confirm and Reveal"){
                        self.showingKBSettings.toggle()
                        NSApplication.shared.activate(ignoringOtherApps: true)
                        openWindow(id: "floatingWindow")
                    }
                }
            }
            else if self.showThirdPartySoftware {
                VStack {
                    Text("keyboardshortcuts")
                        .font(.headline)
                    Text("https://github.com/sindresorhus/KeyboardShortcuts").font(.subheadline)
                    Divider()
                    Button("Back") {
                        self.showThirdPartySoftware.toggle()
                    }
                }
            }
            else if showAppRestrictionsView {
                AppRestrictionsView(viewModel: self.appRestrictions, showAppRestrictionsView: $showAppRestrictionsView)
            }
        else {
                NavigationStack{
                    ScrollView
                    {
                        ForEach(searchResults,id: \.id) { item in
                            HStack{
                                CardView(actionCallback: writePasteboardCallback,
                                         deleteCallback: deleteItemCallback,
                                         pinItemCallback: pinItemCallback,
                                         item:item)
                            }
                        }
                    }
                }
                .searchable(text: $searchText)
            }
            
            
            Divider()
            VStack {
                
                Button(action: {
                    showingPopover = true
                }) {
                    Image(systemName: "gear")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                    .popover(isPresented: $showingPopover, arrowEdge: .bottom) {
                        ZStack{
                            HStack{
                                VStack(spacing: 0){
                                    Button("Feature Demos") {
                                        openWindow(id: tutorialWindowName)
                                    }
                                    .buttonStyle(SettingsContextMenuButtonStyle())
                                    Button("Reveal Floating Window") {
                                        NSApplication.shared.activate(ignoringOtherApps: true)
                                        openWindow(id: floatingWindowName)
                                    }
                                    .help("Reveal the floating window")
                                    .buttonStyle(SettingsContextMenuButtonStyle())
                                    Button("App Restrictions"){
                                        self.showAppRestrictionsView.toggle()
                                    }.buttonStyle(SettingsContextMenuButtonStyle())
                                    Button("Keyboard Shortucts") {
                                        self.showingKBSettings.toggle()
                                    }
                                    .help("Configure keyboard shortcuts for displaying the floating window")
                                    .buttonStyle(SettingsContextMenuButtonStyle())
                                    Button("App Permissions") {
                                        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                                    }
                                    .help("Open System Application Permissions")
                                    .buttonStyle(SettingsContextMenuButtonStyle())
                                    Divider()
                                    Form {
                                        LaunchOnLoginToggle.Toggle()
                                    }
                                    .help("Launch CopyPad to start on login to this computer")
                                    .padding(.vertical)
                                    Button("Clear") {
                                        itemsView.clear()
                                    }
                                    .help("Clear all the items from CopyPad")
                                    .buttonStyle(SettingsContextMenuButtonStyle())
                                    Button("Quit") {
                                        NSApplication.shared.terminate(nil)
                                    }
                                    .help("Quit the app (All items in CopyPad will be lost)")
                                    .buttonStyle(SettingsContextMenuButtonStyle())
                                    Button("Restart") {
                                        self.restartFunc()
                                    }
                                    .help("Restart CopyPad (All items in CopyPad will be lost)")
                                    .buttonStyle(SettingsContextMenuButtonStyle())
                                    Button("Third Party Software") {
                                        self.showThirdPartySoftware.toggle()
                                    }
                                    .buttonStyle(SettingsContextMenuButtonStyle())
                                    Text("\(appVersion ?? "0.0").\(appBuild ?? "##")")
                                        .font(.footnote)
                                }
                            }.padding(10)
                        
                        }.fixedSize(horizontal: true, vertical: true)
                    }
            }
        }
        
    }
    
    var searchResults: [Item] {
        if searchText.isEmpty {
            return itemsView.items
        } else {
            let items = itemsView.items.filter { $0.alias.lowercased().contains(searchText.lowercased()) }
            // need to wrap this activity in an async function to avoid modifying state during a view update
            DispatchQueue.main.async {
                firstItem = items.first
            }
            return items
        }
    }
    
    // Callbacks: //
    // when searching for an item, then deleteing it, make sure to reset the search to an empty string, so it returns you to the original list of items minus the one you deleted
    func deleteItemCallback(item: Item) {
        if !itemsView.items.isEmpty {
            itemsView.deletePasteBoard(item: item)
            searchText = ""
        }
    }
    
    // just to keep things clean, all interfaces to the ItemsView from a card, goes through a method in the parent
    func writePasteboardCallback(item: Item, overrideData: [NSPasteboard.PasteboardType: Data]) {
        self.itemsView.writePasteBoard(item: item, overrideData: overrideData)
    }
    
    func pinItemCallback(item: Item) {
        self.itemsView.togglePinning(item: item)
    }
}


private struct FloatingWindow: View {
    @State private var isPressed1 = false
    var appDelegate: AppDelegate
    @State private var isWindowHidden = false

    
    init(isPressed1: Bool = false, appDelegate: AppDelegate) {
        self.isPressed1 = isPressed1
        self.appDelegate = appDelegate

    }
    
    func hide(){
        NSApp.windows.first { $0.identifier?.rawValue == floatingWindowName }?.close()
        NSApp.windows.first { $0.identifier?.rawValue == floatingWindowName }?.collectionBehavior.insert(.transient)
    }
    
    var body: some View {
        Form {
            CopyPadView(itemsView: appDelegate.app!.itemsView, restart: appDelegate.app!.restart, permissionsService: appDelegate.app!.permissionsService, appRestrictions: appRestrictionsController)
        }
        .offset(x: -40)
        .frame(maxWidth: 300)
        .padding()
        .padding()
        .onKeyboardShortcut(.showFloatingPannel) {
            isPressed1 = $0 == .keyDown
        }
        .task {
            KeyboardShortcuts.onKeyUp(for: .showFloatingPannel) {
                isPressed1.toggle()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
            self.hide()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)){
            _ in
            NSApp.windows.first {
                $0.identifier?.rawValue == floatingWindowName
            }?.standardWindowButton(.zoomButton)?.isHidden = true
        }
    }
}



class AppDelegate: NSObject, NSApplicationDelegate {
    //@Environment(\.openWindow) var openWindow
    @State var permissionsEnabled: Bool = false
    var app: CopyPad?
    
    private func start(){
        self.app = CopyPad()
        // create observer to close the floating dialog when esc key is pressed
        NotificationCenter.default.addObserver(self, selector:#selector(HideFloatingWindow(_:)),name: .escKeyPressed, object: nil)
        self.app?.registerFloatingViewShortCut()
        HideFloatingWindow(nil)
        
    }
    
    // impl objc func to close the floating window when we hit esc
    @objc func HideFloatingWindow(_ notification: Notification?){
        NSApp.windows.first { $0.identifier?.rawValue == floatingWindowName }?.close()
    }
    
    private func configureFloatingWindowBehavior() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 { // Check if the pressed key is Esc (key code 53)
                // fire off a notification (the escKeyPressed Notification we have implemented
                NotificationCenter.default.post(name: .escKeyPressed,object: nil)
            }
            return event
        }
        
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.start()
        permissionsEnabled = Permissions.getAccessibilityPermissions()
        self.configureFloatingWindowBehavior()
        for w in NSApp.windows{
            print(w.identifier?.rawValue)
        }
    }
    
    func applicationDidResignActive(_ notification: Notification) {
        if permissionsEnabled {
            NSApplication.shared.hide(nil)
        }
        self.HideFloatingWindow(nil)
    }
}

struct SceneController: Scene {
    var app: CopyPad
    var menuBarView: CopyPadView
    
    init(app: CopyPad) {
        self.app = app
        // FIXME: can probably move these to singletons marked area instead of passing instances around
        self.menuBarView =  CopyPadView(itemsView: app.itemsView, restart: app.restart, permissionsService: app.permissionsService, appRestrictions: appRestrictionsController)
    }
    @SceneBuilder var body: some Scene {
        MenuBarExtra("", image:"MenuBar") {
            self.menuBarView
        }
        .menuBarExtraStyle(.window)
        
        
        Window("FloatingWindow", id: floatingWindowName) {
            self.menuBarView
                .frame(minWidth: 250, idealWidth: 250, maxWidth: 450, minHeight: 290, idealHeight: 290, maxHeight: 490)
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.willUpdateNotification), perform: { _ in
                    if let floatingWindow = NSApp.windows.first(where: { $0.identifier?.rawValue == floatingWindowName }) {
                        floatingWindow.standardWindowButton(.zoomButton)?.isHidden = true
                        floatingWindow.standardWindowButton(.closeButton)?.isHidden = true
                        floatingWindow.standardWindowButton(.miniaturizeButton)?.isHidden = true
                    }
                })
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        Window("Showcase", id: tutorialWindowName){
            FeatureTutorialsView()
        }
        .windowResizability(.automatic)

    }
}



@main
struct CopyPad: App {
    @Environment(\.openWindow) var openWindow
    @StateObject var permissionsService = Permissions(areAccessibilityPermissionsEnabled: false)
    @StateObject var itemsView = observableItemList
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    func restart(){
        Process.launchedProcess(launchPath: "/usr/bin/open", arguments: ["-n", Bundle.main.bundlePath])
        NSApplication.shared.terminate(self)
    }
    
    var body: some Scene {
        SceneController(app: self)
    }
    
    func registerFloatingViewShortCut() {
        openWindow(id: floatingWindowName)
        KeyboardShortcuts.onKeyUp(for: .showFloatingPannel) { [self] in
                    NSApplication.shared.activate(ignoringOtherApps: true)
                    openWindow(id: floatingWindowName)
                    NSApplication.shared.windows.first { $0.identifier?.rawValue == floatingWindowName }?.makeKeyAndOrderFront(nil)
        }
        NSApplication.shared.windows.first { $0.identifier?.rawValue == floatingWindowName }?.hidesOnDeactivate = true
        NSApplication.shared.windows.first { $0.identifier?.rawValue == floatingWindowName }?.close()
    }
}
