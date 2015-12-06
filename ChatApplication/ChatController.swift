//
//  ViewController.swift
//  ChatApplication
//
//  Created by Henry Savit on 12/5/15.
//  Copyright © 2015 HenrySavit. All rights reserved.
//

import UIKit
import Socket_IO_Client_Swift
import CoreLocation
import MapKit
import Foundation

class ChatController: UIViewController, UITableViewDataSource, UITableViewDelegate, MKMapViewDelegate, CLLocationManagerDelegate, UITextFieldDelegate {
    
    //UI
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mapView: MKMapView!
    
    //Socket
    let socket = SocketIOClient(socketURL: "http://192.196.1.106:3000", options: [.Log(true), .ForcePolling(true)])
    var ongoingChat = [(name: String, time:NSDate, lat:CLLocationDegrees?, lon:CLLocationDegrees?)]()
    var username: String?
    var name:String?
    var resetAck:SocketAckEmitter?

    //Manager
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            self.locationManager.delegate = self
            self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            self.locationManager.startUpdatingLocation()
        }
        
        mapView.delegate = self
        
        tableView.delegate = self
        tableView.dataSource = self
        
        socket.on("connection") {data, ack in
            print("socket connected")
        }
        
        socket.on("chat message") {data, ack in
            print("Got an update! \(data[0])")
//            self.ongoingChat.append(data[0] as! (name: String, time:NSDate, lat:CLLocationDegrees?, lon:CLLocationDegrees?))
//            self.tableView.reloadData()
//            
            
//            ack("I got your message, and I'll send my response")!
//            self.socket.emit("response", "Hello!")
        }
        
        self.socket.connect()
        
        self.socket.onAny {
            print("Got event: \($0.event), with items: \($0.items)")
        
//            self.ongoingChat.append(data[0] as! (name: String, time:NSDate, lat:CLLocationDegrees?, lon:CLLocationDegrees?))
//            self.tableView.reloadData()
        }

    
    }

    
    
    // MARK:- CLLocationManagerDelegate methods
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first as CLLocation? {
             mapView.region = MKCoordinateRegionMakeWithDistance(location.coordinate, 3000, 3000)
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("there was an error")
        print(error)
    }
    
    @IBAction func shareMyLocation(sender: UIBarButtonItem) {
        if ((self.username?.characters.count) == nil){
            let usernamePrompt = UIAlertController(title: "Enter Your Name", message:nil, preferredStyle: UIAlertControllerStyle.Alert)
            usernamePrompt.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil))
            usernamePrompt.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: {
                (action) -> Void in
                    if ((usernamePrompt.textFields![0].text?.characters.count) > 0) {
                        let input = usernamePrompt.textFields![0].text!
                        self.sendAckText(input)
                        self.username = input
                    }
            }))
            var inputTextField: UITextField?
            usernamePrompt.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
                textField.placeholder = "Name"
                inputTextField = textField
            })
            presentViewController(usernamePrompt, animated: true, completion: nil)
        }
        else {
            self.sendAckText(self.username as String!)
        }
    }
    
    func sendAckText(text: String){
        let lat = self.locationManager.location?.coordinate.latitude
        let lon = self.locationManager.location?.coordinate.longitude
        
        let newElement = (text, NSDate(), lat, lon)
        self.ongoingChat.append(newElement)

        //testing ack emission with just strings
        self.socket.emit("chat message", "hey there")
//        self.socket.emit("chat message", text, NSDate(), lat!, lon!)
        print("ack emitted")
        self.tableView.reloadData()
        let indexPath = NSIndexPath(forRow: self.ongoingChat.count - 1, inSection: 0)
        self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Bottom, animated: true)
    }
    
    // MARK: UITableView Methods
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ongoingChat.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("chatCell", forIndexPath: indexPath)
        cell.textLabel?.text = "User: \(self.ongoingChat[indexPath.row].name)"
        cell.detailTextLabel?.text = "Location: \(self.ongoingChat[indexPath.row].lat as Double!), \(self.ongoingChat[indexPath.row].lon as Double!)"
        return cell
    }
    
}

