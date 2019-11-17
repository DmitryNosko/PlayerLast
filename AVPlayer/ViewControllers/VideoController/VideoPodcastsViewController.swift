//
//  VideoPlayerViewController.swift
//  AVPlayer
//
//  Created by Dzmitry Noska on 10/23/19.
//  Copyright © 2019 Dzmitry Noska. All rights reserved.
//

import UIKit

class VideoPodcastsViewController: UITableViewController {
    
    private struct Constants {
        static let kTedTalksVideoPodcastr = "https://feeds.feedburner.com/tedtalks_video"
        static let kVideoCellIdentifier = "Cell"
        static let kItemMediaTypeVideo = "videoType"
        static let kSettingsSort = "sort"
        static let kSettingsDelete = "delete"
        static let kSegueShowDetailsID = "showDetails"
        static let kProgressStatusWathed = "watched"
        static let kProgressStatusNew = "new"
        static let kEmptyString = ""
    }

    let feedParser = FeedParser()
    let coreDataManager = CoreDataManager()
    let userDefaults = UserDefaults.standard
    
    private var displayedVideoItems: [PodcastItem]?
    private var parsedVideoItems: [PodcastItem]?
    private var deletedItems: [PodcastItem]?
    private var downloadedItems: [PodcastItem]?
    private var watchedInProgressItems: [PodcastItem]?
    private var allPreviusItems: [PodcastItem]?
    
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
        allPreviusItems = coreDataManager.fetchItemsBy(predicate: NSPredicate(format: "itemMediaType = %@", Constants.kItemMediaTypeVideo))
        feedParser.parseFeed(url: Constants.kTedTalksVideoPodcastr)
        itemWasLoadedHandler()
        parserDidEndDocumetnHandler()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        prepareDisplayedContentItems()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let dvi = displayedVideoItems, dvi.count == 0 {
            activityIndicator.startAnimating()
        }
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let videoItems = displayedVideoItems else {
            return 0
        }
        return videoItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.kVideoCellIdentifier, for: indexPath) as! PodcastTableViewCell
        
        if var item = displayedVideoItems?[indexPath.row] {
            var added = false
            for it in watchedInProgressItems! {
                if it.itemTitle == item.itemTitle {
                    item.itemURL = it.itemURL
                    item.itemProgressStatus = ProgressStatus(rawValue: Constants.kProgressStatusWathed)!
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
        performSegue(withIdentifier: Constants.kSegueShowDetailsID, sender: self)
    }
    
    //MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.kSegueShowDetailsID {
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
    
    //MARK: parser handlers
    
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
            let res = self!.sortPodcastsInMode(podcasts: self!.parsedVideoItems!, asc: self!.userDefaults.integer(forKey: Constants.kSettingsSort))
            self?.displayedVideoItems?.append(contentsOf: res)
            DispatchQueue.main.async {
                self?.tableView.reloadSections(IndexSet(integer: 0), with: .left)
            }
        }
    }
    
    func addParsedFeedItemToFeeds(item: PodcastItem) {
        var newItem: PodcastItem?
        
        if item.isDeletedItem(deleted: deletedItems) {
            let isDownloaded = isDownloadedItem(item: item)
            let isWathedInProgress = item.watchedInProgressStatus(watched: watchedInProgressItems)
            newItem = PodcastItem(identifier: item.identifier, itemTitle: item.itemTitle, itemDescription: item.itemDescription, itemPubDate: item.itemPubDate, itemDuration: item.itemDuration, itemURL: item.itemURL, itemImage: item.itemImage, itemAuthor: item.itemAuthor, itemIsDownloaded:isDownloaded, itemIsDeleted: true, itemMediaType: item.itemMediaType, itemProgressStatus: isWathedInProgress)
            coreDataManager.addItem(item: newItem!)
        } else {
            let isDownloaded = isDownloadedItem(item: item)
            let prevData = getPreviusData(item: item)
            var url = item.itemURL
            var status = item.itemProgressStatus
            
            if prevData.0 != Constants.kEmptyString {
                url = prevData.0
                status = prevData.1
            }

            newItem = PodcastItem(identifier: item.identifier, itemTitle: item.itemTitle, itemDescription: item.itemDescription, itemPubDate: item.itemPubDate, itemDuration: item.itemDuration, itemURL: url, itemImage: item.itemImage, itemAuthor: item.itemAuthor, itemIsDownloaded:isDownloaded, itemIsDeleted: false, itemMediaType: item.itemMediaType, itemProgressStatus: status)
            parsedVideoItems?.append(newItem!)
            coreDataManager.addItem(item: newItem!)
        }
    }
    
    func getPreviusData(item: PodcastItem) -> (String, ProgressStatus) {
        var oldUrl: String?
        var progress: ProgressStatus?
        
        for it in allPreviusItems! {
            if it.itemTitle == item.itemTitle {
                oldUrl = it.itemURL
                progress = it.itemProgressStatus
                return (oldUrl!, progress!)
            }
        }
        return (Constants.kEmptyString, ProgressStatus(rawValue: Constants.kProgressStatusNew)!)
    }

    // Mark: - VK SetUp's
    
    func setUpTableView() {
        self.tableView.addSubview(activityIndicator)
        self.tableView.separatorStyle = .none
        self.tableView.register(PodcastTableViewCell.self, forCellReuseIdentifier: Constants.kVideoCellIdentifier)
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
        coreDataManager.deleteAllItemsForMediaType(type: MediaType.videoType)
        feedParser.parseFeed(url: Constants.kTedTalksVideoPodcastr)
        tableView.reloadSections(IndexSet(integer: 0), with: .left)
    }
    
    func prepareDisplayedContentItems() {
        allPreviusItems = coreDataManager.fetchItemsBy(predicate: NSPredicate(format: "itemMediaType = %@", Constants.kItemMediaTypeVideo))
        watchedInProgressItems = coreDataManager.wathedInProgressItems()
        let currentSortValue = userDefaults.integer(forKey: Constants.kSettingsSort)
        let currentDeleteModeValue = userDefaults.integer(forKey: Constants.kSettingsDelete)
        
        let sortMode = sortPodcastsInMode(podcasts: displayedVideoItems!, asc: currentSortValue)
        displayedVideoItems?.removeAll()
        displayedVideoItems?.append(contentsOf: sortMode)
        
        if currentDeleteModeValue == 1 {
            for item in watchedInProgressItems! {
                coreDataManager.updateItem(item: item)
                for podcast in displayedVideoItems! {
                    if podcast.itemURL == item.itemURL {
                        let index = displayedVideoItems?.index(of: podcast)
                        //let index = displayedVideoItems!.firstIndex(where: {$0 == podcast})
                        displayedVideoItems?.remove(at: index!)
                    }
                }
            }
        }
        
        tableView.reloadSections(IndexSet(integer: 0), with: .left)
        coreDataManager.deleteAllItemsForMediaType(type: MediaType.videoType)
    }
    
    func sortPodcastsInMode(podcasts: [PodcastItem], asc: Int) -> [PodcastItem] {
        var sorted = podcasts
        sorted.sort(by: { (item1, item2) -> Bool in
            let date1 = Date.dateFromString(str: item1.itemPubDate)
            let date2 = Date.dateFromString(str: item2.itemPubDate)
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
    
    //MARK: - Other
    
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
    
    //MARK: - Constraintrs
    
    func indicatorConstraints() {
        activityIndicator.centerXAnchor.constraint(equalTo: tableView.safeAreaLayoutGuide.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: tableView.safeAreaLayoutGuide.centerYAnchor).isActive = true
    }
    
}
















