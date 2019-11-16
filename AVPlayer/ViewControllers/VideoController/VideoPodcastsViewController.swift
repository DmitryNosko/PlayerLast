//
//  VideoPlayerViewController.swift
//  AVPlayer
//
//  Created by Dzmitry Noska on 10/23/19.
//  Copyright © 2019 Dzmitry Noska. All rights reserved.
//

import UIKit

class VideoPodcastsViewController: UITableViewController {

    let TED_TALKS_VIDEO_RESOURCE_URL: String = "https://feeds.feedburner.com/tedtalks_video"
    let VIDEO_CELL_IDENTIFIER: String = "Cell"
    let feedParser = FeedParser()
    let coreDataManager = CoreDataManager()
    let userDefaults = UserDefaults.standard
    
    private var displayedVideoItems: [PodcastItem]?
    private var parsedVideoItems: [PodcastItem]?
    var deletedItems: [PodcastItem]?
    var downloadedItems: [PodcastItem]?
    var watchedInProgressItems: [PodcastItem]?
    var allPreviusItems: [PodcastItem]?
    
    lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        indicator.activityIndicatorViewStyle = .gray
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
        setUpNavigationItem()
        indicatorConstraints()
        
        displayedVideoItems = [PodcastItem]()
        parsedVideoItems = [PodcastItem]()
        deletedItems = coreDataManager.deletedItems()
        downloadedItems = coreDataManager.downloadedItems()
        watchedInProgressItems = coreDataManager.wathedInProgressItems()
        allPreviusItems = coreDataManager.fetchItemsBy(predicate: NSPredicate(format: "itemMediaType = %@", "videoType"))
        
        itemWasLoadedHandler()
        coreDataManager.deleteAllFeedItemsForType(type: MediaType.videoType)
        feedParser.parseFeed(url: TED_TALKS_VIDEO_RESOURCE_URL)
        parserDidEndDocumetnHandler()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        allPreviusItems = coreDataManager.fetchItemsBy(predicate: NSPredicate(format: "itemMediaType = %@", "videoType"))
        watchedInProgressItems = coreDataManager.wathedInProgressItems()
        let currentSortValue = userDefaults.integer(forKey: "sort")
        let currentDeleteModeValue = userDefaults.integer(forKey: "delete")
        
        let sortMode = sortPodcastsInMode(podcasts: displayedVideoItems!, asc: currentSortValue)
        displayedVideoItems?.removeAll()
        displayedVideoItems?.append(contentsOf: sortMode)
        
        if currentDeleteModeValue == 1 {
            for item in watchedInProgressItems! {
                coreDataManager.updateItem(item: item)
                for podcast in displayedVideoItems! {
                    if podcast.itemURL == item.itemURL {
                        let index = displayedVideoItems!.firstIndex(where: {$0 == podcast})
                        displayedVideoItems?.remove(at: index!)
                    }
                }
            }
        }
        tableView.reloadSections(IndexSet(integer: 0), with: .left)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let dvi = displayedVideoItems, dvi.count == 0 {
            activityIndicator.startAnimating()
        }
    }
    
    func itemWasLoadedHandler() {
        feedParser.itemDownloadedHandler = {[weak self] (videoItem) in
            DispatchQueue.main.async {
                self?.addParsedFeedItemToFeeds(item: videoItem)
            }
        }
    }
    
    func parserDidEndDocumetnHandler() {
        feedParser.parserDidEndDocumentHandler = {[weak self] in
            self?.activityIndicator.stopAnimating()
            let res = self!.sortPodcastsInMode(podcasts: self!.parsedVideoItems!, asc: self!.userDefaults.integer(forKey: "sort"))
            self?.displayedVideoItems?.append(contentsOf: res)
            DispatchQueue.main.async {
                self?.tableView.reloadSections(IndexSet(integer: 0), with: .left)
            }
        }
    }
    
    func sortPodcastsInMode(podcasts: [PodcastItem], asc: Int) -> [PodcastItem] {
        var sorted = podcasts
        sorted.sort(by: { (item1, item2) -> Bool in
            let date1 = self.dateFromString(str: item1.itemPubDate)
            let date2 = self.dateFromString(str: item2.itemPubDate)
            let res = (date1.compare(date2)).rawValue
            if asc == 0 {
                if res == 1 {
                    return true
                } else {
                    return false
                }
            } else {
                if res == 1 {
                    return false
                } else {
                    return true
                }
            }
        })
        return sorted
    }
    
    func dateFromString(str: String) -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        let date = dateFormatter.date(from: str)
        return date!
    }
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let videoItems = displayedVideoItems else {
            return 0
        }
        return videoItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: VIDEO_CELL_IDENTIFIER, for: indexPath) as! PodcastTableViewCell
        
        if var item = displayedVideoItems?[indexPath.row] {
            var added = false
            for it in watchedInProgressItems! {
                if it.itemTitle == item.itemTitle {
                    item.itemURL = it.itemURL
                    item.itemProgressStatus = ProgressStatus(rawValue: "watched")!
                    cell.item = item
                    added = true
                } else {
                    added = true
                    cell.item = item
                }
            }
            if !added {
                cell.item = item
            }
        }
        cell.layoutSubviews()
        return cell
    }
    
    //MARK: - TableViewDelegate
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            var item = displayedVideoItems?[indexPath.row]
            item?.itemIsDeleted = true
            coreDataManager.updateItem(item: item!)
            displayedVideoItems?.remove(at: indexPath.row)
            parsedVideoItems?.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .left)
            tableView.reloadData()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "showDetails", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier == "showDetails" {
            let destinationVC: DetailsViewController = segue.destination as! DetailsViewController
            if let indexPath = self.tableView.indexPathForSelectedRow {
                if let cell = self.tableView.cellForRow(at: indexPath) {
                    let customCell = cell as? PodcastTableViewCell
                    if var item = customCell!.item {
                        customCell!.item.itemProgressStatus = ProgressStatus(rawValue: ProgressStatus.watched.rawValue)!
                        item.itemProgressStatus = ProgressStatus(rawValue: ProgressStatus.watched.rawValue)!
                        destinationVC.podcastURL = item.itemURL
                        destinationVC.podcastItem = item
                        destinationVC.podcastImage = customCell!.videoImageView.image
                        watchedInProgressItems?.append(item)
                        coreDataManager.updateItem(item: item)
                    }
                }
            }
        }
    }
    
    // Mark: - SetUp's
    
    func setUpTableView() {
        self.tableView.addSubview(activityIndicator)
        self.tableView.separatorStyle = .none
        self.tableView.register(PodcastTableViewCell.self, forCellReuseIdentifier: VIDEO_CELL_IDENTIFIER)
        self.tableView.estimatedRowHeight = 200
    }
    
    func setUpNavigationItem() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshData))
    }
    
    @objc func refreshData() {
        activityIndicator.startAnimating()
        displayedVideoItems?.removeAll()
        parsedVideoItems?.removeAll()
        deletedItems = coreDataManager.deletedItems()
        watchedInProgressItems = coreDataManager.wathedInProgressItems()
        coreDataManager.deleteAllFeedItemsForType(type: MediaType.videoType)
        feedParser.parseFeed(url: TED_TALKS_VIDEO_RESOURCE_URL)
        tableView.reloadSections(IndexSet(integer: 0), with: .left)
    }
    
    //MARK: - Block's
    
    func addParsedFeedItemToFeeds(item: PodcastItem) {
        var newItem: PodcastItem?
        if isDeletedItem(item: item) {
            let isDownloaded = isDownloadedItem(item: item)
            let isWathedInProgress = watchedInProgressStatus(item: item)
            newItem = PodcastItem(identifier: item.identifier, itemTitle: item.itemTitle, itemDescription: item.itemDescription, itemPubDate: item.itemPubDate, itemDuration: item.itemDuration, itemURL: item.itemURL, itemImage: item.itemImage, itemAuthor: item.itemAuthor, itemIsDownloaded:isDownloaded, itemIsDeleted: true, itemMediaType: item.itemMediaType, itemProgressStatus: isWathedInProgress)
                coreDataManager.addItem(item: newItem!)
        } else {
            let isDownloaded = isDownloadedItem(item: item)
                let prevData = getPreviusURL(item: item)
            
                if prevData.0 != "" {
                    newItem = PodcastItem(identifier: item.identifier, itemTitle: item.itemTitle, itemDescription: item.itemDescription, itemPubDate: item.itemPubDate, itemDuration: item.itemDuration, itemURL: prevData.0, itemImage: item.itemImage, itemAuthor: item.itemAuthor, itemIsDownloaded:isDownloaded, itemIsDeleted: false, itemMediaType: item.itemMediaType, itemProgressStatus: prevData.1)
                } else {
                    newItem = PodcastItem(identifier: item.identifier, itemTitle: item.itemTitle, itemDescription: item.itemDescription, itemPubDate: item.itemPubDate, itemDuration: item.itemDuration, itemURL: item.itemURL, itemImage: item.itemImage, itemAuthor: item.itemAuthor, itemIsDownloaded:isDownloaded, itemIsDeleted: false, itemMediaType: item.itemMediaType, itemProgressStatus: item.itemProgressStatus)
                }
                        parsedVideoItems?.append(newItem!)
                        coreDataManager.addItem(item: newItem!)
        }
    }
    
    func getPreviusURL(item: PodcastItem) -> (String, ProgressStatus) {
        var oldUrl: String?
        var progress: ProgressStatus?
        
        for it in allPreviusItems! {
            if it.itemTitle == item.itemTitle {
                oldUrl = it.itemURL
                progress = it.itemProgressStatus
                return (oldUrl!, progress!)
            }
        }
        return ("", ProgressStatus(rawValue: "new")!)
    }
    
    func isDeletedItem(item: PodcastItem) -> Bool {
        var isDeleted = false
        if deletedItems!.count > 0 {
            for it in deletedItems! {
                if item.itemURL == it.itemURL {
                    isDeleted = true
                }
            }
        }
        return isDeleted
    }
    
    func watchedInProgressStatus(item: PodcastItem) -> ProgressStatus {
        var status = ProgressStatus(rawValue: "new")!
        if watchedInProgressItems!.count > 0 {
            for it in watchedInProgressItems! {
                if item.itemTitle == it.itemTitle {
                    status = ProgressStatus(rawValue: "watched")!
                }
            }
        }
        return status
    }
    
    func isDownloadedItem(item: PodcastItem) -> Bool {
        var isDownloaded = false
        if downloadedItems!.count > 0 {
            for it in downloadedItems! {
                if item.itemURL == it.itemURL {
                    isDownloaded = true
                }
            }
        }
        return isDownloaded
    }
    
    func indicatorConstraints() {
        activityIndicator.centerXAnchor.constraint(equalTo: tableView.safeAreaLayoutGuide.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: tableView.safeAreaLayoutGuide.centerYAnchor).isActive = true
    }
    
}
















