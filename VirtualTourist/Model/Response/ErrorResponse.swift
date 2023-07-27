//
//  ErrorResponse.swift
//  VirtualTourist
//
//  Created by MacBook Pro on 27.07.23.
//

import Foundation

struct ErrorResponse: Codable {
    let stat: String
    let message: String
    let code: Int
}

extension ErrorResponse: LocalizedError {
    var errorDescription: String? {
        return message
    }
}
