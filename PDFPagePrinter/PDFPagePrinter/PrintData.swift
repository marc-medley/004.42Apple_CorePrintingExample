//
//  PrintData.swift
//  PDFPagePrinter
//
//  Created by marc on 2017.07.04.
//  Copyright © 2017 Example. All rights reserved.
//

import Foundation

public class PrintData {
    
    public static func getPMPageFormatInfo(pmPageFormat: PMPageFormat) -> Dictionary<String, Any> {
        var d = Dictionary<String, Any>()
        
        //PMGetPageFormatExtendedData(pmPageFormat, 
        //                            _ dataID: OSType, 
        //    _ size: UnsafeMutablePointer<UInt32>?, 
        //    _ extendedData: UnsafeMutableRawPointer?)
        
        var pmPaper = unsafeBitCast(0, to: PMPaper.self)
        PMGetPageFormatPaper(pmPageFormat, &pmPaper)
        d["pmPaper"] = getPMPaperInfo(pmPaper: pmPaper)
        
        var printerIDUnmanaged: Unmanaged<CFString>?
        _ = PMPageFormatGetPrinterID(pmPageFormat, &printerIDUnmanaged)
        if let printerID = printerIDUnmanaged?.takeUnretainedValue() {
            d["printerID"] = printerID as String
        }
        
        // kPMPortrait, kPMLandscape, kPMReversePortrait, kPMReverseLandscape
        var orientation = PMOrientation(kPMPortrait)
        _ = PMGetOrientation(pmPageFormat, &orientation)
        d["orientation"] = orientation
        
        var scale: Double = 100.0
        _ = PMGetScale(pmPageFormat, &scale)
        d["scale"] = scale
        
        var adjustedPageRect = PMRect(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        _ = PMGetAdjustedPageRect(pmPageFormat, &adjustedPageRect) 
        d["pageRectAdjusted"] = adjustedPageRect
        
        var adjustedPaperRect = PMRect(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        _ = PMGetAdjustedPaperRect(pmPageFormat, &adjustedPaperRect)
        d["paperRectAdjusted"] = adjustedPaperRect
        
        var unadjustedPageRect = PMRect(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        _ = PMGetUnadjustedPageRect(pmPageFormat, &unadjustedPageRect)
        d["pageRectUnadjusted"] = unadjustedPageRect
        
        // 
        var unadjustedPaperRect = PMRect(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        _ = PMGetUnadjustedPaperRect(pmPageFormat, &unadjustedPaperRect)
        d["paperRectUnadjusted"] = unadjustedPaperRect
        
        return d
    }
    
    public static func getPMPaperInfo(pmPaper: PMPaper) -> Dictionary<String, Any> {
        var d = Dictionary<String, Any>()
        
        // func PMPaperGetPPDPaperName(_ paper: PMPaper, _ paperName: UnsafeMutablePointer<Unmanaged<CFString>?>)
        var ppdPaperNameUnmanaged: Unmanaged<CFString>?
        PMPaperGetPPDPaperName(pmPaper, &ppdPaperNameUnmanaged)
        if let ppdPaperName: CFString = ppdPaperNameUnmanaged?.takeUnretainedValue() {
            d["ppdPaperName"] = ppdPaperName as String
        }
        
        // func PMPaperGetID(PMPaper, UnsafeMutablePointer<Unmanaged<CFString>>)
        var paperIDUnmanaged: Unmanaged<CFString> = unsafeBitCast(0, to: Unmanaged<CFString>.self)
        PMPaperGetID(pmPaper, &paperIDUnmanaged)
        let paperID: CFString = paperIDUnmanaged.takeUnretainedValue()
        d["paperID"] = paperID as String
        
        // func PMPaperGetWidth(PMPaper, UnsafeMutablePointer<Double>)
        var width: Double = 0.0
        PMPaperGetWidth(pmPaper, &width)
        d["width"] = width
        d["widthInch"] = width / 72.0
        
        // func PMPaperGetHeight(PMPaper, UnsafeMutablePointer<Double>)
        var height: Double = 0.0
        PMPaperGetHeight(pmPaper, &height)
        d["height"] = height
        d["heightInch"] = height / 72.0
        
        // typealias PMPaperMargins = PMRect
        // https://developer.apple.com/documentation/applicationservices/pmrect
        // func PMPaperGetMargins(PMPaper, UnsafeMutablePointer<PMPaperMargins>)
        var pmPaperMargins = PMPaperMargins(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        PMPaperGetMargins(pmPaper, &pmPaperMargins)
        d["pmPaperMargins"] = pmPaperMargins
        
        // func PMPaperCreateLocalizedName(PMPaper, PMPrinter, UnsafeMutablePointer<Unmanaged<CFString>?>)        
        
        // func PMPaperGetPrinterID(PMPaper, UnsafeMutablePointer<Unmanaged<CFString>?>)
        var printerIDUnmanaged: Unmanaged<CFString>?
        PMPaperGetPrinterID(pmPaper, &printerIDUnmanaged)
        if let printerIDCFString = printerIDUnmanaged?.takeUnretainedValue() { 
            let printerID = printerIDCFString as String
            d["printerID"] = printerID
        }
        
        return d
    } 
    
    public static func getPMPrinterInfo(pmPrinter: PMPrinter) -> Dictionary<String, Any> {
        // https://developer.apple.com/documentation/applicationservices/core_printing
        var d = Dictionary<String, Any>()
        
        // Printer ID
        let idUnmanaged: Unmanaged<CFString>? = PMPrinterGetID(pmPrinter)
        if let printerID = idUnmanaged?.takeUnretainedValue() as String? {
            d["printerID"] = printerID
        }        
        
        // Host Name
        var hostNameUnmanaged: Unmanaged<CFString> = unsafeBitCast(0, to: Unmanaged<CFString>.self)
        let _ = PMPrinterCopyHostName(pmPrinter, &hostNameUnmanaged)
        let hostName = hostNameUnmanaged.takeUnretainedValue() as String
        d["hostName"] = String(hostName)
  
        // Device URI
        var printerDeviceURIUnmanaged: Unmanaged<CFURL>?
        let _ = PMPrinterCopyDeviceURI(pmPrinter, &printerDeviceURIUnmanaged)
        if let printerDeviceURI: CFURL = printerDeviceURIUnmanaged?.takeUnretainedValue() {
            d["printerDeviceURI"] = printerDeviceURI as URL
            // "You are responsible for releasing the URL."
        }
        
        // Description File URI
        var printerDescriptionURLUnmanaged: Unmanaged<CFURL>?
        let _ = PMPrinterCopyDescriptionURL(pmPrinter, kPMPPDDescriptionType as CFString, &printerDescriptionURLUnmanaged)
        if let printerDescriptionURL = printerDescriptionURLUnmanaged?.takeUnretainedValue() as URL? {
            d["printerDescriptionURL"] = printerDescriptionURL
        }
        
        // Communication Channel Info
        var supportsControlCharRangeP: DarwinBoolean = false
        var supportsEightBitP: DarwinBoolean = false
        let _ = PMPrinterGetCommInfo(pmPrinter, &supportsControlCharRangeP, &supportsEightBitP)
        d["commChannelSupportsControlChar"] = supportsControlCharRangeP.boolValue
        d["commChannelSupportsEightBit"] = supportsEightBitP.boolValue

        // Printer Human Readable Name
        let nameUnmanaged: Unmanaged<CFString>? = PMPrinterGetName(pmPrinter)
        if let name = nameUnmanaged?.takeUnretainedValue() as String? {
            d["nameReadble"] = name
        }
        
        // Printer Location (may be user created)
        let locationUnmanaged: Unmanaged<CFString>? = PMPrinterGetLocation(pmPrinter)
        if let location = locationUnmanaged?.takeUnretainedValue() as String? {
            d["location"] = location
        }
        
        // Manufacturer & Model
        var modelUnmanaged: Unmanaged<CFString>?
        let _ = PMPrinterGetMakeAndModelName(pmPrinter, &modelUnmanaged)
        if let model = modelUnmanaged?.takeUnretainedValue() as String? {
            d["model"] = model
        }
        
        // Resolution
        var resolutionCount: UInt32 = 0
        let result = PMPrinterGetPrinterResolutionCount(pmPrinter, &resolutionCount)
        if result == Int32(kPMNotImplemented) {
            d["resolutionCount"] = -1
        }
        else {
            d["resolutionCount"] = resolutionCount
            var resolutionList = [PMResolution]()
            for idx:UInt32 in 1...resolutionCount {
                var pmResolution = PMResolution() 
                let _ = PMPrinterGetIndexedPrinterResolution(pmPrinter, idx, &pmResolution)
                resolutionList.append(pmResolution)
                // CHECK: pmResolution.hRes x pmResolution.vRes
            }
            d["resolutionList"] = resolutionList
        }
        
        // Printer State
        var printerState: PMPrinterState = 0
        let _ = PMPrinterGetState(pmPrinter, &printerState)
        d["printerState"] = printerState
        switch printerState {
        case UInt16(kPMPrinterIdle) :
            d["printerStateName"] = "kPMPrinterIdle"
        case UInt16(kPMPrinterProcessing) :
            d["printerStateName"] = "kPMPrinterProcessing"
        case UInt16(kPMPrinterStopped) :
            d["printerStateName"] = "kPMPrinterStopped"
        default:
            d["printerStateName"] = "UNSPECIFIED"
        }

        // Default
        d["isDefaultPrinter"] = PMPrinterIsDefault(pmPrinter)
        
        // Favorite
        d["isFavoritePrinter"] = PMPrinterIsFavorite(pmPrinter)
        
        // Postscript Capable.  possibly rendered via macOS printing system
        d["isPostscriptCapable"] = PMPrinterIsPostScriptCapable(pmPrinter)
        
        // Postscript Printer. printer is a postscript printer
        var isPostScriptPrinter: DarwinBoolean = false
        let _ = PMPrinterIsPostScriptPrinter(pmPrinter, &isPostScriptPrinter)
        d["isPostscriptCapable"] = isPostScriptPrinter.boolValue
        
        // Remote Printer
        var isRemotePrinter: DarwinBoolean = false
        let _ = PMPrinterIsRemote(pmPrinter, &isRemotePrinter)
        d["isRemote"] = isRemotePrinter.boolValue

        // Driver Creater. 4-byte creater code. 'APPL' is Apple
        var osType: OSType = UInt32(0)
        let _ = PMPrinterGetDriverCreator(pmPrinter, &osType)
        d["osType"] = String(format: "%c", osType)
        
        // Driver Version (use here for information only)
        // Note: application use of version can make application version dependent.
        //var versionRecord:VersRec // Error: Use of undeclared type 'VersRec'
        //let _ = PMPrinterGetDriverReleaseInfo(pmPrinter, &versionRecord)
        
        // Language Information
        // uses Darwin.Str32 aka Str32
        var pmLanguageInfo: PMLanguageInfo = PMLanguageInfo() 
        var _ = PMPrinterGetLanguageInfo(pmPrinter, &pmLanguageInfo)
        d["pmLanguageInfo"] = [
            "level" : darwinStr32ToString(darwinStr32: pmLanguageInfo.level), 
            "version" : darwinStr32ToString(darwinStr32: pmLanguageInfo.version), 
            "release" : darwinStr32ToString(darwinStr32: pmLanguageInfo.release)
        ]
        
        // MIME Types
        // typically used in conjunction with func PMPrinterPrintWithFile(_:_:_:_:_:)
        var mimeTypeArray = [String]()
        var mimeTypesUnmanaged: Unmanaged<CFArray>?
        let settings: PMPrintSettings? = nil
        var _ = PMPrinterGetMimeTypes(pmPrinter, settings, &mimeTypesUnmanaged)
        if let mimeTypes = mimeTypesUnmanaged?.takeUnretainedValue() { 
            for idx in 0..<CFArrayGetCount(mimeTypes) {
                let mime: CFString = unsafeBitCast(CFArrayGetValueAtIndex(mimeTypes, idx), to: CFString.self)
                mimeTypeArray.append(mime as String)
            }
            d["mimeTypes"] = mimeTypeArray
        }
        
        // Printer Presets
        // use PMPrinterCopyPresets(_:_:) to obtain available presets
        // use PMPresetGetAttributes(_:_:) to obtain preset information
        // use PMPresetCreatePrintSettings(_:_:_:) to create a print settings object
        var presetArray = Array<CFDictionary>()
        var presetListUnmanaged: Unmanaged<CFArray>?
        let _ = PMPrinterCopyPresets(pmPrinter, &presetListUnmanaged)
        if let presetList = presetListUnmanaged?.takeUnretainedValue() { 
            for idx in 0..<CFArrayGetCount(presetList) {
                let preset = PMPreset( CFArrayGetValueAtIndex(presetList, idx) )!
                var attributesUnmanaged: Unmanaged<CFDictionary>?
                let _ = PMPresetGetAttributes(preset, &attributesUnmanaged)
                if let attributes: CFDictionary = attributesUnmanaged?.takeUnretainedValue() {
                    presetArray.append(attributes)
                }
            }
            d["presets"] = presetArray
        }

        
        // Printer Paper List
        // Get the array of pre-defined PMPapers this printer supports.
        // PMPrinterGetPaperList(PMPrinter, UnsafeMutablePointer<Unmanaged<CFArray>?>)
        var paperArray = Array<Dictionary<String, Any>>()
        var paperListUnmanaged: Unmanaged<CFArray>?
        let _ = PMPrinterGetPaperList(pmPrinter, &paperListUnmanaged)
        if let paperList = paperListUnmanaged?.takeUnretainedValue() { 
            //PMPaperGetPrinterID(PMPaper, UnsafeMutablePointer<Unmanaged<CFString>?>)
            for idx in 0..<CFArrayGetCount(paperList) {
                let paper = PMPaper(CFArrayGetValueAtIndex(paperList, idx))!
                paperArray.append(getPMPaperInfo(pmPaper: paper))
            }
            d["paperList"] = paperArray
        }
        
        return d
    }
    
    public static func getPMPrintSessionInfo(pmPrintSession: PMPrintSession) -> Dictionary<String, Any> {
        var d = Dictionary<String, Any>()
        
        var currentPrinter = unsafeBitCast(0, to: PMPrinter.self) 
        PMSessionGetCurrentPrinter(pmPrintSession, &currentPrinter)
        d["currentPrinter"] = getPMPrinterInfo(pmPrinter: currentPrinter)
        
        // PMSessionGetCGGraphicsContext(_ printSession: PMPrintSession, 
        //                              _ context: UnsafeMutablePointer<Unmanaged<CGContext>?>)
        
        // kPMDestinationPrinter, kPMDestinationFile, kPMDestinationFax, kPMDestinationPreview, kPMDestinationProcessPDF
        // PMSessionGetDestinationType(_ printSession: PMPrintSession, 
        //                            _ printSettings: PMPrintSettings, 
        //    _ destTypeP: UnsafeMutablePointer<PMDestinationType>)
        
        // PMSessionCopyDestinationFormat(_ printSession: PMPrintSession, 
        //                               _ printSettings: PMPrintSettings, 
        //    _ destFormatP: UnsafeMutablePointer<Unmanaged<CFString>?>)
        
        // PMSessionCopyDestinationLocation(_ printSession: PMPrintSession, 
        //                                 _ printSettings: PMPrintSettings, 
        //    _ destLocationP: UnsafeMutablePointer<Unmanaged<CFURL>?>) -> OSStatus
        
        // PMSessionCopyOutputFormatList(_ printSession: PMPrintSession, 
        //                               _ destType: PMDestinationType, 
        //    _ documentFormatP: UnsafeMutablePointer<Unmanaged<CFArray>?>) -> OSStatus
        
        // PMSessionCreatePrinterList(_ printSession: PMPrintSession, 
        //                           _ printerList: UnsafeMutablePointer<Unmanaged<CFArray>>, 
        //    _ currentIndex: UnsafeMutablePointer<CFIndex>?, 
        //    _ currentPrinter: UnsafeMutablePointer<PMPrinter>?) -> OSStatus

        return d
    }
    
    public static func getPMPrintSettingsInfo(pmPrintSettings: PMPrintSettings) -> Dictionary<String, Any> {
        var d = Dictionary<String, Any>()
        
        //var options: UnsafeMutablePointer<Int8>?
        //PMPrintSettingsToOptions(pmPrintSettings, &options)
        
        var first: UInt32 = 1
        PMGetFirstPage(pmPrintSettings, &first) 
        d["first"] = Int(first)
        
        var last: UInt32 = 1
        PMGetLastPage(pmPrintSettings, &last) 
        d["last"] = Int(last)
       
        var minPage: UInt32 = 1
        var maxPage: UInt32 = 1
        PMGetPageRange(pmPrintSettings, &minPage, &maxPage)
        d["range"] = ["min": Int(minPage), "max": Int(maxPage)]
        
        var nameUnmanaged: Unmanaged<CFString>?
        PMPrintSettingsGetJobName(pmPrintSettings, &nameUnmanaged)
        if let name: CFString = nameUnmanaged?.takeUnretainedValue() {
            d["name"] = name as String
        }
        
        var copies: UInt32 = 0
        PMGetCopies(pmPrintSettings, &copies)
        d["copies"] = Int(copies)
       
        var collate = DarwinBoolean(false) 
        PMGetCollate(pmPrintSettings, &collate)
        d["collate"] = collate.boolValue
       
        var duplexMode: PMDuplexMode = PMDuplexMode(kPMDuplexNone)
        PMGetDuplex(pmPrintSettings, &duplexMode)
        d["duplexMode"] = Int(duplexMode)
        
        return d
    }
    
    private static func darwinStr32ToString( darwinStr32 ds: Darwin.Str32 ) -> String {
        // typealias Str32 = (UInt8, UInt8, …, UInt8, UInt8) // 33 element tuple
        // NOTE: currently, iterating on a tuple is not native to Swift and rather impractical
        
        var a: [UInt8] = []
        // ds.0 is a byte count
        if ds.1 != 0 { a.append(ds.1) }
        if ds.2 != 0 { a.append(ds.2) }
        if ds.3 != 0 { a.append(ds.3) }
        if ds.4 != 0 { a.append(ds.4) }
        if ds.5 != 0 { a.append(ds.5) }
        if ds.6 != 0 { a.append(ds.6) }
        if ds.7 != 0 { a.append(ds.7) }
        if ds.8 != 0 { a.append(ds.8) }
        if ds.9 != 0 { a.append(ds.9) }
        if ds.10 != 0 { a.append(ds.10) }
        if ds.11 != 0 { a.append(ds.11) }
        if ds.12 != 0 { a.append(ds.12) }
        if ds.13 != 0 { a.append(ds.13) }
        if ds.14 != 0 { a.append(ds.14) }
        if ds.15 != 0 { a.append(ds.15) }
        if ds.16 != 0 { a.append(ds.16) }
        if ds.17 != 0 { a.append(ds.17) }
        if ds.18 != 0 { a.append(ds.18) }
        if ds.19 != 0 { a.append(ds.19) }
        if ds.20 != 0 { a.append(ds.20) }
        if ds.21 != 0 { a.append(ds.21) }
        if ds.22 != 0 { a.append(ds.22) }
        if ds.23 != 0 { a.append(ds.23) }
        if ds.24 != 0 { a.append(ds.24) }
        if ds.25 != 0 { a.append(ds.25) }
        if ds.26 != 0 { a.append(ds.26) }
        if ds.27 != 0 { a.append(ds.27) }
        if ds.28 != 0 { a.append(ds.28) }
        if ds.29 != 0 { a.append(ds.29) }
        if ds.30 != 0 { a.append(ds.30) }
        if ds.31 != 0 { a.append(ds.31) }
        if ds.32 != 0 { a.append(ds.32) }

        return String(bytes: a, encoding: String.Encoding.utf8)!
    }
    
    private static func darwinStr32FromString( inStr: String ) -> Darwin.Str32 {
        // NOTE: currently, iterating on a tuple is not native to Swift and rather impractical
        var a: [UInt8] = Array(inStr.utf8)
        var i = a.count
        while i < 32 {
            a.append(0)
            i = i + 1
        }
        
        let outStr32: Darwin.Str32 = (
            UInt8(a.count), 
            a[0], a[1], a[2], a[3], a[4], a[5], a[6], a[7], 
            a[8], a[9], a[10], a[11], a[12], a[13], a[14], a[15], 
            a[16], a[17], a[18], a[19], a[20], a[21], a[22], a[23], 
            a[24], a[25], a[26], a[26], a[28], a[29], a[30], a[31]
        )
        
        return outStr32
    }
}
