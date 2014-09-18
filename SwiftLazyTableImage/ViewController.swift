//
//  ViewController.swift
//  SwiftLazyTableImage
//
//  Created by Hai Luong Quang on 9/17/14.
//  Copyright (c) 2014 Hai Luong Quang. All rights reserved.
//

import UIKit

class ViewController: UITableViewController {
    
    let cellIdentifier = "TableCellIdentifier"
    let kCustomRowCount = 7
    
    var entries = []
    var imageDownloadsInProgress = [NSIndexPath: IconDownloader]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    //MARK: Table View DataSource Methods
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var count = self.entries.count
        
        if count == 0 {
            return kCustomRowCount
        }
        
        return count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        // customize the appearance of table view cells
        //
        let placeholderCellIdentifier = "PlaceholderCell"
        var nodeCount = self.entries.count
        
        if (nodeCount == 0 && indexPath.row == 0)
        {
            let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier(placeholderCellIdentifier) as UITableViewCell
            
            cell.detailTextLabel?.text = "Loading..."
            
            return cell;
        }
        
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as UITableViewCell
        
        // Leave cells empty if there's no data yet
        if (nodeCount > 0)
        {
            // Set up the cell...
            var appRecord: AppRecord = self.entries[indexPath.row] as AppRecord
            cell.textLabel?.text = appRecord.appName
            cell.detailTextLabel?.text = appRecord.artist
            
            // Only load cached images; defer new downloads until scrolling ends
            if appRecord.appIcon == nil {
                if (self.tableView.dragging == false && self.tableView.decelerating == false)
                {
                    self.startIconDownload(appRecord, indexPath: indexPath)
                }
                
                // if a download is deferred or in progress, return a placeholder image
                cell.imageView?.image = UIImage(named: "Placeholder.png")

            }
            else
            {
                cell.imageView?.image = appRecord.appIcon
            }
            
        }
        
        return cell;
    }
    
    //MARK: Table cell image support
    
    // -------------------------------------------------------------------------------
    //	startIconDownload:forIndexPath:
    // -------------------------------------------------------------------------------
    func startIconDownload(appRecord: AppRecord, indexPath: NSIndexPath) {
        var iconDownloader: IconDownloader? = self.imageDownloadsInProgress[indexPath]
        
        if (iconDownloader == nil) {
            iconDownloader = IconDownloader()
            iconDownloader?.appRecord = appRecord
            iconDownloader?.completionHandler = {
                let cell: UITableViewCell = self.tableView.cellForRowAtIndexPath(indexPath) as UITableViewCell!
                
                // Display the newly loaded image
                cell.imageView?.image = appRecord.appIcon
                
                // Remove the IconDownloader from the in progress list.
                self.imageDownloadsInProgress[indexPath] = nil
            }
            self.imageDownloadsInProgress[indexPath] = iconDownloader
            iconDownloader?.startDownload()
        }
    }
    
    // -------------------------------------------------------------------------------
    //	loadImagesForOnscreenRows
    //  This method is used in case the user scrolled into a set of cells that don't
    //  have their app icons yet.
    // -------------------------------------------------------------------------------
    func loadImagesForOnscreenRows() {
        if self.entries.count > 0 {
            let visiblePaths = self.tableView.indexPathsForVisibleRows() as [NSIndexPath]
            for indexPath in visiblePaths {
                var appRecord: AppRecord = self.entries.objectAtIndex(indexPath.row) as AppRecord
                
                if appRecord.appIcon == nil {
                    // Avoid the app icon download if the app already has an icon
                    self.startIconDownload(appRecord, indexPath: indexPath)
                }
            }
        }
    }
    
    //MARK: UIScrollViewDelegate
    
    // -------------------------------------------------------------------------------
    //	scrollViewDidEndDragging:willDecelerate:
    //  Load images for all onscreen rows when scrolling is finished.
    // -------------------------------------------------------------------------------
    override func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            self.loadImagesForOnscreenRows()
        }
    }
    
    // -------------------------------------------------------------------------------
    //	scrollViewDidEndDecelerating:
    // -------------------------------------------------------------------------------
    override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        self.loadImagesForOnscreenRows()
    }
}

