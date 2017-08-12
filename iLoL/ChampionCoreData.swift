//
//  ChampionCoreData.swift
//  iLoL
//
//  Created by Alex Wong on 8/10/17.
//  Copyright © 2017 Alex Wong. All rights reserved.
//

import Foundation
import UIKit

// MARK: - ChampionStorage

class ChampionStorage {
    
    // MARK: - Properties
    
    let imageStore = ImageStorage()
    
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()
    
    enum ChampionImageResult {
        case success(UIImage)
        case fail(Error)
    }
    
    private func processChampionImageRequest(data: Data?, error: Error?) -> ChampionImageResult {
        guard
            let imageData = data,
            let image = UIImage(data: imageData) else {
                
                // Couldn't create an image
                if data == nil {
                    return .fail(error!)
                } else {
                    return .fail(ChampionError.championImageCreationError)
                }
        }
        
        return .success(image)
    }
    
    func fetchChampionImage(for champion: ChampionDetails, completion: @escaping (ChampionImageResult) -> Void) {
        
        let photoKey = String(champion.championID)
        if let image = imageStore.image(forKey: photoKey) {
            OperationQueue.main.addOperation {
                completion(.success(image))
            }
            return
        }
        
        let photoURL = champion.photoURL
        let request = URLRequest(url: photoURL)
        
        let task = session.dataTask(with: request) {
            (data, response, error) -> Void in
            
            let result = self.processChampionImageRequest(data: data, error: error)
            
            if case let .success(image) = result {
                self.imageStore.setImage(image, forKey: photoKey)
            }
            
            OperationQueue.main.addOperation {
                completion(result)
            }
        }
        task.resume()
    }
    
    private func processChampionsRequest(data: Data?, error: Error?) -> ChampionsResult {
        guard let jsonData = data else {
            return .failure(error!)
        }
        
        return RiotClient.champions(fromJSON: jsonData)
    }
    
    func fetchChampions(completion: @escaping (ChampionsResult) -> Void) {
        let url = RiotClient.championsURL
        let request = URLRequest(url: url)
        let task = session.dataTask(with: request) {
            (data, response, error) -> Void in
            
            let result = self.processChampionsRequest(data: data, error: error)
            OperationQueue.main.addOperation {
                completion(result)
            }
        }
        task.resume()
    }
    
    
}