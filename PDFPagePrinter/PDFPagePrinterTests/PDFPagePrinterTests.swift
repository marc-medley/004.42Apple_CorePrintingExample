//
//  PDFPagePrinterTests.swift
//  PDFPagePrinterTests
//
//  Created by marc on 2017.07.01.
//  Copyright © 2017 Example. All rights reserved.
//

import XCTest
@testable import PDFPagePrinter

class PDFPagePrinterTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // printerID: "EPSON_R2880", "EPSON_WF_7520", PT_9500PC_, "Brother_PT9500PC"
        //        _ = TN2248.replacePageFormat()
        let result01 = TN2155.getAvailablePrinterList()
        print("printer names=\(result01.printerNames ?? ["empty list"])")
        if let printerList = result01.printers {
            for idx in 0..<CFArrayGetCount(printerList) {
                let printer = PMPrinter(CFArrayGetValueAtIndex(printerList, idx))!
                let nameUnmanaged: Unmanaged<CFString>? = PMPrinterGetName(printer)
                guard let name = nameUnmanaged?.takeUnretainedValue() as String? else {
                    continue
                }
                print("printer_name:\(name)")
                print( PrintData.getPMPrinterInfo(pmPrinter: printer) )
            }
        }
        
        if let printPreferencesFromUser = TN2155.getPrintInfoViaPrintPanel() {
            let userSession = PrintData.getPMPrintSessionInfo(pmPrintSession: printPreferencesFromUser.session)
            let userSettings = PrintData.getPMPrintSettingsInfo(pmPrintSettings: printPreferencesFromUser.settings)
            let userPageFormat = PrintData.getPMPageFormatInfo(pmPageFormat: printPreferencesFromUser.format)
            print("printPreferencesFromUser.session=\(userSession)")
            print("printPreferencesFromUser.settings=\(userSettings)")
            print("printPreferencesFromUser/format=\(userPageFormat)")
            
            _ = TN2155.savePrintPreferences(data: printPreferencesFromUser, prefix: "sample_")
            
            if let restoredPreferences = TN2155.readPrintPreferences(prefix: "sample_") {
                let restoredSettings = PrintData.getPMPrintSettingsInfo(pmPrintSettings: restoredPreferences.settings)
                let restoredPageFormat = PrintData.getPMPageFormatInfo(pmPageFormat: restoredPreferences.format)
                print("restoredPreferences.printerID=\(restoredPreferences.id)")
                print("restoredPreferences.settings=\(restoredSettings)")
                print("restoredPreferences.format=\(restoredPageFormat)")
            }
        }
        
        _ = TN2155.getPrintInfoViaPrintPanel2()
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
