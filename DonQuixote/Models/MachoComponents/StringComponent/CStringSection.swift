//
//  CStringSection.swift
//  DonQuixote
//
//  Created by white on 2023/6/11.
//

import Foundation

class CStringSection: StringSection, @unchecked Sendable {
    
    private let baseVirtualAddress: UInt64
    
    init(virtualAddress: UInt64, data: Data, title: String, subTitle: String? = nil) {
        self.baseVirtualAddress = virtualAddress
        super.init(encoding: .utf8, data: data, title: title, subTitle: subTitle)
    }
    
    func findString(virtualAddress: Swift.UInt64) async throws -> String? {
        let virtualAddressBegin = self.baseVirtualAddress
        let virtualAddressEnd = virtualAddressBegin + UInt64(dataSize)
        if virtualAddress < virtualAddressBegin || virtualAddress >= virtualAddressEnd { return nil }
        let dataOffset = Int(virtualAddress - self.baseVirtualAddress)
        return try await super.findString(atDataOffset: dataOffset)
    }
    
}
