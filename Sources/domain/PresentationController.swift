//
//  PresentationController.swift
//
//
//  Created by Igor Ferreira on 9/9/22.
//

import Foundation
import SwiftUI

private let kDefaultGIFFrameInterval: TimeInterval = 1.0 / 24.0

struct PresentationController {
    let source: GIFSource
    let frameRate: FrameRate
    let action: (GIFSource) async throws -> Void

    init(
        source: GIFSource,
        frameRate: FrameRate,
        action: @Sendable @escaping (GIFSource) async throws -> Void = { _ in }
    ) {
        self.source = source
        self.action = action
        self.frameRate = frameRate
    }

    func start(store: GIFImage.PresentationStore, imageLoader: ImageLoader, fallbackImage: RawImage, frameUpdate: (RawImage) async -> Void) async {
        do {
            repeat {
                for try await imageFrame in try await imageLoader.load(source: source) {
                    try await update(imageFrame, frameUpdate: frameUpdate)
                    if !store.animate {
                        break
                    }
                }
                if store.animate {
                    try await action(source)
                }
            } while store.loop // TDT: 相比原版去掉了 && store.animate, 将Action放在loop结束之后执行, 同时不断的进行update，避免Watcn上可能是残留导致的闪烁，同时保证action仅执行一次。
            if !store.animate {
                try await action(source)
            }
        } catch is CancellationError {

        } catch {
            await frameUpdate(fallbackImage)
        }
    }

    private func update(_ imageFrame: ImageFrame, frameUpdate: (RawImage) async -> Void) async throws {
        await frameUpdate(RawImage.create(with: imageFrame.image))
        let calculatedInterval = imageFrame.interval ?? kDefaultGIFFrameInterval
        let interval: Double
        switch frameRate {
        case .static(let fps):
            interval = (1.0 / Double(fps))
        case .limited(let fps):
            let intervalLimit = (1.0 / Double(fps))
            interval = max(calculatedInterval, intervalLimit)
        case .dynamic:
            interval = imageFrame.interval ?? kDefaultGIFFrameInterval
        }
        try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000.0))
    }
}
