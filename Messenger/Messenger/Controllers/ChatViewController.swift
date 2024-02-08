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
    
    private var conversationId: String?
    
    private var messages = [Message]()
    
    private var selfSender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
       return Sender(photoURL: "", senderId: safeEmail, displayName: "自分")
        
        
    }
   
    
    init(with email: String , id: String?) {
        self.conversationId = id
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
        setupInputButton()
    }
    
    //　インプットボタン
    private func setupInputButton() {
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.onTouchUpInside{ [weak self] _ in
            self?.presentInputActionSheet()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    
    private func presentInputActionSheet(){
        let actionSheet = UIAlertController(title: "メディア添付", message: "お好きなどうぞ", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "写真", style: .default , handler: {[weak self] _ in
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "ビデオ", style: .default , handler: {[weak self] _ in
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "キャセル", style: .cancel , handler: {[weak self] _ in
            
        }))
        
        present(actionSheet, animated: true)
    }
    
    
    
    private func listenForMessages(id: String ,shouldScrollToBottom: Bool) {
        DatabaseManager.shared.getAllMessagesForConversation(with: id, completion: {[weak self] result in
            switch result {
            case .success(let messages):
                guard !messages.isEmpty else {
                    return
                }
                
                self?.messages = messages
                
                DispatchQueue.main.async{
                   
                    // チャット画面で表示されているメッセージデータを再度読み込み、同時にユーザーが現在見ている位置を保持します.ユーザーエクスペリエンスを向上させます。
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                    
                    if shouldScrollToBottom {
                        
                    self?.messagesCollectionView.scrollToBottom()
                   
                    }
                    
                }
               
            case .failure(let error):
                print("メッセージ取得に失敗")
            }
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
        if let conversationId = conversationId {
            listenForMessages(id: conversationId , shouldScrollToBottom: true)
            
        }
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
        
        let message = Message(sender: selfSender , messageId: messageId, sentDate: Date(), kind: .text(text))
        //メッセージを発信する
        if isNewConversation {
            //データベースにメッセージを入れる
            DatabaseManager.shared.createNewConversation(with: otherUserEmail,name: self.title ?? "User" , firstMessage: message, completion: { [weak self ] success in
                
                if success {
                    print("メッセージ送信した")
                    self?.isNewConversation = false
                }
                else {
                    print("送信に失敗した")
                }
            })
        }
        else {
            guard let conversationId = conversationId , let name = self.title else {
                return
            }
            // 存在してる会話に追加
            DatabaseManager.shared.sendMessage(to: conversationId, name: name, otherUserEmail: otherUserEmail , newMessage: message, completion: { success in
                if success {
                    print("メッセージ送信した")
                }
                else {
                    print("送信に失敗した")
                }
            })
            
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
    
   
    //メッセージの発信方
    func currentSender() -> MessageKit.SenderType {
        if let sender = selfSender {
            return sender
        }
        fatalError("セルフ送信者がnilです、メールはキャッシュされるべきです")
       
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> MessageKit.MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        return messages.count
    }
    
    
}
