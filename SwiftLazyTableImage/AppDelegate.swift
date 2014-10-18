//
//  AppDelegate.swift
//  SwiftLazyTableImage
//
//  Created by Hai Luong Quang on 9/17/14.
//  Copyright (c) 2014 Hai Luong Quang. All rights reserved.
//

import UIKit
import CFNetwork

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, NSURLConnectionDataDelegate {

    let TopPaidAppsFeed = "http://phobos.apple.com/WebObjects/MZStoreServices.woa/ws/RSS/toppaidapplications/limit=75/xml"
    
    var queue: NSOperationQueue?
    // RSS feed network connection to the App Store
    var appListFeedConnection: NSURLConnection?
    var appListData: NSMutableData?
    
    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // Hide status bar
        UIApplication.sharedApplication().statusBarHidden = true
        
        var urlRequest = NSURLRequest(URL: NSURL(string: TopPaidAppsFeed)!)
        self.appListFeedConnection = NSURLConnection(request: urlRequest, delegate: self)
        
        // Test the validity of the connection object. The most likely reason for the connection object
        // to be nil is a malformed URL, which is a programmatic error easily detected during development
        // If the URL is more dynamic, then you should implement a more flexible validation technique, and
        // be able to both recover from errors and communicate problems to the user in an unobtrusive manner.
        //
        assert(self.appListFeedConnection != nil, "Failure to create URL connection.")
        
        // show in the status bar that network activity is starting
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        return true;
    }

    // -------------------------------------------------------------------------------
    //	handleError:error
    // -------------------------------------------------------------------------------
    func handleError(error: NSError) {
        var errorMessage: String = error.localizedDescription

        var alertView = UIAlertView()
        alertView.title = "Cannot Show Top Paid Apps"
        alertView.message = errorMessage
        alertView.delegate = nil
        alertView.addButtonWithTitle("OK")

        alertView.show()
    }
    
    // The following are delegate methods for NSURLConnection. Similar to callback functions, this is how
    // the connection object,  which is working in the background, can asynchronously communicate back to
    // its delegate on the thread from which it was started - in this case, the main thread.
    //
    
    //MARK: NSURLConnectionDelegate methods
    
    // -------------------------------------------------------------------------------
    //	connection:didReceiveResponse:response
    // -------------------------------------------------------------------------------
    func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
        self.appListData = NSMutableData()// start off with new data
    }
    
    // -------------------------------------------------------------------------------
    //	connection:didReceiveData:data
    // -------------------------------------------------------------------------------
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        self.appListData?.appendData(data)
    }
    
    // -------------------------------------------------------------------------------
    //	connection:didFailWithError:error
    // -------------------------------------------------------------------------------
    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        
        if error.code == CFNetworkErrors.CFURLErrorNotConnectedToInternet.hashValue {
            // if we can identify the error, we can present a more precise message to the user.
            var userInfo = ["No Connection Error": NSLocalizedDescriptionKey]
            var noConnecitonError = NSError(domain: NSCocoaErrorDomain, code: CFNetworkErrors.CFURLErrorNotConnectedToInternet.hashValue, userInfo: userInfo)
        } else {
            // otherwise handle the error generically
            self.handleError(error)
        }
        
        self.appListFeedConnection = nil
    }
    
    // -------------------------------------------------------------------------------
    //	connectionDidFinishLoading:connection
    // -------------------------------------------------------------------------------
    func connectionDidFinishLoading(connection: NSURLConnection) {
        self.appListFeedConnection = nil    // Release our connection
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        
        // Create the queue to run our ParserOperation
        self.queue = NSOperationQueue()
        
        // create an ParseOperation (NSOperation subclass) to parse the RSS feed data
        // so that the UI is not blocked
        var parser: ParseOperation = ParseOperation(data: self.appListData!)
        
        parser.errorHandler = {(parseError: NSError) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.handleError(parseError)
            })
        }
        
        // Referencing parser from within its completionBlock would create a retain
        // cycle.
        var weakParser = parser

        parser.completionBlock = {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                // The root rootViewController is the only child of the navigation
                // controller, which is the window's rootViewController.
                
                var viewController: ViewController = self.window?.rootViewController as ViewController

                viewController.entries = weakParser.appRecordList!
                
                // tell our table view to reload its data, now that parsing has completed
                viewController.tableView.reloadData()
            })
            
            // we are finished with the queue and our ParseOperation
            self.queue = nil;
        }
        
        self.queue?.addOperation(parser)    // this will start the "ParseOperation"
        
        // ownership of appListData has been transferred to the parse operation
        // and should no longer be referenced in this thread
        self.appListData = nil;
    }
    
}

