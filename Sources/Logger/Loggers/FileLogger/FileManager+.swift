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
        usingSuiteName suiteName: String? = nil,
        withPathExtension pathExtension: String
    ) throws {
        let logFiles = try allFiles(
            at: directoryURL,
            usingSuiteName: suiteName,
            withPathExtension: pathExtension
        )

        try logFiles.forEach { try deleteFileIfExists(at: $0) }
    }

    func allFiles(
        at directoryURL: URL,
        usingSuiteName suiteName: String? = nil,
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

    func createFileIfNotExists(at url: URL, shouldRemoveExistingFileContents: Bool = false) throws {
        let fileExists = fileExists(atPath: url.path)

        if fileExists, shouldRemoveExistingFileContents {
            try "".write(toFile: url.path, atomically: false, encoding: .utf8)
        }

        guard !fileExists else { return }

        if !createFile(atPath: url.path, contents: nil) {
            throw FileManagerError.fileCreationFailed
        }
    }

    func contents(fromFileIfExists url: URL) throws -> String {
        guard fileExists(atPath: url.path) else {
            throw FileManagerError.fileNotFound
        }

        return try String(contentsOf: url, encoding: .utf8)
    }
}
