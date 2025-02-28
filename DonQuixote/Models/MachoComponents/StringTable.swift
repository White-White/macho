//
//  StringTable.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/10.
//

import Foundation

class StringTable: StringSection, @unchecked Sendable {
    
    init(stringTableOffset: Int, sizeOfStringTable: Int, machoData: Data) {
        let stringTableData = machoData.subSequence(from: stringTableOffset, count: sizeOfStringTable)
        super.init(encoding: .utf8, data: stringTableData, title: "String Table", subTitle: nil)
    }
    
}
