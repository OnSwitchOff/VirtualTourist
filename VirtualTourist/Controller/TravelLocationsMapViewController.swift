//
//  TravelLocationsMapViewController.swift
//  VirtualTourist
//
//  Created by MacBook Pro on 27.07.23.
//

import Foundation
import CoreData
import UIKit
import MapKit

class TravelLocationsMapViewController: UIViewController, MKMapViewDelegate {
    
    var dataController: DataController!
    var saveObserverToken: Any?
    
    @IBOutlet weak var mapView: MKMapView!
    
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    
    override func viewDidLoad() {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleMapLongPress(_:)))
        mapView.addGestureRecognizer(longPressGesture)
        reloadMap()
        addSaveNotificationObserver()
    }
    
    deinit {
        removeSaveNotificationObserver()
    }
    
    
    var coordinate: CLLocationCoordinate2D?
    @objc func handleMapLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: mapView)
            coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            
            if let coordinate = coordinate {
                FlickrClient().getPhotosInfoByLocation(CLLocationCoordinate2DMake(coordinate.latitude, coordinate.longitude), completion: getPhotosInfoByloctaionCompleteHandler(response:error:))
            }
        }
    }
    
    func getPhotosInfoByloctaionCompleteHandler(response: SearchPhotosResponse?, error: Error?) {
        if let response = response, let coordinate = coordinate {
            let backgroundContext: NSManagedObjectContext! = dataController.backgroundContext
            backgroundContext.perform {
                let totalPages = response.photos.pages
                let pin = Pin(context: backgroundContext)
                pin.latitude = coordinate.latitude
                pin.longitude = coordinate.longitude
                pin.currentPage = 1
                pin.totalPages = Int32(min(totalPages, 4000/FlickrClient.perPage))
                
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

    
    // MARK: - MKMapViewDelegate

    
    // Here we create a view with a "right callout accessory view". You might choose to look into other
    // decoration alternatives. Notice the similarity between this method and the cellForRowAtIndexPath
    // method in TableViewDataSource.
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "Pin") as? MKPinAnnotationView ?? MKPinAnnotationView(annotation: annotation, reuseIdentifier: "Pin")
        annotationView.annotation = annotation
        annotationView.pinTintColor = .blue // Set the pin color here
        annotationView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        annotationView.canShowCallout = true
        return annotationView
    }
    
    var selectedPin: Pin?
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let annotation = view.annotation{
            let coordinate = annotation.coordinate
            let lon: Double = coordinate.longitude
            let lat: Double = coordinate.latitude
            
            let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
            //let predicate = NSPredicate(format: "longitude = %f AND latitude = %f", lon, lat)
            //fetchRequest.predicate = predicate
            let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
            fetchRequest.sortDescriptors = [sortDescriptor]
            do {
                let results = try dataController.viewContext.fetch(fetchRequest)
                for result in results {
                    if result.longitude == lon, result.latitude == lat {
                        selectedPin = result
                        performSegue(withIdentifier: "showPhotoAlbum", sender: nil)
                        break;
                    }
                }
            } catch {
                fatalError("The fetch could not be performed: \(error.localizedDescription)")
            }
        }
    }
    
    // -------------------------------------------------------------------------
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? PhotoAlbumViewController {
            if let selectedPin = selectedPin {
                vc.pin = selectedPin
                vc.dataController = self.dataController
            }
        }
    }
}

extension TravelLocationsMapViewController {
    
    func addSaveNotificationObserver() {
        removeSaveNotificationObserver()
        saveObserverToken = NotificationCenter.default.addObserver(forName: .NSManagedObjectContextObjectsDidChange, object: dataController.viewContext, queue: nil, using: handleSaveNotification(notification:))
    }
    
    func removeSaveNotificationObserver() {
        if let token = saveObserverToken {
            NotificationCenter.default.removeObserver(token)
        }
    }
    
    fileprivate func reloadMap() {
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        do {
            let results = try dataController.viewContext.fetch(fetchRequest)
            mapView.removeAnnotations(mapView.annotations)
            for result in results {
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2DMake(result.latitude, result.longitude)
                self.mapView.addAnnotation(annotation)
            }
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    func handleSaveNotification(notification: Notification) {
        DispatchQueue.main.async {
            self.reloadMap()
        }
    }
}


