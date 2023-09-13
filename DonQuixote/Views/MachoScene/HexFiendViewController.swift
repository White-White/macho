//
//  HexFiendViewController.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/9.
//

import SwiftUI
import AppKit

struct HexFiendDataRange: Equatable {
    
    var isValidValue: Bool {
        length != 0
    }
    
    let lowerBound: UInt64
    let length: UInt64
    var upperBound: UInt64 {
        lowerBound + length
    }
    
    var rawRange: Range<UInt64> {
        lowerBound..<upperBound
    }
    
    var hfHiglightedColorRange: HFColorRange {
        let colorRange = HFColorRange()
        colorRange.range = self.hfRangeWrapper
        colorRange.color = NSColor.init(calibratedWhite: 212.0/255.0, alpha: 1)
        return colorRange
    }
    
    var hfSelectedColorRange: HFColorRange {
        let colorRange = HFColorRange()
        colorRange.range = self.hfRangeWrapper
        colorRange.color = NSColor.selectedTextBackgroundColor
        return colorRange
    }
    
    var hfRangeWrapper: HFRangeWrapper {
        if self.isValidValue {
            return HFRangeWrapper.withRange(HFRangeMake(self.lowerBound, self.length))
        } else {
            return HFRangeWrapper.withRange(HFRange(location: 0, length: 0))
        }
    }
    
    static func zero() -> HexFiendDataRange {
        HexFiendDataRange(lowerBound: 0, length: 0)
    }
    
}

protocol HexFiendViewControllerDelegate: NSObjectProtocol {
    func didClickHexView(at charIndex: UInt64)
}

public class HexFiendViewController: NSViewController {
    
    static let fontSize: CGFloat = 12
    static let bytesPerLine = 20
    let data: Data
    let hfController: HFController
    let layoutRep: HFLayoutRepresenter
    weak var delegate: HexFiendViewControllerDelegate?
    
    public override func loadView() {
        view = layoutRep.view()
    }
    
    init(data: Data) {
        HexFiendUtil.doSwizzleOnce()
        
        self.data = data
        self.hfController = HFController()
        self.hfController.bytesPerColumn = 1
        self.hfController.editable = false
        self.hfController.font = NSFont.monospacedSystemFont(ofSize: HexFiendViewController.fontSize, weight: .regular)
        
        let byteSlice = HFSharedMemoryByteSlice(unsharedData: data)
        let byteArray = HFBTreeByteArray()
        byteArray.insertByteSlice(byteSlice, in: HFRangeMake(0, 0))
        hfController.byteArray = byteArray
        
        let layoutRep = HFLayoutRepresenter()
        let hexRep = HFHexTextRepresenter()
        let scrollRep = HFVerticalScrollerRepresenter()
        let lineCounting = HFUntouchableLineCountingRepresenter()
        lineCounting.lineNumberFormat = HFLineNumberFormat.hexadecimal
        if let lineCountingView = lineCounting.view() as? HFLineCountingView {
            lineCountingView.font = NSFont.monospacedSystemFont(ofSize: HexFiendViewController.fontSize, weight: .regular)
        }
        let asciiRep = HFStringEncodingTextRepresenter()
        if let asciiView = asciiRep.view() as? HFRepresenterTextView {
            asciiView.font = NSFont.monospacedSystemFont(ofSize: HexFiendViewController.fontSize, weight: .regular)
        }
        
        hfController.addRepresenter(lineCounting)
        hfController.addRepresenter(layoutRep)
        hfController.addRepresenter(hexRep)
        hfController.addRepresenter(scrollRep)
        hfController.addRepresenter(asciiRep)
        
        layoutRep.addRepresenter(lineCounting)
        layoutRep.addRepresenter(hexRep)
        layoutRep.addRepresenter(asciiRep)
        layoutRep.addRepresenter(scrollRep)
        
        self.layoutRep = layoutRep
        
        super.init(nibName: nil, bundle: nil)
        self.hfController.setController(self)
    }
    
    func updateDataRange(highlightedRange: HexFiendDataRange, selectedRange: HexFiendDataRange) {
        self.hfController.colorRanges = [highlightedRange.hfHiglightedColorRange, selectedRange.hfSelectedColorRange]
        if selectedRange.isValidValue {
            self.hfController.scrollHexView(to: UInt(selectedRange.lowerBound), bytesPerLine: UInt(HexFiendViewController.bytesPerLine))
        } else if highlightedRange.isValidValue {
            self.hfController.scrollHexView(to: UInt(highlightedRange.lowerBound), bytesPerLine: UInt(HexFiendViewController.bytesPerLine))
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    func didClickCharacter(at index: UInt64) {
        self.delegate?.didClickHexView(at: index)
    }
    
}

struct HexFiendViewControllerRepresentable: NSViewControllerRepresentable {
    
    typealias NSViewControllerType = HexFiendViewController
    typealias ClickHexViewCallback = ((_ dataIndex: UInt64) -> Void)
    
    let data: Data
    @Binding var machoViewState: MachoViewState
    var clickHexViewCallback: ClickHexViewCallback?
    
    func makeNSViewController(context: Context) -> HexFiendViewController {
        let hexFiendViewController = HexFiendViewController(data: data)
        hexFiendViewController.delegate = context.coordinator
        return hexFiendViewController
    }
    
    func updateNSViewController(_ hexFiendViewController: HexFiendViewController, context: Context) {
        hexFiendViewController.updateDataRange(highlightedRange: machoViewState.coloredDataRange,
                                               selectedRange: machoViewState.selectedDataRange)
    }
    
    class HexViewCoordinator: NSObject, HexFiendViewControllerDelegate {
        let clickHexViewCallback: ClickHexViewCallback?
        init(clickHexViewCallback: ClickHexViewCallback?) {
            self.clickHexViewCallback = clickHexViewCallback
        }
        func didClickHexView(at charIndex: UInt64) {
            self.clickHexViewCallback?(charIndex)
        }
    }
    
    func makeCoordinator() -> HexViewCoordinator {
        return HexViewCoordinator(clickHexViewCallback: self.clickHexViewCallback)
    }
    
    func sizeThatFits(_ proposal: ProposedViewSize, nsViewController: HexFiendViewController, context: Context) -> CGSize? {
        CGSize(width: nsViewController.layoutRep.minimumViewWidth(forBytesPerLine: UInt(HexFiendViewController.bytesPerLine)), height: proposal.height ?? .infinity)
    }
    
    func onClickHexView(_ callback: @escaping (_ dataIndex: UInt64) -> Void) -> HexFiendViewControllerRepresentable {
        var vSelf = self
        vSelf.clickHexViewCallback = callback
        return vSelf
    }
    
}
