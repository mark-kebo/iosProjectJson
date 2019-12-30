//
//  Constants.swift
//  zaliczenie
//
//  Created by Dmitry Vorozhbicki on 30/12/2019.
//  Copyright © 2019 kprzystalski. All rights reserved.
//

import Foundation

struct CoreDataEntities {
    static let id = "id"
    static let product = "product"
    static let descriptionJSON = "description"
    static let descriptionCD = "desc"
    static let image = "image"
    static let location_lat = "location_lat"
    static let location_long = "location_long"
}

struct Constants {
    static let serverUrl: String = "https://my-json-server.typicode.com/mark-kebo/iosUJZaliczenie/products" //typicode.com
    static let entityProductName = "Product"
    static let segueDetailsIdentifier = "showDetail"
    static let cellIdentifier = "Cell"
    static let fetchedCacheName = "Master"
}
