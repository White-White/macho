//
//  LoadCommand.swift
//  mocha
//
//  Created by white on 2021/6/17.
//

import Foundation

enum LoadCommandType: UInt32 {
    
    // ref: <mach-o/loader.h>
    /* After MacOS X 10.1 when a new load command is added that is required to be
      understood by the dynamic linker for the image to execute properly the
      LC_REQ_DYLD bit will be or'ed into the load command constant. */
    // So we remove the mask value here
    
    case segment = 0x1
    case symbolTable
    case symseg
    case thread
    case unixThread
    case loadFVMLib
    case idFVMLib
    case ident
    case FVMFile
    case prePage
    case dynamicSymbolTable
    case loadDylib
    case idDylib
    case loadDynamicLinker
    case idDynamicLinker
    case preBoundDylib
    case routines
    case subFramework
    case subUmbrella
    case subClient
    case subLibrary
    case twoLevelHints
    case prebindChecksum
    case loadWeakDylib = 0x80000018
    case segment64 = 0x19
    case routines64
    case uuid
    case rpath = 0x8000001c
    case codeSignature = 0x1d
    case segmentSplitInfo
    case reexportDylib = 0x8000001f
    case lazyLoadDylib = 0x20
    case encryptionInfo
    case dyldInfo
    case dyldInfoOnly = 0x80000022
    case loadUpwardDylib
    case macOSMinVersion = 0x24
    case iOSMinVersion
    case functionStarts
    case dyldEnvironment
    case main = 0x80000028
    case dataInCode = 0x29
    case sourceVersion
    case dylibCodeSigDRs
    case encryptionInfo64
    case linkerOption
    case linkerOptimizationHint
    case tvOSMinVersion
    case watchOSMinVersion
    case note
    case buildVersion
    case dyldExportsTrie = 0x80000033
    case dyldChainedFixups
    case fileSetEntry
    
    var name: String {
        switch self {
        case .segment:
            return "LC_SEGMENT"
        case .symbolTable:
            return "LC_SYMTAB"
        case .symseg:
            return "LC_SYMSEG"
        case .thread:
            return "LC_THREAD"
        case .unixThread:
            return "LC_UNIXTHREAD"
        case .loadFVMLib:
            return "LC_LOADFVMLIB"
        case .idFVMLib:
            return "LC_IDFVMLIB"
        case .ident:
            return "LC_IDENT"
        case .FVMFile:
            return "LC_FVMFILE"
        case .prePage:
            return "LC_PREPAGE"
        case .dynamicSymbolTable:
            return "LC_DYSYMTAB"
        case .loadDylib:
            return "LC_LOAD_DYLIB"
        case .idDylib:
            return "LC_ID_DYLIB"
        case .loadDynamicLinker:
            return "LC_LOAD_DYLINKER"
        case .idDynamicLinker:
            return "LC_ID_DYLINKER"
        case .preBoundDylib:
            return "LC_PREBOUND_DYLIB"
        case .routines:
            return "LC_ROUTINES"
        case .subFramework:
            return "LC_SUB_FRAMEWORK"
        case .subUmbrella:
            return "LC_SUB_UMBRELLA"
        case .subClient:
            return "LC_SUB_CLIENT"
        case .subLibrary:
            return "LC_SUB_LIBRARY"
        case .twoLevelHints:
            return "LC_TWOLEVEL_HINTS"
        case .prebindChecksum:
            return "LC_PREBIND_CKSUM"
        case .loadWeakDylib:
            return "LC_LOAD_WEAK_DYLIB"
        case .segment64:
            return "LC_SEGMENT_64"
        case .routines64:
            return "LC_ROUTINES_64"
        case .uuid:
            return "LC_UUID"
        case .rpath:
            return "LC_RPATH"
        case .codeSignature:
            return "LC_CODE_SIGNATURE"
        case .segmentSplitInfo:
            return "LC_SEGMENT_SPLIT_INFO"
        case .reexportDylib:
            return "LC_REEXPORT_DYLIB"
        case .lazyLoadDylib:
            return "LC_LAZY_LOAD_DYLIB"
        case .encryptionInfo:
            return "LC_ENCRYPTION_INFO"
        case .dyldInfo:
            return "LC_DYLD_INFO"
        case .dyldInfoOnly:
            return "LC_DYLD_INFO_ONLY"
        case .loadUpwardDylib:
            return "LC_LOAD_UPWARD_DYLIB"
        case .macOSMinVersion:
            return "LC_VERSION_MIN_MACOSX"
        case .iOSMinVersion:
            return "LC_VERSION_MIN_IPHONEOS"
        case .functionStarts:
            return "LC_FUNCTION_STARTS"
        case .dyldEnvironment:
            return "LC_DYLD_ENVIRONMENT"
        case .main:
            return "LC_MAIN"
        case .dataInCode:
            return "LC_DATA_IN_CODE"
        case .sourceVersion:
            return "LC_SOURCE_VERSION"
        case .dylibCodeSigDRs:
            return "LC_DYLIB_CODE_SIGN_DRS"
        case .encryptionInfo64:
            return "LC_ENCRYPTION_INFO_64"
        case .linkerOption:
            return "LC_LINKER_OPTION"
        case .linkerOptimizationHint:
            return "LC_LINKER_OPTIMIZATION_HINT"
        case .tvOSMinVersion:
            return "LC_VERSION_MIN_TVOS"
        case .watchOSMinVersion:
            return "LC_VERSION_MIN_WATCHOS"
        case .note:
            return "LC_NOTE"
        case .buildVersion:
            return "LC_BUILD_VERSION"
        case .dyldExportsTrie:
            return "LC_DYLD_EXPORTS_TRIE"
        case .dyldChainedFixups:
            return "LC_DYLD_CHAINED_FIXUPS"
        case .fileSetEntry:
            return "LC_FILESET_ENTRY"
        }
    }
}

class LoadCommand: GroupTranslatedMachoSlice {
    
    let type: LoadCommandType
    
    init(_ data: Data, type: LoadCommandType, title: String? = nil, subTitle: String? = nil) {
        self.type = type
        super.init(data, title: title ?? type.name, subTitle: subTitle)
    }
    
    override func translate() async -> [TranslationGroup] {
        let translationGroup = TranslationGroup(dataStartIndex: self.offsetInMacho)
        translationGroup.addTranslation(definition: "Load Command Type", humanReadable: type.name, translationType: .numberEnum32Bit)
        translationGroup.addTranslation(definition: "Load Command Size", humanReadable: data.count.hex, translationType: .uint32)
        self.addCommandTranslation(to: translationGroup)
        return [translationGroup]
    }

    func addCommandTranslation(to translationGroup: TranslationGroup) {
        
    }

    static func loadCommands(from machoData: Data,
                             machoHeader: MachoHeader,
                             onLCSegment: (LCSegment) -> Void,
                             onLCSymbolTable: (LCSymbolTable) -> Void,
                             onLCDynamicSymbolTable: (LCDynamicSymbolTable) -> Void,
                             onLCLinkedITData: (LCLinkedITData) -> Void,
                             onLCDyldInfo: (LCDyldInfo) -> Void) -> [LoadCommand] {
        let loadCommandsData = machoData.subSequence(from: machoHeader.dataSize, count: Int(machoHeader.sizeOfAllLoadCommand))
        var loadCommands: [LoadCommand] = []
        var dataShifter = DataShifter(loadCommandsData)
        while dataShifter.shiftable {
            guard let loadCommandType = LoadCommandType(rawValue: dataShifter.shift(.doubleWords).UInt32) else {
                print("Unknown load command type. Debug me."); fatalError()
            }
            let loadCommandSize = dataShifter.shift(.doubleWords).UInt32
            dataShifter.back(.quadWords)
            let loadCommandData = dataShifter.shift(.rawNumber(Int(loadCommandSize)))
            
            let loadCommand: LoadCommand
            switch loadCommandType {
            case .iOSMinVersion, .macOSMinVersion, .tvOSMinVersion, .watchOSMinVersion:
                loadCommand = LCMinOSVersion(with: loadCommandType, data: loadCommandData)
            case .linkerOption:
                loadCommand = LCLinkerOption(with: loadCommandType, data: loadCommandData)
            case .segment, .segment64:
                let segment = LCSegment(with: loadCommandType, data: loadCommandData)
                onLCSegment(segment)
                loadCommand = segment
            case .symbolTable:
                let symbolTableCommand = LCSymbolTable(with: loadCommandType, data: loadCommandData)
                onLCSymbolTable(symbolTableCommand)
                loadCommand = symbolTableCommand
            case .dynamicSymbolTable:
                let dynamicSymbolTableCommand = LCDynamicSymbolTable(with: loadCommandType, data: loadCommandData)
                onLCDynamicSymbolTable(dynamicSymbolTableCommand)
                loadCommand = dynamicSymbolTableCommand
            case .idDylib, .loadDylib, .loadWeakDylib, .reexportDylib, .lazyLoadDylib, .loadUpwardDylib:
                loadCommand = LCDylib(with: loadCommandType, data: loadCommandData)
            case .rpath, .idDynamicLinker, .loadDynamicLinker, .dyldEnvironment:
                loadCommand = LCMonoString(with: loadCommandType, data: loadCommandData)
            case .uuid:
                loadCommand = LCUUID(with: loadCommandType, data: loadCommandData)
            case .sourceVersion:
                loadCommand = LCSourceVersion(with: loadCommandType, data: loadCommandData)
            case .dataInCode, .codeSignature, .functionStarts, .segmentSplitInfo, .dylibCodeSigDRs, .linkerOptimizationHint, .dyldExportsTrie, .dyldChainedFixups:
                let linkedITData = LCLinkedITData(with: loadCommandType, data: loadCommandData)
                onLCLinkedITData(linkedITData)
                loadCommand = linkedITData
            case .main:
                loadCommand = LCMain(with: loadCommandType, data: loadCommandData)
            case .dyldInfo, .dyldInfoOnly:
                let dyldInfo = LCDyldInfo(with: loadCommandType, data: loadCommandData)
                onLCDyldInfo(dyldInfo)
                loadCommand = dyldInfo
            case .encryptionInfo64,. encryptionInfo:
                loadCommand = LCEncryptionInfo(with: loadCommandType, data: loadCommandData)
            case .buildVersion:
                loadCommand = LCBuildVersion(with: loadCommandType, data: loadCommandData)
            default:
                Log.warning("Unknown load command \(loadCommandType.name). Debug me.")
                loadCommand = LoadCommand(loadCommandData, type: loadCommandType)
            }
            loadCommands.append(loadCommand)
        }
        
        guard loadCommands.count == Int(machoHeader.numberOfLoadCommands) else { fatalError() }
        
        return loadCommands
    }
}
