//
//  Name.swift
//  Musharakaat
//
//  Created by Owais on 2024-10-12.
//



struct Name {
    let first: String
    let last: String
    let middleInitial: String?
    var full: String {
        var name = first
        if let middleInitial {
            name += " \(middleInitial)"
        }
        name += " \(last)"
        return name
    }
}
