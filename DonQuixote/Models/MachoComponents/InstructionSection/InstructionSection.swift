//
//  InstructionSection.swift
//  mocha (macOS)
//
//  Created by white on 2022/2/7.
//

import Foundation
import SwiftUI

// ARMv8 (AArch64) Instruction Encoding
// http://kitoslab-eng.blogspot.com/2012/10/armv8-aarch64-instruction-encoding.html

final class InstructionBank: @unchecked Sendable {
    
    let numberOfInstructions: Int
    private let bank: CapStoneInstructionBank
    
    init(_ bank: CapStoneInstructionBank) {
        self.bank = bank
        self.numberOfInstructions = bank.numberOfInstructions()
    }
    
    func translation(at index: Int) -> Translation {
        let capInstruction = bank.instruction(at: index)
        let translation = Translation(dataRangeInMacho: capInstruction.startAddrInMacho..<(capInstruction.startAddrInMacho + UInt64(capInstruction.size)),
                    definition: nil,
                    humanReadable: capInstruction.mnemonic + capInstruction.operand,
                    translationType: .code(Int(capInstruction.size)))
        return translation
    }
    
    func searchIndexForInstruction(with targetDataIndex: UInt64) -> Int {
        bank.searchIndexForInstruction(with: targetDataIndex)
    }
    
}


class InstructionSection: MachoTranslatedSlice<InstructionBank> {

    let capStoneArchType: CapStoneArchType
    let virtualAddress: UInt64
    
    init(_ data: Data, title: String, cpuType: CPUType, virtualAddress: UInt64) {
        let capStoneArchType: CapStoneArchType
        switch cpuType {
        case .x86:
            capStoneArchType = .I386
        case .x86_64:
            capStoneArchType = .X8664
        case .arm:
            capStoneArchType = .ARM
        case .arm64:
            capStoneArchType = .ARM64
        case .arm64_32:
            fallthrough
        case .unknown(_):
            fatalError() /* unknown code */
        }
        self.capStoneArchType = capStoneArchType
        self.virtualAddress = virtualAddress
        super.init(data, title: title, subTitle: nil)
    }
    
    override func translate() async -> InstructionBank {
        let bank = CapStoneHelper.instructions(from: self.data, arch: self.capStoneArchType, codeStartAddress: virtualAddress) { progress in
            // TODO: update loading progress
        }
        if let _ = bank.error {
            //TODO: handle error
        }
        
        bank.codeStartAddr = self.virtualAddress
        bank.instructionSectionOffsetInMacho = UInt64(self.offsetInMacho)
        
        return InstructionBank(bank)
    }
    
    override func searchForTranslation(with targetDataIndex: UInt64) async -> TranslationSearchResult? {
        guard let instructionBank = await self.untilTranslated(source: "Translation search") else { return nil }
        let searchedIndex = instructionBank.searchIndexForInstruction(with: targetDataIndex)
        guard searchedIndex >= 0 else { return nil }

        return TranslationSearchResult(translationGroup: nil, translation: instructionBank.translation(at: searchedIndex))
    }
    
}
