//
//  RemoteConfigHelper.swift
//  GA-TB-Reference-Guide
//
//  Created by Maxwell Kapezi Jr on 12/02/2025.
//

import FirebaseRemoteConfig
import FirebaseRemoteConfigSwift

/// RemoteConfigHelper centralizes related app data or service logic.
class RemoteConfigHelper {
	let downloadManager = BatchDownloadManager()

	/// configure Remote Config.
	func configureRemoteConfig() {
		let remoteConfig = RemoteConfig.remoteConfig()
		let settings = RemoteConfigSettings()
		settings.minimumFetchInterval = 1
		remoteConfig.configSettings = settings

		/// Set default values
		let defaults: [String: NSObject] = [
			"update_value": 0 as NSObject
		]
		remoteConfig.setDefaults(defaults)

		/// Fetch and activate the Remote Config values
		remoteConfig.fetchAndActivate { status, error in
			if status == .successFetchedFromRemote || status == .successUsingPreFetchedData {
				let updateValue = remoteConfig.configValue(forKey: "update_value").numberValue as? Int ?? 0
				self.handleUpdateValueChange(updateValue)
			} else {
				print("Error fetching Remote Config: \(String(describing: error))")
			}
		}
	}

	/// handle Update Value Change.
	func handleUpdateValueChange(_ newValue: Int) {
		if newValue != UserDefaults.standard.integer(forKey: "last_update_value") {
			UserDefaults.standard.set(newValue, forKey: "last_update_value")

			downloadUpdatedFiles()
		}
	}

	/// download Updated Files.
	func downloadUpdatedFiles() {
		let remoteConfig = RemoteConfig.remoteConfig()
		let updateValue = remoteConfig.configValue(forKey: "update_value").numberValue as? Int ?? 0

		print("Current update value: \(updateValue)")

		let filesToDownload = [
			(url: "https://apphatchery.github.io/GA-TB-Reference-Guide-Web/pages/15_appendix_district_tb_coordinators_(by_district).html", filename: "15_appendix_district_tb_coordinators_(by_district).html"),
		]

		downloadManager.startBatchDownload(files: filesToDownload)
	}
}
