//
//  DiaryEntryFormController.swift
//  DiaryApp
//
//  Created by Jun Kakeno on 1/14/19.
//  Copyright © 2019 Jun Kakeno. All rights reserved.
//

import UIKit
import MapKit
import CoreData

protocol BackPress {
    func didPressBack()->Void
}

protocol SavePress {
    func didPressSave()->Void
}


class DiaryEntryFormController: UIViewController {
    
    enum Mood: String{
        case bad,average,good
    }
    
    enum Color: Int{
        case green = 0x82A74B
        case purple = 0x564C7F
        case red = 0xA5330C
    }

    @IBOutlet weak var diaryImage: UIImageView!
    @IBOutlet weak var diaryDateLabel: UILabel!
    @IBOutlet weak var addLocationBtn: UIButton!
    @IBOutlet weak var diaryText: UITextView!
    @IBOutlet weak var badMoodBtn: UIButton!
    @IBOutlet weak var averageMoodBtn: UIButton!
    @IBOutlet weak var goodMoodBtn: UIButton!
    
    let locationManager = CLLocationManager()
    
    var backProtocol: BackPress?
    var saveProtocol: SavePress?
    
    //Place holder for objects received from DiaryListController
    var entry: Entry?
    var context: NSManagedObjectContext?
    var indexPath: Int?
    
    //This is needed to prevent crashing.
    var photo: UIImage?
    lazy var displayImage: UIImage? = {
        guard let image = photo else {
            return UIImage(named: "icn_picture") }
        
        let imageWidth = image.size.width
        let imageHeight = image.size.height
        let screenWidth = UIScreen.main.bounds.width
        let scaledRatio = screenWidth/imageWidth
        let scaledHeight = scaledRatio * imageHeight
        let size = CGSize(width: screenWidth, height: scaledHeight)
        
        return image.resized(to: size)
    }()
    
    lazy var photoPickerManager: PhotoPickerManager = {
        //Get an instance of PhotoPickerManager
        let manager = PhotoPickerManager(presentingViewController: self)
        //Self can be assigned to the manager's delegate property because this class adopts PhotoPickerManagerDelegate in the extension below.
        manager.delegate = self
        return manager
    }()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Diary Entry Form View did load")

        //Set up navigatoin bar buttons action
        let saveButton = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(DiaryEntryFormController.saveEntry))
        navigationItem.rightBarButtonItem = saveButton
        
        let backButton = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(DiaryEntryFormController.back))
        navigationItem.leftBarButtonItem = backButton
        
        //Set up view's actions
        let mapPicker = UITapGestureRecognizer(target: self, action: #selector(self.mapPicker(_:)))
        let cameraPicker = UITapGestureRecognizer(target: self, action: #selector(self.camera(_:)))
        let badMoodSelector = UITapGestureRecognizer(target: self, action: #selector(self.bad(_:)))
        let averageMoodSelector = UITapGestureRecognizer(target: self, action: #selector(self.average(_:)))
        let goodMoodSelector = UITapGestureRecognizer(target: self, action: #selector(self.good(_:)))
        let dismissKeyboard = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard(_:)))
        
        addLocationBtn.addGestureRecognizer(mapPicker)
        diaryImage.isUserInteractionEnabled = true
        diaryImage.addGestureRecognizer(cameraPicker)
        diaryImage.roundImage()
        badMoodBtn.addGestureRecognizer(badMoodSelector)
        averageMoodBtn.addGestureRecognizer(averageMoodSelector)
        goodMoodBtn.addGestureRecognizer(goodMoodSelector)
        view.addGestureRecognizer(dismissKeyboard)
        
        //Display entry date, image, text, location, mood button for a selected entry.
        if let entry = entry,let today = entry.date as? Date {
            diaryDateLabel.text = today.fullDate
        }
        if let entry = self.entry, let text = entry.text{
            diaryText.text = text
        }else{
            diaryText.text = "Enter your thoughts here..."
            diaryText.textColor = .gray
        }
        if let entry = self.entry, let image = entry.image{
            print("Entry image received")
            diaryImage.image = sizeImage(UIImage(data: image as Data)!)
        }else{
            diaryImage.image = displayImage
        }
        if let entry = self.entry, let mood = entry.mood{
            print("Entry mood is: \(mood)")
            switch mood {
            case Mood.bad.rawValue:
                badMoodBtn.backgroundColor = .gray
                averageMoodBtn.backgroundColor = UIColor(rgb:Color.purple.rawValue)
                goodMoodBtn.backgroundColor = UIColor(rgb:Color.green.rawValue)
            case Mood.average.rawValue:
                badMoodBtn.backgroundColor = UIColor(rgb: Color.red.rawValue)
                averageMoodBtn.backgroundColor = .gray
                goodMoodBtn.backgroundColor = UIColor(rgb: Color.green.rawValue)
            case Mood.good.rawValue:
                badMoodBtn.backgroundColor = UIColor(rgb: Color.red.rawValue)
                averageMoodBtn.backgroundColor = UIColor(rgb: Color.purple.rawValue)
                goodMoodBtn.backgroundColor = .gray
            default:
                return
            }
        }

        //Get access to the DiaryListController
        guard let diaryListController = storyboard?.instantiateViewController(withIdentifier: "DiaryListController") as? DiaryListController else { return }
        
        //Set the DiaryListController to reference of the protocols. DiaryListController needs to adopt these protocols to implement the methods.
        backProtocol = diaryListController
        saveProtocol = diaryListController
    }
    
    @objc func back() {
        print("Back")
        //Note: if push is used to display the controller pop is required to dismiss it.
        navigationController?.popViewController(animated: true)
        dismiss(animated: true, completion: nil)
        //Activiate the protocol func
        backProtocol?.didPressBack()
    }
    
    @objc func saveEntry() {
        print("Save Entry")
        
        guard let context = context else {return}
        guard let entry = entry else {return}
        
        //Save properties of the model to core data
        if let image = entry.image {
            entry.setValue(image, forKey: "image")
        }else{
            let imageData = UIImage(named: "icn_picture")?.jpegData(compressionQuality: 1.0)! as! NSData
            entry.setValue(imageData, forKey: "image")
        }
        if let text = entry.text {
            entry.setValue(text, forKey: "text")
        }else{
            entry.setValue("No text", forKey: "text")
        }
        if let mood = entry.mood {
            entry.setValue(mood, forKey: "mood")
        }else{
            entry.setValue("No mood", forKey: "mood")
        }
        if let lat = entry.lat {
            entry.setValue(lat, forKey: "lat")
        }else{
            entry.setValue(0.0, forKey: "lat")
        }
        if let lng = entry.lng {
            entry.setValue(lng, forKey: "lng")
        }else{
            entry.setValue(0.0, forKey: "lng")
        }

        //Apply save data to core data
        context.saveChanges()
        
        //Note: if push is used to display the controller pop is required to dismiss it.
        navigationController?.popViewController(animated: true)
        dismiss(animated: true, completion: nil)
    
        //Notify DiaryListController that save button was pressed.
        saveProtocol?.didPressSave()
    }
    
    @objc func mapPicker(_ sender: UITapGestureRecognizer){
        print("Navigate to map picker")
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }
    
    @objc func camera(_ sender: UITapGestureRecognizer){
        print("Navigate to camera")
        photoPickerManager.presentPhotoPicker(animated: true)
    }

    @objc func bad(_ sender: UITapGestureRecognizer){
        print("Feeling bad")
        guard let entry = entry else {return}
        entry.mood = Mood.bad.rawValue

        badMoodBtn.backgroundColor = .gray
        averageMoodBtn.backgroundColor = UIColor(rgb:Color.purple.rawValue)
        goodMoodBtn.backgroundColor = UIColor(rgb:Color.green.rawValue)
    }
    
    @objc func average(_ sender: UITapGestureRecognizer){
        print("Feeling average")
        guard let entry = entry else {return}
        entry.mood = Mood.average.rawValue
        
        badMoodBtn.backgroundColor = UIColor(rgb: Color.red.rawValue)
        averageMoodBtn.backgroundColor = .gray
        goodMoodBtn.backgroundColor = UIColor(rgb: Color.green.rawValue)
    }
    
    @objc func good(_ sender: UITapGestureRecognizer){
        print("Feeling good")
        guard let entry = entry else {return}
        entry.mood = Mood.good.rawValue

        badMoodBtn.backgroundColor = UIColor(rgb: Color.red.rawValue)
        averageMoodBtn.backgroundColor = UIColor(rgb: Color.purple.rawValue)
        goodMoodBtn.backgroundColor = .gray
    }
    
    @objc func dismissKeyboard(_ sender: UITapGestureRecognizer){
        print("Dismiss keyboard")
        view.endEditing(true)
        guard let entry = entry else {return}
        entry.text = diaryText.text
    }
    
}

//This extension is used to get an image taken with the camera and detect when the camera was dismissed.
extension DiaryEntryFormController: PhotoPickerManagerDelegate {
    //Method to conform to the protocol adopted. Method called when user taps on "Use Photo" (right button) on camera because this is the implementation of the protocol method call in PhotoPickerManager extension.
    func manager(_ manager: PhotoPickerManager, didPickImage image: UIImage) {
        print("Use Photo")
        self.photo = image
        //Call the PhotoPickerManager helper method to dismiss the picker.
        manager.dismissPhotoPicker(animated: true) {
            print("Dismissed camera")
            //Display resized image on view controller.
            self.diaryImage.image = self.sizeImage(image)
            //Store image in entry object.
            guard let entry = self.entry else {return}
            entry.image = image.pngData() as NSData?
        }
    }
    
    func sizeImage(_ image: UIImage)->UIImage{
        
        let imageWidth = image.size.width
        let imageHeight = image.size.height
        let screenWidth = diaryImage.bounds.width
        let scaledRatio = screenWidth/imageWidth
        let scaledHeight = scaledRatio * imageHeight
        let size = CGSize(width: screenWidth, height: scaledHeight)
        
        return image.resized(to: size)!
    }
}

//This extension is used to get the current location of the user.
//Tutorial: https://www.thorntech.com/2016/01/how-to-search-for-location-using-apples-mapkit/
extension DiaryEntryFormController : CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("error: \(error.localizedDescription)")
    }
    
    //This method gets called when the user responds to the permission dialog. If the user chose Allow, the status becomes CLAuthorizationStatus.AuthorizedWhenInUse.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }

    //This gets called when location information comes back. You get an array of locations, but you’re only interested in the first item.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if locations.first != nil {
            print("Current location: \(String(describing: locations.first))")
            guard let entry = entry else {return}
            entry.lat = locations.first?.coordinate.latitude as NSNumber?
            entry.lng = locations.first?.coordinate.longitude as NSNumber?
            addLocationBtn.setTitle(entry.locationName, for: .normal)
        }
    }
}
