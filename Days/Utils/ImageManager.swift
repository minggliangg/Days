//
//  ImageManager.swift
//  Days
//

import UIKit
import Foundation

enum ImageManager {
    static let appGroupID = "group.com.minggliangg.Days"

    enum ValidationResult {
        case valid
        case tooSmall
        case tooLarge
        case unreadable
    }

    // MARK: - Validate

    static func validate(_ image: UIImage) -> ValidationResult {
        guard image.size.width > 0, image.size.height > 0 else {
            return .unreadable
        }
        if image.size.width < 50 || image.size.height < 50 {
            return .tooSmall
        }
        if let data = image.jpegData(compressionQuality: 1.0), data.count > 10 * 1024 * 1024 {
            return .tooLarge
        }
        return .valid
    }

    // MARK: - Process & Save

    @discardableResult
    static func processAndSave(image: UIImage, forEventID id: UUID) -> String? {
        guard let containerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            return nil
        }

        let imagesDir = containerURL.appendingPathComponent("images")
        let thumbnailsDir = containerURL.appendingPathComponent("thumbnails")
        try? FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: thumbnailsDir, withIntermediateDirectories: true)

        let resized = resizeImage(image, maxDimension: 1200)
        guard let jpegData = resized.jpegData(compressionQuality: 0.82) else { return nil }

        let relativePath = "images/\(id.uuidString).jpg"
        let fullPath = containerURL.appendingPathComponent(relativePath)
        do {
            try jpegData.write(to: fullPath)
        } catch {
            return nil
        }

        let thumbnail = resizeImage(image, maxDimension: 300)
        if let thumbData = thumbnail.jpegData(compressionQuality: 0.82) {
            let thumbPath = containerURL.appendingPathComponent("thumbnails/\(id.uuidString).jpg")
            try? thumbData.write(to: thumbPath)
        }

        return relativePath
    }

    // MARK: - Load

    static func loadImage(relativePath: String?) -> UIImage? {
        guard let relativePath else { return nil }
        guard let containerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            return nil
        }
        let fullURL = containerURL.appendingPathComponent(relativePath)
        guard let data = try? Data(contentsOf: fullURL) else { return nil }
        return UIImage(data: data)
    }

    static func loadThumbnail(forEventID id: UUID) -> UIImage? {
        guard let containerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            return nil
        }
        let thumbPath = containerURL.appendingPathComponent("thumbnails/\(id.uuidString).jpg")
        guard let data = try? Data(contentsOf: thumbPath) else { return nil }
        return UIImage(data: data)
    }

    // MARK: - Delete

    static func deleteImage(forEventID id: UUID) {
        guard let containerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            return
        }
        let fullPath = containerURL.appendingPathComponent("images/\(id.uuidString).jpg")
        let thumbPath = containerURL.appendingPathComponent("thumbnails/\(id.uuidString).jpg")
        try? FileManager.default.removeItem(at: fullPath)
        try? FileManager.default.removeItem(at: thumbPath)
    }

    static func deleteImage(relativePath: String?) {
        guard let relativePath else { return }
        guard let containerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            return
        }
        let fullURL = containerURL.appendingPathComponent(relativePath)
        try? FileManager.default.removeItem(at: fullURL)
    }

    // MARK: - Private

    private static func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        guard maxDimension > 0, size.width > 0, size.height > 0 else { return image }

        let longestEdge = max(size.width, size.height)
        guard longestEdge > maxDimension else { return image }

        let scale = maxDimension / longestEdge
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
