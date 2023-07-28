//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by MacBook Pro on 27.07.23.
//

import CoreData
import UIKit
import MapKit

class PhotoAlbumViewController: UICollectionViewController {
    
    var dataController: DataController!
    var saveObserverToken: Any?
    
    @IBOutlet var photoAlbumCollectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    var pin: Pin!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let space: CGFloat = 3.0
        let dimension = (view.frame.size.width - 2 * space) / 3.0
        
        flowLayout.minimumLineSpacing = space
        flowLayout.minimumInteritemSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
        
        reloadCollection()
        
        addSaveNotificationObserver()
    }
    
    deinit {
        removeSaveNotificationObserver()
    }
    
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            
        }
        
        print(fetchedResultsController.sections?.count)
        return fetchedResultsController.sections?.count ?? 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            
        }
        print(fetchedResultsController.sections?[section].numberOfObjects)
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoAlbumCollectionViewCell", for: indexPath) as! PhotoAlbumCollectionViewCell
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            
        }
        
        let data = fetchedResultsController.object(at: indexPath)
        
        if  let imageData = data.image {
            cell.PhotoImageView.image = UIImage(data: imageData)
        }
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photoToDelete = fetchedResultsController.object(at: indexPath)
        let photoID = photoToDelete.objectID
        let backgroundContext: NSManagedObjectContext! = self.dataController.backgroundContext
        backgroundContext.perform {
            backgroundContext.delete(backgroundContext.object(with: photoID))
            try? backgroundContext.save()
        }
    }
}

class PhotoAlbumCollectionViewCell: UICollectionViewCell {
    @IBOutlet var PhotoImageView: UIImageView!
}

extension PhotoAlbumViewController {
    
    func addSaveNotificationObserver() {
        removeSaveNotificationObserver()
        saveObserverToken = NotificationCenter.default.addObserver(forName: .NSManagedObjectContextObjectsDidChange, object: dataController.viewContext, queue: nil, using: handleSaveNotification(notification:))
    }
    
    func removeSaveNotificationObserver() {
        if let token = saveObserverToken {
            NotificationCenter.default.removeObserver(token)
        }
    }
    
    fileprivate func reloadCollection() {

        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", pin)
        //fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            
        }
        
        do {
            let results = try dataController.viewContext.fetch(fetchRequest)
            if results.count == 0 {
                FlickrClient().getPhotosInfoByLocation(CLLocationCoordinate2DMake(pin.latitude, pin.longitude), completion: getPhotosInfoByloctaionCompleteHandler(response:error:))
            } else {
                self.photoAlbumCollectionView.reloadData()
            }
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    func handleSaveNotification(notification: Notification) {
        DispatchQueue.main.async {
            self.photoAlbumCollectionView.reloadData()
        }
    }
    
    func getPhotosInfoByloctaionCompleteHandler(response: SearchPhotosResponse?, error: Error?) {
        if let response = response {
            if let photos = response.photos.photo {
                for photo in photos {
                    FlickrClient().getJpgPhoto(photo) { data, error in
                        guard let data = data else {
                            return
                        }
                        let backgroundContext: NSManagedObjectContext! = self.dataController.backgroundContext
                        backgroundContext.perform {
                            let photo = Photo(context: backgroundContext)
                            photo.creationDate = Date()
                            photo.image = data
                            try? backgroundContext.save()
                        }
                    }
                }
            }
        } else {
            if let error = error {
                showFailure(message: error.localizedDescription)
            }
        }
    }

    func showFailure(message: String, title: String = "Failed") {
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        show(alertVC, sender: nil)
    }

}


