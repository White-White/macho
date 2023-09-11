//
//  TickTock.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/12.
//

import Foundation

class TickTock {
    
    private var enabled: Bool = true
    private var ts: Double = CACurrentMediaTime() * 1000
    
    static func tick() -> TickTock {
        return TickTock()
    }
    
    func tock(_ name: String, threshHold: Double? = nil) {
        let nextTs = CACurrentMediaTime() * 1000
        let timeGap = nextTs - ts; ts = nextTs
        guard enabled else { return }
        if let threshHold, timeGap <= threshHold { return }
        print("\n\(name)'s time usage:")
        print("--- \(timeGap) ms.")
    }
    
    func reset() {
        ts = CACurrentMediaTime() * 1000
    }
 
    func disable() -> TickTock {
        enabled = false
        return self
    }
    
    func enable() -> TickTock {
        enabled = true
        return self
    }
}
