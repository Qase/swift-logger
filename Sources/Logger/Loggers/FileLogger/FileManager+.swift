//
//  FileManager+.swift
//  
//
//  Created by Martin Troup on 18.10.2021.
//

import Foundation

enum FileManagerError: Error {
    case fileCreationFailed
    case fileNotFound
}

extension FileManager {
    func deleteAllFiles(
        at directoryURL: URL,
        withPathExtension pathExtension: String
    ) throws {
        let logFiles = try allFiles(
            at: directoryURL,
            withPathExtension: pathExtension
        )

        try logFiles.forEach { try deleteFileIfExists(at: $0) }
    }

    func allFiles(
        at directoryURL: URL,
        withPathExtension pathExtension: String
    ) throws -> [URL] {
        try contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == pathExtension }
    }

    func documentDirectoryURL(withName name: String, usingSuiteName suiteName: String? = nil) throws -> URL {
        (
            try suiteName.flatMap(containerURL(forSecurityApplicationGroupIdentifier:))
                ?? url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        )
        .appendingPathComponent(name)
    }

    func createDirectoryIfNotExists(at url: URL) throws {
        if fileExists(atPath: url.path) { return }

        try createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
    }

    func deleteFileIfExists(at url: URL) throws {
        guard fileExists(atPath: url.path) else { return }

        try removeItem(at: url)
    }

    func createFileIfNotExists(at url: URL, withInitialContent initialContent: String = "") throws {
        guard !fileExists(atPath: url.path) else { return }

        let initialContent = initialContent.count > 0 ? "\(initialContent)\n\n" : initialContent

        try initialContent.write(toFile: url.path, atomically: false, encoding: .utf8)
    }

    func contents(fromFileIfExists url: URL) throws -> String {
        guard fileExists(atPath: url.path) else {
            throw FileManagerError.fileNotFound
        }

        return try String(contentsOf: url, encoding: .utf8)
    }
}
