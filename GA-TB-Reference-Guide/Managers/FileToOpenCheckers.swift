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

			if let iconURL = Bundle.main.url(forResource: "ic_title_icon", withExtension: "svg") {
				let iconPath = iconURL.relativePath

				// Replace replace the existing <img />  tag with new <img /> with relative path
				// It is this way because the image src will not always be "../assets/ic_title_icon.svg" after the first update/download

				let updatedImgTag = #"<img alt="aut" src="\#(iconPath)" width="50" height="50"/>"#
				fileContent = fileContent.replacingOccurrences(of: #"<img alt="aut" src=".*?"/>"#, with: updatedImgTag, options: .regularExpression)

				print(fileContent)

					// Optionally, write the updated content back to the file
					// Failure to update the existing fileContent will not update what the user sees
				try fileContent.write(to: filePath, atomically: true, encoding: .utf8)
			} else {
				print("Icon file not found in the bundle!")
			}
		} catch {
			print("Error reading or writing file: \(error.localizedDescription)")
		}
	} else {
		print("File \(filename).\(fileExtension) not found!")
	}
}
