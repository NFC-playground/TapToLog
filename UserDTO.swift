//
//  UserDTO.swift
//  TapLog
//
//  Created by Sheena Kaw on 11/4/26.
//

import Foundation

struct UserDTO: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let email: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case createdAt = "created_at"
    }
}
