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
        
        // TODO: Add firebase installation
        
        let newrealm = RealmHelper.sharedInstance.mainRealm()
        
        // If newrealm is not Empty and the visitorId setting is also not empty, then it means the user installed the app in the past
        
        if !newrealm!.isEmpty {
            if UserDefaults.standard.string(forKey: "visitorId") == nil {
                let visitorId = "May-23-\(UUID())"
                UserDefaults.standard.set(visitorId, forKey: "visitorId")
            }
        }
        // Set up Pendo
        // Generate Visitor ID Upon Initial Launch
        else {
            // Generate Visitor ID Upon Initial Launch
            if UserDefaults.standard.string(forKey: "visitorId") == nil {
                let visitorId = "Aug-23-\(UUID())"
                UserDefaults.standard.set(visitorId, forKey: "visitorId")
            }
        }
        
        let accountId = "GTRG"
        
        if let visitorId = UserDefaults.standard.string(forKey: "visitorId") {
            // Use visitorID in your Pendo initialization code here
            PendoManager.shared().startSession(
                 visitorId,
                 accountId: accountId,
                 visitorData: [:],
                 accountData: [:])
        } else {
            // Handle the case where visitorID is not available (unlikely to happen)
            PendoManager.shared().startSession(
                 "",
                 accountId: accountId,
                 visitorData: [:],
                 accountData: [:])
        }
        
        // Only open this database if the new one is empty, otherwise ignore it
//        let realm = OldRealmFile.sharedInstance.mainRealm()
//        print("Tis is the old realm",realm?.objects(ContentPage.self))
        // My guess is this is triggering in the background from time to time and causing the app to launch and sometimes crash because it can't get the encryption properly, but clearly the rest of the documentation is there. Maybe the solution is to hide the failed opened state. Although something similar was failing on the previous version of the Realm architecture so maybe it just didn't get fixed with this change.
//        let newrealm = RealmHelper.sharedInstance.mainRealm()
        
        if newrealm!.isEmpty {
            let realm = OldRealmFile.sharedInstance.mainRealm()
            // If the old realm is empty then don't go through this code
            if (!realm!.isEmpty){
                try! newrealm?.write({
                    // Would unwrapping this option make the application crash??
                    if let contentRealm = realm?.objects(ContentPage.self){
                        for object in contentRealm{
                            newrealm?.create(ContentPage.self, value: object, update: .modified)
                        }
                    }
                    if let accessedRealm = realm?.objects(ContentAccess.self){
                        for object in accessedRealm{
                            newrealm?.create(ContentAccess.self, value: object, update: .modified)
                        }
                    }
                    if let notesRealm = realm?.objects(Notes.self){
                        for object in notesRealm{
                            newrealm?.create(Notes.self, value: object, update: .modified)
                        }
                    }
                    
                    if let settingsRealm = realm?.objects(UserSettings.self){
                        for object in settingsRealm{
                            newrealm?.create(UserSettings.self, value: object, update: .modified)
                        }
                    }
                })
                try! realm?.write({
                    realm?.deleteAll()
                })
                
            }
        } else {
            print("the database is already full of content from the past database!")
//            try! newrealm?.write({
//                newrealm?.deleteAll()
//            })
        }
        
        
//        print("Tis is the new realm yo (pages)!",newrealm?.objects(ContentPage.self))
//        print("Tis is the old realm after deleting supposedly",realm?.objects(ContentPage.self))
//        print("Tis is the new realm yo (content history)!",newrealm?.objects(ContentAccess.self))
//        print("Tis is the new realm yo (notes)!",newrealm?.objects(Notes.self))
        
        /*
        // Setting up Realm
        
        // Schema version represents the version of the database being used
        let schemaVersion: UInt64 = 2 //1 //0

        var config = Realm.Configuration()
        config.schemaVersion = schemaVersion
        config.encryptionKey = getKey()
        config.migrationBlock = { migration, oldSchemaVersion in
//
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
        */
        FirebaseApp.configure()
        
//        if #available(iOS 15, *) {
//            print("skip to appDidBecomeActive")
//        } else {
//            ATTrackingManager.requestTrackingAuthorization(completionHandler: { status in
//                // Tracking authorization completed. Start loading ads here.
//              })
//        }
        
        return true
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

    /*
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
        if status != errSecSuccess {
            fatalError("The encryption key could not be saved in the keychain") // you should throw an error or return nil so this can fail gracefully
            // Added here from https://github.com/realm/realm-swift/issues/5615 as a way to test if the encryption fails the first time a user accesses it
        }
        assert(status == errSecSuccess, "Failed to insert the new key in the keychain")

        return key
    }
    */
    //--------------------------------------------------------------------------------------------------
    // Adding this for 1.5 release bringing in from HomeTown
    func deleteRealm()
    {
        let realmURL = Realm.Configuration.defaultConfiguration.fileURL!
        
        let realmURLs = [
            realmURL,
            realmURL.appendingPathExtension("lock"),
            realmURL.appendingPathExtension("note"),
            realmURL.appendingPathExtension("management")
        ]
        
        for URL in realmURLs
        {
            do
            {
                try FileManager.default.removeItem(at: URL)
            }
            catch
            {
                print( error )
            }
        }
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

