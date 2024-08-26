//
//  GIFImage.swift
//
//
//  Created by Igor Ferreira on 06/04/2022.
//

import SwiftUI

/// `GIFImage` is a `View` that loads a `Data` object from a source into `CoreImage.CGImageSource`, parse the image source
/// into frames and stream them based in the "Delay" key packaged on which frame item. The view will use the `ImageLoader` from the environment
/// to convert the fetch the `Data`
public struct GIFImage: View {
    public let source: GIFSource
    public let placeholder: RawImage
    public let errorImage: RawImage?
    private let presentationController: PresentationController

    @Environment(\.imageLoader) var imageLoader
    @State @MainActor private var store: PresentationStore
    @State @MainActor private var frame: RawImage?
    @State private var presentationTask: Task<(), Never>?

    /// `GIFImage` is a `View` that loads a `Data` object from a source into `CoreImage.CGImageSource`, parse the image source
    /// into frames and stream them based in the "Delay" key packaged on which frame item.
    ///
    /// - Parameters:
    ///   - source: Source of the image. If the source is remote, the response is cached using `URLCache`
    ///   - animate: A flag to indicate that GIF should animate or not. If non-animated, the first frame will be displayed
    ///   - loop: Flag to indicate if the GIF should be played only once or continue to loop
    ///   - placeholder: Image to be used before the source is loaded
    ///   - errorImage: If the stream fails, this image is used
    ///   - frameRate: Option to control the frame rate of the animation or to use the GIF information about frame rate
    ///   - loopAction: Closure called whenever the GIF finishes rendering one cycle of the action
    public init(
        source: GIFSource,
        animate: Bool,
        loop: Bool,
        placeholder: RawImage = RawImage(),
        errorImage: RawImage? = nil,
        frameRate: FrameRate = .dynamic,
        loopAction: @Sendable @escaping (GIFSource) async throws -> Void = { _ in }
    ) {
        self.init(
            source: source,
            store: .init(animate: animate, loop: loop),
            placeholder: placeholder,
            errorImage: errorImage,
            frameRate: frameRate,
            loopAction: loopAction
        )
    }
    
    /// `GIFImage` is a `View` that loads a `Data` object from a source into `CoreImage.CGImageSource`, parse the image source
    /// into frames and stream them based in the "Delay" key packaged on which frame item.
    ///
    /// - Parameters:
    ///   - source: Source of the image. If the source is remote, the response is cached using `URLCache`
    ///   - loop: Flag to indicate if the GIF should be played only once or continue to loop
    ///   - placeholder: Image to be used before the source is loaded
    ///   - errorImage: If the stream fails, this image is used
    ///   - frameRate: Option to control the frame rate of the animation or to use the GIF information about frame rate
    ///   - loopAction: Closure called whenever the GIF finishes rendering one cycle of the action
    public init(
        source: GIFSource,
        store: PresentationStore = .init(animate: true, loop: true),
        animate: Binding<Bool> = Binding.constant(true),
        loop: Binding<Bool> = Binding.constant(true),
        placeholder: RawImage = RawImage(),
        errorImage: RawImage? = nil,
        frameRate: FrameRate = .dynamic,
        loopAction: @Sendable @escaping (GIFSource) async throws -> Void = { _ in }
    ) {
        self.source = source
        self._store = .init(wrappedValue: store)
        self.placeholder = placeholder
        self.errorImage = errorImage
        
        self.presentationController = PresentationController(
            source: source,
            frameRate: frameRate,
            action: loopAction
        )
    }

    public var body: some View {
        Image.loadImage(with: frame ?? placeholder)
            .resizable()
            .scaledToFit()
            .onChange(of: store.loop) { newValue in
                handle(loop: newValue)
            }
            .onChange(of: store.animate) { newValue in
                handle(animate: newValue)
            }
            .task(id: source, load)
    }

    private func handle(animate: Bool) {
        if animate {
            load()
        } else {
            presentationTask?.cancel()
        }
    }
    
    private func handle(loop: Bool) {
        if loop { load() }
    }
    
    @Sendable private func load() {
        presentationTask?.cancel()
        presentationTask = Task { await presentationController.start(
            store: store,
            imageLoader: imageLoader,
            fallbackImage: errorImage ?? placeholder,
            frameUpdate: setFrame(_:)
        )}
    }
    
    @MainActor
    @Sendable private func setFrame(_ frame: RawImage) async {
        self.frame = frame
    }
}

#if DEBUG
let placeholder = RawImage.create(symbol: "photo.circle.fill")!
let error = RawImage.create(symbol: "xmark.octagon")
let gifURL = "https://raw.githubusercontent.com/igorcferreira/GIFImage/main/Tests/test.gif"
#Preview("Raw URL") {
    GIFImage(url: gifURL, placeholder: placeholder, errorImage: error)
}
#Preview("Limited 5 FPS") {
    GIFImage(url: gifURL, placeholder: placeholder, errorImage: error, frameRate: .limited(fps: 5))
}
#Preview("Limited to 30 FPS") {
    GIFImage(url: gifURL, placeholder: placeholder, errorImage: error, frameRate: .static(fps: 30))
}
#endif

