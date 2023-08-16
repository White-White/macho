//
//  IPAView.swift
//  DonQuixote
//
//  Created by white on 2023/6/25.
//

import Foundation
import SwiftUI

struct IPAView: DocumentView {
    
    let ipa: IPA
    
    init(_ ipa: IPA) {
        self.ipa = ipa
    }
    
    var body: some View {
        Button("Start Faking") {
//            try! Faking.run(for: ipa)
        }
    }
    
}
