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
        
        let pinID = pin.objectID
        let selectedPin = dataController.viewContext.object(with: pinID)
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", selectedPin )
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        do {
            try fetchedResultsController.performFetch()
            print(fetchedResultsController.sections?[0].numberOfObjects ?? 0)
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
        
        let space: CGFloat = 3.0
        let dimension = (view.frame.size.width - 2 * space) / 3.0
        
        flowLayout.minimumLineSpacing = space
        flowLayout.minimumInteritemSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
        
        reloadCollection()
        
        addSaveNotificationObserver()
    }

    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    var refreshInProgress = false
    @IBAction func refreshButtonTapped(_ sender: UIBarButtonItem) {
        let pinID = pin.objectID
        let backgroundContext: NSManagedObjectContext! = self.dataController.backgroundContext
        backgroundContext.perform {
            let backgroundPin = backgroundContext.object(with: pinID)
            let fetchRequest:NSFetchRequest<NSFetchRequestResult> = Photo.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "pin = %@", backgroundPin)
            
            let bacthDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try backgroundContext.execute(bacthDeleteRequest)
                try backgroundContext.save()
                
                DispatchQueue.main.async {
                    FlickrClient.curentPage = Int(self.pin.currentPage % self.pin.totalPages + 1)
                    FlickrClient().getPhotosInfoByLocation(CLLocationCoordinate2DMake(self.pin.latitude, self.pin.longitude), completion: self.getPhotosInfoByloctaionCompleteHandler(response:error:))
                }
            } catch {
                
            }
        }
    }
    
    
    deinit {
        removeSaveNotificationObserver()
    }
    
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoAlbumCollectionViewCell", for: indexPath) as! PhotoAlbumCollectionViewCell
        let data = fetchedResultsController.object(at: indexPath)
        
        if  let imageData = data.image {
            cell.PhotoImageView.image = UIImage(data: imageData)
        } else {
            let placeholder: UIImage? = UIImage(named: "PosterPlaceholder")
            cell.PhotoImageView.image = placeholder
            if let id = data.id, let secret = data.secret, let server = data.server {
                let photoInfo = PhotoInfoDTO(id: id, secret: secret, server: server)
                FlickrClient().getJpgPhoto(photoInfo){ imagedata, error in
                    guard let imagedata = imagedata else {
                        return
                    }
                    let image = UIImage(data: imagedata)
                    cell.PhotoImageView.image = image
                    data.image = imagedata
                    try? self.dataController.viewContext.save()
                    cell.setNeedsLayout()
                }
            }
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
            DispatchQueue.main.async {
                try? self.fetchedResultsController.performFetch()
            }
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
        guard let fetchedResultsController = fetchedResultsController else { return }
        
        try? fetchedResultsController.performFetch()
        
        DispatchQueue.main.async {
            self.navigationItem.title = "\(self.pin.currentPage)/\(self.pin.totalPages)"
            
            self.photoAlbumCollectionView.reloadData()
        }
    }
    
    func handleSaveNotification(notification: Notification) {
        reloadCollection()
    }
    
    func getPhotosInfoByloctaionCompleteHandler(response: SearchPhotosResponse?, error: Error?) {
        if let response = response {
            let pinID = self.pin.objectID
            let backgroundContext: NSManagedObjectContext! = dataController.backgroundContext
            backgroundContext.perform {
                let pin: Pin = backgroundContext.object(with: pinID) as! Pin
                pin.currentPage = Int32(response.photos.page)
                if let photos = response.photos.photo {
                    for photoInfo in photos {
                        let photo = Photo(context: backgroundContext)
                        photo.creationDate = Date()
                        photo.image = nil
                        photo.pin = pin
                        photo.farm = Int32(photoInfo.farm)
                        photo.id = photoInfo.id
                        photo.isFamily = photoInfo.isfamily == 1
                        photo.isFriend = photoInfo.isfriend == 1
                        photo.isPublic = photoInfo.ispublic == 1
                        photo.owner = photoInfo.owner
                        photo.secret = photoInfo.secret
                        photo.server = photoInfo.server
                        photo.title = photoInfo.title
                    }
                    try? backgroundContext.save()
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
        present(alertVC, animated: true)
    }

}
