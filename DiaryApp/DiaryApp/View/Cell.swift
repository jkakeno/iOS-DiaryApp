//
//  Cell.swift
//  DiaryApp
//
//  Created by Jun Kakeno on 1/16/19.
//  Copyright © 2019 Jun Kakeno. All rights reserved.
//

import UIKit

//This class represents a cell in table view
final class Cell: UITableViewCell {
    static let reuseIdentifier = String(describing: Cell.self)
    
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var diaryText: UILabel!
    @IBOutlet weak var diaryImage: UIImageView!
    @IBOutlet weak var moodImage: UIImageView!
    
    @IBOutlet weak var location: UIButton!
    
    
}
