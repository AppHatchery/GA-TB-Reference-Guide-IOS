//
//  AppDelegate.swift
//  GA-TB-Reference-Guide
//
//  Created by Yago Arconada on 8/20/21.

import UIKit
import RealmSwift
import Firebase
import Pendo

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Setting up Pendo
        // Set up Pendo
        let appKey = "eyJhbGciOiJSUzI1NiIsImtpZCI6IiIsInR5cCI6IkpXVCJ9.eyJkYXRhY2VudGVyIjoidXMiLCJrZXkiOiJlYThlNjdmNTAwOGIwODYzOTdmMzI0NDA4NGNjZjkxYzVjNTYyOTMxNjRkZWQ4ZDdjZDEwNGY3NzcxYjAyNDZjNDNjZjQ4OGYzMjhiNWFhMmE0ZDExZTI1NWRmMDU3YzZhMGQ5ZDgyZmI5N2NjYjcxNTg5Zjc3ZDlhNWFjMGRhMS5iOTY3ZjEyODMzZDRkZWMyZDk0ZjY1NTNiMzNkZTU0ZC44ZWQyYjFhYWIyMWIzNTZiNjhkMGM0MzNkNWE2ZGU2OTJkYTcxZjQwODI5YWYzNTQ4NGQ4YzBjYzE0OTRmNWRiIn0.iqVDaCeOBxH8egrKUGdDn4F-ITFmmbXVp_VJ2hk7_MaZSJXiPvuFCTc1nx-jyAqTfT0b-toHLPMP2EvxA1Qoi7GKscbSgb2O8WBg6Uy-QuvZVNym6n-bVnn4CLrX1j7I-oEuTrKec5PCP_bYVeOs0RrHaLF8qiX-o-HYCQCgqaM"
         PendoManager.shared().setup(appKey)
        
        // Set up Pendo
        // TODO: Add firebase installation
        // Set visitor as "" to anonymize the entries
        let visitorId = ""
        let accountId = "GTRG"
        
        PendoManager.shared().startSession(
             visitorId,
             accountId: accountId,
             visitorData: [:],
             accountData: [:]
         )
        
        // Setting up Realm
        
        // Schema version represents the version of the database being used
        let schemaVersion: UInt64 = 2 //1 //0
                
        var config = Realm.Configuration()
        config.schemaVersion = schemaVersion
        config.encryptionKey = getKey()
        config.migrationBlock = { migration, oldSchemaVersion in

            if (oldSchemaVersion < schemaVersion)
            {
                // New props are not initialized with their default values, so we manually init them here, like this:
                //
                // migration.enumerateObjects(ofType: FamilyMember.className()) { oldObject, newObject in
                //    newObject!["aNewProp"] = "aNewProp"
                // }

                print( "migration complete!" )
            }
        }
        
        Realm.Configuration.defaultConfiguration = config
        
        FirebaseApp.configure()
        
        if let current = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String?, current.compare(lastChapterIndexUpdate, options: .numeric) == .orderedDescending {
            ChapterIndex.shared.updateDates = fetchDateFromJSON()
        }


        
        
        
//        if #available(iOS 15, *) {
//            print("skip to appDidBecomeActive")
//        } else {
//            ATTrackingManager.requestTrackingAuthorization(completionHandler: { status in
//                // Tracking authorization completed. Start loading ads here.
//              })
//        }
        
        return true
    }
    
    
    func fetchDateFromJSON() -> [[String]] {
        guard let subchapterURL = Bundle.main.url(forResource: "subchapter", withExtension: "json") else {
            print("err: accessing json")
            return []
        }
        
        do {
            let data = try Data(contentsOf: subchapterURL)
            let decoder = JSONDecoder()
            if let subchapters = try? decoder.decode([Subchapter].self, from: data) {
                let dict = Dictionary(grouping: subchapters, by: {$0.chapterId}).sorted {$0.key < $1.key}
                let arr = dict.map({$0.value}).map{$0.map({$0.lastUpdated})}
//                let arr = dict.map({$0.map({$0.lastUpdated})})
                return arr
            } else {
                print("err: casting json")
            }
        }
        
        catch {
            print("err: \(error)")
        }
        
        return []
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    //--------------------------------------------------------------------------------------------------
    func getKey() -> Data
    {
        // Identifier for our keychain entry - should be unique for your application
        
        let keychainIdentifier = "Emory.GA-TB-Reference-Guide.key"
        let keychainIdentifierData = keychainIdentifier.data(using: String.Encoding.utf8, allowLossyConversion: false)!
        
        // First check in the keychain for an existing key
        
        var query: [NSString: AnyObject] = [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: keychainIdentifierData as AnyObject,
            kSecAttrKeySizeInBits: 512 as AnyObject,
            kSecReturnData: true as AnyObject
        ]
        
        // To avoid Swift optimization bug, should use withUnsafeMutablePointer() function to retrieve the keychain item
        // See also: http://stackoverflow.com/questions/24145838/querying-ios-keychain-using-swift/27721328#27721328
        
        var dataTypeRef: AnyObject?
        var status = withUnsafeMutablePointer(to: &dataTypeRef) { SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0)) }
        
        if status == errSecSuccess
        {
            // swiftlint:disable:next force_cast
            return dataTypeRef as! Data
        }
        
        // No pre-existing key from this application, so generate a new one
        // Generate a random encryption key
        
        var key = Data(count: 64)
        
        key.withUnsafeMutableBytes({ (pointer: UnsafeMutableRawBufferPointer) in
            let result = SecRandomCopyBytes(kSecRandomDefault, 64, pointer.baseAddress!)
            assert(result == 0, "Failed to get random bytes")
        })
        
        // Store the key in the keychain
        query = [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: keychainIdentifierData as AnyObject,
            kSecAttrKeySizeInBits: 512 as AnyObject,
            kSecValueData: key as AnyObject
        ]
        
        status = SecItemAdd(query as CFDictionary, nil)
        assert(status == errSecSuccess, "Failed to insert the new key in the keychain")
        
        return key
    }
    
    //--------------------------------------------------------------------------------------------------
    // Pendo Setup - disable it for now to test the dynamic links first
//    func application(_ app: UIApplication,
//     open url: URL,
//     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool
//     {
//         if url.scheme?.range(of: "pendo") != nil {
//             PendoManager.shared().initWith(url)
//             return true
//         }
//         // your code here…
//         return true
//     }
    
    //--------------------------------------------------------------------------------------------------
    // Dynamic Links
    func application(_ application: UIApplication, continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if let incomingURL = userActivity.webpageURL {
            print("incoming URL is \(incomingURL)")
        } else {
            print("note")
        }
        
      let handled = DynamicLinks.dynamicLinks().handleUniversalLink(userActivity.webpageURL!) { dynamiclink, error in
            print("came here")
          // ...
        }

      return handled
    }
    
    @available(iOS 9.0, *)
    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
        print("after here")
      return application(app, open: url,
                         sourceApplication: options[UIApplication.OpenURLOptionsKey
                           .sourceApplication] as? String,
                         annotation: "")
    }

    func application(_ application: UIApplication, open url: URL, sourceApplication: String?,
                     annotation: Any) -> Bool {
      if let dynamicLink = DynamicLinks.dynamicLinks().dynamicLink(fromCustomSchemeURL: url) {
        // Handle the deep link. For example, show the deep-linked content or
        // apply a promotional offer to the user's account.
        // ...
          print("this is the dynamic link",dynamicLink)
          
        return true
      }
        print("but not here")
      return false
    }



}

