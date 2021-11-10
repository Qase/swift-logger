//
//  MetaInformationType.swift
//  
//
//  Created by Martin Troup on 24.09.2021.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

public enum MetaInformationType: String, CaseIterable {
    case identifier = "CFBundleIdentifier"
    case compiler = "DTCompiler"
    case version = "CFBundleShortVersionString"
    case buildNumber = "CFBundleVersion"
    case modelType = "ModelType"
    case currentOSVersion = "CurrentOSVersion"
    case upTime = "UpTime"
    case language = "Language"

    func value(inBundle bundle: Bundle) -> String? {
        switch self {
        case .identifier:
            return bundle.infoDictionary?[MetaInformationType.identifier.rawValue] as? String

        case .compiler:
            return bundle.infoDictionary?[MetaInformationType.compiler.rawValue] as? String

        case .version:
            return bundle.infoDictionary?[MetaInformationType.version.rawValue] as? String

        case .buildNumber:
            return bundle.infoDictionary?[MetaInformationType.buildNumber.rawValue] as? String

        case .modelType:
            var systemInfo = utsname()
            uname(&systemInfo)
            let machineMirror = Mirror(reflecting: systemInfo.machine)

            let modelType = machineMirror.children.reduce(into: "") { identifier, element in
                guard let value = element.value as? Int8, value != 0 else { return }
                identifier += String(UnicodeScalar(UInt8(value)))
            }

            return modelType

        case .currentOSVersion:
            #if canImport(UIKit)
            return UIDevice.current.systemVersion
            #elseif os(OSX)
            return ProcessInfo.processInfo.operatingSystemVersionString
            #else
            return "Unknown OS"
            #endif

        case .upTime:
            var upTime = timeval()
            var size = MemoryLayout<timeval>.stride
            sysctlbyname("kern.boottime", &upTime, &size, nil, 0)
            return "\(upTime.tv_usec) microseconds"

        case .language:
            return Locale.current.languageCode
        }
    }
}

// MARK: - Array + MetaInformationType

extension Array where Element == MetaInformationType {
    func dictionary(fromBundle bundle: Bundle) -> [String: String] {
        reduce([String: String]()) { dictionary, nextType in
            var newDictionary = dictionary
            newDictionary[nextType.rawValue] = nextType.value(inBundle: bundle)

            return newDictionary
        }
    }
}
