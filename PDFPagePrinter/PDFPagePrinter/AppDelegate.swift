//
//  AppDelegate.swift
//  PDFPagePrinter
//
//  Created by marc on 2017.07.01.
//  Copyright © 2017 Example. All rights reserved.
//

import Cocoa
import Quartz

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        defer { NSApp.terminate(nil) }
        
        // NSOpenPanel
        let openPanel = NSOpenPanel()
        openPanel.allowedFileTypes = [kUTTypePDF as String] // "com.adobe.pdf"
        openPanel.allowsMultipleSelection = true
        if (openPanel.runModal() != NSFileHandlingPanelOKButton) { return }
        
        application(NSApp, openFiles: openPanel.urls.flatMap({ $0.path }))
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        for path in filenames {
            // ALERT
            let alert = NSAlert()
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Cancel")
            alert.messageText = "Enter comma separated page ranges:"
            alert.informativeText = (path as NSString).lastPathComponent
            let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
            textField.placeholderString = "1-2,18-19,21"
            alert.accessoryView = textField
            if alert.runModal() != NSAlertFirstButtonReturn { continue }
            
            // PRINT
            var pageRanges = Array<Array<UInt32>>()
            
            // remove characters not in set "0123456789,-"
            let text = textField.stringValue.trimmingCharacters(in: CharacterSet(charactersIn: "0123456789,-").inverted)
            let components = text.components(separatedBy: ",")
            for component in components { 
                pageRanges.append(component.components(separatedBy: "-").flatMap({ UInt32($0) })) 
            }
            
            let printedPageRanges = printPDF(URL(fileURLWithPath: path), pageRanges: pageRanges)
            print("\(path): printed pages in ranges \(printedPageRanges)")
            // /…/file.pdf: printed pages in ranges [[1, 2], [5]]
        }
        
        // QUIT
        NSApp.terminate(nil)
    }
    
    func printPDF(_ fileURL: URL, pageRanges: Array<Array<UInt32>>) -> Array<Array<UInt32>> {
        guard let pdfDocument = PDFDocument(url: fileURL) else { return [] }
        var printInfo = NSPrintInfo()  
        
        // --- Print Panel ---
        let printPanel = NSPrintPanel()
        
        printPanel.options = [
            NSPrintPanelOptions.showsCopies, 
            NSPrintPanelOptions.showsPageSetupAccessory
        ]
                
        if printPanel.runModal(with: printInfo) != NSModalResponseOK {
            return []
        }        
        printInfo = printPanel.printInfo
        
        let printSettingCPtr: PMPrintSettings = OpaquePointer(printInfo.pmPrintSettings()) 
        
        var printedPageRanges = Array<Array<UInt32>>()
        
        for pageRange in pageRanges {
            guard let first = pageRange.first else { continue }
            guard let last = pageRange.last else { continue }
            
            if PMSetPageRange(printSettingCPtr, first, last) == OSStatus(kPMValueOutOfRange) { continue }
            
            PMSetFirstPage(printSettingCPtr, first, false)
            PMSetLastPage(printSettingCPtr, last, false)            
            printInfo.updateFromPMPrintSettings()
            
            guard let nspo: NSPrintOperation = pdfDocument.printOperation(
                for: printInfo, 
                scalingMode: PDFPrintScalingMode.pageScaleNone, 
                autoRotate: true
                ) else { continue }
            
            nspo.jobTitle = fileURL.lastPathComponent
            nspo.showsPrintPanel = false
            if nspo.run() {
                printedPageRanges.append(pageRange)
            }
        }
        
        return printedPageRanges
    }

}

