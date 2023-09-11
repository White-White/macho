//
//  Relocations.swift
//  mocha (macOS)
//
//  Created by white on 2021/12/17.
//

import Foundation

//struct relocation_info {
//   int32_t    r_address;    /* offset in the section to what is being
//                   relocated */
//   uint32_t     r_symbolnum:24,    /* symbol index if r_extern == 1 or section
//                   ordinal if r_extern == 0 */
//        r_pcrel:1,     /* was relocated pc relative already */
//        r_length:2,    /* 0=byte, 1=word, 2=long, 3=quad */
//        r_extern:1,    /* does not include value of sym referenced */
//        r_type:4;    /* if not 0, machine specific relocation type */
//};

struct RelocationEntry {
    
    static let entrySize: Int = 8
    
    let dataStartIndex: Int
    let address: UInt32
    let symbolNum: UInt32
    let pcRelocated: Bool
    let length: UInt8
    let isExternal: Bool
    let type: UInt8
    let sectionName: String
    
    init(with data: Data, sectionName: String) {
        self.dataStartIndex = data.startIndex
        
        self.address = data.subSequence(from: .zero, count: Straddle.doubleWords.raw).UInt32
        self.symbolNum = (data.subSequence(from: 4, count: 3) + [UInt8(0)]).UInt32
        
        let lastByte = data.subSequence(from: 7, count: 1).UInt8
        
        let type = (lastByte & 0b11110000) >> 4
        self.type = type
        
        let isExternal = (lastByte & 0b00001000) != 0
        self.isExternal = isExternal
        
        let powerOfLength = (lastByte & 0b00000110) >> 1
        self.length = 0b00000001 << powerOfLength
        
        let pcRelocated = (lastByte & 0b00000001) != 0
        self.pcRelocated = pcRelocated
        
        self.sectionName = sectionName
    }
    
    var translationGroup: TranslationGroup {
        let translationGroup = TranslationGroup(dataStartIndex: self.dataStartIndex)
        translationGroup.addTranslation(definition: "Address", humanReadable: self.address.hex, translationType: .uint32)
        translationGroup.addTranslation(definition: "SymbolNum", humanReadable: self.symbolNum.hex, translationType: .rawData(3))
        translationGroup.addTranslation(definition: "extra", humanReadable: "pcRelocated: \(self.pcRelocated), length: \(self.length), isExternal: \(self.isExternal), type: \(self.type)", translationType: .flags(1))
        return translationGroup
    }
    
}
