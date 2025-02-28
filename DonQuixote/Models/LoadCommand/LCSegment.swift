//
//  Segment.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/1.
//

import Foundation

struct VMProtection {
    
    let raw: UInt32
    let readable: Bool
    let writable: Bool
    let executable: Bool
    
    init(raw: UInt32) {
        self.raw = raw
        self.readable = raw & 0x01 != 0
        self.writable = raw & 0x02 != 0
        self.executable = raw & 0x04 != 0
    }
    
    var humanReadable: String {
        if readable && writable && executable { return "VM_PROT_ALL" }
        if readable && writable { return "VM_PROT_DEFAULT" }
        var ret: [String] = []
        if readable { ret.append("VM_PROT_READ") }
        if writable { ret.append("VM_PROT_WRITE") }
        if executable { ret.append("VM_PROT_EXECUTE") }
        if ret.isEmpty { ret.append("VM_PROT_NONE") }
        return ret.joined(separator: ",")
    }
}

class LCSegment: LoadCommand, @unchecked Sendable {
    
    let is64Bit: Bool
    let segmentName: String
    let vmaddr: UInt64
    let vmsize: UInt64
    let segmentFileOff: UInt64
    let segmentSize: UInt64
    let maxprot: UInt32
    let initprot: UInt32
    let numberOfSections: UInt32
    let flags: UInt32
    let sectionHeaders: [SectionHeader]
    
    init(with type: LoadCommandType, data: Data) {
        let is64Bit = type == LoadCommandType.segment64
        self.is64Bit = is64Bit
        
        var dataShifter = DataShifter(data); dataShifter.skip(.quadWords)
        self.segmentName = dataShifter.shift(.rawNumber(16)).utf8String!.spaceRemoved /* Unlikely Error */
        self.vmaddr = is64Bit ? dataShifter.shiftUInt64() : UInt64(dataShifter.shiftUInt32())
        self.vmsize = is64Bit ? dataShifter.shiftUInt64() : UInt64(dataShifter.shiftUInt32())
        self.segmentFileOff = is64Bit ? dataShifter.shiftUInt64() : UInt64(dataShifter.shiftUInt32())
        self.segmentSize = is64Bit ? dataShifter.shiftUInt64() : UInt64(dataShifter.shiftUInt32())
        self.maxprot = dataShifter.shiftUInt32()
        self.initprot = dataShifter.shiftUInt32()
        self.numberOfSections = dataShifter.shiftUInt32()
        self.flags = dataShifter.shiftUInt32()
        
        var sectionHeaders: [SectionHeader] = []
        while dataShifter.shiftable {
            // section header data length for 32-bit is 68, and 64-bit 80
            sectionHeaders.append(SectionHeader(is64Bit: is64Bit, data: dataShifter.shift(.rawNumber(is64Bit ? 80 : 68))))
        }
        guard sectionHeaders.count == Int(self.numberOfSections) else { fatalError() }
        self.sectionHeaders = sectionHeaders
        super.init(data, type: type, title: type.name + " (\(segmentName))")
    }
    
    override func addCommandTranslation(to translationGroup: TranslationGroup) {
        translationGroup.addTranslation(definition: "Segment Name", humanReadable: self.segmentName, translationType: .utf8String(16))
        translationGroup.addTranslation(definition: "Virtual Memory Start Address", humanReadable: self.vmaddr.hex, translationType: self.is64Bit ? .uint64 : .uint32)
        translationGroup.addTranslation(definition: "Virtual Memory Size", humanReadable: self.vmsize.hex, translationType: self.is64Bit ? .uint64 : .uint32)
        translationGroup.addTranslation(definition: "File Offset", humanReadable: self.segmentFileOff.hex, translationType: self.is64Bit ? .uint64 : .uint32)
        translationGroup.addTranslation(definition: "Size to Map into Memory", humanReadable: self.segmentSize.hex, translationType: self.is64Bit ? .uint64 : .uint32)
        translationGroup.addTranslation(definition: "Maximum VM Protection", humanReadable: VMProtection(raw: self.maxprot).humanReadable, translationType: .flags(4))
        translationGroup.addTranslation(definition: "Initial VM Protection", humanReadable: VMProtection(raw: self.initprot).humanReadable, translationType: .flags(4))
        translationGroup.addTranslation(definition: "Number of Sections", humanReadable: "\(self.numberOfSections)", translationType: .uint32)
        translationGroup.addTranslation(definition: "Flags", humanReadable: LCSegment.flags(for: self.flags), translationType: .flags(4))
    }
    
    override func translate(initializeResult: AsyncInitializeResult) async -> AsyncTranslationResult {
        let loadCommandTranslationGroups = (await super.translate(initializeResult: initializeResult)) as! TranslationGroups
        let sectionHeaderTranslationGroups = (self.sectionHeaders.map { $0.translationGroup })
        return TranslationGroups(loadCommandTranslationGroups.translationGroups + sectionHeaderTranslationGroups)
    }
    
    func relocationTable(machoData: Data, machoHeader: MachoHeader) -> RelocationTable? {
        var startOffsetInMacho: Int?
        var numberOfAllEntries: Int = 0
        
        var relocationInfos: [RelocationInfo] = []
        self.sectionHeaders.forEach {
            let fileOffsetOfRelocationEntries = Int($0.fileOffsetOfRelocationEntries)
            let numberOfRelocatioEntries = Int($0.numberOfRelocatioEntries)
            if fileOffsetOfRelocationEntries == 0 || numberOfRelocatioEntries == 0 { return }
            if let startOffsetInMacho = startOffsetInMacho {
                guard startOffsetInMacho + (numberOfAllEntries * RelocationEntry.entrySize) == fileOffsetOfRelocationEntries else { fatalError() }
            } else {
                startOffsetInMacho = fileOffsetOfRelocationEntries
            }
            numberOfAllEntries += numberOfRelocatioEntries
            relocationInfos.append(RelocationInfo(numberOfEntries: numberOfRelocatioEntries, sectionName: $0.section))
        }
        guard let startOffsetInMacho = startOffsetInMacho, !relocationInfos.isEmpty else { return nil }
        
        let relocationData = machoData.subSequence(from: startOffsetInMacho, count: RelocationEntry.entrySize * numberOfAllEntries)
        return RelocationTable(data: relocationData, relocationInfos: relocationInfos)
    }
    
    static func flags(for flags: UInt32) -> String {
        
//        /* Constants for the flags field of the segment_command */
//        #define    SG_HIGHVM    0x1    /* the file contents for this segment is for
//                           the high part of the VM space, the low part
//                           is zero filled (for stacks in core files) */
//        #define    SG_FVMLIB    0x2    /* this segment is the VM that is allocated by
//                           a fixed VM library, for overlap checking in
//                           the link editor */
//        #define    SG_NORELOC    0x4    /* this segment has nothing that was relocated
//                           in it and nothing relocated to it, that is
//                           it maybe safely replaced without relocation*/
//        #define SG_PROTECTED_VERSION_1    0x8 /* This segment is protected.  If the
//                               segment starts at file offset 0, the
//                               first page of the segment is not
//                               protected.  All other pages of the
//                               segment are protected. */
//        #define SG_READ_ONLY    0x10 /* This segment is made read-only after fixups */
        
        var ret: [String] = []
        if (flags & 0x1 != 0) { ret.append("SG_HIGHVM") }
        if (flags & 0x2 != 0) { ret.append("SG_FVMLIB") }
        if (flags & 0x4 != 0) { ret.append("SG_NORELOC") }
        if (flags & 0x8 != 0) { ret.append("SG_PROTECTED_VERSION_1") }
        if (flags & 0x10 != 0) { ret.append("SG_READ_ONLY") }
        return ret.joined(separator: "\n")
    }
}
