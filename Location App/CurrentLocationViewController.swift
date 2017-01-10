//
//  FirstViewController.swift
//  Location App
//
//  Created by Yingcai Dong on 2016-12-15.
//  Copyright © 2016 Yingcai Dong. All rights reserved.
//

import UIKit
import CoreLocation

class CurrentLocationViewController: UIViewController, CLLocationManagerDelegate, Error {

    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var tagButton: UIButton!
    @IBOutlet weak var getButton: UIButton!
    
    var updatingLocation = false
    var lastLocationError: Error?
    let locationManager = CLLocationManager()
    var location: CLLocation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        updateLabels()
        configureGetButton()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func getLocation() {
        // request getting location permission
        let authorizeStatus = CLLocationManager.authorizationStatus()
        if authorizeStatus == .notDetermined {
            // pop up the aler to request permission
            locationManager.requestWhenInUseAuthorization()
            return
        }
        // some other situation
        if authorizeStatus == .denied || authorizeStatus == .restricted || !CLLocationManager.locationServicesEnabled() {
            showLocationServicesDeniedAlert()
            return
        }
        print("location service: \(CLLocationManager.locationServicesEnabled())")
        print("authorize status: \(CLLocationManager.authorizationStatus().rawValue)")
        
        if updatingLocation {
            stopLocationManager()
        } else {
            location = nil
            lastLocationError = nil
            startLocationManager()
        }
    }

    func showLocationServicesDeniedAlert() {
        // standered steps of showing alert
        // 1
        let alert = UIAlertController(title: "Location Services Disabled", message: "Please enable location services for this app in Settings.", preferredStyle: .alert)
        // 2
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        // 3
        alert.addAction(okAction)
        // 4
        present(alert, animated: true, completion: nil)
    }
    
    func updateLabels() {
        if let location = location {
            print(String(format: "latitude %+.6f, longitude %+.6f\n", location.coordinate.latitude, location.coordinate.longitude))
            latitudeLabel.text = String(format: "%.8f", location.coordinate.latitude)
            longitudeLabel.text = String(format: "%.8f", location.coordinate.longitude)
            tagButton.isHidden = false
            messageLabel.text = ""
        } else {
            latitudeLabel.text = ""
            longitudeLabel.text = ""
            addressLabel.text = ""
            tagButton.isHidden = true
            
            let statuseMessage: String
            // cast to NSError to heve NSError's property
            if let error = lastLocationError as? NSError {
                if error.domain == kCLErrorDomain && error.code == CLError.denied.rawValue {
                    statuseMessage = "Location Services Disabled"
                } else {
                    statuseMessage = "Error getting location"
                }
            } else if !CLLocationManager.locationServicesEnabled() {
                statuseMessage = "Location Services Disabled"
            } else if updatingLocation {
                statuseMessage = "Searching..."
            } else {
                statuseMessage = "Tap 'Get My Location' to Start"
            }
            
            messageLabel.text = statuseMessage
        }
    }
    
    func configureGetButton() {
        if updatingLocation {
            getButton.setTitle("Stop", for: .normal)
        } else {
            getButton.setTitle("Get My Location", for: .normal)
        }
    }
    
    func startLocationManager() {
        if CLLocationManager.locationServicesEnabled() {
            // start update location
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            updatingLocation = true
        }
    }
    func stopLocationManager() {
        if updatingLocation {
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            updatingLocation = false
        }
    }
    
    // MARK: delegate function
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("locationManger did fail with error")
        if (error as NSError).code == CLError.locationUnknown.rawValue {
            return
        }
        lastLocationError = error
        stopLocationManager()
        // here will update the label using error information
        updateLabels()
        configureGetButton()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations.last!
        let howRecent = newLocation.timestamp.timeIntervalSinceNow
        if howRecent < -5 {
            return
        }
        if newLocation.horizontalAccuracy < 0 {
            return
        }
        if location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy {
            lastLocationError = nil
            location = newLocation
            updateLabels()
            
            if newLocation.horizontalAccuracy < locationManager.desiredAccuracy {
                print("*** we are done")
                stopLocationManager()
                configureGetButton()
            }
        }
    }
}

