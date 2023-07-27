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
    }
    
    @objc func handleMapLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: mapView)
            let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            addPinToMap(coordinate: coordinate)
        }
    }
    
    func addPinToMap(coordinate: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
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
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let annotation = view.annotation{
            let coordinate = annotation.coordinate
            print(coordinate)
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


