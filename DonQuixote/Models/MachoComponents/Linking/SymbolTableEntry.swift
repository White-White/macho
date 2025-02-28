//
//  SymbolTable.swift
//  mocha (macOS)
//
//  Created by white on 2021/12/15.
//

import Foundation

enum StabType: UInt8 {
    case gsym = 0x20    /* global symbol */
    case fname = 0x22    /* F77 function name */
    case fun = 0x24    /* procedure name */
    case stsym = 0x26    /* data segment variable */
    case lcsym = 0x28    /* bss segment variable */
    case main = 0x2a    /* main function name */
    case pc = 0x30    /* global Pascal symbol */
    case rsym = 0x40    /* register variable */
    case sline = 0x44    /* text segment line number */
    case dsline = 0x46    /* data segment line number */
    case bsline = 0x48    /* bss segment line number */
    case ssym = 0x60    /* structure/union element */
    case sol = 0x64    /* main source file name */
    case lsym = 0x80    /* stack variable */
    case bincl = 0x82    /* include file beginning */
    case so = 0x84    /* included source file name */
    case psym = 0xa0    /* parameter variable */
    case eincl = 0xa2    /* include file end */
    case entry = 0xa4    /* alternate entry point */
    case lbrac = 0xc0    /* left bracket */
    case excl = 0xc2    /* deleted include file */
    case rbrac = 0xe0    /* right bracket */
    case bcomm = 0xe2    /* begin common */
    case ecomm = 0xe4    /* end common */
    case ecoml = 0xe8    /* end common (local name) */
    case leng = 0xfe    /* length of preceding entry */
    
    var readable: String {
        switch self {
        case .gsym:
            return "N_GSYM"
        case .fname:
            return "N_FNAME"
        case .fun:
            return "N_FUN"
        case .stsym:
            return "N_STSYM"
        case .lcsym:
            return "N_LCSYM"
        case .main:
            return "N_MAIN"
        case .pc:
            return "N_PC"
        case .rsym:
            return "N_RSYM"
        case .sline:
            return "N_SLINE"
        case .dsline:
            return "N_DSLINE"
        case .bsline:
            return "N_BSLINE"
        case .ssym:
            return "N_SSYM"
        case .so:
            return "N_SO"
        case .lsym:
            return "N_LSYM"
        case .bincl:
            return "N_BINCL"
        case .sol:
            return "N_SOL"
        case .psym:
            return "N_PSYM"
        case .eincl:
            return "N_EINCL"
        case .entry:
            return "N_ENTRY"
        case .lbrac:
            return "N_LBRAC"
        case .excl:
            return "N_EXCL"
        case .rbrac:
            return "N_RBRAC"
        case .bcomm:
            return "N_BCOMM"
        case .ecomm:
            return "N_ECOMM"
        case .ecoml:
            return "N_ECOML"
        case .leng:
            return "N_LENG"
        }
    }
}

enum SymbolType: Equatable {
    case stab(StabType?)
    case undefined
    case absolute
    case section
    case preBound
    case indirect
    
    var readable: String {
        switch self {
        case .stab(_):
            return "N_STAB" // FIXME: ignoring detailed stab type
        case .undefined:
            return "Undefined Symbol (N_UNDF)"
        case .absolute:
            return "Absolute Symbol (N_ABS)"
        case .section:
            return "Defined in "
        case .preBound:
            return "Prebound undefined (N_PBUD)"
        case .indirect:
            return "Indirect Symbol (N_INDR)"
        }
    }
    
    init(rawValue: UInt8) {
        if (rawValue & 0xe0) != 0 {
            let stabType = StabType(rawValue: rawValue)
            self = .stab(stabType)
        } else {
            let n_type_filed = rawValue & 0x0e /* 0x0e == N_TYPE mask == 00001110 */
            switch n_type_filed {
            case 0x0:
                self = .undefined // N_UNDF    0x0        /* undefined, n_sect == NO_SECT */
            case 0x2:
                self = .absolute // N_ABS    0x2        /* absolute, n_sect == NO_SECT */
            case 0xe:
                self = .section // N_SECT    0xe        /* defined in section number n_sect */
            case 0xc:
                self = .preBound // N_PBUD    0xc        /* prebound undefined (defined in a dylib) */
            case 0xa:
                self = .indirect // N_INDR    0xa        /* indirect */
            default:
                /* Unlikely. it must be a symbol */
                fatalError()
            }
        }
    }
}

struct SymbolTableEntry {
    
    static var modelSizeFor64Bit: Int { 16 }
    static var modelSizeFor32Bit: Int { 12 }
    
    let is64Bit: Bool
    let stringTable: StringTable
    let machoSectionHeaders: [SectionHeader]
    
    let indexInStringTable: UInt32
    let symbolType: SymbolType
    let symbolName: String
    
    /*
     ref: http://mirror.informatimago.com/next/developer.apple.com/documentation/DeveloperTools/Conceptual/MachORuntime/8rt_file_format/chapter_10_section_24.html
     N_PEXT (0x10). If this bit is on, this symbol is marked as having limited global scope. When the file is fed to the static linker, it clears the N_EXT bit for each symbol with the N_PEXT bit set. (The ld option -keep_private_externs disables this behavior.) With Mac OS X GCC, you can use the __private_extern__ function attribute to set this bit.
     
     ref: https://lists.llvm.org/pipermail/cfe-dev/2008-November/003249.html
     A private external symbol is a defined external symbol that is visible
     only to other modules within the same object file as the module that
     contains it. The standard static linker changes private external
     symbols into private defined symbols unless you specify otherwise
     (using the -keep_private_externs flag).
     You can mark a symbol as private external by using the
     __private_extern__ keyword (which works only in C) or the
     visibility("hidden")attribute (which works both in C and C++ with GCC
     4.0), as in this example:
     
     __private_extern__ int x = 0;                       // C only
     int y = 99 __attribute__((visibility("hidden")));   // C and C++, GCC
     4.0 only
     */
    let isPrivateExternalSymbol: Bool
    
    let isExternalSymbol: Bool
    
    let nSect: UInt8
    let nDesc: Swift.UInt16
    let nValue: UInt64
    
    let dataStartIndex: Int
    
    init(with data: Data, is64Bit: Bool, stringTable: StringTable, machoSectionHeaders: [SectionHeader]) async {
        self.dataStartIndex = data.startIndex
        
        self.is64Bit = is64Bit
        self.stringTable = stringTable
        self.machoSectionHeaders = machoSectionHeaders
        
        var dataShifter = DataShifter(data)
        
        self.indexInStringTable = dataShifter.shiftUInt32()
        
        /*
         * n_type
         * The n_type field really contains four fields:
         *    unsigned char N_STAB:3, if any of these bits set, a symbolic debugging entry
         *              N_PEXT:1,
         *              N_TYPE:3,
         *              N_EXT:1;
         * which are used via the following masks.
         */
        
        
        let nTypeValue = dataShifter.shiftUInt8()
        let symbolType = SymbolType(rawValue: nTypeValue)
        self.symbolType = symbolType
        
        let isPrivateExternalSymbol = (nTypeValue & 0x10) != 0 // 0x10 == N_PEXT mask == 00010000 /* private external symbol bit */
        self.isPrivateExternalSymbol = isPrivateExternalSymbol
        let isExternalSymbol = (nTypeValue & 0x01) != 0 // 0x01 == N_EXT mask == 00000001 /* external symbol bit, set for external symbols */
        self.isExternalSymbol = isExternalSymbol
        
        /*
         * n_sect
         * n_desc
         * n_value
         */
        
        self.nSect = dataShifter.shiftUInt8()
        self.nDesc = dataShifter.shiftUInt16()
        self.nValue = is64Bit ? dataShifter.shiftUInt64() : UInt64(dataShifter.shiftUInt32())
        
        switch self.symbolType {
        case .stab(_):
            //TODO: make sure for stab symbol, it's normal to fail to find symbol name
            if let foundName = try? await self.stringTable.findString(atDataOffset: Int(self.indexInStringTable)) {
                self.symbolName = foundName
            } else {
                self.symbolName = "Not found"
            }
        default:
            self.symbolName = (try? await self.stringTable.findString(atDataOffset: Int(self.indexInStringTable))) ?? "Not Found"
        }
    }
    
    var translationGroup: TranslationGroup {
        get async {
            let translationGroup = TranslationGroup(dataStartIndex: self.dataStartIndex)
            
            translationGroup.addTranslation(definition: "String Table Offset", humanReadable: self.indexInStringTable.hex,
                                                   translationType: .uint32,
                                                   extraDefinition: "Symbol Name from String Table", extraHumanReadable: self.symbolName)
            
            var symbolTypeExplanation: String = self.symbolType.readable
            var nSectExplanation: String = "\(nSect)"
            
            var nValueDesp: String = "Value"
            var nValueExplanation: String = "\(nValue)"
            var nValueExtraDesp: String?
            var nValueExtraExplanation: String?
            
            switch self.symbolType {
            case .undefined:
                nSectExplanation = "0 (NO_SECT)"
            case .absolute:
                nSectExplanation = "0 (NO_SECT)"
            case .section:
                let ordinal = Int(self.nSect)
                let sectionHeader = machoSectionHeaders[ordinal - 1] // ordinal starts from 1
                let sectionName = sectionHeader.segment + "," + sectionHeader.section
                symbolTypeExplanation += (sectionName + " (N_SECT)")
            case .indirect:
                nValueDesp = "String table offset"
                nValueExplanation = nValue.hex
                nValueExtraDesp = "Referred string"
                nValueExtraExplanation = try? await self.stringTable.findString(atDataOffset: Int(nValue))
            default:
                break
            }
            
            translationGroup.addTranslation(definition: "Symbol Type",
                                            humanReadable: symbolTypeExplanation + " (Private External:\(self.isPrivateExternalSymbol), External:\(self.isExternalSymbol)",
                                            translationType: .numberEnum8Bit)
            
            translationGroup.addTranslation(definition: "Section Ordinal", humanReadable: nSectExplanation,
                                            translationType: .uint8)
            
            translationGroup.addTranslation(definition: "Descriptions", humanReadable: SymbolTableEntry.flagsFrom(nDesc: nDesc, symbolType: symbolType).joined(separator: "\n"),
                                            translationType: .flags(2))
            
            translationGroup.addTranslation(definition: nValueDesp, humanReadable: nValueExplanation,
                                            translationType: self.is64Bit ? .uint64 : .uint32,
                                            extraDefinition: nValueExtraDesp, extraHumanReadable: nValueExtraExplanation)
            
            return translationGroup
        }
    }
    
    static func flagsFrom(nDesc: UInt16, symbolType: SymbolType) -> [String] {
        // FIXME: the code below for pasing n_desc is far from complete, less alone correct
        // it takes more effort to read llvm-nm and other sources to finally create good codes
        
        var flags: [String] = []
        
        switch symbolType {
        case .undefined:
            fallthrough
        case .preBound:
            let referenceType = nDesc & 0x7
            switch referenceType {
            case 0:
                flags.append("REFERENCE_FLAG_UNDEFINED_NON_LAZY")
            case 1:
                flags.append("REFERENCE_FLAG_UNDEFINED_LAZY")
            case 2:
                flags.append("REFERENCE_FLAG_DEFINED")
            case 3:
                flags.append("REFERENCE_FLAG_PRIVATE_DEFINED")
            case 4:
                flags.append("REFERENCE_FLAG_PRIVATE_UNDEFINED_NON_LAZY")
            case 5:
                flags.append("REFERENCE_FLAG_PRIVATE_UNDEFINED_LAZY")
            default:
                break
            }
            
            let libraryOrdinal = (nDesc >> 8) & 0xff
            switch libraryOrdinal {
            case 0x0:
                flags.append("SELF_LIBRARY_ORDINAL")
            case 0xfd:
                flags.append("MAX_LIBRARY_ORDINAL")
            case 0xfe:
                flags.append("DYNAMIC_LOOKUP_ORDINAL")
            case 0xff:
                flags.append("EXECUTABLE_ORDINAL")
            default:
                break
            }
        default:
            break
        }
        
        if nDesc & 0x0010 != 0 {
            flags.append("REFERENCED_DYNAMICALLY")
        }
        
        if nDesc & 0x0020 != 0 {
            flags.append("N_NO_DEAD_STRIP")
        }
        
        if nDesc & 0x0040 != 0 {
            flags.append("N_WEAK_REF")
        }
        
        switch symbolType {
        case .undefined:
            if nDesc & 0x0080 != 0 {
                flags.append("N_REF_TO_WEAK")
            }
        default:
            if nDesc & 0x0080 != 0 {
                flags.append("N_WEAK_DEF")
            }
            if nDesc & 0x0100 != 0 {
                flags.append("N_SYMBOL_RESOLVER")
            }
        }
        
        if nDesc & 0x0008 != 0 {
            flags.append("N_ARM_THUMB_DEF")
        }
        
        if flags.isEmpty {
            flags.append("NONE")
        }
        
        return flags
    }
    
}
