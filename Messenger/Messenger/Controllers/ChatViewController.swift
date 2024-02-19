//
//  ChatViewController.swift
//  Messenger
//
//  Created by dreaMTank on 2024/02/04.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import AVFoundation
import AVKit
import CoreLocation

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

struct Media: MediaItem {
    var url: URL?
    
    var image: UIImage?
    
    var placeholderImage: UIImage
    
    var size: CGSize
    
    
}

struct Location: LocationItem {
    var location: CLLocation
    
    var size: CGSize
    
    
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
        messagesCollectionView.messageCellDelegate = self
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
            self?.presentPhotoInputActionSheet()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "ビデオ", style: .default , handler: { [weak self] _ in
            self?.presentVideoInputActionSheet()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "オーディオ", style: .default , handler: { _ in
            
        }))
        actionSheet.addAction(UIAlertAction(title: "位置", style: .default , handler: {[weak self] _ in
            self?.presentLocationPicker()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "キャセル", style: .cancel , handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    private func presentLocationPicker() {
        let vc = LocationPickerViewController(coordinates: nil)
        vc.title = "場所を選択する"
        vc.navigationItem.largeTitleDisplayMode = .never
        
        vc.completion = {[weak self] selectedCoorindates in
            
            guard let strongSelf = self else {
                return
            }
            
            guard  let messageId = strongSelf.createMessageId() ,
                   let conversationId = strongSelf.conversationId ,
                    let name = strongSelf.title,
                   let selfSender = strongSelf.selfSender else {
                 return
             }
            
            let longitude: Double = selectedCoorindates.longitude
            let latitude: Double = selectedCoorindates.latitude
            
            let location = Location(location: CLLocation(latitude: latitude, longitude: longitude), size: .zero)
            
            let message = Message(sender: selfSender , messageId: messageId, sentDate: Date(), kind: .location(location))
            
            DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: message, completion: {success in
                
                if success {
                    print("位置メッセージ送信済み")
                }
                else {
                    print("位置メッセージ送信失敗")
                }
            })
        }
       
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func presentPhotoInputActionSheet(){
        let actionSheet = UIAlertController(title: "写真添付", message: "どちらから選択します", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "写真ライブラリ", style: .default , handler: {[weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker,animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "カメラ", style: .default , handler: {[weak self]  _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker,animated: true)
        }))

        actionSheet.addAction(UIAlertAction(title: "キャセル", style: .cancel , handler: nil))
        
        present(actionSheet, animated: true)
    
    }
    
    private func presentVideoInputActionSheet(){
        let actionSheet = UIAlertController(title: "ビデオ添付", message: "どちらから選択します", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "カメラ", style: .default , handler: {[weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker,animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "ライブラリ", style: .default , handler: {[weak self]  _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            self?.present(picker,animated: true)
        }))

        actionSheet.addAction(UIAlertAction(title: "キャセル", style: .cancel , handler: nil))
        
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

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    //取り消し
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    //選択済み
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        //ライブラリを閉じる
        picker.dismiss(animated: true, completion: nil)
       guard  let messageId = createMessageId() ,
        let conversationId = conversationId ,
        let name = self.title,
        let selfSender = selfSender else {
            return
        }
          //UIImagePickerController.InfoKey.editedImage: 選択したメッセージを出す
          if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage,
             //image.pngData()：　バイナリファイルに変換
             let imageData = image.pngData() {
              
              let fileName = "photo_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ""
              
              //イメージをアップロード
              StorageManager.shared.uploadMessagePhoto(with: imageData, fileName: fileName, completion:{ [weak self]result in
                  guard let strongSelf = self else {
                      return
                  }
                  
                  switch result {
                  case .success(let urlString):
                      //メッセージ送信の下準備
                      print("アップロードした画像メッセージ:\(urlString)")
                      guard let url = URL(string: urlString),let placeholder = UIImage(systemName: "plus") else {
                          return
                      }
                      
                      let media = Media(url: url, image: nil , placeholderImage: placeholder, size: .zero)
                      
                      let message = Message(sender: selfSender , messageId: messageId, sentDate: Date(), kind: .photo(media))
                      
                      DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: message, completion: {success in
                          
                          if success {
                              print("画像メッセージ送信済み")
                          }
                          else {
                              print("画像メッセージ送信失敗")
                          }
                      })
                
                  case .failure(let error):
                      print("画像メッセージのアップロードが失敗：\(error)")
                  }
              })
          }
        else if let videoUrl = info[.mediaURL] as? URL {
            let fileName = "photo_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".mov"
            
            //ビデオをダウンロード
            
            StorageManager.shared.uploadMessageVideo(with: videoUrl, fileName: fileName, completion:{ [weak self]result in
                guard let strongSelf = self else {
                    return
                }
                
                switch result {
                case .success(let urlString):
                    //メッセージ送信の下準備
                    print("アップロードしたビデオメッセージ: \(urlString)")
                    guard let url = URL(string: urlString),let placeholder = UIImage(systemName: "plus") else {
                        return
                    }
                    
                    let media = Media(url: url, image: nil , placeholderImage: placeholder, size: .zero)
                    
                    let message = Message(sender: selfSender , messageId: messageId, sentDate: Date(), kind: .video(media))
                    
                    DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: message, completion: {success in
                        
                        if success {
                            print("画像メッセージ送信済み")
                        }
                        else {
                            print("画像メッセージ送信失敗")
                        }
                    })
              
                case .failure(let error):
                    print("画像メッセージのアップロードが失敗：\(error)")
                }
            })
            
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
            DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: otherUserEmail, name: name , newMessage: message, completion: { success in
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
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        
        guard let message = message as? Message else {
            return
        }
        
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else {
                return
            }
            imageView.sd_setImage(with: imageUrl,completed: nil)
        default:
            break
        }
    }
}
    

extension ChatViewController: MessageCellDelegate {
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .location(let locationData):
            let coordinates = locationData.location.coordinate
            let vc = LocationPickerViewController(coordinates: coordinates)
            vc.title = "場所"
            self.navigationController?.pushViewController(vc, animated: true)
            
           default:
            break
        }
        
    }
    
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else {
                return
            }
            let vc = PhotoViewerViewController(with:  imageUrl)
            self.navigationController?.pushViewController(vc, animated: true)
            
        case .video(let media):
            guard let videoUrl = media.url else {
                return
            }
        
            let vc = AVPlayerViewController()
            vc.player = AVPlayer(url: videoUrl)
            present(vc , animated: true)
            
           default:
            break
        }
        

    }
}
