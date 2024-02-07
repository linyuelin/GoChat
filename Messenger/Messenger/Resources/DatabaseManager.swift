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
    
    static func safeEmail(emailAddress: String) -> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "_")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "_")
        return safeEmail
    }
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
    public func insertUser(with user: ChatAppUser , completion: @escaping (Bool) -> Void) {
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name" : user.lastName
        ] , withCompletionBlock: { error , _ in
            guard error == nil else {
                print("データベースに書き込むのを失敗しました")
                completion(false)
                return
            }
            
            //.value を使用して "users" ノードの一時的なデータスナップショットを取得しています
            self.database.child("users").observeSingleEvent(of: .value , with: { snapshot in
                
                if var usersCollection = snapshot.value as? [[String: String]] {
                    //ユーザーディクショナリーに追加する
                    let newElement = [
                        "name": user.firstName + " " + user.lastName,
                        "email": user.safeEmail
                    ]
                    
                    usersCollection.append(newElement)
                    
                    //ユーザーを追加したコネクションアップロードする
                    self.database.child("users").setValue(usersCollection , withCompletionBlock: { error , _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        completion(true)
                    })
                }
                else {
                    //arrayを作成する
                    let newCollection: [[String: String]] = [
                        [
                            "name": user.firstName + " " + user.lastName,
                            "email": user.safeEmail
                        ]
                    ]
                    
                    //ノードを作成する
                    self.database.child("users").setValue(newCollection , withCompletionBlock: { error , _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        completion(true)
                    })
                }
            })
        })
    }
    
    public func getAllUsers(completion: @escaping (Result<[[String: String]], Error>) -> Void) {
        database.child("users").observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value as?[[String: String]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        })
    }
    
    
    public enum DatabaseError: Error {
        case failedToFetch
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
        
        var profilePictureFileName: String {
            //        afraz9-gmail-com_profile_picture.png
            
            return "\(safeEmail)_profile_picture.png"
        }
    }

