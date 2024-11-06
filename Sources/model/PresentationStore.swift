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
        @Published public var animate: Bool // 直接停
        @Published public var loop: Bool // 等到结束停止。(目前: 跳出循环释放内存)

        public init(animate: Bool, loop: Bool) {
            self.animate = animate
            self.loop = loop
            print("\(Self.self) init")
        }

        deinit {
            print("\(Self.self) deinit")
        }

        public func invalidate() {
            loop = false
        }
    }

}
