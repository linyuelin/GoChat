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

extension DatabaseManager {
    public func getDataFor(path: String , completion: @escaping (Result<Any , Error>) -> Void ) {
        self.database.child("\(path)").observeSingleEvent(of: .value ) { snapshot in
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
                    self?.database.child("\(otherUserEmail)/conversations").setValue(conversationId)
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
                let sender = Sender(photoURL: "", senderId: senderEmail, displayName: name)
                
                return Message(sender: sender, messageId: messageId, sentDate: date, kind: .text(content))
                
            })
            
            completion(.success(messages))
        })
        
    }
    ///対象の会話とメッセージを送信する
    public func sendMessage(to conversation: String ,name:String ,otherUserEmail: String , newMessage: Message , completion: @escaping (Bool) -> Void) {
        //新しいメッセージをmessages　に追加
        
        //送信側の latest messageをアップデート
        
        //受信側の latest messageをアップデート
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        let currentEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        database.child("\(conversation)/messages").observeSingleEvent(of: .value, with:{[weak self] snapshot in
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
            
            let newMessageEntry: [String: Any] = [
                "id": newMessage.messageId,
                "type":  newMessage.kind.messageKindString,
                "content": message,
                "date": dateString,
                "sender_email": currentUserEmail,
                "is_read": false,
                "name": name
            ]
            
            currentMessages.append(newMessageEntry)
            
            strongSelf.database.child("\(conversation)/messages").setValue(currentMessages ) {error , _ in
                guard  error == nil else {
                    completion(false)
                    return
                }
                
                strongSelf.database.child("\(currentEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                    guard var currentUserConversations = snapshot.value as? [[String: Any]] else {
                       completion(false)
                        return
                    }
                    
                    let updatedValue: [String: Any] = [
                        "date": dateString,
                        "is_read": false,
                        "message": message
                    ]
                    
                    var targetConversation: [String: Any]?
                    
                    var position = 0
                    
                    for conversationDictionary in currentUserConversations {
                        if let currentId = conversationDictionary["id"] as? String , currentId == conversation {
                            targetConversation = conversationDictionary
                            break
                        }
                        position += 1
                    }
                    
                    targetConversation?["latest_message"] = updatedValue
                    guard let finalConversation = targetConversation else {
                        completion(false)
                        return
                    }
                    currentUserConversations[position] = finalConversation
                    
                    strongSelf.database.child("\(currentEmail)/conversations").setValue(currentUserConversations , withCompletionBlock: {
                        error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        //受信側の最後のメッセージを更新する
                            
                            strongSelf.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                                guard var otherUserConversations = snapshot.value as? [[String: Any]] else {
                                   completion(false)
                                    return
                                }
                                
                                let updatedValue: [String: Any] = [
                                    "date": dateString,
                                    "is_read": false,
                                    "message": message
                                ]
                                
                                var targetConversation: [String: Any]?
                                
                                var position = 0
                                
                                for conversationDictionary in otherUserConversations {
                                    if let currentId = conversationDictionary["id"] as? String , currentId == conversation {
                                        targetConversation = conversationDictionary
                                        
                                        break
                                    }
                                    position += 1
                                }
                                
                                targetConversation?["latest_message"] = updatedValue
                                guard let finalConversation = targetConversation else {
                                    completion(false)
                                    return
                                }
                                otherUserConversations[position] = finalConversation
                                
                                strongSelf.database.child("\(otherUserEmail)/conversations").setValue(otherUserConversations , withCompletionBlock: {
                                    error, _ in
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

