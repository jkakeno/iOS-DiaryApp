//
//  LocationPickerController.swift
//  DiaryApp
//
//  Created by Jun Kakeno on 1/21/19.
//  Copyright © 2019 Jun Kakeno. All rights reserved.
//

import UIKit
import MapKit
import CoreData

protocol StoreLocationProtocol{
    func didGetCurrentLocation(_ location:String)
}

//Tutorial: https://www.techotopia.com/index.php/Working_with_Maps_on_iOS_8_with_Swift,_MapKit_and_the_MKMapView_Class
//Tutorial: https://appsandbiscuits.com/getting-the-users-location-ios-15-fe0a63be085b

class LocationPickerController: UIViewController,MKMapViewDelegate{

    @IBOutlet weak var mapView: MKMapView!
    
    var storeLocation: StoreLocationProtocol?
    
    //Place holder for objects received from DiaryEntryFormController
    var entry: Entry?
    var context: NSManagedObjectContext?
    var location:String?
    var state:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.showsUserLocation = true
        let geoCoder = CLGeocoder()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let userLocation = self.mapView.userLocation.location?.coordinate {
                print("Got user location: Lat: \(userLocation.latitude) Lng: \(userLocation.longitude)")

                let location = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
                let region = MKCoordinateRegion(
                    center: userLocation, latitudinalMeters: 2000, longitudinalMeters: 2000)
                
                geoCoder.reverseGeocodeLocation(location, completionHandler:
                    {
                        placemarks, error -> Void in
                        
                        // Get the first location
                        guard let placeMark = placemarks?.first else { return }
                        
                        // Get the city and state for current location
                        if let city = placeMark.subAdministrativeArea, let state = placeMark.administrativeArea{
                            self.location = "\(city), \(state)"
                            //Set up navigatoin bar buttons action
                            let saveButton = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(LocationPickerController.saveLocation))
                            self.navigationItem.rightBarButtonItem = saveButton
                        }
                })
                //Move map view camera to the set region
                self.mapView.setRegion(region, animated: true)
            }
        }
        //Activate the map view deleate to override the method mapView.
        mapView.delegate = self
    }
    
    //Tracks user location and centers it on the map when user moves
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        mapView.centerCoordinate = userLocation.location!.coordinate
    }
    
    @objc func saveLocation() {
        if let location = location{
            //Notify DiaryEntryFormController that current location was obtained and pass the current location.
            self.storeLocation?.didGetCurrentLocation(location)
            //Note: if push is used to display the controller pop is required to dismiss it.
            navigationController?.popViewController(animated: true)
            dismiss(animated: true, completion: nil)
        }
    }
}
