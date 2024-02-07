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
//MARK: - メッセージの送信・会話
extension DatabaseManager {
    
     ///- パラメーター
    ///    - otherUserEmail:　向こうのイーメール
    ///    - firstMessage:　　初めてのメッセージ
    ///    - completion:　　　完成時の呼び出しクロージャ
    ///新しい相手との会話を構築して、初めてのメッセージを送信する
    public func createNewConversation(with otherUserEmail: String , firstMessage: Message , completion: @escaping (Bool) -> Void) {
        //現在のユーザーのイーメール取得
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        //規則を準拠するイーメールに変換する
       let safeEmail =  DatabaseManager.safeEmail(emailAddress: currentEmail)
        
        //現在のユーザーへの参照を作成する
        let ref = database.child("\(safeEmail)")
        
        //ノードの一時的なデータスナップショットを取得しています
        ref.observeSingleEvent(of: .value, with: { snapshot in
            guard var userNode = snapshot.value as? [String: Any] else {
                //ユーザー見つからない場合
                completion(false)
                print("ユーザーが見つかりません")
                return
            }
            
            //メッセージの送信日時を取得して、フォーマットする
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            //メッセージを初期化する
            var message = ""
            
            //メッセージのタイプによって異なる処理を行う
            switch firstMessage.kind {
                
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            //会話の唯一の識別子を作成する
            let conversationId = "conversation_\(firstMessage.messageId)"
            
            //新しい会話データ構造を作成する
            let newConversationData: [String: Any] = [
                "id": conversationId,
                "other_user_email": otherUserEmail,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                 // 現在のユーザー会話配列が存在します、追加する
                
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                //新しいヌードを書き込む
                ref.setValue(userNode,withCompletionBlock: { [weak self] error , _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(conversationID: conversationId, firstMessage: firstMessage, completion: completion)
        
                })
            }
            else {
               //　存在しません、作成
                userNode["conversations"] = [
                  newConversationData
                ]
                
                ref.setValue(userNode,withCompletionBlock: {[weak self] error , _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(conversationID: conversationId, firstMessage: firstMessage, completion: completion)
        
                })
            }
        })
    }
    
    //　両方のやり取り
    private func finishCreatingConversation(conversationID: String,firstMessage: Message ,completion: @escaping (Bool) -> Void) {
//        {
//            "id": String,
//            "type": text,photo,video ,
//            "content": String,
//            "date" : Date(),
//            "sender_email": String,
//            "isRead": true/false,
//
//        }
        
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        var message = ""
        
        switch firstMessage.kind {
            
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        let collectionMessage: [String: Any] = [
            "id": firstMessage.messageId,
            "type":  firstMessage.kind.messageKindString,
            "content": message,
            "date": dateString,
            "sender_email": currentUserEmail,
            "is_read": false
        ]
        
        let value: [String: Any] = [
            "messages":[
                collectionMessage
            ]
        ]
        
        database.child("\(conversationID)").setValue(value,withCompletionBlock: { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    ///emailで全ての会話内容を取得し、リターン
    public func getAllConversations(for email: String , completion: @escaping (Result<String , Error>) -> Void) {
        
    }
    
    ///指定された会話のすべてのメッセージを取得する
    public func getAllMessagesForConversation(with id: String , completion: @escaping (Result<String , Error>) -> Void) {
        
    }
    ///対象の会話とメッセージを送信する
    public func sendMessage(to conversation: String , message: Message , completion: @escaping (Bool) -> Void) {
        
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

