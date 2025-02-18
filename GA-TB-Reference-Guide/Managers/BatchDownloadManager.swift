//
//  BatchDownloadManager.swift
//  GA-TB-Reference-Guide
//
//  Created by Maxwell Kapezi Jr on 12/02/2025.
//

import Foundation
import UIKit

class BatchDownloadManager: NSObject, URLSessionDownloadDelegate {
	private var urlSession: URLSession!
	private var downloads: [(url: URL, filename: String)] = []
	private var completedDownloads = 0

	override init() {
		super.init()
		let configuration = URLSessionConfiguration.default
		urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
	}

	func startBatchDownload(files: [(url: String, filename: String)]) {
		completedDownloads = 0
		downloads.removeAll()
		
		for file in files {
			guard let url = URL(string: file.url) else {
				print("❌ Invalid URL: \(file.url)")
				continue
			}
			downloads.append((url, file.filename))
			let downloadTask = urlSession.downloadTask(with: url)
			downloadTask.resume()
		}
	}

		// URLSessionDownloadDelegate methods
	func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
		guard let url = downloadTask.originalRequest?.url,
			  let index = downloads.firstIndex(where: { $0.url == url }),
			  let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
		else {
			print("❌ Failed to retrieve original URL or documents path.")
			return
		}

		let filename = downloads[index].filename
		let destinationURL = documentsPath.appendingPathComponent(filename)

		do {
			if FileManager.default.fileExists(atPath: destinationURL.path) {
				try FileManager.default.removeItem(at: destinationURL)
			}

				// Move the downloaded file
			try FileManager.default.moveItem(at: location, to: destinationURL)

			completedDownloads += 1
			print("✅ Download completed: \(filename) (\(completedDownloads)/\(downloads.count))")

				// Post notification when all downloads complete
			if completedDownloads == downloads.count {
				DispatchQueue.main.async {
					print("📢 Posting BatchDownloadCompleted notification...")
					NotificationCenter.default.post(
						name: Notification.Name("BatchDownloadCompleted"),
						object: nil,
						userInfo: ["updatedFiles": self.downloads.map { $0.filename }]
					)
				}
			}
		} catch {
			print("❌ Error handling file \(filename): \(error.localizedDescription)")
		}
	}

		// Track progress
	func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
					didWriteData bytesWritten: Int64, totalBytesWritten: Int64,
					totalBytesExpectedToWrite: Int64)
	{
		guard let url = downloadTask.originalRequest?.url else { return }
		let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite) * 100
		print("📥 Download progress for \(url.lastPathComponent): \(String(format: "%.2f", progress))%")
	}
}
