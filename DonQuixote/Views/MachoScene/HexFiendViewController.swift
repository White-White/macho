//
//  HexFiendViewController.swift
//  mocha (macOS)
//
//  Created by white on 2022/7/9.
//

import SwiftUI
import AppKit

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
    
    var selectedDataRange: Range<UInt64>?
    var selectedComponentDataRange: Range<UInt64>?
    
    func updateSelectedDataRange(with range: Range<UInt64>?, autoScroll: Bool) {
        if let range {
            self.hfController.selectedContentsRanges = [HexFiendViewController.hfRangeWrapper(from: range)]
            if autoScroll {
                self.scrollHexView(basedOn: range)
            }
        } else {
            self.hfController.selectedContentsRanges = [HFRangeWrapper.withRange(HFRange(location: 0, length: 0))]
        }
    }
    
    func updateColorDataRange(with range: Range<UInt64>?) {
        if let range {
            self.hfController.colorRanges = [HexFiendViewController.colorRange(from: range)]
        }
    }
    
    private func scrollHexView(basedOn selectedRange: Range<UInt64>) {
        self.hfController.scrollHexViewBased(on: NSMakeRange(Int(selectedRange.lowerBound), Int(selectedRange.upperBound - selectedRange.lowerBound)), bytesPerLine: UInt(HexFiendViewController.bytesPerLine))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    static func hfRangeWrapper(from range: Range<UInt64>) -> HFRangeWrapper {
        let hfRange = HFRangeMake(range.lowerBound, range.upperBound - range.lowerBound)
        return HFRangeWrapper.withRange(hfRange)
    }
    
    static func colorRange(from range: Range<UInt64>) -> HFColorRange {
        let colorRange = HFColorRange()
        colorRange.range = self.hfRangeWrapper(from: range)
        colorRange.color = NSColor.init(calibratedWhite: 212.0/255.0, alpha: 1)
        return colorRange
    }
    
    // exposed to Objective-C
    @objc
    func didClickCharacter(at index: UInt64) {
        self.delegate?.didClickHexView(at: index)
    }
    
}

struct HexFiendViewControllerRepresentable: NSViewControllerRepresentable {
    
    typealias NSViewControllerType = HexFiendViewController
    
    let data: Data
    @Binding var machoViewSelection: MachoViewSelection
    let clickingHexViewCallBack: ((_ charIndex: UInt64) -> Void)
    
    func makeNSViewController(context: Context) -> HexFiendViewController {
        let hexFiendViewController = HexFiendViewController(data: data)
        hexFiendViewController.delegate = context.coordinator
        return hexFiendViewController
    }
    
    func updateNSViewController(_ hexFiendViewController: HexFiendViewController, context: Context) {
        hexFiendViewController.updateColorDataRange(with: machoViewSelection.coloredDataRange)
        hexFiendViewController.updateSelectedDataRange(with: machoViewSelection.selectedDataRange, autoScroll: true)
    }
    
    class HexViewCoordinator: NSObject, HexFiendViewControllerDelegate {
        let clickingHexViewCallBack: ((_ charIndex: UInt64) -> Void)
        init(clickingHexViewCallBack: @escaping (_: UInt64) -> Void) {
            self.clickingHexViewCallBack = clickingHexViewCallBack
        }
        func didClickHexView(at charIndex: UInt64) {
            self.clickingHexViewCallBack(charIndex)
        }
    }
    
    func makeCoordinator() -> HexViewCoordinator {
        return HexViewCoordinator(clickingHexViewCallBack: self.clickingHexViewCallBack)
    }
    
    func sizeThatFits(_ proposal: ProposedViewSize, nsViewController: HexFiendViewController, context: Context) -> CGSize? {
        CGSize(width: nsViewController.layoutRep.minimumViewWidth(forBytesPerLine: UInt(HexFiendViewController.bytesPerLine)), height: proposal.height ?? .infinity)
    }
    
}
