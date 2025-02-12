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
	
	return FileManager.default.fileExists(atPath: filePath.path)
}
