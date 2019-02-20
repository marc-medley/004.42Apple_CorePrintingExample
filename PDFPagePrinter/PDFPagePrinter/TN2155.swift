//
//  TN2155.swift
//  PDFPagePrinter
//
//  Created by marc on 2017.07.01.
//  Copyright © 2017 Example. All rights reserved.
//

import Cocoa
import Quartz

public class TN2155 {
    
    /// Obtain available printer list  
    /// 
    /// See also:
    ///
    /// - returns: (err, printers, printerNames)
    public static func getAvailablePrinterList() -> (err: OSStatus, printers: CFArray?, printerNames: [String]?) 
    {
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
    
    /// Obtain print settings from dialog
    public static func getPrintInfoViaPageSetupPanel() 
        -> (session: PMPrintSession, settings: PMPrintSettings, format: PMPageFormat)? {
            
            // Use Page Setup to get a page format
            let printInfo = NSPrintInfo()
            let pageLayout = NSPageLayout()
            if pageLayout.runModal(with: printInfo) == NSApplication.ModalResponse.OK.rawValue {   
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
                NSPrintPanel.Options.showsCopies,      // Copies:__ [] B&W [] Two-Sided
                //.showsPageRange,                     // Pages: (•) All, ( ) From:__ To:__
                NSPrintPanel.Options.showsPaperSize,   // Paper Size: US Letter, …
                NSPrintPanel.Options.showsOrientation, // 
                NSPrintPanel.Options.showsScaling      // 
                //.showsPrintSelection,                // Pages: ( ) Selection
                // showsPaperSize, showsOrientation, showsScaling affect showsPageSetupAccessory
                //.showsPageSetupAccessory, // Paper Size, Orientation, Scale
                //.showsPreview
            ]
            
            if printPanel.runModal(with: printInfo) == NSApplication.ModalResponse.OK.rawValue {
                return ( 
                    PMPrintSession(printInfo.pmPrintSession()), 
                    PMPrintSettings(printInfo.pmPrintSettings()), 
                    PMPageFormat(printInfo.pmPageFormat()) 
                )
            }
            return nil
    }
    
    /// Obtain print settings from dialog
    /// getPageSettingsAndFormat() version accesses PM for some initial setup
    public static func getPrintInfoViaPrintPanel2() -> (
        printSession: PMPrintSession,
        printSettings: PMPrintSettings,
        pageFormat: PMPageFormat
        )? {
            let printInfo = NSPrintInfo()
            
            //let printSession = printInfo.pmPrintSession()
            // PMSessionSetCurrentPMPrinter(session: PMPrintSession, printer: PMPrinter)
            
            // Set any initial PMPageFormat values
            let pageFormat = PMPageFormat(printInfo.pmPageFormat())
            // kPMPortrait, kPMLandscape, kPMReversePortrait, kPMReverseLandscape
            let orientation = PMOrientation(kPMLandscape)
            PMSetOrientation(pageFormat, orientation, false)
            PMSetScale(pageFormat, 72.0)
            printInfo.updateFromPMPageFormat()
            
            // Set any initial PMPrintSettings values
            let printSettings = PMPrintSettings( printInfo.pmPrintSettings() )
            PMSetCopies(printSettings, 3, false)
            // PMSetFirstPage(printSettings: PMPrintSettings, first: UInt32, lock: Bool)
            // PMSetLastPage(printSettings: PMPrintSettings, last: UInt32, lock: Bool)
            // PMSetPageRange(printSettings: PMPrintSettings, minPage: UInt32, maxPage: UInt32)
            // PMPrintSettingsSetJobName(printSettings: PMPrintSettings, name: CFString)
            PMSetCollate(printSettings, true)
            // kPMDuplexNone, kPMDuplexNoTumble, kPMDuplexTumble
            // PMSetDuplex(printSettings: PMPrintSettings, duplexSetting: PMDuplexMode)
            // PMPrinterSetOutputResolution(printer: PMPrinter, printSettings: PMPrintSettings, resolutionP: UnsafePointer<PMResolution>)
            printInfo.updateFromPMPrintSettings()
            
            let printPanel = NSPrintPanel()
            printPanel.setDefaultButtonTitle("Save")
            
            // set NSPrintPanel options as needed
            printPanel.options = [
                NSPrintPanel.Options.showsCopies,      // Copies:__ [] B&W [] Two-Sided
                //.showsPageRange,                     // Pages: (•) All, ( ) From:__ To:__
                NSPrintPanel.Options.showsPaperSize,   // Paper Size: US Letter, …
                NSPrintPanel.Options.showsOrientation, // 
                NSPrintPanel.Options.showsScaling      // 
                //.showsPrintSelection,                // Pages: ( ) Selection
                // showsPaperSize, showsOrientation, showsScaling affect showsPageSetupAccessory
                //.showsPageSetupAccessory, // Paper Size, Orientation, Scale
                //.showsPreview
            ]
            
            if printPanel.runModal(with: printInfo) == NSApplication.ModalResponse.OK.rawValue {
                return ( 
                    PMPrintSession(printInfo.pmPrintSession()), 
                    PMPrintSettings(printInfo.pmPrintSettings()), 
                    PMPageFormat(printInfo.pmPageFormat()) 
                )
            }
            
            return nil
    }
    
    /* ***********************************************************
     :TODO: explore whether using `PMCreateSession(_:)` to obtain a print session has any advantages over `let pmPrintSession = PMPrintSession(printInfo.pmPrintSession())`
     
     :NYI: createPageFormat3() to use PMCreatePageFormat and PMCreatePrintSettings to replace NSPrintInfo PM objects.
     
     ``` swift
     PMSessionCreatePrinterList(PMPrintSession, UnsafeMutablePointer<Unmanaged<CFArray>>, UnsafeMutablePointer<CFIndex>?, UnsafeMutablePointer<PMPrinter>?)
     ```
     
     Use using the function PMCreateSession(_:) to create print session
     see https://developer.apple.com/documentation/applicationservices/1463247-pmcreatesession
     
     Some printing functions can be called only after you have created a printing session object. For example, setting defaults for or validating page format and print settings objects can only be done after you have created a printing session object
     
     • can use a printing session to implement multithreaded printing
     
     • can create multiple sessions within a single-threaded application
     
     • If your application does not use sheets, then your application can open only one dialog at a time  
     
     • Each printing session can have its own dialog, and settings changed in one dialog are independent of settings in any other dialog
     
     ``` objc 
     // not yet translated per se
     OSStatus CreatePrintSettings( PMPageFormat ioFormat, PMPrinter * outPrinter, PMPrintSettings * outSettings)
     {
     PMPrintSession printSession;
     OSStatus err;
     Boolean accepted = false;
     
     *outPrinter = NULL;
     *outSettings = NULL;
     
     // In order to create the Print Settings & select a printer we'll
     // ask the user to create their settings using the Print dialog.
     err = PMCreateSession( &printSession );
     if( !err )
     {
     // Validate the Page Format against the current Printer, which may update
     // that format.
     err = PMSessionValidatePageFormat( printSession, ioFormat, kPMDontWantBoolean );
     
     // Create and default the print settings
     if( !err )
     err = PMCreatePrintSettings( outSettings );
     if( !err )
     err = PMSessionDefaultPrintSettings( printSession, *outSettings );
     
     // Present the Print dialog.
     if( !err )
     err = PMSessionPrintDialog( printSession, *outSettings, ioFormat, &accepted );
     if( !err && accepted )
     {
     // If the user accepted, then we'll retain the printer selected
     // so that it survives the scope of this session.
     // If there is an error getting the printer, then it will
     // remain NULL
     err = PMSessionGetCurrentPrinter( printSession, outPrinter );
     if( !err )
     PMRetain( *outPrinter );
     }
     else
     {
     // We got an error, or the user canceled the operation
     // so we'll release our settings and NULL them out.
     // The PMPrinter hasn't been set yet, so it will remain NULL.
     PMRelease( *outSettings );
     *outSettings = NULL;
     }
     
     PMRelease( printSession );
     }
     return err;
     }
     ```
     
     *********************************************************** */
    
    /// Saving print settings to preferences
    
    public static func savePrintPreferences( 
        data: (session: PMPrintSession, settings: PMPrintSettings, format: PMPageFormat),
        prefix: String = ""
        ) -> OSStatus {
        return savePrintPreferences(session: data.session, settings: data.settings, format: data.format, prefix: prefix)
    }
    
    public static func savePrintPreferences( 
        session: PMPrintSession, 
        settings: PMPrintSettings, 
        format: PMPageFormat, 
        prefix: String = "" 
        ) -> OSStatus {
        let kPrinterID: CFString = "\(prefix)kPrinterIDKey" as CFString
        let kPrintSettings: CFString = "\(prefix)kPrintSettingsKey" as CFString 
        let kPageFormat: CFString = "\(prefix)kPageFormatKey" as CFString 
        
        var printerOptional: PMPrinter?
        
        var err: OSStatus = noErr
        var tempErr: OSStatus = noErr
        
        // First, attempt to get the current printer from the print session
        // If an error occurs, then simply return that error and do nothing else
        err = PMSessionGetCurrentPrinter( session, &printerOptional )
        guard let printer = printerOptional else { return err }
        if err == noErr {
            // If PMSessionGetCurrentPrinter returns successfully, then the printer is valid
            // for as long as the session is valid, therefore we will assume that the printer name is valid.
            let idUnmanaged: Unmanaged<CFString>? = PMPrinterGetID( printer )
            guard let printerID = idUnmanaged?.takeUnretainedValue() as CFString? else { fatalError() }
            
            // -- Preferences Set: Printer ID --
            CFPreferencesSetAppValue( kPrinterID, printerID, kCFPreferencesCurrentApplication )
            
            // -- Preferences Set: Print Settings --
            var settingsDataUnmanagedOptional: Unmanaged<CFData>?
            tempErr = PMPrintSettingsCreateDataRepresentation(settings, &settingsDataUnmanagedOptional, kPMDataFormatXMLMinimal)
            guard let settingsDataUnmanaged = settingsDataUnmanagedOptional else { fatalError() }
            
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
            var formatDataUnmanagedOptional: Unmanaged<CFData>?
            // kPMDataFormatXMLMinimal, 
            tempErr = PMPageFormatCreateDataRepresentation(format, &formatDataUnmanagedOptional, kPMDataFormatXMLDefault)
            guard let formatDataUnmanaged = formatDataUnmanagedOptional else { fatalError() }
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
    
    /// Restore print settings from preferences
    public static func readPrintPreferences(prefix: String = "") 
        -> (id:CFString, settings: PMPrintSettings, format: PMPageFormat)? {
            
            let kPrinterID: CFString = "\(prefix)kPrinterIDKey" as CFString
            let kPrintSettings: CFString = "\(prefix)kPrintSettingsKey" as CFString 
            let kPageFormat: CFString = "\(prefix)kPageFormatKey" as CFString 
            
            var printerID: CFString = "" as CFString
            var printSettingsOptional: PMPrintSettings?
            var pageFormatOptional: PMPageFormat?
            
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
                &printSettingsOptional // _ printSettings: UnsafeMutablePointer<PMPrintSettings>
            )
            guard let printSettings = printSettingsOptional else { fatalError() }
            
            // -- Page Format --
            guard let formatPropertyList: CFPropertyList = CFPreferencesCopyAppValue( 
                kPageFormat, 
                kCFPreferencesCurrentApplication 
                ) else { 
                    return nil 
            }
            _ = PMPageFormatCreateWithDataRepresentation(
                formatPropertyList as! CFData, // _ data: CFData
                &pageFormatOptional // _ pageFormat: UnsafeMutablePointer<PMPageFormat>
            )
            guard let pageFormat = pageFormatOptional else { fatalError() }
            
            return (printerID, printSettings, pageFormat)
    }
    
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
    
    
}
