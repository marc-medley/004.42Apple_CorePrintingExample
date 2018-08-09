# TN2248 Using Cocoa and Core Printing Together<br>_(Unofficial Swift Interpretation)_

_This document provides a possible (unofficial) Swift interpretation of Apple's  Objective-C Technical Note [TN2248 Using Cocoa and Core Printing Together](https://developer.apple.com/library/content/technotes/tn2248/_index.html) (revision 2009.05.27)._

<a id="toc"></a>
| [Modifying Print Settings](#ModifyingPrintSettings) | [Programmatic Paper Selection](#ProgrammaticPaperSelection) | [Resources](#Resources) | 

## Modifying Print Settings <a id="ModifyingPrintSettings">[▴](#toc)</a>


How to modify print settings information that is stored in an NSPrintInfo object. Error handling is not shown.

1. obtain print settings from a printInfo object
2. change the print settings
3. synchronize by notifying Cocoa that the settings have been changed

**Listing 1**  Modify Print Settings.

``` swift
// Obtain PrintInfo to be modified.
// NSPrintInfo init(dictionary: [NSPrintInfo.AttributeKey : Any])
let printInfo: NSPrintInfo = NSPrintInfo()

// NOTE: Use `Swift.print()` inside NSView subclass to not call `NSView.print()`
Swift.print("printInfo=\(printInfo)") 

// Get PMPrintSettings object from printInfo.
let settings: PMPrintSettings = OpaquePointer(printInfo.pmPrintSettings())

// Modify/Set any settings
PMSetCopies(settings, 10, false) // copies to print
PMSetCollate(settings, true)     // enable collation

// Notify Cocoa that the print settings have changed.
printInfo.updateFromPMPrintSettings()
```

## Programmatic Paper Selection <a id="ProgrammaticPaperSelection">[▴](#toc)</a>


This code snippet illustrates how to replace one of the low level Core Printing objects stored in an NSPrintInfo with a custom object you obtain or create.

1. Obtain a PMPaper object from those available for the currently selected printer. To do this:
    * Obtain the currently selected printer.
    * Get an array of the pre-defined papers for that printer.
    * Choose a paper from that list that meets your criteria.
2. Make that paper the current paper for your Cocoa print job. To do this:
    * Create a PMPageFormat from the chosen paper.
    * Copy that page format into the page format stored in the NSPrintInfo you want to modify.
    * Tell Cocoa you have made a change to the PageFormat in the NSPrintInfo.

**Listing 2**  Replacing the PageFormat object.

``` swift
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
        _ = PrintUtil.getPMPaperInfo(pmPaper: paper)
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
```

## Resources <a id="Resources">[▴](#toc)</a>


[Apple/ApplicationServices: Core Printing ⇗](https://developer.apple.com/documentation/applicationservices/core_printing)  
[Apple/TechnicalNote: TN2248 Using Cocoa and Core Printing Together ⇗](https://developer.apple.com/library/content/technotes/tn2248/_index.html) _2009-05-27_

  

