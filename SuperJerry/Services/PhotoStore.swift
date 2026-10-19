import Foundation
import UIKit

/// Saves label photos as small JPEG files on this device only, so each medicine shows its own envelope.
enum PhotoStore {
    private static let folder = URL.documentsDirectory.appending(path: "LabelPhotos", directoryHint: .isDirectory)
    private static var cache: [String: UIImage] = [:]

    /// Returns the file name to keep in the medicine, or nil if saving failed.
    static func save(_ image: UIImage) -> String? {
        let name = "\(UUID().uuidString).jpg"
        let small = resized(image, maxSide: 1600)
        guard let data = small.jpegData(compressionQuality: 0.8) else { return nil }
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try data.write(to: folder.appending(path: name), options: .atomic)
            cache[name] = small
            return name
        } catch {
            print("YaoYao couldn't save the photo: \(error)")
            return nil
        }
    }

    static func load(_ name: String) -> UIImage? {
        if let cached = cache[name] { return cached }
        let image = UIImage(contentsOfFile: folder.appending(path: name).path(percentEncoded: false))
        cache[name] = image
        return image
    }

    static func delete(_ name: String) {
        cache[name] = nil
        try? FileManager.default.removeItem(at: folder.appending(path: name))
    }

    static func deleteAll() {
        cache = [:]
        try? FileManager.default.removeItem(at: folder)
    }

    /// Also turns the photo upright, so it's stored the right way round.
    private static func resized(_ image: UIImage, maxSide: CGFloat) -> UIImage {
        let scale = min(1, maxSide / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
