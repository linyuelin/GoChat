//
//  StorageManager.swift
//  Messenger
//
//  Created by dreaMTank on 2024/02/04.
//

import Foundation
import FirebaseStorage
import FirebaseDatabase

/// イメージ、動画などのファイルをフェッチ、アップロード、ゲットできます
final class StorageManager {
    
    static let shared = StorageManager()
    
    //Firebase Storageの根リファレンスを初期化する
    private let storage = Storage.storage().reference()
    
    //
    private let database = Database.database().reference()
   
    /*
     /images/afraz9-gmail-com_profile_picture.png
     */
    
    public typealias UploadPictureCompletion = (Result<String , Error>) -> Void
    
    
    ///  　ストレージに画像をアップロードし、URL、文字列で完了時にコールバックを返します
    public func uploadProfilePicture(with data: Data , fileName: String , completion: @escaping UploadPictureCompletion) {
        
        storage.child("images/\(fileName)").putData(data, metadata: nil , completion: {[weak self] metadata,error in
            guard let strongSelf = self else {
                return
            }
            
            guard error == nil else {
                // 失敗
                print("firebaseに画像を送ることに失敗した")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            strongSelf.storage.child("images/\(fileName)").downloadURL(completion: {url , error in
                guard let url = url else {
                    print("ダウンロードURLのゲットに失敗した")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                let urlString = url.absoluteString
                print("ゲットしたurl: \(urlString)")
                completion(.success(urlString))
            })
        })
    }
    
    ///  　ストレージにメッセージ写真をアップロードし、URL、文字列で完了時にコールバックを返します
    public func uploadMessagePhoto(with data: Data , fileName: String , completion: @escaping UploadPictureCompletion) {
        
        storage.child("message_images/\(fileName)").putData(data, metadata: nil , completion: {[weak self] metadata,error in
            guard error == nil else {
                // 失敗
                print("firebaseに画像を送ることに失敗した")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self?.storage.child("message_images/\(fileName)").downloadURL(completion: {url , error in
                guard let url = url else {
                    print("ダウンロードURLのゲットに失敗した")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                let urlString = url.absoluteString
                print("ゲットしたurl: \(urlString)")
                completion(.success(urlString))
            })
        })
    }
    
    ///  　ストレージにメッセービデオをアップロードし、URL、文字列で完了時にコールバックを返します
    public func uploadMessageVideo(with fileUrl: URL , fileName: String , completion: @escaping UploadPictureCompletion) {
        
        storage.child("message_videos/\(fileName)").putFile(from: fileUrl, metadata: nil , completion: {[weak self] metadata,error in
            guard error == nil else {
                // 失敗
                print("firebaseにビデオを送ることに失敗した")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self?.storage.child("message_videos/\(fileName)").downloadURL(completion: {url , error in
                guard let url = url else {
                    print("ダウンロードURLのゲットに失敗した")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                let urlString = url.absoluteString
                print("ゲットしたurl: \(urlString)")
                completion(.success(urlString))
            })
        })
    }
    
    
    
    public enum StorageErrors: Error {
        case failedToUpload
        case failedToGetDownloadUrl
    }
    
    public func downloadURL(for path: String, completion:  @escaping (Result<URL , Error>) -> Void ){
        //ストレージリファレンスを作成する
        let reference = storage.child(path)
        
        reference.downloadURL(completion: { url ,error in
            guard let url = url, error == nil else {
                completion(.failure(StorageErrors.failedToGetDownloadUrl))
                return
            }
            
            
            completion(.success(url))
           
        })
    }
}
