//
//  ApiManager.swift
//  zaliczenie
//
//  Created by Dmitry Vorozhbicki on 30/12/2019.
//  Copyright © 2019 kprzystalski. All rights reserved.
//

import UIKit

class ApiManager {
    static let sharedInstance = ApiManager()
    
    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }
}

extension ApiManager {
    func downloadImage(for url:String, completion:@escaping ((UIImage?, Error?) -> ())) {
        guard let urlTask = URL(string: url) else {
            completion(nil, NSError(domain:"", code:400, userInfo:[ NSLocalizedDescriptionKey: "Invaild URL"]))
            return
        }
        getData(from: urlTask) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil, error)
                return
            }
            DispatchQueue.main.async() {
                completion(UIImage(data: data), nil)
            }
        }
    }
}
