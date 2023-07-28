//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by MacBook Pro on 26.07.23.
//

import Foundation
import MapKit

class FlickrClient {
    static let apiKey = "2392b66c17d15a4d5d569fcfb52ad025"
    static let apiSecret = "2502f37b9fd41f20"
    static let perPage = 10
    static let sizeSuffix = "w"
    
    enum Endpoints {
        static let base = "https://www.flickr.com"
        
        case getPhotosInfoByLocation(CLLocationCoordinate2D)
        case getJpgPhoto(PhotoInfo)
        
        var stringValue: String {
            switch self {
            case .getPhotosInfoByLocation(let coordinate): return "\(FlickrClient.Endpoints.base)/services/rest/?method=flickr.photos.search&api_key=\(apiKey)&lat=\(coordinate.latitude.description)&lon=\(coordinate.longitude.description)&per_page=\(perPage)&page=\(1)&format=json&nojsoncallback=1"
            case .getJpgPhoto(let photoInfo): return
                "https://live.staticflickr.com/\(photoInfo.server)/\(photoInfo.id)_\(photoInfo.secret)_\(sizeSuffix).jpg"
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
        
        
    }
    
    func getPhotosInfoByLocation(_ coordinate: CLLocationCoordinate2D, completion: @escaping (SearchPhotosResponse?, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: FlickrClient.Endpoints.getPhotosInfoByLocation(coordinate).url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
            if let data = data {
                let decoder = JSONDecoder()
                do {
                    let responseObject = try decoder.decode(SearchPhotosResponse.self, from: data)
                    DispatchQueue.main.async {
                        completion(responseObject, nil)
                    }
                } catch {
                    do{
                        let errorResponse = try decoder.decode(ErrorResponse.self, from: data) as Error
                        DispatchQueue.main.async {
                            completion(nil, errorResponse)
                        }
                    } catch {
                        DispatchQueue.main.async {
                            completion(nil, error)
                        }
                    }
                }
            }
        }
        task.resume()
    }
    
    func getJpgPhoto(_ photoInfo: PhotoInfo, completion: @escaping (Data?, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: FlickrClient.Endpoints.getJpgPhoto(photoInfo).url) { data, response, error in
            DispatchQueue.main.async {
                completion(data, error)
            }
        }
        task.resume()
    }
}


