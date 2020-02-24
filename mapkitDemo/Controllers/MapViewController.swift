//
//  ViewController.swift
//  mapkitDemo
//
//  Created by Melinda Diaz on 2/24/20.
//  Copyright © 2020 Melinda Diaz. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchTextField: UITextField!
    //add this button so at any point you can click on it and go to the user location
    private var userTrackingButton: MKUserTrackingButton!
    private let locationSession = CoreLocationSession()
    private var isShowingNewAnnotations = false
    private var annotations = [MKPointAnnotation]()
    //NSLocationAlwaysAndWhenInUseUsageDescription,NSLocationWhenInUseUsageDescription must be added
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //you need this in order see the blue circle that means you are there
        mapView.showsUserLocation = true
        searchTextField.delegate = self
        //configure tackin button it sets the size
        userTrackingButton = MKUserTrackingButton(frame: CGRect(x: 20, y: 40, width: 40, height: 40))
        //its just like any other view you should addSubView
        mapView.addSubview(userTrackingButton)
        userTrackingButton.mapView = mapView
        mapView.delegate = self
        loadMap()
    
    }
    
    private func loadMap(){
        let annotations = makeAnnotations()
        mapView.addAnnotations(annotations)
    }
    
    private func makeAnnotations() -> [MKPointAnnotation] {
        var annotations = [MKPointAnnotation]()
        for location in Location.getLocations() {
            let annotation = MKPointAnnotation()
            annotation.title = location.title
            annotation.coordinate = location.coordinate
            annotations.append(annotation)
        //TODO: missing
        }
        isShowingNewAnnotations = true
        self.annotations = annotations
        return annotations
    }

    private func convertPlaceNameToCoordinate(_ placeName: String) {
        locationSession.convertPlaceNameToCoordinate(addressString: placeName) { (result) in
            switch result {
            case .failure(let error):
                print("geocoding error: \(error)")
            case .success(let coordinate):
                print("coordinate \(coordinate)")
                //set mapview at given coordinate
                //moves map to the given coordinate
                let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 1600, longitudinalMeters: 1600)
                self.mapView.setRegion(region, animated: true)
            }
        }
    }
}

extension MapViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        guard let searchText = textField.text,
        !searchText.isEmpty else {
           return true
        }
        convertPlaceNameToCoordinate(searchText)
        return true
    }
}

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        guard let annotation = view.annotation else { return }
        //you want a location of the pin
        guard let location = (Location.getLocations().filter { $0.title == annotation.title}).first else { return }
        guard let detailVC = storyboard?.instantiateViewController(identifier: "LocationDetailedViewController", creator: { (coder) in
            return LocationDetailedViewController(coder: coder, location: location)
        }) else {
            fatalError("could not document to LocationDetailedView Controller")
        }
        detailVC.modalPresentationStyle = .overCurrentContext
        detailVC.modalTransitionStyle = .partialCurl
        present(detailVC, animated: true)
        
        print("\(view.annotation?.title) was selected")
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        //similar to dequeueReusableCell
        guard annotation is MKPointAnnotation else { return nil }
        let identifier = "annotationView"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView //this has more properties thean the original pin had
        if annotationView == nil {
           annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
            annotationView?.glyphImage = UIImage(named: "duck")
            annotationView?.glyphTintColor = .systemYellow
            annotationView?.markerTintColor = .systemBlue
            //if you want use text INSTEAD of pic and text still overrride pics
            ///annotationView?.glyphText = "ios 6.3"
        } else {
            annotationView?.annotation = annotation
        }
        return annotationView
    }
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        if isShowingNewAnnotations {
            mapView.showAnnotations(annotations, animated: false)
        }
        isShowingNewAnnotations = false
        //we set it to false because setting it to true means that it will be very glitchy zooming in
    }
}
