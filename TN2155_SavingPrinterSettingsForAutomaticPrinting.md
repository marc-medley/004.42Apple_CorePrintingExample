# TN2155 Saving Printer Settings for Automatic Printing<br>_(Unofficial Swift Interpretation)_

_This document provides a possible (unofficial) Swift interpretation of Apple's Objective-C Technical Note [TN2155 Saving Printer Settings for Automatic Printing](https://developer.apple.com/library/content/technotes/tn2155/_index.html) (revision 2007.03.29)._

<a id="toc"></a>
[List Available Printers](#ListAvailablePrinters) |
[Obtain Print Settings via Dialog](#ObtainPrintSettingsviaDialog) |
[Save Print Settings](#SavePrintSettings), 
[Read Print Settings](#ReadPrintSettings) | 
[Validate Printer ID](#ValidatePrinterID) |
[Resources](#Resources)

Printer ID specifies a particular print queue and can be saved in preferences. A `PMPrinter` cannot be saved in preferences.

Approachs to obtain an original `PMPrinter` to use for printing: 

* (simple) choose from a list of available printers, or 
* (detailed) select a printer and print settings using the standard Print & Page Setup dialog boxes. 

### List Available Printers <a id="ListAvailablePrinters"></a>[▴](#toc)

`PMServerCreatePrinterList` returns a `CFArray` of `PMPrinter` which are available and setup.

**Listing 1**  Obtain Available Printers List

``` swift
public static func getAvailablePrinterList() 
    -> (err: OSStatus, printers: CFArray?, printerNames: [String]?) {
    var outPrinters: CFArray? = nil
    var outPrinterNames: [String]? = nil
    
    // Obtain the list of PMPrinters
    var outPrintersUnmanaged: Unmanaged<CFArray>?        
    let err: OSStatus = PMServerCreatePrinterList( nil, &outPrintersUnmanaged )
    outPrinters = outPrintersUnmanaged?.takeUnretainedValue()
    
    if let printerArray = outPrinters {
        var printerNames: [String] = []
        for idx in 0 ..< CFArrayGetCount(printerArray) {
            let printer = PMPrinter(CFArrayGetValueAtIndex(printerArray, idx))!
            let nameUnmanaged: Unmanaged<CFString>? = PMPrinterGetName(printer)
            guard let name = nameUnmanaged?.takeUnretainedValue() as String? else {
                continue
            }
            printerNames.append(name)
        }
        outPrinterNames = printerNames
    }
    
    return (err, outPrinters, outPrinterNames)
}
```

### Obtain Print Settings via Dialog <a id="ObtainPrintSettingsviaDialog"></a>[▴](#toc)

Listing 2 shows how to display a Print Dialog and obtain the printer and print settings in order to reuse them again later.

_NOTE:_

* `PMSessionPageSetupDialog` does not appear to be available for Swift 3.1. 
* `NSPageLayout` can return changes values for `NSPaperName`, `NSPaperSize`, `NSOrientation`, `NSOrientation`  
* `NSPrintSession` can optionally show scale, orientation and paper selection.

**Listing 2**  Obtain Printer information from a Print Dialog

``` swift
public static func getPrintInfoViaPageSetupPanel() 
    -> (session: PMPrintSession, settings: PMPrintSettings, format: PMPageFormat)? {
        
    // Use Page Setup to get a page format
    let printInfo = NSPrintInfo()
    let pageLayout = NSPageLayout()
    if pageLayout.runModal(with: printInfo) == NSModalResponseOK {   
        return ( 
            PMPrintSession(printInfo.pmPrintSession()), 
            PMPrintSettings(printInfo.pmPrintSettings()), 
            PMPageFormat(printInfo.pmPageFormat()) 
        )
    }
    return nil
}

public static func getPrintInfoViaPrintPanel() 
    -> (session: PMPrintSession, settings: PMPrintSettings, format: PMPageFormat)? {
        
    // Use Page Setup to get a page format
    let printInfo = NSPrintInfo()
        
    let printPanel = NSPrintPanel()
    printPanel.setDefaultButtonTitle("Save")
    
    // set NSPrintPanel options as needed
    printPanel.options = [
        NSPrintPanelOptions.showsCopies, // Copies:__ [] B&W [] Two-Sided
        //.showsPageRange,               // Pages: (•) All, ( ) From:__ To:__
        .showsPaperSize,                 // Paper Size: US Letter, …
        .showsOrientation,               // 
        .showsScaling                    // 
        //.showsPrintSelection,          // Pages: ( ) Selection
        // showsPaperSize, showsOrientation, showsScaling affect showsPageSetupAccessory
        //.showsPageSetupAccessory, // Paper Size, Orientation, Scale
        //.showsPreview
    ]
    
    if printPanel.runModal(with: printInfo) == NSModalResponseOK {
        return ( 
            PMPrintSession(printInfo.pmPrintSession()), 
            PMPrintSettings(printInfo.pmPrintSettings()), 
            PMPageFormat(printInfo.pmPageFormat()) 
        )
    }
    return nil
}
```

### Save and Read Print Settings <a id="SavePrintSettings"></a>[▴](#toc)

Listing 3 shows how to save print settings to the application preferences with `CFPreferences`. Listing 4 shows how to recover the printer and print settings from preferences.  `prefix: String` allows an application to have multiple, different Print Preference sets to be stored.

_**Warning: Since a user can easily change the printer configuration, always first verify that the printer is valid.  If the printer is not valid, then ask the user to select a new printer. See Listing 5: `isValidPrinter(inPrinterID: CFString)`**_

**Listing 3**  Save Print Settings via `CFPreferences`

``` swift
public static func savePrintPreferences( 
    session: PMPrintSession, 
    settings: PMPrintSettings, 
    format: PMPageFormat, 
    prefix: String = "" 
    ) -> OSStatus {
    
    let kPrinterID: CFString = "\(prefix)kPrinterIDKey" as CFString
    let kPrintSettings: CFString = "\(prefix)kPrintSettingsKey" as CFString 
    let kPageFormat: CFString = "\(prefix)kPageFormatKey" as CFString 
    
    var printer: PMPrinter = unsafeBitCast(0, to: PMPrinter.self)
    
    var err: OSStatus = noErr
    var tempErr: OSStatus = noErr
    
    // First, attempt to get the current printer from the print session
    // If an error occurs, then simply return that error and do nothing else
    err = PMSessionGetCurrentPrinter( session, &printer )
    if err == noErr {
        // If PMSessionGetCurrentPrinter returns successfully, then the printer is valid
        // for as long as the session is valid, therefore we will assume that the printer name is valid.
        let idUnmanaged: Unmanaged<CFString>? = PMPrinterGetID( printer )
        guard let printerID = idUnmanaged?.takeUnretainedValue() as CFString? else { fatalError() }
        
        // -- Preferences Set: Printer ID --
        CFPreferencesSetAppValue( kPrinterID, printerID, kCFPreferencesCurrentApplication )
        
        // -- Preferences Set: Print Settings --
        var settingsDataUnmanaged: Unmanaged<CFData> = unsafeBitCast(0, to: Unmanaged<CFData>.self)
        tempErr = PMPrintSettingsCreateDataRepresentation(settings, &settingsDataUnmanaged, kPMDataFormatXMLMinimal) 
        if tempErr == noErr  {
            // If print settings are created, then save them to preferences
            let settingsData: CFData = settingsDataUnmanaged.takeUnretainedValue() as CFData
            CFPreferencesSetAppValue( kPrintSettings, settingsData, kCFPreferencesCurrentApplication )
        }
        else {
            // If print settings are not created, then remove them from preferences
            CFPreferencesSetAppValue( kPrintSettings, nil, kCFPreferencesCurrentApplication )
        }
        
        // -- Preferences Set: Page Format --
        var formatDataUnmanaged: Unmanaged<CFData> = unsafeBitCast(0, to: Unmanaged<CFData>.self)
        // kPMDataFormatXMLMinimal, 
        tempErr = PMPageFormatCreateDataRepresentation(format, &formatDataUnmanaged, kPMDataFormatXMLDefault)
        if tempErr == noErr  {
            // If page format data is created, then save data to preferences
            let formatData: CFData = formatDataUnmanaged.takeUnretainedValue() as CFData
            CFPreferencesSetAppValue( kPageFormat, formatData, kCFPreferencesCurrentApplication )
        }
        else {
            // If page format is not created, no change is made
        }
    }
    
    return err;
}
```

**Listing 4**  Read Print Settings via `CFPreferences` <a id="ReadPrintSettings"></a>[▴](#toc)

``` swift
public static func readPrintPreferences(prefix: String = "") 
    -> (id:CFString, settings: PMPrintSettings, format: PMPageFormat)? {
    let kPrinterID: CFString = "\(prefix)kPrinterIDKey" as CFString
    let kPrintSettings: CFString = "\(prefix)kPrintSettingsKey" as CFString 
    let kPageFormat: CFString = "\(prefix)kPageFormatKey" as CFString 
    
    
    var printerID: CFString = "" as CFString
    var printSettings: PMPrintSettings = unsafeBitCast(0, to: PMPrintSettings.self)
    var pageFormat: PMPageFormat = unsafeBitCast(0, to: PMPageFormat.self)
    
    // -- Printer ID -- 
    // load the printer ID via CFPreferences
    guard let outPrinterID: CFPropertyList = CFPreferencesCopyAppValue( 
        kPrinterID,                      // key: CFString
        kCFPreferencesCurrentApplication // applicationID: CFString
        ) else {
            return nil
    }
    
    printerID = outPrinterID as! CFString
    
    // -- Printer Settings --
    guard let settingsPropertyList: CFPropertyList = CFPreferencesCopyAppValue( 
        kPrintSettings, // key: CFString
        kCFPreferencesCurrentApplication // applicationID: CFString
        ) else {
            return nil
    }
    _ = PMPrintSettingsCreateWithDataRepresentation(
        settingsPropertyList as! CFData,  // _ data: CFData 
        &printSettings // _ printSettings: UnsafeMutablePointer<PMPrintSettings>
    )
    
    // -- Page Format --
    guard let formatPropertyList: CFPropertyList = CFPreferencesCopyAppValue( 
        kPageFormat, 
        kCFPreferencesCurrentApplication 
        ) else { 
            return nil 
    }
    _ = PMPageFormatCreateWithDataRepresentation(
        formatPropertyList as! CFData, // _ data: CFData
        &pageFormat // _ pageFormat: UnsafeMutablePointer<PMPageFormat>
    )
    
    return (printerID, printSettings, pageFormat)
}
```


## Validate Printer ID <a id="ValidatePrinterID"></a>[▴](#toc)


Simple routine to check if Print ID is valid prior to each printing operation.

**Listing 5**  Check Printer ID

``` swift
// One approach to validate a printer.
// Alternate approach:
//   attempt to create the printer. 
//   on success, use the printer print. 
//   on failure, ask user to update settings
public static func isValidPrinter(inPrinterID: CFString) -> Bool {
    let printer: PMPrinter? = PMPrinterCreateFromPrinterID(inPrinterID)
    
    var valid = false
    if let _ = printer {
        valid = true
    }
    
    // Be sure to release any non-NULL printer.
    // If printer is `nil`, then PMRelease will return an error code
    // which can be safely ignored.
    PMRelease( PMObject(printer) )
    
    return valid
}
```

## Resources <a id="Resources"></a>[▴](#toc)


[Apple/ApplicationServices: Core Printing ⇗](https://developer.apple.com/documentation/applicationservices/core_printing)  
[Apple/Technical Note: TN2155 Saving Printer Settings for Automatic Printing ⇗](https://developer.apple.com/library/content/technotes/tn2155/_index.html) _2007-03-29_
