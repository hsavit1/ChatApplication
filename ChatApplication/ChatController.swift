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
    let socket = SocketIOClient(socketURL: "http://192.168.1.106:8900")//"https://floating-savannah-1961.herokuapp.com/")
    var ongoingChat = [(name: String, time:NSDate, lat:CLLocationDegrees?, lon:CLLocationDegrees?)]()
    var username: String?
    var name:String?
    var resetAck:SocketAckEmitter?

    //Manager
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.socket.connect()
        
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

//        socket.on("important message") {data, ack in
//            print("Message for you! \(data[0])")
//            ack("I got your message, and I'll send my response")
//            self.socket.emit("response", "Hello!")
//        }
//        socket.connect()

    
    }
    
    func addHandlers() {
        // Our socket handlers go here
        
        // Using a shorthand parameter name for closures
        self.socket.onAny {
            print("Got event: \($0.event), with items: \($0.items)")
        }

        self.socket.on("startGame") {[weak self] data, ack in
//            self?.handleStart()
            return
        }
    
        //[weak self] is a capture list. It tells the compiler that the reference to self in this closure should not add to the reference count of self.
    }

//    func addHandlers() {
//        self.socket.on("startGame") {[weak self] data, ack in
//            self?.handleStart()
//            return
//        }
//        
//        self.socket.on("name") {[weak self] data, ack in
//            if let name = data[0] as? String {
//                self?.name = name
//            }
//        }
//        
//        self.socket.on("playerMove") {[weak self] data, ack in
//            if let name = data[0] as? String, x = data[1] as? Int, y = data[2] as? Int {
//                self?.handlePlayerMove(name, coord: (x, y))
//            }
//        }
//        
//        self.socket.on("win") {[weak self] data, ack in
//            if let name = data[0] as? String, typeDict = data[1] as? NSDictionary {
//                self?.handleWin(name, type: typeDict)
//            }
//        }
//        
//        self.socket.on("draw") {[weak self] data, ack in
//            self?.handleDraw()
//            return
//        }
//        
//        self.socket.on("currentTurn") {[weak self] data, ack in
//            if let name = data[0] as? String {
//                self?.handleCurrentTurn(name)
//                
//            }
//        }
//        
//        self.socket.on("gameReset") {[weak self] data, ack in
//            let alert = UIAlertView(title: "Play Again?",
//                message: "Do you want to play another round?", delegate: self,
//                cancelButtonTitle: "No", otherButtonTitles: "Yes")
//            self?.resetAck = ack
//            alert.show()
//        }
//        
//        self.socket.on("gameOver") {data, ack in
//            exit(0)
//        }
//        
//        self.socket.onAny {print("Got event: \($0.event), with items: \($0.items)")}
//    }
    
    
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
        
        //AckEmitter has a variadic definition, so you can send multiple things at once if you want.
        self.socket.emit("location", text, NSDate(), lat!, lon!)
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

