//
//  IPA.swift
//  DonQuixote
//
//  Created by white on 2023/6/25.
//

import Foundation
//import Zip

enum Platform {
    
    case iOS
    case iOSSimulator
    case macOS
    
    init(platform: String) throws {
        switch platform {
        case "iphoneos":
            self = .iOS
        case "iphonesimulator":
            self = .iOSSimulator
        case "macosx":
            self = .macOS
        default:
            throw DonError.unknownApplePlatform
        }
    }
    
    var name: String {
        switch self {
        case .iOS:
            fallthrough
        case .iOSSimulator:
            return "iOS"
        case .macOS:
            return "macOS"
        }
    }
    
    var deploymentTarget: String {
        switch self {
        case .iOS:
            fallthrough
        case .iOSSimulator:
            return "9.0"
        case .macOS:
            return "10.13"
        }
    }
    
}

struct InfoPlist {
    
    let plistURL: URL
    let plistDict: NSDictionary
    
    let bundleID: String
    let displayName: String
    let bundleName: String
    let appVersion: String
    let bundleVersion: String
    let platform: Platform
    
    init(bundleURL: URL) throws {
        
        let plistURL = bundleURL.appendingPathComponent("Info.plist", conformingTo: .propertyList)
        self.plistURL = plistURL
        guard let plistDict = NSDictionary(contentsOf: plistURL) else { throw DonError.invalidIPAPlist }
        self.plistDict = plistDict
        
        guard let bundleID = plistDict["CFBundleIdentifier"] as? String,
              let displayName = plistDict["CFBundleDisplayName"] as? String,
              let bundleName = plistDict["CFBundleExecutable"] as? String,
              let appVersion = plistDict["CFBundleShortVersionString"] as? String,
              let bundleVersion = plistDict["CFBundleVersion"] as? String,
              let platform = plistDict["DTPlatformName"] as? String else {
            throw DonError.invalidIPAPlist
        }
        
        self.bundleID = bundleID
        self.displayName = displayName
        self.bundleName = bundleName
        self.appVersion = appVersion
        self.bundleVersion = bundleVersion
        self.platform = try Platform(platform: platform)
        
    }
    
}

struct IPA: File {
    
    let infoPlist: InfoPlist
    let unzipRootURL: URL
    let bundleURL: URL
    
    init(with location: FileLocation) throws {
        let unzipRootURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent(UUID().uuidString, conformingTo: .folder)
//        Zip.addCustomFileExtension("ipa")
//        try Zip.unzipFile(location.fileURL, destination: unzipRootURL, overwrite: true, password: nil, progress: { (progress) -> () in
//            // TODO: progress
//        })
        
        let bundleURL = try IPA.findBundle(in: unzipRootURL)
        self.infoPlist = try InfoPlist(bundleURL: bundleURL)
        self.unzipRootURL = unzipRootURL
        self.bundleURL = bundleURL
    }
    
    static func findBundle(in rootURL: URL ) throws -> URL {
        let payloadFolderURL = rootURL.appendingPathComponent("Payload", conformingTo: .folder)
        var isDir: ObjCBool = false
        let payloadExists = FileManager.default.fileExists(atPath: payloadFolderURL.path(), isDirectory: &isDir)
        if (!isDir.boolValue || !payloadExists) {
            throw DonError.invalidIPABundle
        }
        guard
            let bundleURL = FileManager.default.enumerator(at: payloadFolderURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)?.nextObject() as? URL,
            bundleURL.pathExtension == "app"
        else {
            throw DonError.invalidIPABundle
        }
        return bundleURL
    }
    
}
