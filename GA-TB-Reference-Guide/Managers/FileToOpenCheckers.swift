//
//  FileToOpenChecker.swift
//  GA-TB-Reference-Guide
//
//  Created by Maxwell Kapezi Jr on 12/02/2025.
//

import Foundation

// Helper function to check if a file was downloaded or not, if it exists, route to points to downloaded file
func getFileURL(for filename: String, withExtension fileExtension: String = "html") -> URL {
	let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
	let filePath = documentsPath.appendingPathComponent("\(filename).\(fileExtension)")

	if FileManager.default.fileExists(atPath: filePath.path) {
		print("Loading from Documents: \(filePath)")
		return filePath
	} else {
		return Bundle.main.url(forResource: filename, withExtension: fileExtension)!
	}
}

func isFileDownloaded(for filename: String, withExtension fileExtension: String = "html") -> Bool {
	let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
	let filePath = documentsPath.appendingPathComponent("\(filename).\(fileExtension)")

	if filename == "15_appendix_district_tb_coordinators_(by_district)" {
		updateFileIfDownloaded(filename: filename)
	}

	return FileManager.default.fileExists(atPath: filePath.path)
}

func updateFileIfDownloaded(filename: String, withExtension fileExtension: String = "html") {
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let filePath = documentsPath.appendingPathComponent("\(filename).\(fileExtension)")

    if FileManager.default.fileExists(atPath: filePath.path) {
        do {
            var fileContent = try String(contentsOf: filePath, encoding: .utf8)

            // Try different ways to locate the SVG file
            if let iconURL = Bundle.main.url(forResource: "ic_title_icon", withExtension: "svg") ??
                              Bundle.main.url(forResource: "ic_title_icon.svg", withExtension: nil) {
                
                let iconPath = iconURL.path
                
                print("Found icon at: \(iconPath)") // Debug print
                
                // More flexible regex that matches the img tag with class="ic_title_icon"
                let pattern = #"<img[^>]*class="ic_title_icon"[^>]*>"#
                let updatedImgTag = #"<img alt="aut" src="\#(iconPath)" width="50" height="50" class="ic_title_icon">"#
                
                fileContent = fileContent.replacingOccurrences(of: pattern, with: updatedImgTag, options: .regularExpression)

                // Write the updated content back to the file
                try fileContent.write(to: filePath, atomically: true, encoding: .utf8)
                print("Successfully updated image source")
            } else {
                // List all bundle resources to debug
//                print("Icon file not found in the bundle!")
                if let bundlePath = Bundle.main.resourcePath {
//                    print("Bundle path: \(bundlePath)")
                    // Check if file exists at bundle path
                    let potentialIconPath = "\(bundlePath)/ic_title_icon.svg"
//                    print("Checking: \(potentialIconPath)")
//                    print("Exists: \(FileManager.default.fileExists(atPath: potentialIconPath))")
                }
            }
        } catch {
            print("Error reading or writing file: \(error.localizedDescription)")
        }
    } else {
        print("File \(filename).\(fileExtension) not found!")
    }
}
