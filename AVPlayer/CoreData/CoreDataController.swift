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
    
    let podcastName = "Item"
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "AVPlayer")
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last
        let url = documentsDirectory?.appendingPathComponent("AVPlayer.sqlite")
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
        let newItem = NSEntityDescription.insertNewObject(forEntityName: podcastName, into: self.persistentContainer.viewContext)
        newItem.setValue(item.identifier, forKey: "identifier")
        newItem.setValue(item.itemIsDownloaded, forKey: "itemIsDownloaded")
        newItem.setValue(item.itemAuthor, forKey: "itemAuthor")
        newItem.setValue(item.itemDescription, forKey: "itemDescription")
        newItem.setValue(item.itemDuration, forKey: "itemDuration")
        newItem.setValue(item.itemImage, forKey: "itemImage")
        newItem.setValue(item.itemPubDate, forKey: "itemPubDate")
        newItem.setValue(item.itemTitle, forKey: "itemTitle")
        newItem.setValue(item.itemURL, forKey: "itemURL")
        newItem.setValue(item.itemIsDeleted, forKey: "itemIsDeleted")
        newItem.setValue(item.itemMediaType.rawValue, forKey: "itemMediaType")
        newItem.setValue(item.itemProgressStatus.rawValue, forKey: "itemProgressStatus")
        do {
            try self.persistentContainer.viewContext.save()
        } catch {
            print(error)
        }
    }
    
    func deleteItem(item: PodcastItem) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: podcastName)
        request.predicate = NSPredicate(format: "itemURL = %@", item.itemURL)
        request.returnsObjectsAsFaults = false
        do {
            let resultItem = try persistentContainer.viewContext.fetch(request).first as! NSManagedObject
            self.persistentContainer.viewContext.delete(resultItem)
            try self.persistentContainer.viewContext.save()
        } catch {
            print("Failed to fetchItems")
        }
    }
    
    func deleteAllFeedItemsForType(type: MediaType) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: podcastName)
        fetchRequest.returnsObjectsAsFaults = false
        fetchRequest.predicate = NSPredicate(format: "itemMediaType = %@", type.rawValue)
        do {
            let results = try self.persistentContainer.viewContext.fetch(fetchRequest)
            for object in results {
                guard let objectData = object as? NSManagedObject else {continue}
                self.persistentContainer.viewContext.delete(objectData)
            }
        } catch let error {
            print("Detele all data in \(podcastName) error :", error)
        }
    }
    
    func updateItem(item: PodcastItem) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: podcastName)
        request.predicate = NSPredicate(format: "itemURL = %@", item.itemURL)
        request.returnsObjectsAsFaults = false
        do {
            let result: NSManagedObject?
            result = try (persistentContainer.viewContext.fetch(request).first as? NSManagedObject)
            if result != nil {
                result!.setValue(item.itemIsDeleted, forKey: "itemIsDeleted")
                result!.setValue(item.itemIsDownloaded, forKey: "itemIsDownloaded")
                result!.setValue(item.itemProgressStatus.rawValue, forKey: "itemProgressStatus")
                try self.persistentContainer.viewContext.save()
            }
        } catch {
            print("Failed to fetchItems")
        }
    }
    
    func updateItem2(item: PodcastItem) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: podcastName)
        request.predicate = NSPredicate(format: "itemTitle = %@", item.itemTitle)
        request.returnsObjectsAsFaults = false
        do {
            let result: NSManagedObject?
            result = try (persistentContainer.viewContext.fetch(request).first as? NSManagedObject)
            if result != nil {
                result!.setValue(item.itemIsDeleted, forKey: "itemIsDeleted")
                result!.setValue(item.itemIsDownloaded, forKey: "itemIsDownloaded")
                result!.setValue(item.itemProgressStatus.rawValue, forKey: "itemProgressStatus")
                result!.setValue(item.itemURL, forKey: "itemURL")
                try self.persistentContainer.viewContext.save()
            }
        } catch {
            print("Failed to fetchItems")
        }
    }
    
    func updateItemURL(item: PodcastItem, url: String, isDownloaded: Bool) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: podcastName)
        request.predicate = NSPredicate(format: "itemURL = %@", item.itemURL)
        request.returnsObjectsAsFaults = false
        do {
            let result = try persistentContainer.viewContext.fetch(request).first as! NSManagedObject
            result.setValue(isDownloaded, forKey: "itemIsDownloaded")
            result.setValue(url, forKey: "itemURL")
            try self.persistentContainer.viewContext.save()
        } catch {
            print("Failed to fetchItems")
        }
    }
    
    func deletedItems() -> [PodcastItem] {
        return fetchItemsBy(predicate: NSPredicate(format: "itemIsDeleted == %@", NSNumber(value: true)))
    }
    
    func downloadedItems() -> [PodcastItem] {
        return fetchItemsBy(predicate: NSPredicate(format: "itemIsDownloaded == %@", NSNumber(value: true)))
    }
    
    func wathedInProgressItems() -> [PodcastItem] {
        return fetchItemsBy(predicate: NSPredicate(format: "itemProgressStatus = %@", "watched"))
    }
    
    func customItemsURlS() -> [String] {
        var urls = [String]()
        let customItems = fetchItemsBy(predicate: NSPredicate(format: "itemMediaType = %@", "customType"))
        for item in customItems {
            urls.append(item.itemURL)
        }
        
        return urls
    }
    
    func fetchItemsBy(predicate: NSPredicate) -> [PodcastItem] {
        var items = [PodcastItem]()
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: podcastName)
        request.predicate = predicate
        request.returnsObjectsAsFaults = false
        do {
            let result = try persistentContainer.viewContext.fetch(request)
            for object in result as! [NSManagedObject] {
                let mediaType = MediaType(rawValue: object.value(forKeyPath: "itemMediaType") as! String)
                let progressStatus = ProgressStatus(rawValue: object.value(forKeyPath: "itemProgressStatus") as! String)
                
                let fetchedItem = PodcastItem(identifier: object.value(forKey: "identifier") as! UUID, itemTitle: object.value(forKey: "itemTitle") as! String, itemDescription: object.value(forKey: "itemDescription") as! String, itemPubDate: object.value(forKey: "itemPubDate") as! String, itemDuration: object.value(forKey: "itemDuration") as! String, itemURL: object.value(forKey: "itemURL") as! String, itemImage: object.value(forKey: "itemImage") as! String, itemAuthor: object.value(forKey: "itemAuthor") as! String, itemIsDownloaded: (object.primitiveValue(forKey: "itemIsDownloaded") != nil), itemIsDeleted: (object.value(forKey: "itemIsDeleted") != nil), itemMediaType: mediaType!, itemProgressStatus: progressStatus!)
                items.append(fetchedItem)
            }
        } catch {
            print("Failed to fetchItems")
        }
        
        return items
    }
    
}


