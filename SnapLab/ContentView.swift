//
//  ContentView.swift
//  SnapLab
//
//  Created by Yashh Sapra on 08/03/26.
//
import CoreImage
import CoreImage.CIFilterBuiltins
import PhotosUI
import StoreKit
import SwiftUI


struct ContentView: View {
    @State private var processedImage: Image?
    @State private var filterIntensity = 0.5
    @State private var filterRadius = 0.5
    @State private var filterScale = 0.5
    @State private var selectedItem: PhotosPickerItem?
    @State private var currentFilter: CIFilter = CIFilter.photoEffectChrome()
    @State private var originalImage: Image?
    @State private var comparisonAmount = 1.0
    @State private var showingConfirmation = false
    @State private var showingSavedAlert = false
    @Environment(\.requestReview) var requestReview
    @AppStorage("filterCount") var filterCount = 0
    
    var hasControls: Bool {
        let keys = currentFilter.inputKeys
        return keys.contains(kCIInputIntensityKey) || keys.contains(kCIInputRadiusKey) || keys.contains(kCIInputScaleKey)
    }
    let context = CIContext()
    
    var body: some View {
        NavigationStack{
            VStack{
                if selectedItem != nil {
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Current Filter")
                            .font(.system(size: 17)).bold()
                            .foregroundStyle(.secondary)
                        
                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: "camera.filters")
                                
                                Text(currentFilter.name.replacingOccurrences(of: "CI", with: ""))
                                    .font(.system(size: 17)).bold()
                            }
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.green.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            Spacer()
                            
                            Button {
                                changeFilter()
                            } label: {
                                
                                HStack(spacing: 6) {
                                    Image(systemName: "wand.and.stars")
                                    
                                    Text("Filters")
                                        .font(.system(size: 17))
                                        .fontWeight(.semibold)
                                }
                                .padding(.horizontal, 18)
                                .padding(.vertical, 10)
                                .background(
                                    LinearGradient(
                                        colors: [.purple, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .shadow(color: .purple.opacity(0.6), radius: 6)
                            }
                        }
                    }
                    .padding()
                    .background(.gray.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.top, 40)
                    .onChange(of: selectedItem, loadImage)
                }
             

                Spacer()
                
                PhotosPicker(selection: $selectedItem){
                    if let processedImage, let originalImage {
                        ZStack {
                            originalImage
                                .resizable()
                                .scaledToFit()
                            processedImage
                                .resizable()
                                .scaledToFit()
                                .mask(
                                    GeometryReader{ geo in
                                        Rectangle()
                                            .frame(width: geo.size.width * comparisonAmount)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                )
                        }
                    } else {
                        ContentUnavailableView(
                            "No Image Selected",systemImage: "photo.badge.plus",
                            description: Text("Tap to import")
                        )
                    }
                }
                //.frame(width: 300, height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(radius: 20)
                .padding()
                .onChange(of: selectedItem, loadImage)
                
                if processedImage != nil {
                    VStack(alignment: .leading, spacing: 10){
                        Text("Before / After")
                            .font(.system(size: 20))
                            .foregroundStyle(.secondary)
                            .padding(.top,5)
                            .padding(.bottom,5)
                            .padding(.horizontal,10)
                            .background(.gray.opacity(0.3))
                            .clipShape(.capsule)

                        Slider(value: $comparisonAmount)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 15)
                }
                
                
                Spacer()
                
                if processedImage != nil && hasControls {
                    VStack {
                        
                        if currentFilter.inputKeys.contains(kCIInputIntensityKey) {
                            VStack{
                                HStack {
                                    Text("Intensity")
                                    Spacer()
                                    Text("\(Int(filterIntensity * 100))%")
                                }
                                
                                Slider(value: $filterIntensity)
                                    .onChange(of: filterIntensity, applyProcessing)
                                    .disabled(selectedItem == nil)
                            }
                        }
                        
                        if currentFilter.inputKeys.contains(kCIInputRadiusKey) {
                            VStack{
                                HStack {
                                    Text("Radius")
                                    Spacer()
                                    Text("\(Int(filterRadius * 100))%")
                                }
                                
                                Slider(value: $filterRadius)
                                    .onChange(of: filterRadius, applyProcessing)
                                    .disabled(selectedItem == nil)
                            }
                        }
                        
                        if currentFilter.inputKeys.contains(kCIInputScaleKey) {
                            VStack{
                                HStack {
                                    Text("Scale")
                                    Spacer()
                                    Text("\(Int(filterScale * 100))%")
                                }
                                
                                Slider(value: $filterScale)
                                    .onChange(of: filterScale, applyProcessing)
                                    .disabled(selectedItem == nil)
                            }
                        }
                        
                    }
                    .padding()
                    .background(.gray.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
             
            }
            //.background(.red)
            .padding(.horizontal)
            .padding(.bottom, 30)
            .navigationTitle("SnapLab")
            .confirmationDialog("Select a Filter", isPresented: $showingConfirmation) {
                Button("Crystallize"){ setFilter(CIFilter.crystallize())}
                Button("Edges") { setFilter(CIFilter.edges())}
                Button("Gaussian Blur") { setFilter(CIFilter.gaussianBlur())}
                Button("Pixellate") { setFilter(CIFilter.pixellate())}
                Button("Sepia Tone") { setFilter(CIFilter.sepiaTone())}
                Button("Unsharp Mask") { setFilter(CIFilter.unsharpMask())}
                Button("Vignette") { setFilter(CIFilter.vignette())}
                Button("Comic Effect") { setFilter(CIFilter.comicEffect())}
                Button("Overlay") { setFilter(CIFilter.lineOverlay())}
                Button("Bloom") { setFilter(CIFilter.bloom())}
                Button("Cancel", role: .cancel) {}
            }
            .toolbar {
                Menu {
                    Button {
                        saveImage()
                    } label: {
                        Label("Save Image", systemImage: "square.and.arrow.down")
                    }
                    
                    if let processedImage {
                        
                        ShareLink(
                            item: processedImage,
                            preview: SharePreview("SnapLab Image", image: processedImage)
                        ) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                    }
                    
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .disabled(processedImage == nil)
            }
            .alert("Saved!", isPresented: $showingSavedAlert){
                Button("Ok", role: .cancel) {}
            } message: {
                Text("Edited Image has been saved to your Photos Library")
            }
          
        }
     
        
    }
 
    
    func changeFilter() {
        showingConfirmation = true
        
    }
    
    func loadImage() { // Asynchronous Task
        Task{
            guard let imageData = try await selectedItem?.loadTransferable(type: Data.self) else { return }
            guard let uiImage = UIImage(data: imageData) else { return }
            originalImage = Image(uiImage: uiImage)
            let inputImage = CIImage(image: uiImage) // CIImage
            currentFilter.setValue(inputImage, forKey: kCIInputImageKey) // InputImage given to filter as CIImage
            applyProcessing()
        }
    }
    
    func applyProcessing() {
        let inputKeys = currentFilter.inputKeys
        
        if inputKeys.contains(kCIInputIntensityKey) {currentFilter.setValue(filterIntensity, forKey: kCIInputIntensityKey)}
        if inputKeys.contains(kCIInputRadiusKey) { currentFilter.setValue(filterRadius * 200, forKey: kCIInputRadiusKey)}
        if inputKeys.contains(kCIInputScaleKey) { currentFilter.setValue(filterScale * 10, forKey: kCIInputScaleKey)}
        
        guard let outputImage = currentFilter.outputImage else { return } // OutputImage of Filter as CIImage
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return }
        let uiImage = UIImage(cgImage: cgImage)
        processedImage = Image(uiImage: uiImage)
    }
    
    @MainActor func setFilter(_ filter: CIFilter) {
        currentFilter = filter
        if selectedItem != nil {
            loadImage()
        }
        
        filterIntensity = 0.5
        filterRadius = 0.5
        filterScale = 0.5
        
        filterCount += 1
        
        if filterCount == 2 {
            requestReview()
        }
    }
    
    func saveImage() {
        guard let outputImage = currentFilter.outputImage else { return }
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else { return }
        let uiImage = UIImage(cgImage: cgImage)
        UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
        showingSavedAlert = true
    }
    
}

#Preview {
    ContentView()
}


























