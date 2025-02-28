//
//  LCSourceVersion.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/18.
//

import Foundation

class LCSourceVersion: LoadCommand, @unchecked Sendable {
    
    let version: String
    
    init(with type: LoadCommandType, data: Data) {
        self.version = LCSourceVersion.versionString(from: data.subSequence(from: 8, count: 8).UInt64)
        super.init(data, type: type)
    }
    
    override func addCommandTranslation(to translationGroup: TranslationGroup) {
        translationGroup.addTranslation(definition: "Source Version", humanReadable: self.version, translationType: .versionString64Bit)
    }
    
    static func versionString(from versionValue: UInt64) -> String {
        /* A.B.C.D.E packed as a24.b10.c10.d10.e10 */
        let mask: Swift.UInt64 = 0x3ff
        let e = versionValue & mask
        let d = (versionValue >> 10) & mask
        let c = (versionValue >> 20) & mask
        let b = (versionValue >> 30) & mask
        let a = versionValue >> 40
        return String(format: "%d.%d.%d.%d.%d", a, b, c, d, e)
    }
    
}
