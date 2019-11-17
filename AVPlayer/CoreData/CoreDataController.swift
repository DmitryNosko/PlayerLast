//
//  CoreDataController.swift
//  AVPlayer
//
//  Created by USER on 11/7/19.
//  Copyright © 2019 Dzmitry Noska. All rights reserved.
//

import Foundation
import CoreData

class CoreDataManager: NSObject {
    
    private struct Constants {
        static let kPodcastName = "Item"
        static let kAppName = "AVPlayer"
        static let kDataBaseName = "AVPlayer.sqlite"
        static let kItemIdentifier = "identifier"
        static let kItemIsDownloaded = "itemIsDownloaded"
        static let kItemAuthor = "itemAuthor"
        static let kItemDescription = "itemDescription"
        static let kItemDuration = "itemDuration"
        static let kItemImage = "itemImage"
        static let kItemPubDate = "itemPubDate"
        static let kItemTitle = "itemTitle"
        static let kItemURL = "itemURL"
        static let kItemIsDeleted = "itemIsDeleted"
        static let kItemMediaType = "itemMediaType"
        static let kItemProgressStatus = "itemProgressStatus"
        static let kItemProgresStatusWatched = "watched"
        static let kItemMediaTypeCustom = "customType"

    }
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: Constants.kAppName)
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last
        let url = documentsDirectory?.appendingPathComponent(Constants.kDataBaseName)
        container.persistentStoreDescriptions = [NSPersistentStoreDescription(url: url!)]
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    //MARK : Methods
    
    func addItem(item: PodcastItem) {
        let newItem = NSEntityDescription.insertNewObject(forEntityName: Constants.kPodcastName, into: self.persistentContainer.viewContext)
        newItem.setValue(item.identifier, forKey: Constants.kItemIdentifier)
        newItem.setValue(item.itemIsDownloaded, forKey: Constants.kItemIsDownloaded)
        newItem.setValue(item.itemAuthor, forKey: Constants.kItemAuthor)
        newItem.setValue(item.itemDescription, forKey: Constants.kItemDescription)
        newItem.setValue(item.itemDuration, forKey: Constants.kItemDuration)
        newItem.setValue(item.itemImage, forKey: Constants.kItemImage)
        newItem.setValue(item.itemPubDate, forKey: Constants.kItemPubDate)
        newItem.setValue(item.itemTitle, forKey: Constants.kItemTitle)
        newItem.setValue(item.itemURL, forKey: Constants.kItemURL)
        newItem.setValue(item.itemIsDeleted, forKey: Constants.kItemIsDeleted)
        newItem.setValue(item.itemMediaType.rawValue, forKey: Constants.kItemMediaType)
        newItem.setValue(item.itemProgressStatus.rawValue, forKey: Constants.kItemProgressStatus)
        do {
            try self.persistentContainer.viewContext.save()
        } catch {
            print(error)
        }
    }
    
    func deleteItem(item: PodcastItem) {
        let request = NSFetchRequest<NSFetchRequestResult>.fetchRequest(entity: Constants.kPodcastName, predicate: NSPredicate(format: "itemURL = %@", item.itemURL))
        do {
            let resultItem = try persistentContainer.viewContext.fetch(request).first as! NSManagedObject
            self.persistentContainer.viewContext.delete(resultItem)
            try self.persistentContainer.viewContext.save()
        } catch {
            print(error)
        }
    }
    
    func deleteAllItemsForMediaType(type: MediaType) {
        let request = NSFetchRequest<NSFetchRequestResult>.fetchRequest(entity: Constants.kPodcastName, predicate: NSPredicate(format: "itemMediaType = %@", type.rawValue))
        do {
            let results = try self.persistentContainer.viewContext.fetch(request)
            for object in results {
                guard let objectData = object as? NSManagedObject else {continue}
                self.persistentContainer.viewContext.delete(objectData)
            }
        } catch let error {
            print(error)
        }
    }
    
    func updateItem(item: PodcastItem) {
        let request = NSFetchRequest<NSFetchRequestResult>.fetchRequest(entity: Constants.kPodcastName, predicate: NSPredicate(format: "itemURL = %@", item.itemURL))
        do {
            let result: NSManagedObject?
            result = try (persistentContainer.viewContext.fetch(request).first as? NSManagedObject)
            if result != nil {
                result!.setValue(item.itemIsDeleted, forKey: Constants.kItemIsDeleted)
                result!.setValue(item.itemIsDownloaded, forKey: Constants.kItemIsDownloaded)
                result!.setValue(item.itemProgressStatus.rawValue, forKey: Constants.kItemProgressStatus)
                try self.persistentContainer.viewContext.save()
            }
        } catch {
            print(error)
        }
    }
    
    func deletedItems() -> [PodcastItem] {
        return fetchItemsBy(predicate: NSPredicate(format: "itemIsDeleted == %@", NSNumber(value: true)))
    }
    
    func downloadedItems() -> [PodcastItem] {
        return fetchItemsBy(predicate: NSPredicate(format: "itemIsDownloaded == %@", NSNumber(value: true)))
    }
    
    func wathedInProgressItems() -> [PodcastItem] {
        return fetchItemsBy(predicate: NSPredicate(format: "itemProgressStatus = %@", Constants.kItemProgresStatusWatched))
    }
    
    func customItemsURlS() -> [String] {
        var urls = [String]()
        let customItems = fetchItemsBy(predicate: NSPredicate(format: "itemMediaType = %@", Constants.kItemMediaTypeCustom))
        for item in customItems {
            urls.append(item.itemURL)
        }
        return urls
    }
    
    func fetchItemsBy(predicate: NSPredicate) -> [PodcastItem] {
        var items = [PodcastItem]()
        let request = NSFetchRequest<NSFetchRequestResult>.fetchRequest(entity: Constants.kPodcastName, predicate: predicate)
        do {
            let result = try persistentContainer.viewContext.fetch(request)
            for object in result as! [NSManagedObject] {
                let mediaType = MediaType(rawValue: object.value(forKeyPath: Constants.kItemMediaType) as! String)
                let progressStatus = ProgressStatus(rawValue: object.value(forKeyPath: Constants.kItemProgressStatus) as! String)
                
                let fetchedItem = PodcastItem(identifier: object.value(forKey: Constants.kItemIdentifier) as! UUID, itemTitle: object.value(forKey: Constants.kItemTitle) as! String, itemDescription: object.value(forKey: Constants.kItemDescription) as! String, itemPubDate: object.value(forKey: Constants.kItemPubDate) as! String, itemDuration: object.value(forKey: Constants.kItemDuration) as! String, itemURL: object.value(forKey: Constants.kItemURL) as! String, itemImage: object.value(forKey: Constants.kItemImage) as! String, itemAuthor: object.value(forKey: Constants.kItemAuthor) as! String, itemIsDownloaded: (object.primitiveValue(forKey: Constants.kItemIsDownloaded) != nil), itemIsDeleted: (object.value(forKey: Constants.kItemIsDeleted) != nil), itemMediaType: mediaType!, itemProgressStatus: progressStatus!)
                items.append(fetchedItem)
            }
        } catch {
            print(error)
        }
        
        return items
    }
    
    func updateItemURL(item: PodcastItem) {
        let request = NSFetchRequest<NSFetchRequestResult>.fetchRequest(entity: Constants.kPodcastName, predicate: NSPredicate(format: "itemTitle = %@", item.itemTitle))
        do {
            let result: NSManagedObject?
            result = try (persistentContainer.viewContext.fetch(request).first as? NSManagedObject)
            if result != nil {
                result!.setValue(item.itemIsDownloaded, forKey: Constants.kItemIsDownloaded)
                result!.setValue(item.itemURL, forKey: Constants.kItemURL)
                try self.persistentContainer.viewContext.save()
            }
        } catch {
            print(error)
        }
    }
    
}


