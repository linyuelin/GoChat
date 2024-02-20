//
//  ConversationsModels.swift
//  Messenger
//
//  Created by dreaMTank on 2024/02/20.
//

import Foundation

struct Conversation {
    let id: String
    let name: String
    let otherUserEmail: String
    let latestMessage: LatestMessage
}

struct LatestMessage {
    let date: String
    let text: String
    let isRead: Bool
}
