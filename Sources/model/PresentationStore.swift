//
//  PresentationStore.swift
//  
//
//  Created by tdt on 2023/5/24.
//

import Foundation

extension GIFImage {
    // 避免由于多线程导致的Binding类型的animate在不同线程上数据不同带来的错误
    public final class PresentationStore: ObservableObject {
        @Published public var animate: Bool
        @Published public var loop: Bool

        public init(animate: Bool, loop: Bool) {
            self.animate = animate
            self.loop = loop
        }
    }

}
