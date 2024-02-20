//
//  ProfileViewModel.swift
//  Messenger
//
//  Created by dreaMTank on 2024/02/20.
//

import Foundation

enum ProfileViewModelType {
    case info , logout
}

struct ProfileViewModel {
    let viewModelType: ProfileViewModelType
    let title: String
    let handler: (() -> Void)?
}
