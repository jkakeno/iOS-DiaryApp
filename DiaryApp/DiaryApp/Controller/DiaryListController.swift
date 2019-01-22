//
//  ViewController.swift
//  iOS-DiaryApp
//
//  Created by Jun Kakeno on 1/14/19.
//  Copyright © 2019 Jun Kakeno. All rights reserved.
//

import UIKit
import CoreData

class DiaryListController: UIViewController {
    
    enum Mood: String{
        case bad,average,good
    }

    //Add button views
    @IBOutlet weak var addBtnImage: UIImageView!
    @IBOutlet weak var addDiaryEntryBtn: UIView!
    @IBOutlet weak var addBtnDateLabel: UILabel!
    //Diary entries table view
    @IBOutlet var diaryEntryTableView: UITableView!
    
    //Store property for date
    lazy var today:String = {
        return Date().fullDate
    }()
    
    lazy var data: [Entry] = {
        let request: NSFetchRequest<Entry> = Entry.fetchRequest()
        var result:[Entry] = []
        do {
            result = try context.fetch(request)
            print("There's currently \(result.count) entries in core data.")
        } catch {
            print("Failed")
        }
        return result
    }()
    
    let context = CoreDataStack().managedObjectContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Diary List View did load")
        
        //Set up Diary Entry Add button action, image, and label
        let addEntry = UITapGestureRecognizer(target: self, action: #selector(self.addEntry(_:)))
        addDiaryEntryBtn.addGestureRecognizer(addEntry)
        addBtnImage.roundImage()
        addBtnDateLabel.text = today
        
        //Activate the extention portion of this class to get access to the datasource and delegate methods of table view. See extentions below...
        diaryEntryTableView.dataSource = self
        diaryEntryTableView.delegate = self
        
//        Delete all data in core data - only for debug
//        for entry in data {
//            context.delete(entry)
//            context.saveChanges()
//        }
        
        //TODO-NOTE: When the diary text is more than 1 full row and the entry saved the entry gets saved in core data but it doesn't show on table view. Look into saving logic of core data for this case and story board to show text up to a certain height.

        updateTableView()
    }

    @objc func addEntry(_ sender: UITapGestureRecognizer){
        print("Add a new entry for \(today)")
        guard let diaryEntryFormController = storyboard?.instantiateViewController(withIdentifier: "DiaryEntryFormController") as? DiaryEntryFormController else { return }
        diaryEntryFormController.context = self.context

        diaryEntryFormController.saveProtocol = self
        navigationController?.pushViewController(diaryEntryFormController, animated: true)
    }
    
    func updateTableView(){
        let request: NSFetchRequest<Entry> = Entry.fetchRequest()
        do {
            self.data = try context.fetch(request)
            if diaryEntryTableView != nil {
                print("Update table view")
                diaryEntryTableView.reloadData()
            }
        } catch {
            print("Failed")
        }
    }
}

//This extension enables detection when a row is tapped.
extension DiaryListController:UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let diaryEntry = data[indexPath.row]
        print("Selected an entry: \(String(describing: diaryEntry.text))")
        
        guard let diaryEntryFormController = storyboard?.instantiateViewController(withIdentifier: "DiaryEntryFormController") as? DiaryEntryFormController else { return }
        diaryEntryFormController.entry = diaryEntry
        diaryEntryFormController.context = self.context
//        diaryEntryFormController.indexPath = indexPath.row
        //NOTE: Activate the DiaryEntryForm delegate here instead of the location picker itself.
        diaryEntryFormController.saveProtocol = self
        navigationController?.pushViewController(diaryEntryFormController, animated: true)
    }
}

//This extention updates each cell of the table with the data, since data is lazy it is not initialized until it is called. Also it implements swipe delete action for a cell.
extension DiaryListController:UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cell.reuseIdentifier, for: indexPath) as! Cell
        
        let diaryEntry = data[indexPath.row]
        
        let date = diaryEntry.date as Date
        cell.date.text = date.fullDate
        
        cell.diaryImage.roundImage()
        
        if let _ = diaryEntry.image{
            cell.diaryImage.image = diaryEntry.uiImage
        }
        
        if let mood = diaryEntry.mood{
            switch mood {
            case Mood.bad.rawValue:
                cell.moodImage.roundImage()
                cell.moodImage.image = UIImage(named: "icn_bad")
            case Mood.average.rawValue:
                cell.moodImage.roundImage()
                cell.moodImage.image = UIImage(named: "icn_average")
            case Mood.good.rawValue:
                cell.moodImage.roundImage()
                cell.moodImage.image = UIImage(named: "icn_happy")
            default:
                cell.moodImage.roundImage()
            }
        }
        
        cell.diaryText.text = diaryEntry.text

        if let location = diaryEntry.location{
            cell.location.setTitle("\(location)", for:[.normal])
        }else{
            cell.location.setTitle("Add location", for: .normal)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let diaryEntry = data[indexPath.row]
        if editingStyle == .delete {
            deleteEntry(entry: diaryEntry)
            //Remove cell from table
            tableView.deleteRows(at: [indexPath], with: .fade)
            //Reload table with data
            tableView.reloadData()
        }
    }
    
    func deleteEntry(entry: Entry){
        let request: NSFetchRequest<Entry> = Entry.fetchRequest()
        do {
            print("Delete \(String(describing: entry.text))")
            context.delete(entry)
            context.saveChanges()
            //Update data with new core data context
            self.data = try context.fetch(request)
            print("Data size: \(data.count)")
        } catch {
            print("Failed")
        }
    }
}

//Adopt the protocol to implement the protocol func and detect when back btn is tapped and when save btn is tapped.
extension DiaryListController:SavePressProtocol{
    
    func didPressSave(){
        updateTableView()
    }
}




