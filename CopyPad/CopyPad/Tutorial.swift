//
//  Tutorial.swift
//  CopyPad
//
//  Created by aram on 8/27/24.
//

import Foundation
import SwiftUI
import AVKit

import SwiftUI
import AppKit


let gifs: [(title: String, gifName: String, description: String)] = [
    (title: "Pin an Item", gifName: "pinToTop", description: "Right click an item and select 'pin' to pin it to the top of the list."),
    (title: "Previews", gifName: "previewMediaThumbnails",
    description: "Double click an item to see its preview."),
    (title: "Configure Keyboard Shortcuts", gifName: "keyboardShortcuts",
     description: "In the Settings menue ('gear' button at the bottom, select 'Keyboard Shortcut' to configure a keyboard shortcut which will trigger the floating window to appear"),
    (title: "Rename an Alias", gifName: "renameAnItem", description: "In CopyPad, every coppied item can have an 'alias', to better identify it, from the preview menu you can change this alias to be anything without actually changing the value you previously coppied.")
]

struct NavViewButtonStyle: ButtonStyle {
    @State private var hovered = false

    func makeBody(configuration: Configuration) -> some View {
        VStack {
            configuration.label
                .foregroundColor(.primary)
                .padding(.horizontal, 2)
                .padding(.vertical, 2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .background(configuration.isPressed ? Color.gray.opacity(0.2) : Color.clear)
                .background(Color(hovered ? .systemBlue : .clear))
                .onHover { isHovered in
                    self.hovered = isHovered
                }
                .animation(.default, value: hovered)
                .clipShape(RoundedRectangle(cornerRadius:10))
                .font(.callout)
                .cornerRadius(1)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 2) // Outline color and width
                )
        }
    }
}


struct GIFSlideshowView: View {
    // List of GIF names and their titles
    
    @State var currentFeature: (title: String, gifName: String, description: String) = gifs[0]

    var body: some View {
        HStack {
            // Titles column
            VStack(alignment: .leading) {
                Text("CopyPad Features")
                NavigationStack{
                    List(0..<gifs.count, id: \.self){index in
                                                Button(gifs[index].title, action: {
                                                    currentFeature = gifs[index]
                        
                                                }).buttonStyle(
                                                    NavViewButtonStyle()
                                                )
                        
                    }.listStyle(SidebarListStyle())
                }
                Spacer()
            }
            .padding()

            // GIF Slideshow
            VStack {
                FeatureView(title: $currentFeature.title, description: $currentFeature.description,
                            gifName: $currentFeature.gifName)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct FeatureView: View {
    
    @Binding var title: String
    @Binding var description: String
    @Binding var gifName: String
    
    var body: some View {
        ZStack{
            Text(description).font(.subheadline)
        }
        HStack{
            GIFImageView(gifName: $gifName)
                        .frame(width: 300, height: 300)
                        .cornerRadius(12)
                        .shadow(radius: 8)
        }
    }
}

struct GIFImageView: NSViewRepresentable {
    
    @Binding var gifName: String
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
//        let gifURL = Bundle.main.url(forResource: gifName, withExtension: "")!
        let asset = NSDataAsset(name: gifName)
               //return UIImage.gif(data: asset.data)
        let imageView = NSImageView()
        
        //let gifData = Data(contentsOf: asset.data)
        let image = NSImage(data: asset!.data)
        
        imageView.image = image
        imageView.animates = true
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
            // Remove all subviews
            nsView.subviews.forEach { $0.removeFromSuperview() }
            
            // Add the new imageView with updated gifName
            let imageView = createImageView()
            nsView.addSubview(imageView)
            
            NSLayoutConstraint.activate([
                imageView.leadingAnchor.constraint(equalTo: nsView.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: nsView.trailingAnchor),
                imageView.topAnchor.constraint(equalTo: nsView.topAnchor),
                imageView.bottomAnchor.constraint(equalTo: nsView.bottomAnchor)
            ])
        }
        
    private func createImageView() -> NSImageView {
            let imageView = NSImageView()
            
            if let asset = NSDataAsset(name: gifName),
               let image = NSImage(data: asset.data) {
                imageView.image = image
                imageView.animates = true
                imageView.imageScaling = .scaleProportionallyUpOrDown
            }
            
            imageView.translatesAutoresizingMaskIntoConstraints = false
            return imageView
        }
}

struct GIFSlideshowView_Previews: PreviewProvider {
    static var previews: some View {
        GIFSlideshowView()
    }
}
