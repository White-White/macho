//
//  MachoItemView.swift
//  DonQuixote
//
//  Created by white on 2023/8/10.
//

import SwiftUI

struct MachoItemView: View {
    
    @Environment(\.openWindow) var openWindow
    @State private var isHover: Bool = false
    let machoLocation: FileLocation
    
    @ViewBuilder
    private var selectionBackground: some View {
        if isHover {
            RoundedRectangle(cornerRadius: 8)
                .fill(.selection)
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(machoLocation.fileName).bold()
                Spacer()
            }
            .padding(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            .border(.separator, width: 2)
            .cornerRadius(8)
            .background(selectionBackground)
            .onHover { isHover in
                self.isHover = isHover
            }
        }
        .onTapGesture {
            openWindow(id: machoLocation.fileType.rawValue, value: machoLocation)
        }
    }
    
}
