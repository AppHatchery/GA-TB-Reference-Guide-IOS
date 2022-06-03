//
//  RealmHelpter.swift
//  GA-TB-Reference-Guide
//
//  Created by Yago Arconada on 4/5/22.
//

import Foundation
import RealmSwift
import Realm

class RealmHelper: NSObject {
    
    class var sharedInstance : RealmHelper {
        struct signletone {
            static var instance = RealmHelper()
        }
        return signletone.instance
    }
    
    // Next step is see if I can migrate data from this database to the other one edu.emory.tb.guide2
    
//    private var kKeychainIdentifier = "Emory.GA-TB-Reference-Guide.key"
    private var kKeychainIdentifier = "edu.emory.tb.guide"
    
    func encryptionKey() -> Data?
    {
        // Identifier for our keychain entry - should be unique for your application
        
        let keychainIdentifier = kKeychainIdentifier
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
            return dataTypeRef as? Data
        }
        
        // No pre-existing key from this application, so generate a new one (if previous step doesn't return the key)
        // Generate a random encryption key
        
        let keyData = NSMutableData(length: 64)!
        
        let result = SecRandomCopyBytes(kSecRandomDefault, 64, keyData.mutableBytes.bindMemory(to: UInt8.self, capacity: 64))
        assert(result == 0, "Failed to get random bytes")
        
        // Store the key in the keychain
        query = [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: keychainIdentifierData as AnyObject,
            kSecAttrKeySizeInBits: 512 as AnyObject,
            kSecValueData: keyData
        ]
        
        status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            return nil
            // Let's re-enable the fatalError and test the Realm encryption for a little bit, I'd be curious to see if it keeps on failing after the Data Protection capability is turned on
            // Extra info on using Realm with background activity, sounds like Realm runs on the background
        // https://www.mongodb.com/docs/realm-legacy/docs/swift/latest/#using-realm-with-background-app-refresh
//            fatalError("The encryption key could not be saved in the keychain") // you should throw an error or return nil so this can fail gracefully
            // Yago update after 1.6 (3) TestFlight release, this was crashing my phone continuosly once a day. So it seems like the app is trying to access the encryption key on the background, I'm going to try and return nil so that the background process can end, I wouldn't want to crash later though. But it seems like it's not crashing on first installs, only use case would be if a user closes the phone immediately on launch and the app didn't finish doing it's encryption pick up.
            // Added here from https://github.com/realm/realm-swift/issues/5615 as a way to test if the encryption fails the first time a user accesses it
        }
        assert(status == errSecSuccess, "Failed to insert the new key in the keychain")
        
        return keyData as Data
    }
    
    func setDefaultRealmConfiguration() -> Realm.Configuration? {
        let schemaVersion: UInt64 = 0 // Resetted to 0 because it's a new database
        
        var config = Realm.Configuration(encryptionKey: encryptionKey())
        let pathLibrary = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).map(\.path)[0]
        let dataPath = URL(fileURLWithPath: pathLibrary).appendingPathComponent("GATBRef.realm").path
        config.fileURL = URL(fileURLWithPath: dataPath)
        
        config.schemaVersion = schemaVersion
        
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
        
        return config
    }
    
    func mainRealm() -> Realm? {
        do {
            let realm = try Realm(configuration: setDefaultRealmConfiguration()!)
            return realm
        } catch let error as NSError {
            print("Error Opening realm :", error.localizedDescription)
            return nil
        }
    }
    
    func save(_ object: Object?, withCompletion saveBlock: @escaping (_ saved:Bool) -> Void) {
        let realm = mainRealm()
        do {
            try realm!.write {
                realm?.add(object!)
            }
            saveBlock(true)
        } catch let error as NSError {
            print("Error write to realm: ", error.localizedDescription)
            saveBlock(false)
        }
    }
    
    func update(_ object: Object?, properties: [AnyHashable:Any], withCompletion updateBlock: @escaping (_ updated:Bool) -> Void) {
        let realm = mainRealm()
        do {
            try realm!.write {
                for (key, value) in properties {
                    object!.setValue(value, forKeyPath: key as! String)
                }
                realm?.add(object!, update: .modified)
            }
            updateBlock(true)
        } catch let error as NSError {
            print("Error write to realm: ", error.localizedDescription)
            updateBlock(false)
        }
    }
    
    func appendNote(_ object: Object?, property: List<Notes>, itemToAppend: Notes, withCompletion appendBlock:
                @escaping (_ appended: Bool) -> Void) {
        let realm = mainRealm()
        do {
            try realm!.write {
                property.append(itemToAppend)
                realm?.add(object!, update: .modified)
            }
            appendBlock(true)
        } catch let error as NSError {
            print("Error write to realm: ", error.localizedDescription)
            appendBlock(false)
        }
    }
    
    func delete(_ object: Object?, withCompletion deleteBlock: @escaping (_ deleted:Bool) -> Void) {
        let realm = mainRealm()
        do {
            try realm!.write {
                realm?.delete(object!)
            }
            deleteBlock(true)
        } catch let error as NSError {
            print("Error deleting from realm: ", error.localizedDescription)
            deleteBlock(false)
        }
    }
}
