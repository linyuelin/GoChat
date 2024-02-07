//
//  ChatViewController.swift
//  Messenger
//
//  Created by dreaMTank on 2024/02/04.
//

import UIKit
import MessageKit
import InputBarAccessoryView

struct Message: MessageType {
   public var sender: SenderType
   public var messageId: String
   public var sentDate: Date
   public var kind: MessageKind
}

extension MessageKind {
    var messageKindString: String {
        switch self {
            
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributed_text"
        case .photo(_):
            return  "photo"
        case .video(_):
            return  "video"
        case .location(_):
            return  "location"
        case .emoji(_):
            return  "emoji"
        case .audio(_):
            return  "audio"
        case .contact(_):
            return  "contact"
        case .custom(_):
            return  "custom"
        case .linkPreview(_):
            return "linkPreview"
        }
    }
}

struct Sender: SenderType {
   public var photoURL:String
   public var senderId: String
   public var displayName: String
}

class ChatViewController: MessagesViewController  {
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        //MMM d, yyyy
        formatter.dateStyle = .medium
        //12:01:23 AM GMT+9
        formatter.timeStyle = .long
        //ローカルタイム
        formatter.locale = .current
        return formatter
    }()
    
    public var isNewConversation = false
    
    public let otherUserEmail: String

    private var messages = [Message]()
    
    private var selfSender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
       return Sender(photoURL: "", senderId: "1", displayName: "Joe Smith")
    }
    
    init(with email: String) {
        self.otherUserEmail = email
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red
    
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
    }
    
   
}
extension ChatViewController: InputBarAccessoryViewDelegate {
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty ,
        let selfSender = self.selfSender ,let messageId = createMessageId() else
        {
            return
        }
        print("発送\(text)")
        //メッセージを発信する
        if isNewConversation {
            //データベースに会話を入れる
            let message = Message(sender: selfSender , messageId: messageId, sentDate: Date(), kind: .text(text))
            
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, firstMessage: message, completion: { success in
                
                if success {
                   print("メッセージ送信した")
                }
                else {
                    print("送信に失敗した")
                }
            })
        }
        else {
            // 存在してる会話に追加
            
        }
        
    }
    
    
    private func createMessageId() -> String? {
        // date , otherUserEmail , senderEmail , randomInt
       
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else  {
            return nil
        }
        let safeCurrentEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        
         let dateString = Self.dateFormatter.string(from: Date())
        
        let newIdentifier = "\(otherUserEmail)_\(safeCurrentEmail)_\(dateString)"
        print("メッセージ番号：\(newIdentifier)")
        return newIdentifier
    }
}


extension ChatViewController: MessagesDataSource,MessagesLayoutDelegate,MessagesDisplayDelegate {
    
   
    func currentSender() -> MessageKit.SenderType {
        if let sender = selfSender {
            return sender
        }
        fatalError("セルフ送信者がnilです、メールはキャッシュされるべきです")
        return Sender(photoURL: "", senderId: "12", displayName: "")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> MessageKit.MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        return messages.count
    }
    
    
}
