//
//  DetailViewController.swift
//  zaliczenie
//
//  Created by kprzystalski on 25/12/2019.
//  Copyright © 2019 kprzystalski. All rights reserved.
//

import UIKit
import MapKit

class DetailViewController: UIViewController {

    @IBOutlet private weak var productTitleLabel: UILabel!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var mapView: MKMapView!
    @IBOutlet private weak var detailTextView: UITextView!
    
    private let apiManager = ApiManager.sharedInstance
    private let regionRadius: CLLocationDistance = 1000
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }
    
    var detailItem: Product? {
        didSet {
            configureView()
        }
    }
}

private extension DetailViewController {
    func configureView() {
        if let detail = detailItem, let image = detail.image, productTitleLabel != nil, imageView != nil, mapView != nil, detailTextView != nil {
            productTitleLabel.text = detail.product
            detailTextView.text = detail.desc
            apiManager.downloadImage(for: image) { [weak self] (uiImage, error) in
                guard let self = self else { return }
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    self.imageView.image = uiImage
                }
            }
            if let latitude = Double(detail.location_lat ?? ""),
                let longitude = Double(detail.location_long ?? ""),
                let name = detail.product {
                drawMapAnnotation(location: CLLocation(latitude: latitude, longitude: longitude), name: name)
            }
        }
    }
    
    func drawMapAnnotation(location: CLLocation, name: String) {
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate,
                                                  latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
        let annotation = MKPointAnnotation()
        annotation.title = name
        annotation.coordinate = location.coordinate
        mapView.addAnnotation(annotation)
        
    }

}

