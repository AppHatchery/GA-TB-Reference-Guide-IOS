//
//  OldRealmFile.swift
//  GA-TB-Reference-Guide
//
//  Created by Yago Arconada on 4/8/22.
//

import Foundation
import RealmSwift
import Realm

class OldRealmFile: NSObject {
    
    class var sharedInstance : OldRealmFile {
        struct signletone {
            static var instance = OldRealmFile()
        }
        return signletone.instance
    }

    
    private var kKeychainIdentifier = "Emory.GA-TB-Reference-Guide.key"
    
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
        
        // No pre-existing key from this application, so generate a new one
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
            fatalError("The encryption key could not be saved in the keychain") // you should throw an error or return nil so this can fail gracefully
            // Added here from https://github.com/realm/realm-swift/issues/5615 as a way to test if the encryption fails the first time a user accesses it
        }
        assert(status == errSecSuccess, "Failed to insert the new key in the keychain")
        
        return keyData as Data
    }
    
    func setDefaultRealmConfiguration() -> Realm.Configuration? {
        let schemaVersion: UInt64 = 2 //1 //0
        
        var config = Realm.Configuration(encryptionKey: encryptionKey())        
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
}
