//
//  User.swift
//  ARPRecipeList
//
//  Created by Arturo Rivera Paniza on 23/6/2024.
//


import Foundation
import FirebaseFirestoreSwift
import FirebaseFirestore

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var username: String
    var fullName: String
    var aboutYou: String
    var userUID: String
    var userEmail: String
    var userProfPicURL: String?
    var savedRecipeIDs: [String]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case fullName
        case aboutYou
        case userUID
        case userEmail
        case userProfPicURL
        case savedRecipeIDs
    }
    
    init(id: String? = nil, username: String, fullName: String, aboutYou: String, userUID: String, userEmail: String, userProfPicURL: String? = nil, savedRecipeIDs: [String]? = nil) {
        self.id = id
        self.username = username
        self.fullName = fullName
        self.aboutYou = aboutYou
        self.userUID = userUID
        self.userEmail = userEmail
        self.userProfPicURL = userProfPicURL
        self.savedRecipeIDs = savedRecipeIDs
    }
    
    init?(dictionary: [String: Any]) {
        guard let username = dictionary["username"] as? String,
              let fullName = dictionary["fullName"] as? String,
              let aboutYou = dictionary["aboutYou"] as? String,
              let userUID = dictionary["userUID"] as? String,
              let userEmail = dictionary["userEmail"] as? String else {
            return nil
        }
        
        self.id = dictionary["id"] as? String
        self.username = username
        self.fullName = fullName
        self.aboutYou = aboutYou
        self.userUID = userUID
        self.userEmail = userEmail
        self.userProfPicURL = dictionary["userProfPicURL"] as? String
        self.savedRecipeIDs = dictionary["savedRecipeIDs"] as? [String] ?? []
    }
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "username": username,
            "fullName": fullName,
            "aboutYou": aboutYou,
            "userUID": userUID,
            "userEmail": userEmail
        ]
        if let userProfPicURL = userProfPicURL {
            dict["userProfPicURL"] = userProfPicURL
        }
        if let savedRecipeIDs = savedRecipeIDs {
            dict["savedRecipeIDs"] = savedRecipeIDs
        }
        return dict
    }
}
