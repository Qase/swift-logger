//
//  MetaInformationLogger.swift
//  
//
//  Created by Martin Troup on 24.09.2021.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

// TODO: Refactor using SwiftUI instead of UIKit

public enum MetaInformationType: String {
    case identifier = "CFBundleIdentifier"
    case compiler = "DTCompiler"
    case version = "CFBundleShortVersionString"
    case buildNumber = "CFBundleVersion"
    case modelType = "ModelType"
    case currentOSVersion = "CurrentOSVersion"
    case upTime = "UpTime"
    case language = "Language"

    static let allValues: [MetaInformationType] = [
        .identifier,
        .compiler,
        .version,
        .buildNumber,
        .modelType,
        .currentOSVersion,
        .upTime,
        .language
    ]
}

protocol MetaInformationLoggerDelegate: AnyObject {
    func logMetaInformation(_ message: String, onLevel level: Level)
}

class MetaInformationLogger {
    weak var delegate: MetaInformationLoggerDelegate?

    private var upTimeUSec: Int32 {
        var upTime = timeval()
        var size = MemoryLayout<timeval>.stride
        sysctlbyname("kern.boottime", &upTime, &size, nil, 0)
        return upTime.tv_usec
    }

    private var modelType: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce(into: "") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return }
            identifier += String(UnicodeScalar(UInt8(value)))
        }
    }

    private var currentOSVersion: String {
        #if canImport(UIKit)
        return UIDevice.current.systemVersion
        #elseif os(OSX)
        return ProcessInfo.processInfo.operatingSystemVersionString
        #else
        return "Unknown OS"
        #endif
    }

    private var language: String? {
        Locale.current.languageCode
    }

    private func values(for dataToLog: [MetaInformationType]) -> [String: String] {
        let bundle = Bundle.main

        var data = [String: String]()

        if dataToLog.contains(.identifier), let value = bundle.infoDictionary?[MetaInformationType.identifier.rawValue] as? String {
            data[MetaInformationType.identifier.rawValue] = value
        }

        if dataToLog.contains(.compiler), let value = bundle.infoDictionary?[MetaInformationType.compiler.rawValue] as? String {
            data[MetaInformationType.compiler.rawValue] = value
        }

        if dataToLog.contains(.version), let value = bundle.infoDictionary?[MetaInformationType.version.rawValue] as? String {
            data[MetaInformationType.version.rawValue] = value
        }

        if dataToLog.contains(.buildNumber), let value = bundle.infoDictionary?[MetaInformationType.buildNumber.rawValue] as? String {
            data[MetaInformationType.buildNumber.rawValue] = value
        }

        if dataToLog.contains(.modelType) {
            data[MetaInformationType.modelType.rawValue] = modelType
        }

        if dataToLog.contains(.currentOSVersion) {
            data[MetaInformationType.currentOSVersion.rawValue] = currentOSVersion
        }

        if dataToLog.contains(.upTime) {
            data[MetaInformationType.upTime.rawValue] = "\(upTimeUSec) microseconds"
        }

        if dataToLog.contains(.language), let value = language {
            data[MetaInformationType.language.rawValue] = value
        }

        return data
    }

    func log(_ dataToLog: [MetaInformationType], onLevel level: Level) {
        let dataToLog = dataToLog.isEmpty ? MetaInformationType.allValues : dataToLog

        delegate?.logMetaInformation("Meta information: \(values(for: dataToLog))", onLevel: level)
    }
}
