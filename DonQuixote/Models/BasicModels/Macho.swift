//
//  Macho.swift
//  mocha
//
//  Created by white on 2021/6/16.
//

import Foundation

struct Macho: File {
    
    static let Magic32: [UInt8] = [0xce, 0xfa, 0xed, 0xfe]
    static let Magic64: [UInt8] = [0xcf, 0xfa, 0xed, 0xfe]
    
    let machoData: Data
    var fileSize: Int { machoData.count }
    
    let machoFileName: String
    let machoHeader: MachoHeader
    let is64Bit: Bool
    
    let allPortions: [MachoPortion]
    
    init(with location: FileLocation) throws {
        let fileHandle = try FileHandle(location)
        defer { try? fileHandle.close() }
        let machoData: Data = try fileHandle.assertReadToEnd()
        let machoFileName: String = location.fileName
        self.init(with: machoData, machoFileName: machoFileName)
    }
    
    init(with machoData: Data, machoFileName: String) {
        
        let is64Bit: Bool
        let magic = machoData[0..<4]
        if magic == Data(Macho.Magic64) {
            is64Bit = true
        } else if magic == Data(Macho.Magic32) {
            is64Bit = false
        } else {
            fatalError() /* what the hell is going on */
        }
        
        self.is64Bit = is64Bit
        let machoHeader = MachoHeader(from: machoData, is64Bit: is64Bit)
        
        self.machoData = machoData
        self.machoFileName = machoFileName
        self.machoHeader = machoHeader
        
        let tick = TickTock()
        
        var loadCommands: [LoadCommand] = []
        var lcSegmentCommands: [LCSegment] = []
        var lcLinkedITDataCommands: [LCLinkedITData] = []
        var lcDyldInfo: LCDyldInfo?
        
        var sections: [MachoPortion] = []
        var allCStrngSections: [CStringSection] = []
        var machoSectionHeaders: [SectionHeader] = []
        var relocationTables: [RelocationTable] = []
        
        var stringTable: StringTable?
        var symbolTable: SymbolTable?
        var indirectSymbolTable: IndirectSymbolTable?
        
        var linkedITSections: [MachoPortion] = []
        var dyldInfoSections: [MachoPortion] = []
        
        loadCommands = LoadCommand.loadCommands(from: machoData, machoHeader: machoHeader, onLCSegment: {lcSegment in
            lcSegmentCommands.append(lcSegment)
            machoSectionHeaders.append(contentsOf: lcSegment.sectionHeaders)
            if let relocationTable = lcSegment.relocationTable(machoData: machoData, machoHeader: machoHeader) {
                relocationTables.append(relocationTable)
            }
        }, onLCSymbolTable: { lcSymbolTable in
            let _stringTable = StringTable(stringTableOffset: Int(lcSymbolTable.stringTableOffset),
                                      sizeOfStringTable: Int(lcSymbolTable.sizeOfStringTable),
                                      machoData: machoData)
            stringTable = _stringTable
            
            symbolTable = SymbolTable(symbolTableOffset: Int(lcSymbolTable.symbolTableOffset),
                                      numberOfSymbolTableEntries: Int(lcSymbolTable.numberOfSymbolTableEntries),
                                      machoData: machoData,
                                      machoHeader: machoHeader, stringTable: _stringTable,
                                      machoSectionHeaders: machoSectionHeaders)
        }, onLCDynamicSymbolTable: { lcDynamicSymbolTable in
            indirectSymbolTable = lcDynamicSymbolTable.indirectSymbolTable(machoData: machoData, machoHeader: machoHeader, symbolTable: symbolTable)
        }, onLCLinkedITData: {
            lcLinkedITDataCommands.append($0)
        }, onLCDyldInfo: {
            guard lcDyldInfo == nil else { fatalError() }
            lcDyldInfo = $0
        })
        
        sections = machoSectionHeaders.map({ sectionHeader in
            Macho.createSection(allCStrngSections: allCStrngSections,
                                indirectSymbolTable: indirectSymbolTable,
                                machoData: machoData,
                                machoHeader: machoHeader,
                                sectionHeader: sectionHeader)
        })
        
        allCStrngSections = sections.compactMap({ $0 as? CStringSection })

        linkedITSections = lcLinkedITDataCommands.map { lcLinkedITData in
            lcLinkedITData.linkedITSection(from: machoData,
                                           machoHeader: machoHeader,
                                           textSegmentLoadCommand: lcSegmentCommands.first { $0.segmentName == "__TEXT" },
                                           symbolTable: symbolTable)
        }
        
        if let lcDyldInfo {
            dyldInfoSections = lcDyldInfo.dyldInfoSections(machoData: machoData, machoHeader: machoHeader)
        }
        
        var allPortions: [MachoPortion] = [machoHeader]
        allPortions.append(contentsOf: loadCommands)
        allPortions.append(contentsOf: sections)
        allPortions.append(contentsOf: relocationTables)
        allPortions.append(contentsOf: linkedITSections)
        allPortions.append(contentsOf: dyldInfoSections)
        
        if let symbolTable { allPortions.append(symbolTable) }
        if let indirectSymbolTable { allPortions.append(indirectSymbolTable) }
        if let stringTable { allPortions.append(stringTable) }
        
        self.allPortions = allPortions
        
        tick.tock("Macho Init Completed")
    }
    
}

extension Macho {
    
    static func createSection(allCStrngSections: [CStringSection],
                              indirectSymbolTable: IndirectSymbolTable?,
                              machoData: Data,
                              machoHeader: MachoHeader,
                              sectionHeader: SectionHeader) -> MachoPortion {
        
        let is64Bit = machoHeader.is64Bit
        let title = sectionHeader.segment + "," + sectionHeader.section
        
        // recognize section by section type
        switch sectionHeader.sectionType {
        case .S_ZEROFILL, .S_THREAD_LOCAL_ZEROFILL, .S_GB_ZEROFILL:
            // ref: https://lists.llvm.org/pipermail/llvm-commits/Week-of-Mon-20151207/319108.html
            /* code snipet from llvm
             inline bool isZeroFillSection(SectionType T) {
             return (T == llvm::MachO::S_ZEROFILL ||
             T == llvm::MachO::S_THREAD_LOCAL_ZEROFILL);
             }
             */
            return ZeroFilledSection(runtimeSize: Int(sectionHeader.size), title: title)
            
        case .S_CSTRING_LITERALS:
            let data = machoData.subSequence(from: Int(sectionHeader.offset), count: Int(sectionHeader.size))
            return CStringSection(virtualAddress: sectionHeader.addr, data: data, title: title)
        case .S_LITERAL_POINTERS:
            let data = machoData.subSequence(from: Int(sectionHeader.offset), count: Int(sectionHeader.size))
            return LiteralPointerComponent(allCStringSections: allCStrngSections, data: data, is64Bit: is64Bit, title: title)
        case .S_LAZY_SYMBOL_POINTERS, .S_NON_LAZY_SYMBOL_POINTERS, .S_LAZY_DYLIB_SYMBOL_POINTERS:
            let data = machoData.subSequence(from: Int(sectionHeader.offset), count: Int(sectionHeader.size))
            return SymbolPointerComponent(indirectSymbolTable: indirectSymbolTable, sectionHeader: sectionHeader, data: data, is64Bit: is64Bit, title: title)
        default:
            break
        }
        
        // recognize section by section attributes
        if sectionHeader.sectionAttributes.hasAttribute(.S_ATTR_PURE_INSTRUCTIONS) {
            let data = machoData.subSequence(from: Int(sectionHeader.offset), count: Int(sectionHeader.size))
            return InstructionSection(data, title: title, cpuType: machoHeader.cpuType, virtualAddress: sectionHeader.addr)
        }
        
        // recognize section by section name
        let data = machoData.subSequence(from: Int(sectionHeader.offset), count: Int(sectionHeader.size), allowZeroLength: true)
        switch sectionHeader.segment {
        case "__TEXT":
            switch sectionHeader.section {
            case "__const":
                return TextConstSection(data, title: title, subTitle: nil)
            case "__ustring":
                return UStringSection(data: data, title: title, subTitle: nil)
            case "__swift5_reflstr":
                // https://knight.sc/reverse%20engineering/2019/07/17/swift-metadata.html
                // a great article on introducing swift metadata sections
                return CStringSection(virtualAddress: sectionHeader.addr, data: data, title: title)
            case "__swift5_protos":
                return SwiftMetadataSection<ProtocolDescriptor>(data, title: title, virtualAddress: sectionHeader.addr)
            case "__swift5_proto":
                return SwiftMetadataSection<ProtocolConformanceDescriptor>(data, title: title, virtualAddress: sectionHeader.addr)
            case "__swift5_types":
                fallthrough
            default:
                return UnknownSection(data, title: title, subTitle: nil)
            }
        default:
            return UnknownSection(data, title: title, subTitle: nil)
        }
    }
    
}
