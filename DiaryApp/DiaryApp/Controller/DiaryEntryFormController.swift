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

protocol SavePressProtocol {
    func didPressSave()->Void
}

class DiaryEntryFormController: UIViewController{

    enum Mood: String{
        case bad,average,good
    }
    
    enum Color: Int{
        case green = 0x82A74B
        case purple = 0x564C7F
        case red = 0xA5330C
    }

    @IBOutlet weak var diaryDateLabel: UILabel!
    @IBOutlet weak var diaryText: UITextView!
    @IBOutlet weak var diaryImage: UIImageView!
    @IBOutlet weak var addLocationBtn: UIButton!
    @IBOutlet weak var badMoodBtn: UIButton!
    @IBOutlet weak var averageMoodBtn: UIButton!
    @IBOutlet weak var goodMoodBtn: UIButton!
    
    let locationManager = CLLocationManager()
    
    var saveProtocol: SavePressProtocol?
    
    //Place holder for objects received from DiaryListController
    var entry: Entry?
    var context: NSManagedObjectContext?
//    var indexPath: Int?
    var mood:String?
    var location:String?
    
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
        
        //Entry selected from DiaryListController
        if let entry = entry{
            diaryDateLabel.text = entry.date.fullDate
            diaryText.text = entry.text
            diaryImage.image = entry.uiImage

            if let location = entry.location{
                addLocationBtn.setTitle("\(location)", for: .normal)
            }else{
                addLocationBtn.setTitle("Add location", for: .normal)
            }
            
            switch entry.mood {
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
        //Add a new entry from DiaryListController
        }else{
            diaryDateLabel.text = Date().fullDate
            diaryText.text = "Enter your thoughts here..."
            diaryText.textColor = .gray
        }
        diaryText.delegate = self
    }
    
    @objc func back() {
        print("Back")
        //Note: if push is used to display the controller pop is required to dismiss it.
        navigationController?.popViewController(animated: true)
        dismiss(animated: true, completion: nil)
    }
    
    @objc func saveEntry() {
        print("Save Entry")
        
        guard let context = context, let text = diaryText.text else {return}

        //Get the location from add location button title
        if let locationName = addLocationBtn.title(for: .normal){
            location = locationName
        }else{
            location = "Add location"
        }
        
        //Get the mood from buttons background
        if badMoodBtn.backgroundColor == .gray {
            mood = Mood.bad.rawValue
        }else if averageMoodBtn.backgroundColor == .gray {
            mood = Mood.average.rawValue
        }else if goodMoodBtn.backgroundColor == .gray {
            mood = Mood.good.rawValue
        }
        
        if let entry = entry {
            print("Updated entry \(entry.text)")
            let _ = Entry.update(entry, text: text, image: diaryImage.image, mood: mood, location: location, in: context)
        } else {
            print("Crated a new entry")
            let _ = Entry.createWith(text: text, image: diaryImage.image, mood: mood, location: location, in: context)
        }
        
        //Apply save data to core data
        context.saveChanges()
        
        //Note: if push is used to display the controller pop is required to dismiss it.
        navigationController?.popViewController(animated: true)
        dismiss(animated: true, completion: nil)
    
        //Notify DiaryListController that save button was pressed
        saveProtocol?.didPressSave()
    }
    
    @objc func mapPicker(_ sender: UITapGestureRecognizer){
        print("Navigate to map picker")

        guard let locationPickerController = storyboard?.instantiateViewController(withIdentifier: "LocationPickerController") as? LocationPickerController else { return }
        
        //NOTE: Activate the location picker delegate here instead of the location picker itself.
        locationPickerController.storeLocation = self
        navigationController?.pushViewController(locationPickerController, animated: true)
    }
    
    @objc func camera(_ sender: UITapGestureRecognizer){
        print("Navigate to camera")
        photoPickerManager.presentPhotoPicker(animated: true)
    }

    @objc func bad(_ sender: UITapGestureRecognizer){
        print("Feeling bad")
        mood = Mood.bad.rawValue
        badMoodBtn.backgroundColor = .gray
        averageMoodBtn.backgroundColor = UIColor(rgb:Color.purple.rawValue)
        goodMoodBtn.backgroundColor = UIColor(rgb:Color.green.rawValue)
    }
    
    @objc func average(_ sender: UITapGestureRecognizer){
        print("Feeling average")
        mood = Mood.average.rawValue
        badMoodBtn.backgroundColor = UIColor(rgb: Color.red.rawValue)
        averageMoodBtn.backgroundColor = .gray
        goodMoodBtn.backgroundColor = UIColor(rgb: Color.green.rawValue)
    }
    
    @objc func good(_ sender: UITapGestureRecognizer){
        print("Feeling good")
        mood = Mood.good.rawValue
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
//            guard let entry = self.entry else {return}
//            entry.image = image.pngData() as NSData?
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

extension DiaryEntryFormController: UITextViewDelegate{
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .gray {
            textView.text = nil
            textView.textColor = .black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "What happened today?"
            textView.textColor = .gray
        }
    }
}

extension DiaryEntryFormController:StoreLocationProtocol{
    func didGetCurrentLocation(_ location: String) {
        print("Location received from location picker: \(location)")
        addLocationBtn.setTitle(" \(location)", for: .normal)
    }
}
