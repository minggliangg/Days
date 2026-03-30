//
//  WidgetImageLoader.swift
//  DaysWidget
//

import UIKit
import Foundation

enum WidgetImageLoader {
    static let appGroupID = "group.com.minggliangg.Days"

    static func loadThumbnail(forImagePath imagePath: String?) -> UIImage? {
        guard let imagePath,
              let containerURL = FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            return nil
        }

        // Extract event ID from path like "images/{uuid}.jpg"
        let filename = (imagePath as NSString).lastPathComponent
        let name = (filename as NSString).deletingPathExtension

        let thumbPath = containerURL.appendingPathComponent("thumbnails/\(name).jpg")
        guard let data = try? Data(contentsOf: thumbPath) else { return nil }
        return UIImage(data: data)
    }
}
