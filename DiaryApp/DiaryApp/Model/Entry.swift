//
//  Entry.swift
//  DiaryApp
//
//  Created by Jun Kakeno on 1/16/19.
//  Copyright © 2019 Jun Kakeno. All rights reserved.
//

import Foundation
import CoreData
import UIKit
import MapKit

//This class represents the object in core data
public class Entry: NSManagedObject {

}

extension Entry {
    //Method to read data from core data and return the data sorted
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Entry> {
        let request = NSFetchRequest<Entry>(entityName: "Entry")
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: true)
        request.sortDescriptors = [sortDescriptor]
        return request
    }
    
    //Object attributes
    @NSManaged public var date: NSDate
    @NSManaged public var image: NSData?
    @NSManaged public var lat: NSNumber?
    @NSManaged public var lng: NSNumber?
    @NSManaged public var mood: String?
    @NSManaged public var text: String?
}

extension Entry {
    //Computated property that returns the name of the class
    static var entityName: String {
        return String(describing: Entry.self)
    }
    
    //Method to create a photo in core data.
    @nonobjc class func with(_ date: NSDate, image: UIImage?, text: String?, lat: NSNumber?, lng: NSNumber?,mood: String?,in context: NSManagedObjectContext) -> Entry {
        let entry = NSEntityDescription.insertNewObject(forEntityName: Entry.entityName, into: context) as! Entry
        
        //Set the entry model properties
        entry.date = Date() as NSDate
        entry.image = image?.jpegData(compressionQuality: 1.0) as NSData?
        entry.text = text
        entry.lat = lat
        entry.lng = lng
        entry.mood = mood
        
        return entry
    }
}

extension Entry {
    //Computated property that converts a NSData type to UIImage type and returns a UIImage
    var convertImage: UIImage {
        return UIImage(data: self.image! as Data)!
    }
    
    //Computated property that returns a location name.
    var locationName:String{
        var cityName:String?
        var stateName:String?

        // Add below code to get address for touch coordinates.
        let geoCoder = CLGeocoder()
        let location = CLLocation(latitude: self.lat as! Double, longitude: self.lng as! Double)
        geoCoder.reverseGeocodeLocation(location, completionHandler:
            {
                placemarks, error -> Void in
                
                // Place details
                guard let placeMark = placemarks?.first else { return }
                
                // Location name
                if let locationName = placeMark.location {
                    print(locationName)
                }
                // Street address
                if let street = placeMark.thoroughfare {
                    print(street)
                }
                // City
                if let city = placeMark.subAdministrativeArea {
                    print(city)
                    cityName = city
                }
                // State
                if let state = placeMark.administrativeArea {
                    print(state)
                    stateName = state
                }
                // Zip code
                if let zip = placeMark.isoCountryCode {
                    print(zip)
                }
                // Country
                if let country = placeMark.country {
                    print(country)
                }
        })
        guard let city = cityName else {return "City is nil"}
        guard let state = stateName else {return "State is nil"}
        return "\(city, state)"
    }
}



