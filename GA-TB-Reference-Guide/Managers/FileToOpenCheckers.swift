//
//  FileToOpenChecker.swift
//  GA-TB-Reference-Guide
//
//  Created by Maxwell Kapezi Jr on 12/02/2025.
//

import Foundation

let filename: String = "15_appendix_district_tb_coordinators_(by_district)"
// Helper function to check if a file was downloaded or not, if it exists, route to points to downloaded file
func getFileURL(for filename: String, withExtension fileExtension: String = "html") -> URL {
	let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
	let filePath = documentsPath.appendingPathComponent("\(filename).\(fileExtension)")

	if FileManager.default.fileExists(atPath: filePath.path) {
		print("Loading from Documents: \(filePath)")
		updateFileIfDownloaded(filename: filename)
		return filePath
	} else {
		return Bundle.main.url(forResource: filename, withExtension: fileExtension)!
	}
}

func isFileDownloaded(for filename: String, withExtension fileExtension: String = "html") -> Bool {
	let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
	let filePath = documentsPath.appendingPathComponent("\(filename).\(fileExtension)")

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
				print("Icon path: \(iconPath)")

					// Replace relative path with the absolute path
				fileContent = fileContent
					.replacingOccurrences(of: "../assets/ic_title_icon.svg", with: iconPath)

					// Optionally, write the updated content back to the file
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
