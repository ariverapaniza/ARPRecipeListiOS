//
//  Post.swift
//  ARPRecipeList
//
//  Created by Arturo Rivera Paniza on 01/7/2024.
//

import Foundation
import FirebaseFirestoreSwift
import FirebaseFirestore

struct Post: Identifiable, Codable, Equatable, Hashable {
    @DocumentID var id: String?
    var title: String
    var text: String
    var imageURL: URL?
    var imageReferenceID: String = ""
    var publishedDate: Date = Date()
    var likedIDs: [String] = []
    var dislikedIDs: [String] = []
    var userName: String
    var userUID: String
    var favourite: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case text
        case imageURL
        case imageReferenceID
        case publishedDate = "timestamp"
        case likedIDs
        case dislikedIDs
        case userName
        case userUID
        case favourite
    }
    
    init(id: String? = nil, title: String, text: String, imageURL: URL? = nil, userName: String, userUID: String, publishedDate: Date = Date()) {
        self.id = id
        self.title = title
        self.text = text
        self.imageURL = imageURL
        self.userName = userName
        self.userUID = userUID
        self.publishedDate = publishedDate
    }
    
    init?(dictionary: [String: Any]) {
        guard let title = dictionary["title"] as? String,
              let text = dictionary["text"] as? String,
              let userName = dictionary["userName"] as? String,
              let userUID = dictionary["userUID"] as? String,
              let timestamp = dictionary["timestamp"] as? Timestamp else {
            return nil
        }
        
        self.id = dictionary["id"] as? String
        self.title = title
        self.text = text
        self.userName = userName
        self.userUID = userUID
        self.publishedDate = timestamp.dateValue()
        self.favourite = dictionary["favourite"] as? Bool ?? false
        
        if let imageURLString = dictionary["imageURL"] as? String {
            self.imageURL = URL(string: imageURLString)
        }
    }
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "title": title,
            "text": text,
            "userName": userName,
            "userUID": userUID,
            "timestamp": Timestamp(date: publishedDate),
            "favourite": favourite
        ]
        if let imageURL = imageURL {
            dict["imageURL"] = imageURL.absoluteString
        }
        return dict
    }
}
