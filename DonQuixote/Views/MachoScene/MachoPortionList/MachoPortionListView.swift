//
//  MachoPortionListView.swift
//  DonQuixote
//
//  Created by white on 2025/1/29.
//

import SwiftUI

struct MachoPortionListView: View {
    
    var allPortions: [MachoPortion] {
        machoViewState.macho.allPortions
    }
    
    @EnvironmentObject var machoViewState: MachoViewState
    
    var body: some View {
        ScrollViewReader { scrollViewProxy in
            List(allPortions, id: \.id) { machoPortion in
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            VStack(alignment: .leading, spacing: 0) {
                                Text(machoPortion.title)
                                    .font(.system(size: 12).bold())
                                    .padding(.bottom, 2)
                                if let subTitle = machoPortion.subTitle {
                                    Text(subTitle)
                                        .font(.system(size: 10).bold())
                                        .padding(.bottom, 2)
                                }
                                Text(String(format: "Range: 0x%0X - 0x%0X", machoPortion.offsetInMacho, machoPortion.offsetInMacho + machoPortion.dataSize))
                                    .font(.system(size: 11))
                                Text(String(format: "Size: 0x%0X(%d) Bytes", machoPortion.dataSize, machoPortion.dataSize))
                                    .font(.system(size: 11))
                            }
                            .padding(4)
                            Spacer()
                        }
                        Divider()
                    }
                }
                .background(self.backgroundColor(machoPortion))
                .listRowInsets(EdgeInsets(top: 0, leading: -8, bottom: 0, trailing: -8))
                .onTapGesture {
                    machoViewState.selectedMachoPortion = machoPortion
                }
                .onChange(of: machoViewState.selectedMachoPortion, initial: false) { oldValue, newValue in
                    withAnimation(.easeInOut(duration: 0.75)) {
                        scrollViewProxy.scrollTo(newValue.id, anchor: .center)
                    }
                }
            }
            .frame(width: MachoPortionListView.widthNeeded(for: allPortions))
            .listStyle(.plain)
            .border(.separator, width: 1)
        }
        
    }
    
    func backgroundColor(_ machoPortion: MachoPortion) -> Color {
        return ((machoViewState.selectedMachoPortion == machoPortion) ? Color(nsColor: .selectedTextBackgroundColor) : .white)
    }
    
    static func widthNeeded(for allMachoPortions: [MachoPortion]) -> CGFloat {
        return allMachoPortions.reduce(0) { partialResult, component in
            let attriString = NSAttributedString(string: component.title, attributes: [.font: NSFont.systemFont(ofSize: 12, weight: .bold)])
            let recommendedWidth = attriString.boundingRect(with: NSSize(width: 1000, height: 0), options: .usesLineFragmentOrigin).size.width
            return max(partialResult, recommendedWidth)
        } + 16
    }
    
}
