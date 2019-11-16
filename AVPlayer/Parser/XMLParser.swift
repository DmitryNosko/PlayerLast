//
//  XMLParser.swift
//  AVPlayer
//
//  Created by Dzmitry Noska on 10/23/19.
//  Copyright © 2019 Dzmitry Noska. All rights reserved.
//

import Foundation
import UIKit

class FeedParser: NSObject, XMLParserDelegate {
    
    private struct Constants {
        static let kEmptyString = ""
        static let kItemTag = "item"
        static let kImageTag = "itunes:image"
        static let kURLTag = "media:content"
        static let kEnclouserTag = "enclosure"
        static let kTitleTag = "title"
        static let kDescriptionTag = "itunes:summary"
        static let kPubDateTag = "pubDate"
        static let kDurationTag = "itunes:duration"
        static let kAuthorTag = "itunes:author"
        static let kVideoType = "videoType"
        static let kAudioType = "audioType"
        static let kURLName = "url"
        static let kHref = "href"
    }
    
    var itemDownloadedHandler: ((PodcastItem) -> Void)?
    var parserDidEndDocumentHandler: (() -> Void)?
    private var rssItems: [PodcastItem] = []
    private var currentElement = Constants.kEmptyString
    private var currentTitle: String = Constants.kEmptyString {
        didSet {
            currentTitle = currentTitle.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }
    }
    private var currentDescription: String = Constants.kEmptyString {
        didSet {
            currentDescription = currentDescription.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }
    }
    private var currentPubDate: String = Constants.kEmptyString {
        didSet {
            currentPubDate = currentPubDate.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }
    }
    private var currentDuration: String = Constants.kEmptyString {
        didSet {
            currentDuration = currentDuration.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }
    }
    private var currentURL: String = Constants.kEmptyString {
        didSet {
            currentURL = currentURL.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }
    }
    private var currentImage: String = Constants.kEmptyString {
        didSet {
            currentImage = currentImage.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }
    }
    private var currentAuthor: String = Constants.kEmptyString {
        didSet {
            currentAuthor = currentAuthor.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }
    }
    
    func parseFeed(url: String) {
        let request = URLRequest(url: URL(string: url)!)
        let urlSession = URLSession.shared
        let task = urlSession.dataTask(with: request) { (data, response, error) in
            guard let data = data else {
                if let error = error {
                    print(error.localizedDescription)
                }
                return
            }
            let parser = XMLParser(data: data)
            parser.delegate = self
            parser.parse()
        }
        task.resume()
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        switch currentElement {
        case Constants.kItemTag:
            currentTitle = Constants.kEmptyString
            currentImage = Constants.kEmptyString
            currentPubDate = Constants.kEmptyString
            currentDescription = Constants.kEmptyString
            currentDuration = Constants.kEmptyString
            currentAuthor = Constants.kEmptyString
        case Constants.kImageTag:
            if let image = attributeDict[Constants.kHref] {
                currentImage = image
            }
        case Constants.kURLTag:
            if let url = attributeDict[Constants.kURLName] {
                currentURL = url
            }
        case Constants.kEnclouserTag:
            if let url = attributeDict[Constants.kURLName] {
                currentURL = url
            }
        default: break
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        switch currentElement {
            case Constants.kTitleTag : currentTitle += string
            case Constants.kDescriptionTag : currentDescription += string
            case Constants.kPubDateTag : currentPubDate += string
            case Constants.kImageTag : currentImage += string
            case Constants.kDurationTag : currentDuration += string
            case Constants.kAuthorTag : currentAuthor += string
        default: break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == Constants.kItemTag {
            var rssItem: PodcastItem?
            var mediaType: MediaType?
            
            if currentURL.last == "4" {
                mediaType = MediaType(rawValue: Constants.kVideoType)
            } else {
                mediaType = MediaType(rawValue: Constants.kAudioType)
            }
            
            rssItem = PodcastItem(identifier:UUID(), itemTitle: currentTitle, itemDescription: currentDescription, itemPubDate: currentPubDate, itemDuration: currentDuration, itemURL: currentURL, itemImage: currentImage, itemAuthor: currentAuthor, itemIsDownloaded: false, itemIsDeleted: false, itemMediaType: mediaType!, itemProgressStatus: ProgressStatus.new)
            itemDownloadedHandler?(rssItem!)
        }
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        DispatchQueue.main.async {
            self.parserDidEndDocumentHandler?()
        }
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print(parseError.localizedDescription)
    }
    
}
