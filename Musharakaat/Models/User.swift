//
//  User.swift
//  Musharakaat
//
//  Created by Owais on 2024-10-12.
//

import Foundation


class User {
    init(
        id: UUID,
        name: Name,
        email: String,
        listings: [Listing],
        purchases: [UUID]
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.listings = listings
        self.purchases = purchases
    }
    let id: UUID
    var name: Name
    var email: String
    var listings: [Listing]
    var purchases: [UUID]
}

