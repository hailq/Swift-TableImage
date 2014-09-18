//
//  ParseOperation.swift
//  SwiftLazyTableImage
//
//  Created by Hai Luong Quang on 9/17/14.
//  Copyright (c) 2014 Hai Luong Quang. All rights reserved.
//

import Foundation

class ParseOperation: NSOperation, NSXMLParserDelegate {
    var appRecordList = [AppRecord]?()
    var dataToParse: NSData?
    var workingArray = [AppRecord]?()
    var workingEntry: AppRecord?
    var workingPropertyString: String?
    var elementsToParse = []
    var storingCharacterData: Bool
    var errorHandler: (NSError -> Void)?
    
    // string contants found in the RSS feed
    
    let kIDStr     = "id"
    let kNameStr   = "im:name"
    let kImageStr  = "im:image"
    let kArtistStr = "im:artist"
    let kEntryStr  = "entry"
    

    
    init(data: NSData) {
        self.workingPropertyString = nil
        self.storingCharacterData = false
        self.dataToParse = data
        self.elementsToParse = [kIDStr, kNameStr, kImageStr, kArtistStr,]
        
    }
    
    // -------------------------------------------------------------------------------
    //	main
    //  Entry point for the operation.
    //  Given data to parse, use NSXMLParser and process all the top paid apps.
    // -------------------------------------------------------------------------------
    override func main() {
        // The default implemetation of the -start method sets up an autorelease pool
        // just before invoking -main however it does NOT setup an excption handler
        // before invoking -main.  If an exception is thrown here, the app will be
        // terminated.
        self.workingArray = [];
        self.workingPropertyString = "";
        
        
        // It's also possible to have NSXMLParser download the data, by passing it a URL, but this is not
        // desirable because it gives less control over the network, particularly in responding to
        // connection errors.
        //
        var parser: NSXMLParser = NSXMLParser(data: self.dataToParse)
        parser.delegate = self
        parser.parse()
        
        if !self.cancelled {
            self.appRecordList = self.workingArray
        }
        
        self.workingArray = nil
        self.workingPropertyString = nil
        self.dataToParse = nil
        
    }
    
    //MARK: RSS processing
    
    // -------------------------------------------------------------------------------
    //	parser:didStartElement:namespaceURI:qualifiedName:attributes:
    // -------------------------------------------------------------------------------
    func parser(parser: NSXMLParser!, didStartElement elementName: String!, namespaceURI: String!, qualifiedName qName: String!, attributes attributeDict: [NSObject : AnyObject]) {
        // entry: { id (link), im:name (app name), im:image (variable height) }
        //
        
        if elementName == kEntryStr {
            self.workingEntry = AppRecord()
        }
        self.storingCharacterData = self.elementsToParse.containsObject(elementName)
    }
    
    // -------------------------------------------------------------------------------
    //	parser:didEndElement:namespaceURI:qualifiedName:
    // -------------------------------------------------------------------------------
    func parser(parser: NSXMLParser!, didEndElement elementName: String!, namespaceURI: String!, qualifiedName qName: String!) {
        if self.workingEntry != nil {
            if self.storingCharacterData {
                var trimmedString: String = self.workingPropertyString!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                
                // Clear the string for the next time
                self.workingPropertyString = ""
                
                if elementName == kIDStr {
                    self.workingEntry?.appURLString = trimmedString
                } else if elementName == kNameStr {
                    self.workingEntry?.appName = trimmedString
                } else if elementName == kImageStr {
                    self.workingEntry?.imageURLString = trimmedString
                } else if elementName == kArtistStr {
                    self.workingEntry?.artist = trimmedString
                }
            } else if elementName == kEntryStr {
                self.workingArray?.append(self.workingEntry!)
                self.workingEntry = nil
            }
        }
    }
    
    // -------------------------------------------------------------------------------
    //	parser:foundCharacters:
    // -------------------------------------------------------------------------------
    func parser(parser: NSXMLParser!, foundCharacters string: String!) {
        if self.storingCharacterData {
            self.workingPropertyString? += string
        }
    }
    // -------------------------------------------------------------------------------
    //	parser:parseErrorOccurred:
    // -------------------------------------------------------------------------------
    func parser(parser: NSXMLParser!, parseErrorOccurred parseError: NSError) {
        if self.errorHandler != nil {
            self.errorHandler!(parseError)
        }
    }
}