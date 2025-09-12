//
//  VaultItem.swift
//  Orga
//
//  Created by Bhavesh Tembhurkar on 06/09/25.
//

import Foundation

struct VaultItem : Codable, Identifiable{
    
    let id : UUID
    let fileName : String
    let originalPath : URL
}
