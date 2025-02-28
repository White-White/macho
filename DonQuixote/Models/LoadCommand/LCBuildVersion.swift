//
//  LCBuildVersion.swift
//  mocha (macOS)
//
//  Created by white on 2022/1/18.
//

import Foundation

enum BuildToolType: UInt32 {
    case clang = 1
    case swift
    case ld
    
    var readable: String {
        switch self {
        case .clang:
            return "Clang (TOOL_CLANG)"
        case .swift:
            return "Swift (TOOL_SWIFT)"
        case .ld:
            return "LD (TOOL_LD)"
        }
    }
}

enum BuildPlatform: UInt32 {
    case macOS = 1
    case iOS
    case tvOS
    case watchOS
    case bridgeOS
    case macCatalyst
    case iOSSimulator
    case tvOSSimulator
    case watchOSSimulator
    case driverKit
    
    var readable: String {
        switch self {
        case .macOS:
            return "PLATFORM_MACOS"
        case .iOS:
            return "PLATFORM_IOS"
        case .tvOS:
            return "PLATFORM_TVOS"
        case .watchOS:
            return "PLATFORM_WATCHOS"
        case .bridgeOS:
            return "PLATFORM_BRIDGEOS"
        case .macCatalyst:
            return "PLATFORM_MACCATALYST"
        case .iOSSimulator:
            return "PLATFORM_IOSSIMULATOR"
        case .tvOSSimulator:
            return "PLATFORM_TVOSSIMULATOR"
        case .watchOSSimulator:
            return "PLATFORM_WATCHOSSIMULATOR"
        case .driverKit:
            return "PLATFORM_DRIVERKIT"
        }
    }
}

struct LCBuildTool {
    let toolType: BuildToolType
    let version: String
}

class LCBuildVersion: LoadCommand, @unchecked Sendable {
    
    let platform: BuildPlatform?
    let minOSVersion: String
    let sdkVersion: String
    let numberOfTools: UInt32
    let buildTools: [LCBuildTool]
    
    init(with type: LoadCommandType, data: Data) {
        var dataShifter = DataShifter(data); dataShifter.skip(.quadWords)
        self.platform = BuildPlatform(rawValue: dataShifter.shiftUInt32())
        self.minOSVersion = LCBuildVersion.version(for: dataShifter.shiftUInt32())
        self.sdkVersion = LCBuildVersion.version(for: dataShifter.shiftUInt32())
        self.numberOfTools = dataShifter.shiftUInt32()
        var tools: [LCBuildTool] = []
        for _ in 0..<self.numberOfTools {
            let toolType = BuildToolType(rawValue: dataShifter.shiftUInt32())!
            let toolVersion = LCBuildVersion.version(for: dataShifter.shiftUInt32())
            tools.append(LCBuildTool(toolType: toolType, version: toolVersion))
        }
        self.buildTools = tools
        super.init(data, type: type)
    }
    
    override func addCommandTranslation(to translationGroup: TranslationGroup) {
        translationGroup.addTranslation(definition: "Target Platform",
                                        humanReadable: platform?.readable ?? "⚠️ Unknown Platform. Contact the author.",
                                        translationType: .numberEnum32Bit)
        translationGroup.addTranslation(definition: "Min OS Version", humanReadable: self.minOSVersion, translationType: .versionString32Bit)
        translationGroup.addTranslation(definition: "Min SDK Version", humanReadable: self.sdkVersion, translationType: .versionString32Bit)
        for tool in self.buildTools {
            translationGroup.addTranslation(definition: "Build Tool Name",
                                            humanReadable: tool.toolType.readable,
                                            translationType: .numberEnum32Bit)
            translationGroup.addTranslation(definition: "Build Tool Version",
                                            humanReadable: "(\(tool.version)",
                                            translationType: .versionString32Bit)
        }
    }
    
    static func version(for value: UInt32) -> String {
        return String(format: "%d.%d.%d", value >> 16, (value >> 8) & 0xff, value & 0xff)
    }
    
}
