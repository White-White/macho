//
//  MachoHeader.swift
//  DonQuixote
//
//  Created by white on 2023/9/8.
//

import Foundation

enum MachoType {
    case object
    case execute
    case dylib
    case unknown(UInt32)
    
    init(with value: UInt32) {
        switch value {
        case 0x1:
            self = .object
        case 0x2:
            self = .execute
        case 0x6:
            self = .dylib
        default:
            self = .unknown(value)
        }
    }
    
    var readable: String {
        switch self {
        case .object:
            return "Relocatable object file (MH_OBJECT)" // : Relocatable object file
        case .execute:
            return "Demand paged executable file (MH_EXECUTE)" // : Demand paged executable file
        case .dylib:
            return "Dynamically bound shared library (MH_DYLIB)" // : Dynamically bound shared library
        case .unknown(let value):
            return "unknown macho file: (\(value)"
        }
    }
}

class MachoHeader: GroupTranslatedMachoSlice {
    
    let magicData: Data
    let is64Bit: Bool
    let cpuType: CPUType
    let cpuSubtype: CPUSubtype
    let machoType: MachoType
    let numberOfLoadCommands: UInt32
    let sizeOfAllLoadCommand: UInt32
    let flags: UInt32
    let reserved: UInt32?
    
    lazy var translationGroup: TranslationGroup = {
        let translationGroup = TranslationGroup(dataStartIndex: self.offsetInMacho)
        translationGroup.addTranslation(definition: "Magic", humanReadable: String.init(format: "%0X%0X%0X%0X", magicData[0], magicData[1], magicData[2], magicData[3]), translationType: .rawData(4))
        translationGroup.addTranslation(definition: "CPU Type", humanReadable: self.cpuType.name, translationType: .numberEnum32Bit)
        translationGroup.addTranslation(definition: "CPU Sub Type", humanReadable: self.cpuSubtype.name, translationType: .numberEnum32Bit)
        translationGroup.addTranslation(definition: "Macho Type", humanReadable: self.machoType.readable, translationType: .numberEnum32Bit)
        translationGroup.addTranslation(definition: "Number of load commands", humanReadable: "\(self.numberOfLoadCommands)", translationType: .uint32)
        translationGroup.addTranslation(definition: "Size of all load commands", humanReadable: self.sizeOfAllLoadCommand.hex, translationType: .uint32)
        translationGroup.addTranslation(definition: "Flags", humanReadable: MachoHeader.flagsDescriptionFrom(self.flags), translationType: .flags(4))
        if let reserved = self.reserved { translationGroup.addTranslation(definition: "Reverved", humanReadable: reserved.hex, translationType: .uint32) }
        return translationGroup
    }()
    
    init(from machoData: Data, is64Bit: Bool) {
        self.is64Bit = is64Bit
        let headerData = machoData.subSequence(from: .zero, count: is64Bit ? 32 : 28)
        var dataShifter = DataShifter(headerData)
        self.magicData = dataShifter.shift(.doubleWords)
        self.cpuType = CPUType(dataShifter.shiftUInt32())
        self.cpuSubtype = CPUSubtype(dataShifter.shiftUInt32(), cpuType: self.cpuType)
        self.machoType = MachoType(with: dataShifter.shiftUInt32())
        self.numberOfLoadCommands = dataShifter.shiftUInt32()
        self.sizeOfAllLoadCommand = dataShifter.shiftUInt32()
        self.flags = dataShifter.shiftUInt32()
        self.reserved = is64Bit ? dataShifter.shiftUInt32() : nil
        super.init(headerData, title: "Mach Header", subTitle: nil)
    }
    
    override func translate(_ progressNotifier: @escaping (Float) -> Void) async -> [TranslationGroup] {
        return [self.translationGroup]
    }
    
    private static func flagsDescriptionFrom(_ flags: UInt32) -> String {
        // this line of shit I'll never understand.. after today...
        return [
            "MH_NOUNDEFS",
            "MH_INCRLINK",
            "MH_DYLDLINK",
            "MH_BINDATLOAD",
            "MH_PREBOUND",
            "MH_SPLIT_SEGS",
            "MH_LAZY_INIT",
            "MH_TWOLEVEL",
            "MH_FORCE_FLAT",
            "MH_NOMULTIDEFS",
            "MH_NOFIXPREBINDING",
            "MH_PREBINDABLE",
            "MH_ALLMODSBOUND",
            "MH_SUBSECTIONS_VIA_SYMBOLS",
            "MH_CANONICAL",
            "MH_WEAK_DEFINES",
            "MH_BINDS_TO_WEAK",
            "MH_ALLOW_STACK_EXECUTION",
            "MH_ROOT_SAFE",
            "MH_SETUID_SAFE",
            "MH_NO_REEXPORTED_DYLIBS",
            "MH_PIE",
            "MH_DEAD_STRIPPABLE_DYLIB",
            "MH_HAS_TLV_DESCRIPTORS",
            "MH_NO_HEAP_EXECUTION",
        ].enumerated().filter { flags & (0x1 << $0.offset) != 0 }.map { $0.element }.joined(separator: "\n")
    }
}
