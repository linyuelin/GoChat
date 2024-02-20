//
//  DatabaseManager.swift
//  Messenger
//
//  Created by dreaMTank on 2024/02/01.
//

import Foundation
import FirebaseDatabase
import MessageKit
import CoreLocation


/// リアルタイム　データーベースとのデータの送受信を行います
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

extension DatabaseManager {
    
    /// ディクショナリー　ヌードを　取得
    public func getDataFor(path: String , completion: @escaping (Result<Any , Error>) -> Void ) {
        database.child("\(path)").observeSingleEvent(of: .value ) { snapshot in
            guard let value = snapshot.value else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion( .success(value))
        }
    }
}

// MARK: - アカウント　マネジメント
extension DatabaseManager {
    
    ///  指定の電子メールに対するユーザーの存在を確認します
    /// - `email`: 確認する対象の電子メール
    /// - `completion`  結果を返す非同期クロージャ
    public func userExists(with email: String , completion: @escaping ((Bool) -> Void)) {
        
        let  safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        database.child(safeEmail).observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.value as? [String: Any] != nil else {
                completion(false)
                return
            }
            completion(true)
            
        })
    }
    
    /// 新しいユーザーをデータベースにインサート
    public func insertUser(with user: ChatAppUser , completion: @escaping (Bool) -> Void) {
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name" : user.lastName
        ] , withCompletionBlock: { [weak self] error , _ in
            
            guard let strongSelf = self else {
                return
            }
            
            guard error == nil else {
                print("データベースに書き込むのを失敗しました")
                completion(false)
                return
            }
            
            //.value を使用して "users" ノードの一時的なデータスナップショットを取得しています
            strongSelf .database.child("users").observeSingleEvent(of: .value , with: { snapshot in
               
                
                if var usersCollection = snapshot.value as? [[String: String]] {
                    //ユーザーディクショナリーに追加する
                    let newElement = [
                        "name": user.firstName + " " + user.lastName,
                        "email": user.safeEmail
                    ]
                    
                    usersCollection.append(newElement)
                    
                    //ユーザーを追加したコネクションアップロードする
                    strongSelf .database.child("users").setValue(usersCollection , withCompletionBlock: { error , _ in
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
                    strongSelf .database.child("users").setValue(newCollection , withCompletionBlock: { error , _ in
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
    
    // データーベースから全てのユーザーを取得する
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
    public func createNewConversation(with otherUserEmail: String , name: String , firstMessage: Message , completion: @escaping (Bool) -> Void) {
        //現在のユーザーのイーメール取得
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String ,
        let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
            return
        }
        
        //規則を準拠するイーメールに変換する
        let safeEmail =  DatabaseManager.safeEmail(emailAddress: currentEmail)
        
        //現在のユーザーへの参照を作成する
        let ref = database.child("\(safeEmail)")
        
        //ノードの一時的なデータスナップショットを取得しています
        ref.observeSingleEvent(of: .value, with: {[weak self] snapshot in
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
                "name": name,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            // 宛先の新しい会話データ構造を作成する
            let recipient_newConversationData: [String: Any] = [
                "id": conversationId,
                "other_user_email": safeEmail,
                "name": currentName,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            //受信側の会話をアップデート
            self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: {[weak self] snapshot in
                if var conversations = snapshot.value as? [[String: Any]] {
                    //追加
                    conversations.append(recipient_newConversationData)
                    self?.database.child("\(otherUserEmail)/conversations").setValue(conversations)
                }
                else {
                    //新設
                    self?.database.child("\(otherUserEmail)/conversations").setValue([recipient_newConversationData])
                }
            })
            
            
            //送信側の
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
                    self?.finishCreatingConversation(name: name ,conversationID: conversationId, firstMessage: firstMessage, completion: completion)
                    
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
                    self?.finishCreatingConversation(name: name,conversationID: conversationId, firstMessage: firstMessage, completion: completion)
                    
                })
            }
        })
    }
    
    //　両方のやり取り
    private func finishCreatingConversation(name: String , conversationID: String,firstMessage: Message ,completion: @escaping (Bool) -> Void) {
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
            "is_read": false,
            "name": name
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
    public func getAllConversations(for email: String , completion: @escaping (Result<[Conversation] , Error>) -> Void) {
        database.child("\(email)/conversations").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            let conversations: [Conversation] = value.compactMap({ dictionary in
                guard let conversationId = dictionary["id"] as? String ,
                      let name = dictionary["name"] as? String,
                      let otherUserEmail = dictionary["other_user_email"] as? String,
                      let latestMessage = dictionary["latest_message"] as? [String: Any],
                      let date = latestMessage["date"] as? String,
                      let message = latestMessage["message"] as? String,
                      let isRead = latestMessage["is_read"] as? Bool else {
                    return nil
                }
                let latestMessageObject = LatestMessage(date: date, text: message, isRead: isRead)
                
                
                return Conversation(id: conversationId, name: name, otherUserEmail: otherUserEmail, latestMessage: latestMessageObject)
            })
            
            completion(.success(conversations))
        })
        
    }
    
    ///指定された会話のすべてのメッセージを取得する
    public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<[Message] , Error>) -> Void) {
        database.child("\(id)/messages").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            let messages: [Message] = value.compactMap({ dictionary in
                guard let name = dictionary["name"] as? String,
                      let isRead = dictionary["is_read"] as? Bool,
                      let messageId = dictionary["id"] as? String,
                      let content = dictionary["content"] as? String,
                      let senderEmail = dictionary["sender_email"] as? String,
                      let type = dictionary["type"] as? String,
                      let dateString = dictionary["date"] as? String ,
                      let date = ChatViewController.dateFormatter.date(from: dateString) else {
                    return nil
                }
                var kind: MessageKind?
                if type == "photo"{
                    //photo
                    guard let imageUrl = URL(string: content),
                          let palceHolder = UIImage(systemName: "plus") else {
                        return nil
                    }
                    let media = Media(url: imageUrl,image: nil, placeholderImage: palceHolder, size: CGSize(width: 300, height: 300))
                    kind = .photo(media)
                }
                else if type == "video"{
                    //photo
                    guard let videoUrl = URL(string: content),
                          let palceHolder = UIImage(named: "video_placeholder") else {
                        return nil
                    }
                    let media = Media(url: videoUrl,image: nil, placeholderImage: palceHolder, size: CGSize(width: 300, height: 300))
                    kind = .video(media)
                }
                else if type == "location" {
                    let locationComponents = content.components(separatedBy: ",")
                    
                   guard let longitude =   Double(locationComponents[0]) ,
                            let latitude =  Double(locationComponents[1])  else {
                       return nil 
                   }
                    
                    let location = Location(location: CLLocation(latitude: latitude, longitude: longitude), size: CGSize(width: 300, height: 300))
                    kind =  .location(location)
                }
                
                else {
                    kind = .text(content)
                }
                
                guard let finalkind = kind else {
                    return nil
                }
                
                let sender = Sender(photoURL: "", senderId: senderEmail, displayName: name)
                
                return Message(sender: sender, messageId: messageId, sentDate: date, kind: finalkind)
                
            })
            
            completion(.success(messages))
        })
        
    }
    ///対象の会話とメッセージを送信する
   
    public func sendMessage(to conversation: String, otherUserEmail: String, name: String, newMessage: Message, completion: @escaping (Bool) -> Void) {
        // 新しいメッセージをmessagesに追加
        // 送信者の最新メッセージを更新
        // 受信者の最新メッセージを更新

        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }

        let currentEmail = DatabaseManager.safeEmail(emailAddress: myEmail)

        database.child("\(conversation)/messages").observeSingleEvent(of: .value, with: { [weak self] snapshot in
            guard let strongSelf = self else {
                return
            }

            guard var currentMessages = snapshot.value as? [[String: Any]] else {
                completion(false)
                return
            }

            let messageDate = newMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)

            var message = ""
            switch newMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString {
                    message = targetUrlString
                }
                break
            case .video(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString {
                    message = targetUrlString
                }
                break
            case .location(let locationData):
                let location = locationData.location
                message = "\(location.coordinate.longitude),\(location.coordinate.latitude)"
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .custom(_), .linkPreview(_):
                break
            }

            guard let myEmmail = UserDefaults.standard.value(forKey: "email") as? String else {
                completion(false)
                return
            }

            let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmmail)

            let newMessageEntry: [String: Any] = [
                "id": newMessage.messageId,
                "type": newMessage.kind.messageKindString,
                "content": message,
                "date": dateString,
                "sender_email": currentUserEmail,
                "is_read": false,
                "name": name
            ]

            currentMessages.append(newMessageEntry)

            strongSelf.database.child("\(conversation)/messages").setValue(currentMessages) { error, _ in
                guard error == nil else {
                    completion(false)
                    return
                }

                strongSelf.database.child("\(currentEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                    var databaseEntryConversations = [[String: Any]]()
                    let updatedValue: [String: Any] = [
                        "date": dateString,
                        "is_read": false,
                        "message": message
                    ]

                    if var currentUserConversations = snapshot.value as? [[String: Any]] {
                        var targetConversation: [String: Any]?
                        var position = 0

                        for conversationDictionary in currentUserConversations {
                            if let currentId = conversationDictionary["id"] as? String, currentId == conversation {
                                targetConversation = conversationDictionary
                                break
                            }
                            position += 1
                        }

                        if var targetConversation = targetConversation {
                            targetConversation["latest_message"] = updatedValue
                            currentUserConversations[position] = targetConversation
                            databaseEntryConversations = currentUserConversations
                        }
                        else {
                            let newConversationData: [String: Any] = [
                                "id": conversation,
                                "other_user_email": DatabaseManager.safeEmail(emailAddress: otherUserEmail),
                                "name": name,
                                "latest_message": updatedValue
                            ]
                            currentUserConversations.append(newConversationData)
                            databaseEntryConversations = currentUserConversations
                        }
                    }
                    else {
                        let newConversationData: [String: Any] = [
                            "id": conversation,
                            "other_user_email": DatabaseManager.safeEmail(emailAddress: otherUserEmail),
                            "name": name,
                            "latest_message": updatedValue
                        ]
                        databaseEntryConversations = [
                            newConversationData
                        ]
                    }

                    strongSelf.database.child("\(currentEmail)/conversations").setValue(databaseEntryConversations, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }


                        // 受信者のユーザーの最新メッセージを更新

                        strongSelf.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                            let updatedValue: [String: Any] = [
                                "date": dateString,
                                "is_read": false,
                                "message": message
                            ]
                            var databaseEntryConversations = [[String: Any]]()

                            guard let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
                                return
                            }

                            if var otherUserConversations = snapshot.value as? [[String: Any]] {
                                var targetConversation: [String: Any]?
                                var position = 0

                                for conversationDictionary in otherUserConversations {
                                    if let currentId = conversationDictionary["id"] as? String, currentId == conversation {
                                        targetConversation = conversationDictionary
                                        break
                                    }
                                    position += 1
                                }

                                if var targetConversation = targetConversation {
                                    targetConversation["latest_message"] = updatedValue
                                    otherUserConversations[position] = targetConversation
                                    databaseEntryConversations = otherUserConversations
                                }
                                else {
                                    // 現在のコレクション内で見つけることができませんでした
                                    let newConversationData: [String: Any] = [
                                        "id": conversation,
                                        "other_user_email": DatabaseManager.safeEmail(emailAddress: currentEmail),
                                        "name": currentName,
                                        "latest_message": updatedValue
                                    ]
                                    otherUserConversations.append(newConversationData)
                                    databaseEntryConversations = otherUserConversations
                                }
                            }
                            else {
                                // 現在のコレクションが存在しません
                                let newConversationData: [String: Any] = [
                                    "id": conversation,
                                    "other_user_email": DatabaseManager.safeEmail(emailAddress: currentEmail),
                                    "name": currentName,
                                    "latest_message": updatedValue
                                ]
                                databaseEntryConversations = [
                                    newConversationData
                                ]
                            }

                            strongSelf.database.child("\(otherUserEmail)/conversations").setValue(databaseEntryConversations, withCompletionBlock: { error, _ in
                                guard error == nil else {
                                    completion(false)
                                    return
                                }

                                completion(true)
                            })
                        })
                    })
                })
            }
        })
    }

    
    public func deleteConversation(conversationId: String , completion: @escaping (Bool) -> Void){
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        print("削除する会話ID: \(conversationId)")
        //ユーザーの全ての会話を取得する
        //id によってコネクションの会話を削除する
        // 残った会話をリセットする
        
        let ref = database.child("\(safeEmail)/conversations")
        
        ref.observeSingleEvent(of: .value ) { snapshot in
            if var conversations = snapshot.value as? [[String: Any]]  {
                var positionToRemove = 0
                for conversation in conversations {
                    if let id =  conversation["id"] as? String , 
                        id == conversationId {
                        print("削除する会話が見つかった")
                        break
                    }
                    positionToRemove += 1
                }
                
                conversations.remove(at: positionToRemove)
                ref.setValue(conversations, withCompletionBlock: { error, _ in
                    guard error == nil else {
                        completion(false)
                        print("新しい会話を書き込むことに失敗しました")
                        return
                    }
                    print("会話が削除されました")
                    completion(true)
                })
           }
        }
        
    }
    public func conversationExists(with targetRecipientEmail: String , completion: @escaping (Result<String, Error>) -> Void ) {
       let safeRecipientEmail =  DatabaseManager.safeEmail(emailAddress: targetRecipientEmail)
        
        guard let senderEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let safeSenderEmail = DatabaseManager.safeEmail(emailAddress: senderEmail)
        
        database.child("\(safeRecipientEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
            guard let collection = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            //　送信側によってセレクトし、更新します
            if let conversation = collection.first(where: {
                guard let targetSenderEmail  = $0["other_user_email"] as? String else {
                    return false
                }
                return safeSenderEmail ==  targetSenderEmail
            }) {
                //id 取得
                guard let id = conversation["id"] as? String else {
                    
                   completion(.failure(DatabaseError.failedToFetch))
                   return
                }
                completion(.success(id))
                return
            }
           
            completion(.failure(DatabaseError.failedToFetch))
            return
        })
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

