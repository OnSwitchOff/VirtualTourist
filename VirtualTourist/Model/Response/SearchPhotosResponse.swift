//
//  SearchPhotosResponse.swift
//  VirtualTourist
//
//  Created by MacBook Pro on 27.07.23.
//

import Foundation

struct SearchPhotosResponse: Codable {
    let photos: PhotosInfo
    let stat: String
}

struct PhotosInfo: Codable {
    let page: Int
    let pages: Int
    let perpage: Int
    let total: Int
    let photo: [PhotoInfo]?
}

struct PhotoInfo: Codable {
    let id: String
    let owner: String
    let secret: String
    let server: String
    let farm: Int
    let title: String
    let ispublic: CFBit
    let isfriend: CFBit
    let isfamily: CFBit
}
