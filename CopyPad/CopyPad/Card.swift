//
//  Card.swift
//  ClipboardManager
//
//  Created by aram on 12/25/22.
//

import Foundation
import SwiftUI
import QuickLook
import QuickLookThumbnailing


extension URL {
    var isDirectory: Bool {
        return (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
}


struct ItemCardStyle: ButtonStyle {
    @Binding var item: Item
    @State private var hovered = false
    @Binding var isPressed : Bool
    @Binding var showPopover : Bool
    @Environment(\.colorScheme) var colorScheme
    @State private var hoverLocation: CGPoint = .zero
    var actionCallback : (Item, [NSPasteboard.PasteboardType: Data]) -> ()
    var deleteCallback : (Item) -> ()
    var pinItemCallback : (Item) -> ()

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 1)
            .padding(.vertical, 5)
            .font(.subheadline)
            .cornerRadius(1)
            .buttonBorderShape(.roundedRectangle)
            .truncationMode(Text.TruncationMode.tail)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(hovered ? .systemBlue : .clear))
            .foregroundColor(
                colorScheme == .dark ? Color.white : Color.black
            )
            .onHover { isHovered in
                self.hovered = isHovered
            }
            .animation(.default, value: hovered)
            .clipShape(RoundedRectangle(cornerRadius:10))
            .bold()
            .scaleEffect(configuration.isPressed ? 0.8 : 0.9)
            .onChange(of: configuration.isPressed, perform: {newVal in
                isPressed = newVal
            })
            .onTapGesture(count: 2) {
                showPopover = true
            }
            .contextMenu(ContextMenu(menuItems: {
            PinButton(pinCallback: pinItemCallback, item: item)
            PreviewButton(showPreview: $showPopover, item: item)
            Divider()
            Divider()
            Divider()
            ContextMenuButton(absolutePath: item.getAbsolutePath(),
                              actionCallback: actionCallback,
                              item: item)
            Divider()
            Divider()
            Divider()
            DeleteItem(deleteCallback: deleteCallback, item: item)
        }))

    }
}


struct DeleteItem: View {
    var deleteCallback : (Item) -> ()
    var item: Item
    var body: some View {
        VStack {
            HStack{
                Button(
                    action: {
                        deleteCallback(item)
                    },
                    label: {
                        Image(systemName: "trash")
                        Text("Delete")
                    }
                )
            }
        }
    }
}

struct PinButton: View {
    var pinCallback : (Item) -> ()
    var item: Item
    var body: some View {
        VStack {
            HStack{
                Button(
                    action: {
                        pinCallback(item)
                    },
                    label: {
                        Image(systemName: self.item.isPinned ? "pin.circle.fill" : "pin.circle")
                        Text(self.item.isPinned ? "Un-Pin":"Pin")
                    }
                )
            }
        }
    }
}

struct PreviewButton: View {
    @Binding var showPreview: Bool
    var item: Item
    var body: some View {
        VStack {
            HStack{
                Button{
                    showPreview = true
                }label: {
                    Text("Preview")
                }
            }
        }
    }
}



struct ContextMenuButton: View {
    var absolutePath: Optional<String>
    var actionCallback : (Item, [NSPasteboard.PasteboardType: Data]) -> ()
    var item: Item
    @State var checked_item_paste = false // test state of each possible checkbox, need to keep this state somewhere else probably
    var body: some View {
        VStack {
            HStack{
                if self.absolutePath != nil{
                    Button(action: {
                        actionCallback(self.item, getDataOverride())
                        print("coppied")
                    }, label: {
                        Image(systemName: "link")
                        Text(self.getLabelByPasteboardType()).font(.subheadline)
                    })
                }
            }
        }
    }
    
    func getDataOverride() -> [NSPasteboard.PasteboardType: Data] {
        let path_data: Data = (
            String(decoding: self.item.data[NSPasteboard.PasteboardType.fileURL]!! , as: UTF8.self )
                .replacingOccurrences(of: "file://", with: "")
                .removingPercentEncoding!.data(using: .utf8))!
        return [NSPasteboard.PasteboardType.string: path_data]
    }
    
    func getLabelByPasteboardType() -> String{
        if self.absolutePath != nil{
            return String("Absolute Path")
        }
        return String()
    }
}


class ThumbnailViewModel: ObservableObject {
    @Published var thumbnail: NSImage? = nil
    
    func setURL(_ url: URL) {
        generateThumbnailRepresentations(url: url)
    }
    
    private func generateThumbnailRepresentations(url:URL) {
        let size: CGSize = CGSize(width: 100, height: 130)
        let scale: CGFloat = NSScreen.main?.backingScaleFactor ?? 1.0
        
        let request = QLThumbnailGenerator.Request(fileAt: url,
                                                   size: size,
                                                   scale: scale,
                                                   representationTypes: .all)
        
        let generator = QLThumbnailGenerator.shared
        generator.generateRepresentations(for: request) { (thumbnail, type, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error generating thumbnail: \(error.localizedDescription)")
                } else if let thumbnail = thumbnail {
                    self.thumbnail = thumbnail.nsImage
                }
            }
        }
    }
}

struct ThumbnailView: View {
    @StateObject private var viewModel = ThumbnailViewModel()
    private let url: URL
    private let scale: CGFloat = NSScreen.main?.backingScaleFactor ?? 1.0

    init(url: URL) {
        self.url = url
    }
    
    var body: some View {
        VStack {
            if let thumbnail = viewModel.thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 130)
            } else {
                Text("No thumbnail available")
            }
        }
        .onAppear {
                    viewModel.setURL(url)
        }
    }
}

struct PopoverView: View {
    @Binding var item: Item
    @Binding var popoverShowing: Bool
    let imageExt = ["gif", "png", "jpg", "HEIC"]
    @State private var isEditing = false
    @State
        var url: URL?
    @State private var snapshotImage: NSImage?

    
    var body: some View{
        HStack{
            ZStack{
                ScrollView{
                    LabeledContent{
                        TextField("Name", text: $item.alias)
                            .onSubmit {
                                item.alias = item.alias
                                self.isEditing.toggle()
                            }
                    } label: {
                        Text("Rename")
                    }
                    
                    Divider()
                    if item.data[NSPasteboard.PasteboardType.fileURL] != nil {
                        // Convert Data to String
                        let urlstr = String(data: item.data[NSPasteboard.PasteboardType.fileURL]!!, encoding: .utf8)
                        if let url = URL(string: urlstr!){
                            ThumbnailView(url: url)
                        }
                    }
                    else if item.data[NSPasteboard.PasteboardType.URL] != nil {
                        let urlstr = String(data: item.data[NSPasteboard.PasteboardType.URL]!!, encoding: .utf8)
                        if let url = URL(string: urlstr!){
                            Link("Open URL", destination: url)
                                        .padding()
                                        .foregroundColor(.blue)
                                        .underline() // Add underline to the link
                        }
                    }

                    
                    else if item.data[NSPasteboard.PasteboardType.string] != nil
                    {
                        Text(
                            String(decoding: item.data[NSPasteboard.PasteboardType.string]!!,
                                   as: UTF8.self))
                        .textSelection(.enabled)
                    }
                    else
                    {
                        Text(String())
                        
                    }
                }
                .padding(10)
                .fixedSize(horizontal: true, vertical: true)
            }
        }
    }
}

struct CardLabelView: View {
    var actionCallback : (Item, [NSPasteboard.PasteboardType: Data]) -> ()
    var deleteCallback : (Item) -> ()
    var pinItemCallback : (Item) -> ()
    @Binding var item: Item
    
    var body: some View {
        HStack{
            item.isPinned ? 
            Image(systemName: "pin.circle.fill")
                .resizable()
                .frame(width: 30, height: 30)
                .padding(.leading, 10) // Optional: Adds some padding on the left side
            : nil
            
            item.getTypeImage()
                .resizable()
                .frame(width: 30, height: 30)
                .padding(.leading, 10) // Optional: Adds some padding on the left side
            
            
            Text(item.alias)
                .padding(.leading, 10) // Adjust the padding value to set the fixed distance from the image
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
        .foregroundColor(.primary)
        .padding(.vertical, 4)
        .background(Color.clear)
        .cornerRadius(8)
    }
    
}



struct CardView: View {
    var actionCallback : (Item, [NSPasteboard.PasteboardType: Data]) -> ()
    var deleteCallback : (Item) -> ()
    var pinItemCallback : (Item) -> ()
    @State var item: Item
    @State var hovered = false
    @State var isPressed : Bool = false
    @State var showPopover : Bool = false
    
    
    var body: some View {
        HStack{
            Button{
                actionCallback(item, [:])
            }label: {
                CardLabelView(actionCallback: actionCallback,
                              deleteCallback: deleteCallback,
                              pinItemCallback: pinItemCallback,
                              item: $item)
            }
        }
        // MARK: This needs to live on the parent of the button, because if it is attached to the button itself
        // spacebar clicks will be captured by the button itself, super annoying.
        .popover(
                isPresented: $showPopover,
                arrowEdge: .leading,
                content: {
                    PopoverView(item: $item, popoverShowing: $showPopover)
                }
            )

        .buttonStyle(
            ItemCardStyle(item: $item, isPressed: $isPressed, showPopover: $showPopover,
                         actionCallback: actionCallback, deleteCallback: deleteCallback, pinItemCallback: pinItemCallback)
        )
    }
}
