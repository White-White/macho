//
//  CPU.swift
//  mocha
//
//  Created by white on 2021/6/17.
//

import Foundation

//ref: <mach/machine.h>
enum CPUType {
    case x86
    case x86_64
    case arm
    case arm64
    case arm64_32
    case unknown(UInt32)
    
    var name: String {
        switch self {
        case .x86:
            return "x86"
        case .x86_64:
            return "x86_64"
        case .arm:
            return "arm"
        case .arm64:
            return "arm64"
        case .arm64_32:
            return "arm64_32"
        case .unknown(let raw):
            return "UNKNOWN(\(raw.hex))"
        }
    }
    
    init(_ value: UInt32) {
        switch value {
        case 0x00000007:
            self = .x86
        case 0x01000007:
            self = .x86_64
        case 0x0000000c:
            self = .arm
        case 0x0100000c:
            self = .arm64
        case 0x0200000c:
            self = .arm64_32
        default:
            self = .unknown(value)
        }
    }
    
    var isARMChip: Bool {
        switch self {
        case .arm, .arm64, .arm64_32:
            return true
        default:
            return false
        }
    }
    
    var isIntelChip: Bool {
        switch self {
        case .x86, .x86_64:
            return true
        default:
            return false
        }
    }
}

//ref: <macho/machine.h>
enum CPUSubtype {
    case x86_all
    case x86_arch1
    case x86_64_all
    case x86_64_h /* Haswell feature subset */
    case arm_all
    case arm_v7
    case arm_v7f
    case arm_v7s
    case arm_v7k
    case arm_v8
    case arm64_all
    case arm64_v8
    case arm64_e
    case arm64_32_all
    case arm64_32_v8
    case unknown(UInt32)
    
    var name: String {
        switch self {
        case .x86_all:
            return "CPU_SUBTYPE_X86_ALL"
        case .x86_arch1:
            return "CPU_SUBTYPE_X86_ARCH1"
        case .x86_64_all:
            return "CPU_SUBTYPE_X86_64_ALL"
        case .x86_64_h:
            return "CPU_SUBTYPE_X86_64_H"
        case .arm_all:
            return "CPU_SUBTYPE_ARM_ALL"
        case .arm_v7:
            return "CPU_SUBTYPE_ARM_V7"
        case .arm_v7f:
            return "CPU_SUBTYPE_ARM_V7F"
        case .arm_v7s:
            return "CPU_SUBTYPE_ARM_V7S"
        case .arm_v7k:
            return "CPU_SUBTYPE_ARM_V7K"
        case .arm_v8:
            return "CPU_SUBTYPE_ARM_V8"
        case .arm64_all:
            return "CPU_SUBTYPE_ARM64_ALL"
        case .arm64_v8:
            return "CPU_SUBTYPE_ARM64_V8"
        case .arm64_e:
            return "CPU_SUBTYPE_ARM64E"
        case .arm64_32_all:
            return "CPU_SUBTYPE_ARM64_32_ALL"
        case .arm64_32_v8:
            return "CPU_SUBTYPE_ARM64_32_V8"
        case .unknown(let raw):
            return "UNKNOWN(\(raw.hex)"
        }
    }
    
    init(_ value: UInt32, cpuType: CPUType) {
        switch cpuType {
        case .x86:
            switch value {
            case 3:
                self = .x86_all
            case 4:
                self = .x86_arch1
            default:
                self = .unknown(value)
            }
        case .x86_64:
            switch value {
            case 3:
                self = .x86_64_all
            case 8:
                self = .x86_64_h
            default:
                self = .unknown(value)
            }
        case .arm:
            switch value {
            case 0:
                self = .arm_all
            case 9:
                self = .arm_v7
            case 10:
                self = .arm_v7f
            case 11:
                self = .arm_v7s
            case 12:
                self = .arm_v7k
            case 13:
                self = .arm_v8
            default:
                self = .unknown(value)
            }
        case .arm64:
            switch value {
            case 0:
                self = .arm64_all
            case 1:
                self = .arm64_v8
            case 2:
                self = .arm64_e
            default:
                self = .unknown(value)
            }
        case .arm64_32:
            switch value {
            case 0:
                self = .arm64_32_all
            case 1:
                self = .arm64_32_v8
            default:
                self = .unknown(value)
            }
        case .unknown(_):
            self = .unknown(value)
        }
    }
}
