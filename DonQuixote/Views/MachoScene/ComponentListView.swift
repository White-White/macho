//
//  ComponentListView.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/17.
//

import SwiftUI

struct ComponentListCell: View {
    
    let machoSlice: MachoSlice
    let isSelected: Bool
    var title: String { machoSlice.title }
    var offsetInMacho: Int { machoSlice.offsetInMacho }
    var dataSize: Int { machoSlice.dataSize }
    
    var textColor: Color {
        self.isSelected ? Color(nsColor: .selectedTextColor) : Color(nsColor: .textColor)
    }
    
    var backgroundColor: Color {
        self.isSelected ? Color(nsColor: .selectedTextBackgroundColor) : Color(nsColor: .textBackgroundColor)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(title)
                        .font(.system(size: 12).bold())
                        .padding(.bottom, 2)
                        .foregroundColor(self.textColor)
                    Spacer()
                }
                
                if let subTitle = machoSlice.subTitle {
                    Text(subTitle)
                        .font(.system(size: 10).bold())
                        .padding(.bottom, 2)
                        .foregroundColor(self.textColor)
                }
                
                Text(String(format: "Range: 0x%0X - 0x%0X", offsetInMacho, offsetInMacho + dataSize))
                    .font(.system(size: 11))
                    .foregroundColor(self.textColor)
                
                Text(String(format: "Size: 0x%0X(%d) Bytes", dataSize, dataSize))
                    .font(.system(size: 11))
                    .foregroundColor(self.textColor)
                
            }
            .padding(4)
            .background(self.backgroundColor)
            
            Divider()
        }
        .padding([.leading, .trailing], 8)
        .background(.white)
    }
    
    static func widthNeeded(for allMachoElements: [MachoSlice]) -> CGFloat {
        return allMachoElements.reduce(0) { partialResult, component in
            let attriString = NSAttributedString(string: component.title, attributes: [.font: NSFont.systemFont(ofSize: 12, weight: .bold)])
            let recommendedWidth = attriString.boundingRect(with: NSSize(width: 1000, height: 0), options: .usesLineFragmentOrigin).size.width
            return max(partialResult, recommendedWidth)
        } + 16
    }
    
}
