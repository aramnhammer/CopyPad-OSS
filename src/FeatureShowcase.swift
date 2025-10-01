//
// FeatureShowcase.swift
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
    (title: "Previews", gifName: "previewMedia",
    description: "Double click an item to see its preview."),
    (title: "Keyboard Shortcuts", gifName: "keyboardShortcuts",
     description: "In the Settings menu ('⚙️' button at the bottom) select 'Keyboard Shortcut' to configure a keyboard shortcut which will trigger the floating window to appear"),
    (title: "Rename an Alias", gifName: "renameAlias", description: "In CopyPad, every coppied item can have an 'alias', to better identify it, from the preview menu you can change this alias to be anything without actually changing the value you previously coppied.")
]

struct NavViewButtonStyle: ButtonStyle {
    @Binding var isSelected: Bool
    @State private var hovered = false
    func makeBody(configuration: Configuration) -> some View {
            HStack {
                configuration.label
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .cornerRadius(10)
            .background(configuration.isPressed ? Color.blue : (isSelected ? Color.blue : (hovered ? Color(.systemBlue) : Color.clear)))
            .onHover { isHovered in
                            self.hovered = isHovered}
        
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 2) // Outline color and width
                        )
        
                        .clipShape(RoundedRectangle(cornerRadius: 8))

        }}



struct FeatureTutorialsView: View {
    @State private var selectedIndex: Int = 0
    @State var currentFeature: (title: String, gifName: String, description: String) = gifs[0]
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    var body: some View {
        HStack {
            // Titles column
            VStack(alignment: .leading) 
            {
                NavigationSplitView(columnVisibility: $columnVisibility)
                {
                    List(0..<gifs.count, id: \.self)
                    {
                        index in
                        Button(action:{
                            currentFeature = gifs[index]
                            selectedIndex = index
                        }) {
                            HStack{
                                Spacer()
                                Text(gifs[index].title)
                                    .textFieldStyle(.roundedBorder)
                                Spacer()
                            }
                            
                        }
                        .buttonStyle(
                            NavViewButtonStyle(isSelected: .constant(selectedIndex == index))
                        )
                    }
                    .listStyle(.sidebar)
                }detail: {
                    
                                    FeatureView(title: $currentFeature.title, description: $currentFeature.description,
                                                gifName: $currentFeature.gifName)
                }
//                .navigationTitle("Feature Showcase")
                }
            }
        }
    }


struct FeatureView: View {
    
    @Binding var title: String
    @Binding var description: String
    @Binding var gifName: String
    
    var body: some View {
            VStack(alignment: .center, spacing: 16){
                Text(title).font(.largeTitle).fontWeight(.bold)
                Text(description).font(.body)
                    .padding() // Add padding around the body text
                    .background(Color.gray.opacity(0.1))
                GIFImageView(gifName: $gifName)
        }
            .padding(.horizontal) // Add padding to all content from the left and right edges of the window
                    .padding(.vertical, 20) // Add some vertical padding
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading) // Align content to top left
    }
}

struct GIFImageView: NSViewRepresentable {
    
    @Binding var gifName: String
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        let asset = NSDataAsset(name: gifName)
        let imageView = NSImageView()
        
        let image = NSImage(data: asset!.data)
        
        imageView.image = image
        imageView.animates = true
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.translatesAutoresizingMaskIntoConstraints = false
        //image?.resizingMode = .stretch
        
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
        FeatureTutorialsView()
    }
}
