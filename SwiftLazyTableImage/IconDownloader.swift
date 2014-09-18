//
//  IconDownloader.swift
//  SwiftLazyTableImage
//
//  Created by Hai Luong Quang on 9/17/14.
//  Copyright (c) 2014 Hai Luong Quang. All rights reserved.
//

import Foundation
import UIKit

class IconDownloader: NSObject, NSURLConnectionDataDelegate {
    
    let kAppIconSize: CGFloat = 48
    var appRecord: AppRecord
    var activeDownload: NSMutableData?
    var imageConnection: NSURLConnection?
    var completionHandler: (Void -> Void)?
    
    override init() {
        self.activeDownload = NSMutableData()
        self.imageConnection = NSURLConnection()
        self.appRecord = AppRecord()
    }
    
    func startDownload() {
        self.activeDownload = NSMutableData.data()
        var request: NSURLRequest = NSURLRequest(URL: NSURL(string: self.appRecord.imageURLString))
        
        // alloc+init and start an NSURLConnection; release on completion/failure
        var conn: NSURLConnection = NSURLConnection(request: request, delegate: self)
        
        self.imageConnection = conn
    }
    
    func cancelDownload() {
        self.imageConnection?.cancel()
        self.imageConnection = nil
        self.activeDownload = nil
    }
    
    //MARK: NSURLConnectionDelegate
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        self.activeDownload?.appendData(data)
    }
    
    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        self.activeDownload = nil
        self.imageConnection = nil
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection) {
        //Set appIcon and clear temporary data/image
        
        var image: UIImage = UIImage(data: self.activeDownload!)
        var width = image.size.width
        var height = image.size.height
        
        if width != kAppIconSize || height != kAppIconSize {
            var itemSize: CGSize = CGSizeMake(kAppIconSize, kAppIconSize)
            UIGraphicsBeginImageContextWithOptions(itemSize, false, 0.0)
            var imageRect: CGRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height)
            image.drawInRect(imageRect)
            self.appRecord.appIcon = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        } else {
            self.appRecord.appIcon = image
        }
        
        self.activeDownload = nil;
        
        // Release the connection now that it's finished
        self.imageConnection = nil;
        
        // call our delegate and tell it that our icon is ready for display
        if ((self.completionHandler) != nil) {
            self.completionHandler!()
        }
    }
}