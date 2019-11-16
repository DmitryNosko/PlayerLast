//
//  PodcastItem.swift
//  AVPlayer
//
//  Created by Dzmitry Noska on 11/16/19.
//  Copyright © 2019 Dzmitry Noska. All rights reserved.
//

import Foundation

enum MediaType: String {
    case videoType
    case audioType
    case customType
}

enum ProgressStatus: String {
    case new
    case watched
}

struct PodcastItem : Equatable {
    var identifier: UUID
    var itemTitle: String
    var itemDescription: String
    var itemPubDate: String
    var itemDuration: String
    var itemURL: String
    var itemImage: String
    var itemAuthor: String
    var itemIsDownloaded: Bool
    var itemIsDeleted: Bool
    var itemMediaType: MediaType
    var itemProgressStatus: ProgressStatus
    
    static func == (item1: PodcastItem, item2: PodcastItem) -> Bool {
        return item1.itemURL == item2.itemURL
    }
}
