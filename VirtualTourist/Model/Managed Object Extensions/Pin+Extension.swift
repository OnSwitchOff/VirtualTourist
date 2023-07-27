//
//  Pin+Extension.swift
//  VirtualTourist
//
//  Created by MacBook Pro on 27.07.23.
//
import Foundation
import CoreData

extension Pin {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        creationDate = Date()
    }
}
