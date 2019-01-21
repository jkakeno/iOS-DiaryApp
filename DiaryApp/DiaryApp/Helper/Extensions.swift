//
//  Extensions.swift
//  DiaryApp
//
//  Created by Jun Kakeno on 1/15/19.
//  Copyright © 2019 Jun Kakeno. All rights reserved.
//

import Foundation
import UIKit

extension Date {
    func localizedDescription(dateStyle: DateFormatter.Style = .medium,
                              timeStyle: DateFormatter.Style = .medium,
                              in timeZone : TimeZone = .current,
                              locale   : Locale = .current) -> String {
        Formatter.date.locale = locale
        Formatter.date.timeZone = timeZone
        Formatter.date.dateStyle = dateStyle
        Formatter.date.timeStyle = timeStyle
        return Formatter.date.string(from: self)
    }
    var localizedDescription: String { return localizedDescription() }
}

extension Date {
    var fullDate:  String { return localizedDescription(dateStyle: .full, timeStyle: .none)  }
    var shortDate: String { return localizedDescription(dateStyle: .short, timeStyle: .none)  }
    var fullTime:  String { return localizedDescription(dateStyle: .none, timeStyle: .full)  }
    var shortTime: String { return localizedDescription(dateStyle: .none, timeStyle: .short)   }
    var fullDateTime:  String { return localizedDescription(dateStyle: .full, timeStyle: .full)  }
    var shortDateTime: String { return localizedDescription(dateStyle: .short, timeStyle: .short)  }
}

extension TimeZone {
    static let gmt = TimeZone(secondsFromGMT: 0)!
}
extension Formatter {
    static let date = DateFormatter()
}

extension UIImage {
    func resized(to size: CGSize) -> UIImage? {
        //Create a rectangle.
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        //Create a bitmap-based place holder in memory of the rectangle size.
        UIGraphicsBeginImageContext(rect.size)
        
        //Draw the image in the rectangle.
        self.draw(in: rect)
        
        //Get the image from the bitmap-based place holder.
        guard let scaledImage = UIGraphicsGetImageFromCurrentImageContext() else { return nil }
        
        //Release the memory.
        UIGraphicsEndImageContext()
        
        //Return the image.
        return scaledImage
    }
}

extension UIImageView{
    func roundImage(){
        //Make round image
        //https://www.youtube.com/watch?v=V1OGv1aNveI
        self.layer.cornerRadius = self.frame.size.width / 2
        self.clipsToBounds = true
    }
}


//https://stackoverflow.com/questions/24263007/how-to-use-hex-color-values
extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}

