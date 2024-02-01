//
//  DatabaseManager.swift
//  Messenger
//
//  Created by dreaMTank on 2024/02/01.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager {
    
    //共有のシングルトンインスタンスを作成
    static let shared = DatabaseManager()
    
    //Firebase Realtime Database の参照を取得
    private let database = Database.database().reference()
}

// MARK: - アカウント　マネジメント
extension DatabaseManager {
    
    public func userExists(with email: String , completion: @escaping ((Bool) -> Void)) {
        
        var safeEmail = email.replacingOccurrences(of: ".", with: "_")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "_")
        
        database.child(safeEmail).observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.value as? String != nil else {
                completion(false)
                return
            }
            completion(true)
            
        })
    }
    
    /// Inserts new user to database
    public func insertUser(with user: ChatAppUser) {
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name" : user.lastName
        ])
    }
}
struct ChatAppUser {
    let firstName: String
    let lastName: String
    let emailAddress: String
    
    var safeEmail: String {
        
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "_")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "_")
        return safeEmail
    }
//    let profilePictureUrl: String
}
