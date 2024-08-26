//
//  PresentationTests.swift
//  
//
//  Created by Igor Ferreira on 19/9/22.
//

import Foundation
import XCTest
@testable import GIFImage

fileprivate class Counter {
    var ticks: Int
    let triggerLimit: Int?
    let triggerAction: () -> Void
    
    init(triggerLimit: Int? = nil, triggerAction: @escaping () -> Void = {}) {
        self.triggerLimit = triggerLimit
        self.triggerAction = triggerAction
        self.ticks = 0
    }
    @Sendable func count(source: GIFSource) async { count() }
    @Sendable func count(image: RawImage) async { count() }
    
    private func count() {
        ticks += 1
        if let triggerLimit, ticks == triggerLimit {
            triggerAction()
        }
    }
}

class PresentationTests: XCTestCase {
    var gifPath: String {
        let bundle = Bundle.module
        let path = bundle.path(forResource: "test", ofType: "gif")!
        return path
    }
    var gifSource: GIFSource {
        .local(filePath: gifPath)
    }
    let testFPS = 1000
    
    func testNoAnimationAndNoLoop() throws {
        let expectation = expectation(description: "Process holder")
        let frameCounter = Counter()
        
        let presenter = PresentationController(source: gifSource, frameRate: .static(fps: testFPS)) { _ in
            expectation.fulfill()
        }
        Task { await presenter.start(store: .init(animate: false, loop: false), imageLoader: ImageLoader(), fallbackImage: RawImage(), frameUpdate: frameCounter.count(image:)) }
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(1, frameCounter.ticks, "Given it is not animated, the frame should be called only once")
    }
    
    func testNoAnimationAndLoop() throws {
        let expectation = expectation(description: "Process holder")

        let frameCounter = Counter()
        
        let presenter = PresentationController(source: gifSource, frameRate: .static(fps: testFPS)) { _ in
            expectation.fulfill()
        }
        let store = GIFImage.PresentationStore(animate: false, loop: true)
        Task { await presenter.start(store: store, imageLoader: ImageLoader(), fallbackImage: RawImage(), frameUpdate: frameCounter.count(image:)) }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            store.loop = false
        }

        wait(for: [expectation], timeout: 1.0)
        XCTAssertGreaterThan(frameCounter.ticks, 1, "Given it is not animated but loop, the frame should be called many times")
    }
    
    func testAnimationAndNoLoop() throws {
        let expectation = expectation(description: "Process holder")
        let frameCounter = Counter()
        
        let presenter = PresentationController(source: gifSource, frameRate: .static(fps: testFPS)) { _ in
            expectation.fulfill()
        }
        Task { await presenter.start(store: .init(animate: true, loop: false), imageLoader: ImageLoader(), fallbackImage: RawImage(), frameUpdate: frameCounter.count(image:)) }
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(19, frameCounter.ticks, "When animated, all 19 frames of the test GIF should be displayed once")
    }
    
    func testAnimationAndLoop() throws {
        let expectation = expectation(description: "Process holder")
        let loopCounter = Counter(triggerLimit: 2) { expectation.fulfill() }
        let frameCounter = Counter()
        
        let presenter = PresentationController(source: gifSource, frameRate: .static(fps: testFPS), action: loopCounter.count(source:))
        Task { await presenter.start(store: .init(animate: true, loop: true), imageLoader: ImageLoader(), fallbackImage: RawImage(), frameUpdate: frameCounter.count(image:)) }
        
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(38, frameCounter.ticks, "When animated, all 38 frames of the test GIF should be displayed once")
    }
}
