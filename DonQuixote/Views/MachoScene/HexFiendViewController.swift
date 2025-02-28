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
        self.hfController.setBytesPerColumn(1)
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
    
    func updateDataRange(selectedDataRange: Range<UInt64>) {
        guard selectedDataRange.count > 0 else {
            fatalError()
        }
        let hfRangeWrapper = HFRangeWrapper.withRange(HFRangeMake(selectedDataRange.lowerBound,
                                                                  UInt64(selectedDataRange.count)))
        self.hfController.selectedContentsRanges = [hfRangeWrapper]
        self.hfController.scrollHexView(to: UInt(selectedDataRange.lowerBound), bytesPerLine: UInt(HexFiendViewController.bytesPerLine))
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
    
    @EnvironmentObject var machoViewState: MachoViewState
    var clickHexViewCallback: ClickHexViewCallback?
    
    func makeNSViewController(context: Context) -> HexFiendViewController {
        let hexFiendViewController = HexFiendViewController(data: machoViewState.macho.machoData)
        hexFiendViewController.delegate = context.coordinator
        return hexFiendViewController
    }
    
    func updateNSViewController(_ hexFiendViewController: HexFiendViewController, context: Context) {
        hexFiendViewController.updateDataRange(selectedDataRange: machoViewState.selectedDataRange)
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
