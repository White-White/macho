//
//  Translatable.swift
//  DonQuixote
//
//  Created by white on 2025/1/29.
//

import Foundation

protocol Translatable {
    
}

protocol SimpleTranslatable: Translatable {
    func translations() -> [Translation]
}
