//
//  LCDyldInfo.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/9.
//

import Foundation

class LCDyldInfo: LoadCommand {
    
    let rebaseOffset: UInt32
    let rebaseSize: UInt32
    
    let bindOffset: UInt32
    let bindSize: UInt32
    
    let weakBindOffset: UInt32
    let weakBindSize: UInt32
    
    let lazyBindOffset: UInt32
    let lazyBindSize: UInt32
    
    let exportOffset: UInt32
    let exportSize: UInt32
    
    init(with type: LoadCommandType, data: Data) {
        var dataShifter = DataShifter(data); dataShifter.skip(.quadWords)
        self.rebaseOffset = dataShifter.shiftUInt32()
        self.rebaseSize = dataShifter.shiftUInt32()
        self.bindOffset = dataShifter.shiftUInt32()
        self.bindSize = dataShifter.shiftUInt32()
        self.weakBindOffset = dataShifter.shiftUInt32()
        self.weakBindSize = dataShifter.shiftUInt32()
        self.lazyBindOffset = dataShifter.shiftUInt32()
        self.lazyBindSize = dataShifter.shiftUInt32()
        self.exportOffset = dataShifter.shiftUInt32()
        self.exportSize = dataShifter.shiftUInt32()
        super.init(data, type: type)
    }
    
    override func addCommandTranslation(to translationGroup: TranslationGroup) {
        translationGroup.addTranslation(definition: "Rebase Info File Offset", humanReadable: rebaseOffset.hex, translationType: .uint32)
        translationGroup.addTranslation(definition: "Rebase Info Size", humanReadable: rebaseSize.hex, translationType: .uint32)
        translationGroup.addTranslation(definition: "Binding Info File Offset", humanReadable: bindOffset.hex, translationType: .uint32)
        translationGroup.addTranslation(definition: "Binding Info Size", humanReadable: bindSize.hex, translationType: .uint32)
        translationGroup.addTranslation(definition: "Weak Binding Info File Offset", humanReadable: weakBindOffset.hex, translationType: .uint32)
        translationGroup.addTranslation(definition: "Weak Binding Info Size", humanReadable: weakBindSize.hex, translationType: .uint32)
        translationGroup.addTranslation(definition: "Lazy Binding Info File Offset", humanReadable: lazyBindOffset.hex, translationType: .uint32)
        translationGroup.addTranslation(definition: "Lazy Binding Info Size", humanReadable: lazyBindSize.hex, translationType: .uint32)
        translationGroup.addTranslation(definition: "Export Info File Offset", humanReadable: exportOffset.hex, translationType: .uint32)
        translationGroup.addTranslation(definition: "Export Info Size", humanReadable: exportSize.hex, translationType: .uint32)
    }
    
    func dyldInfoSections(machoData: Data, machoHeader: MachoHeader) -> [MachoSlice] {
        let is64Bit = machoHeader.is64Bit
        var components: [MachoSlice] = []
        let rebaseInfoStart = Int(self.rebaseOffset)
        let rebaseInfoSize = Int(self.rebaseSize)
        if rebaseInfoStart.isNotZero && rebaseInfoSize.isNotZero {
            let rebaseInfoData = machoData.subSequence(from: rebaseInfoStart, count: rebaseInfoSize)
            let rebaseInfoComponent = OperationCodeSection<RebaseOperationCodeMetadata>(rebaseInfoData, title: "Rebase Opcode", subTitle: nil)
            components.append(rebaseInfoComponent)
        }
        
        
        let bindInfoStart = Int(self.bindOffset)
        let bindInfoSize = Int(self.bindSize)
        if bindInfoStart.isNotZero && bindInfoSize.isNotZero {
            let bindInfoData = machoData.subSequence(from: bindInfoStart, count: bindInfoSize)
            let bindingInfoComponent = OperationCodeSection<BindOperationCodeMetadata>(bindInfoData, title: "Binding Opcode", subTitle: nil)
            components.append(bindingInfoComponent)
        }
        
        let weakBindInfoStart = Int(self.weakBindOffset)
        let weakBindSize = Int(self.weakBindSize)
        if weakBindInfoStart.isNotZero && weakBindSize.isNotZero {
            let weakBindData = machoData.subSequence(from: weakBindInfoStart, count: weakBindSize)
            let weakBindingInfoComponent = OperationCodeSection<BindOperationCodeMetadata>(weakBindData, title: "Weak Binding Opcode", subTitle: nil)
            components.append(weakBindingInfoComponent)
        }
        
        let lazyBindInfoStart = Int(self.lazyBindOffset)
        let lazyBindSize = Int(self.lazyBindSize)
        if lazyBindInfoStart.isNotZero && lazyBindSize.isNotZero {
            let lazyBindData = machoData.subSequence(from: lazyBindInfoStart, count: lazyBindSize)
            let lazyBindingInfoComponent = OperationCodeSection<BindOperationCodeMetadata>(lazyBindData, title: "Lazy Binding Opcode", subTitle: nil)
            components.append(lazyBindingInfoComponent)
        }
        
        let exportInfoStart = Int(self.exportOffset)
        let exportInfoSize = Int(self.exportSize)
        if exportInfoStart.isNotZero && exportInfoSize.isNotZero {
            let exportInfoData = machoData.subSequence(from: exportInfoStart, count: exportInfoSize)
            let exportInfoComponent = ExportInfoSection(exportInfoData, title: "Export Info", is64Bit: is64Bit)
            components.append(exportInfoComponent)
        }
        
        return components
    }
}
