//
//  ViewController.swift
//  demoMap
//
//  Created by Ankit on 05/08/21.
//

import UIKit
import MapKit
import CoreLocation
import AVFoundation

class ViewController: BaseViewController {
    
    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var getDirectionButton: UIButton!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var directionLabel: UILabel!
    var steps : [MKRoute.Step] = []
    var timer:Timer?
    let blueColor = UIColor(red: 23/255.0, green: 162/255.0, blue: 184/255.0, alpha: 1.0);
    var stepCounter = 0;
    var route:MKRoute?
    var showMapRoute = false;
    var navigationStarted = false;
    let locationDistance :Double = 500;
    var speechSynthesizer  = AVSpeechSynthesizer()
    var destinationAnnotation = MKPointAnnotation()
    
    lazy var locationManager:CLLocationManager = {
        let locationManager = CLLocationManager();
        if CLLocationManager.locationServicesEnabled(){
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            handleAuthorizationStatus(locationManager: locationManager, status: CLLocationManager.authorizationStatus())
        }else{
            print("No locationa enabled")
        }
        return locationManager
    }()
    
 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self;
        mapView.showsUserLocation = true ;
        
        startStopButton.backgroundColor = .clear
        startStopButton.layer.borderWidth = 1
        startStopButton.layer.borderColor = blueColor.cgColor
        
        searchTextField.layer.borderColor = blueColor.cgColor
        searchTextField.layer.borderColor = blueColor.cgColor
        searchTextField.layer.borderWidth = 1.0
        
        getDirectionButton.backgroundColor = .clear
        getDirectionButton.layer.borderWidth = 1
        getDirectionButton.layer.borderColor = blueColor.cgColor
        
        locationManager.stopUpdatingLocation()
        
       
       
        
    }
    
    @objc func updateLocation() {
        
        if CLLocationManager.locationServicesEnabled() {
             switch CLLocationManager.authorizationStatus() {
                case .notDetermined, .restricted, .denied:
                   print("No access")
                case .authorizedAlways, .authorizedWhenInUse:
                    
                    print ("updating user location as per timer ")
                    locationManager.startUpdatingLocation()
             }
          } else {
             print("Location services not enabled")
          }
     
    }
    
    
    @IBAction func getDirectionButtonTapped(_ sender: Any) {
        
        navigationStarted = false;
        startStopButton.setTitle(navigationStarted ? "Stop Navigation" : "Start Navigation", for: .normal)
        
        //Remove Overlay (Map path in blue color)
        let overlays = mapView.overlays
        mapView.removeOverlays(overlays)

        //Stop speech
        speechSynthesizer.stopSpeaking(at: .immediate)

        
        self.mapView.removeAnnotation(destinationAnnotation)
        
        //Search Route
        guard let text = searchTextField.text else { return}
        showMapRoute = true
        searchTextField.endEditing(true)
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(text) {placemarks, err in
            
            
            if let err = err{
                print(err.localizedDescription)
                return
            }
            guard let placemarks = placemarks,
                  let placemark = placemarks.first,
                  let location = placemark.location else {return}
            
            let destinationCordinate = location.coordinate
            
        
            // point B
                
            self.destinationAnnotation.coordinate = destinationCordinate
            self.mapView.addAnnotation(self.destinationAnnotation)
            
            self.mapRoute(destinationCoordinate: destinationCordinate)
        }
    }
    
    
    @IBAction func startStopButtonTapped(_ sender: Any) {
        if !navigationStarted{
            self.timer = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(updateLocation), userInfo: nil, repeats: true)
            showMapRoute = true
            if let location = locationManager.location{
                
                let center = location.coordinate
                centerViewToUserLocation(center: center)
                
            }
        }else{
            if let timer = self.timer {
                timer.invalidate()
                self.timer = nil
            }
            speechSynthesizer.stopSpeaking(at: .immediate)
            if let route = route {
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5), animated: true)
                self.steps.removeAll()
                self.stepCounter = 0;
            }
        }
        
        navigationStarted.toggle()
        startStopButton.setTitle(navigationStarted ? "Stop Navigation" : "Start Navigation", for: .normal)
    }
    
    

  
    
    
    fileprivate func centerViewToUserLocation(center: CLLocationCoordinate2D) {
        let region = MKCoordinateRegion(center: center, latitudinalMeters: locationDistance, longitudinalMeters: locationDistance)
        mapView.setRegion(region, animated: true)
       
        // point A
        let pin = MKPointAnnotation()
        pin.coordinate = center
        mapView.addAnnotation(pin)
        
    }
    
    fileprivate func handleAuthorizationStatus(locationManager: CLLocationManager, status: CLAuthorizationStatus) {
        
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            print("restricted")
        case .denied:
            print("denied")
        case .authorizedAlways:
            print("authorizedAlways")
        case .authorizedWhenInUse:
            
            
            if let center = locationManager.location?.coordinate{
                centerViewToUserLocation(center: center)
            }
            print("authorizedAlways")
        @unknown default:
            print("authorizedAlways")
        }
    }
    
    fileprivate func mapRoute(destinationCoordinate: CLLocationCoordinate2D) {
        
        guard let sourceCordinate = locationManager.location?.coordinate else { return}
        
        let sourcePlacemark = MKPlacemark(coordinate:sourceCordinate)
        
        let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate)
        
        let sourceItem = MKMapItem(placemark: sourcePlacemark)
        let destinationItem = MKMapItem(placemark: destinationPlacemark)
        
        let routeRequest = MKDirections.Request()
        routeRequest.source = sourceItem
        routeRequest.destination = destinationItem
        routeRequest.transportType = .automobile
        
        let directions = MKDirections(request: routeRequest)
        directions.calculate { (response, err) in
            if let err = err{
                self.showAlert(message: "Directions not available for selected destination")
                print(err.localizedDescription)
                return
            }
            
            guard let response = response ,
                  let route = response.routes.first else {return}
            
            self.route = route
            self.mapView.addOverlay(route.polyline)
            self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5), animated: true)
            self.getRouteSteps(route: route)
        }
    }
    
    fileprivate func getRouteSteps(route: MKRoute) {
        for monitoredregion   in locationManager.monitoredRegions{
            locationManager.stopMonitoring(for: monitoredregion)
        }
        
        let steps = route.steps
        self.steps = steps
        for i in 0..<steps.count{
            
            let step = steps[i]
            print(step.instructions)
            print(step.distance)
            
            let region = CLCircularRegion(center: step.polyline.coordinate, radius: 20, identifier: "\(i)")
            locationManager.stopMonitoring(for: region)
        }
        stepCounter += 1
        
        
        
      
        
        let initailmessage = "In \(converttoStr(input: steps[stepCounter].distance)) meters \(steps[stepCounter].instructions) , then in \(converttoStr(input: steps[stepCounter+1].distance)) meters \(steps[stepCounter + 1 ].instructions)"
        directionLabel.text = initailmessage;
        let speechUtter = AVSpeechUtterance(string: initailmessage)
        speechSynthesizer.speak(speechUtter)

    }
    
    
    func converttoStr(input:Double) -> String{
        return String(format: "%.2f",input)
         
    }
    
}


extension ViewController : CLLocationManagerDelegate{
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if !showMapRoute{
            if let location = locations.last{
                
                
                let center = location.coordinate
                centerViewToUserLocation(center: center)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        handleAuthorizationStatus(locationManager: locationManager, status: status)
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        stepCounter += 1
        if stepCounter  < steps.count{
            let message = "In \(steps[stepCounter].distance) meters \(steps[stepCounter].instructions) , then in \(steps[stepCounter + 1].distance) meters \(steps[stepCounter + 1 ].instructions)"
            directionLabel.text = message
            let speechUtter = AVSpeechUtterance(string: message)
            speechSynthesizer.speak(speechUtter)
            
        }else{
            let message = "You have arrived at your destination"
            directionLabel.text = message
            stepCounter = 0;
            navigationStarted = false
            for monitoredRegion in locationManager.monitoredRegions{
                locationManager.stopMonitoring(for: monitoredRegion)
            }
        }
      print("didEnterRegion")
    }
    
}

extension ViewController : MKMapViewDelegate{
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
     
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = .systemTeal
            return renderer
        
       
    }
    
    
}
