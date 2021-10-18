//
//  URL+fileSize.swift
//  
//
//  Created by Martin Troup on 18.10.2021.
//

import Foundation

extension URL {
    var fileSize: Int? {
        do {
            return try resourceValues(forKeys: [.fileSizeKey]).fileSize
        } catch {
            return nil
        }
    }
}
