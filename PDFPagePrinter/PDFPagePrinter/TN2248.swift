//
//  TN2248.swift
//  PDFPagePrinter
//
//  Created by marc on 2017.07.01.
//  Copyright © 2017 Example. All rights reserved.
//

import Cocoa
//import Quartz

public class TN2248 {
    
    public static func modifyPrintSettings() {
        // Obtain PrintInfo to be modified.
        // let printInfo = NSPrintInfo.shared() 
        // The application shared() instantance is not persistant between launches.
        let printInfo: NSPrintInfo = NSPrintInfo() // New instance.
        
        // NOTE: Use `Swift.print()` inside NSView subclass to not call `NSView.print()`
        Swift.print("printInfo=\(printInfo)") 
        
        // Get PMPrintSettings object from printInfo.
        // Definition: typealias PMPrintSettings = OpaquePointer
        let settings = PMPrintSettings(printInfo.pmPrintSettings())
        
        // Modify/Set any settings
        PMSetCopies(settings, 10, false) // copies to print
        PMSetCollate(settings, true)     // enable collation
        
        // Notify NSPrintInfo Cocoa object that the print settings have changed.
        printInfo.updateFromPMPrintSettings()
    }
    
    /**
     Completely replace a low level CorePrinting object stored in an NSPrintInfo
     with one you obtain or create.  This code performs no error handling. 
     
     Here are the steps this code takes:
     
     1) Obtain a PMPaper object from those available for the currently selected printer. To do this:
     1a) Obtain the currently selected printer.
     1b) Get an array of the pre-defined papers for that printer.
     1c) Choose a paper from that list that meets your criteria.
     2) Make that paper the current paper for your Cocoa print job. To do this:
     2a) Create a PMPageFormat from the chosen paper.
     2b) Copy that page format into the page format stored in the NSPrintInfo you want to modify.
     2c) Tell Cocoa you have made a change to the PageFormat in the NSPrintInfo.
     */
    public static func replacePageFormat() -> Int {
        
        // Obtain the printInfo to be modified.
        let printInfo = NSPrintInfo()
        
        // Get the PMPrintSession from the printInfo.
        // Definition: typealias PMPrintSession = OpaquePointer
        let printSession = PMPrintSession(printInfo.pmPrintSession())
        
        /// Get the current printer from the session.
        var currentPrinter = unsafeBitCast(0, to: PMPrinter.self)
        PMSessionGetCurrentPrinter(printSession, &currentPrinter)
        
        // Get the array of pre-defined PMPapers this printer supports.
        // PMPrinterGetPaperList(PMPrinter, UnsafeMutablePointer<Unmanaged<CFArray>?>)
        var paperListUnmanaged: Unmanaged<CFArray>?
        let status: OSStatus = PMPrinterGetPaperList(currentPrinter, &paperListUnmanaged)
        if status != noErr { return Int(status) } // place error handling here
        guard let paperList = paperListUnmanaged?.takeUnretainedValue() else { 
            fatalError()
        }
        
        // Pick a paper from the list, using the appropriate criteria for your application.
        // This code simply chooses the first paper in the list. More likely you would use
        // information from your data (perhaps obtained from a database) to determine
        // which paper in the paperList best meets the current need.
        let chosenPaper = PMPaper(CFArrayGetValueAtIndex(paperList, 0))!
        
        // --- EXTRA: shows an approach to handle <Unmanaged<CFString>? ---
        //PMPaperGetPrinterID(PMPaper, UnsafeMutablePointer<Unmanaged<CFString>?>)
        for idx in 0..<CFArrayGetCount(paperList) {
            let paper = PMPaper(CFArrayGetValueAtIndex(paperList, idx))!
            _ = PrintData.getPMPaperInfo(pmPaper: paper)
            var width = 0.0, height = 0.0
            PMPaperGetWidth(paper, &width)
            PMPaperGetHeight(paper, &height)
            print("width=\(width), height=\(height)")
        }
        // --- ------------------------------------------------------- --- 
        
        // Create a PMPageFormat from that paper.
        // func PMCreatePageFormatWithPMPaper(UnsafeMutablePointer<PMPageFormat>, PMPaper) -> OSStatus
        var chosenPageFormat: PMPageFormat = unsafeBitCast(0, to: PMPageFormat.self)
        PMCreatePageFormatWithPMPaper(&chosenPageFormat, chosenPaper)
        
        // Get the PMPageFormat contained in the printInfo.
        let originalFormat = PMPageFormat(printInfo.pmPageFormat())
        
        // Copy over the original format with the new format you want to use.
        //PMCopyPageFormat(formatSrc: PMPageFormat, formatDest: PMPageFormat)
        PMCopyPageFormat(chosenPageFormat, originalFormat)
        
        // Notify Cocoa that page format has changed.
        printInfo.updateFromPMPageFormat()
        
        // Release the PMPageFormat this code created.
        // func PMRelease(_ object: PMObject?) -> OSStatus
        return Int( PMRelease(PMObject(chosenPageFormat)) )
    }
    
}
