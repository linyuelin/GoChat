//
//  ConversationTableViewCell.swift
//  Messenger
//
//  Created by dreaMTank on 2024/02/07.
//

import UIKit
import SDWebImage

class ConversationTableViewCell: UITableViewCell {
   
    static let identifier = "ConversationTableViewCell"
    
    private let userImageView: UIImageView = {
       let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 50
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    private let userNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 21, weight: .semibold)
        return label
    }()
    
    private let userMessageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 19, weight: .regular)
        //改行できる
        label.numberOfLines = 0
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(userImageView)
        contentView.addSubview(userNameLabel)
        contentView.addSubview(userMessageLabel)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        userImageView.frame = CGRect(x: 10, y: 10, width: 100, height: 100)
        
        userNameLabel.frame = CGRect(x: userImageView.right + 10, y: 10, width: contentView.width - 20 - userImageView.width, height: (contentView.height-20)/2)
        
        userMessageLabel.frame = CGRect(x: userImageView.right + 10, y: userNameLabel.bottom + 10, width: contentView.width - 20 - userImageView.width, height: (contentView.height-20)/2)
       
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func configure(with model: Conversation) {
        
        userMessageLabel.text = model.latestMessage.text
        userNameLabel.text = model.name
        
        let path = "images/\(model.otherUserEmail)_profile_picture.png"
        StorageManager.shared.downloadURL(for: path, completion: { [weak self] result in
            switch result {
            case .success(let url) :
                
                
                DispatchQueue.main.async {
                    self?.userImageView.sd_setImage(with: url , completed: nil)
                }
               
                
            case .failure(let error) :
                print("イメージ取得に失敗した:\(error)")
            }
            
        })
    }
}
