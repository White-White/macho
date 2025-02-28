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

struct InstructionTranslation: Identifiable {
    
    var id: Range<UInt64> { metaInfo.id }
    let metaInfo: TranslationMetaInfo
    let instruction: String
    
    init(dataIndexInMacho: Int, instructionSize: UInt16, instruction: String) {
        self.metaInfo = TranslationMetaInfo(dataIndexInMacho: dataIndexInMacho, type: .code(Int(instructionSize)), humanReadable: instruction)
        self.instruction = instruction
    }
    
}

final class InstructionBank: @unchecked Sendable, SearchableTranslationContainer {
    
    let numberOfInstructions: Int
    private let bank: CapStoneInstructionBank
    
    init(_ bank: CapStoneInstructionBank) {
        self.bank = bank
        self.numberOfInstructions = bank.numberOfInstructions()
    }
    
    func instructionTranslation(at index: Int) -> InstructionTranslation? {
        guard let capInstruction = bank.instruction(at: index) else { return nil }
        
        let instructionTranslation = InstructionTranslation(dataIndexInMacho: Int(capInstruction.startAddrInMacho),
                                                            instructionSize: capInstruction.size,
                                                            instruction: capInstruction.mnemonic + capInstruction.operand)
        
        return instructionTranslation
    }
    
    func searchIndexForInstruction(with targetDataIndex: UInt64) -> Int {
        bank.searchIndexForInstruction(with: targetDataIndex)
    }
    
    func searchForTranslationMetaInfo(at dataIndexInMacho: UInt64) async -> TranslationSearchResult? {
        let searchedIndex = self.searchIndexForInstruction(with: dataIndexInMacho)
        guard let instruction = self.instructionTranslation(at: searchedIndex) else { return nil }
        
        return TranslationSearchResult(translationMetaInfo: instruction.metaInfo)
    }
    
    func firstTranslationMetaInfo() -> TranslationSearchResult? {
        if let instructionTranslation = self.instructionTranslation(at: 0) {
            return TranslationSearchResult(translationMetaInfo: instructionTranslation.metaInfo)
        }
        return nil
    }
    
}


class InstructionSection: MachoPortion, @unchecked Sendable {

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
    
    override func initialize() async -> AsyncInitializeResult {
        return Void()
    }
    
    override func translate(initializeResult: AsyncInitializeResult) async -> AsyncTranslationResult {
        let bank = CapStoneHelper.capStoneInstructionBank(from: self.data, arch: self.capStoneArchType, codeStartAddress: virtualAddress) { progress in
            //TODO: progress
//            progressNotifier(progress)
        }
        if let _ = bank.error {
            //TODO: handle error
        }
        
        bank.codeStartAddr = self.virtualAddress
        bank.instructionSectionOffsetInMacho = UInt64(self.offsetInMacho)
        
        return InstructionBank(bank)
    }
    
}
