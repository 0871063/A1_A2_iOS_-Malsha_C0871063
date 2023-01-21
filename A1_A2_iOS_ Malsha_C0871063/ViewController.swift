//
//  ViewController.swift
//  A1_A2_iOS_ Malsha_C0871063
//
//  Created by Malsha Lambton on 2023-01-20.
//

import UIKit
import MapKit

protocol HandleMapSearch: class {
    func addCityMarker(coordinate: CLLocationCoordinate2D)
}

class ViewController: UIViewController, CLLocationManagerDelegate, HandleMapSearch {
    
    
    @IBOutlet weak var mapView: MKMapView!
    var locationMnager = CLLocationManager()
    var destination = [CLLocationCoordinate2D]()
    var userAddress = ""
    
    var cityArray = ["A", "B","C"]
    var dropCount = 0
    var citySelection = false
    var destinationSelected = false
    let userCurrentLocationTitle = "User Current Location"
    var userCurrentLocation: CLLocationCoordinate2D? = nil
    var distanceLables : [UILabel] = []
    
    var resultSearchController: UISearchController!
    
    var matchingItems:[MKMapItem] = []
    var selectedPin: MKPlacemark?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.showsUserLocation = true
        mapView.isZoomEnabled = false
        
        locationMnager.delegate = self
        locationMnager.desiredAccuracy = kCLLocationAccuracyBest
        locationMnager.requestWhenInUseAuthorization()
        locationMnager.startUpdatingLocation()
        
        mapView.delegate = self
        addAnnotationOnDoubleTap()
        
        //Add Long Press
   //     let userLongPress = UILongPressGestureRecognizer(target: self, action: #selector(addAnnotationOnLongPress))
   //     mapView.addGestureRecognizer(userLongPress)
    
        let locationSearchTable = storyboard!.instantiateViewController(withIdentifier: "LocationSearchTableViewController") as! LocationSearchTableViewController
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController.searchResultsUpdater = locationSearchTable
        let searchBar = resultSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Search for places"
        navigationItem.titleView = resultSearchController?.searchBar
        resultSearchController.hidesNavigationBarDuringPresentation = false
        resultSearchController.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        locationSearchTable.mapView = mapView
        locationSearchTable.handleMapSearchDelegate = self
    }
    
    func getDirections(){
        guard let selectedPin = selectedPin else { return }
        let mapItem = MKMapItem(placemark: selectedPin)
        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        mapItem.openInMaps(launchOptions: launchOptions)
    }
    
    @IBAction func clearMap(){
        removeRroute()
        dropCount = 0
        citySelection = false
        destination.removeAll()
        destinationSelected = false
        removePin()
        for lbl in distanceLables{
            lbl.removeFromSuperview()
        }
        distanceLables.removeAll()
    }
    
    //MARK: - long press gesture recognizer for the annotation
    @objc func addAnnotationOnLongPress(gestureRecognizer: UIGestureRecognizer) {
        let touchPoint = gestureRecognizer.location(in: mapView)
        let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        addCityMarker(coordinate: coordinate)
    }
    
    //MARK: - Double Tap
    func addAnnotationOnDoubleTap() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(dropPinAtTapLocation))
        doubleTap.numberOfTapsRequired = 2
        mapView.addGestureRecognizer(doubleTap)
    }
    
    @objc func dropPinAtTapLocation(sender: UITapGestureRecognizer) {
        
        let touchPoint = sender.location(in: mapView)
        let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        addCityMarker(coordinate: coordinate)
       
    }
    
    func addCityMarker(coordinate : CLLocationCoordinate2D){
        if (dropCount == 3){
            var locationAvailable = false
            for des in destination {
                if  des == coordinate{
                    locationAvailable = true
                }
            }
            if !locationAvailable {
                clearMap()
                displayCityMarker(coordinate: coordinate)
                
            }else{
                displayLocationErrorAlert()
            }
        }
        else if (dropCount < 3){
            for des in destination {
                if  des == coordinate{
                    if let index = destination.firstIndex(of: des) {
                        destination.remove(at: index)
                    }
                    removeAnnotation(coordinate: des)
                    dropCount -= 1
                    return
                }
            }
            displayCityMarker(coordinate: coordinate)
        }
        else{
            displayLocationErrorAlert()
        }
    }
    
    func displayCityMarker(coordinate : CLLocationCoordinate2D ){
        citySelection = true
        var subtitle = ""
        if let userLocation = userCurrentLocation {
            let distanceA = calculatedistance(from: userLocation, to: coordinate)
             subtitle =  " Distance : " + String(format: "%.2f", distanceA) + " km"
        }
        
        self.displayLocation(latitude: coordinate.latitude, longitude: coordinate.longitude, title: cityArray[dropCount], subtitle: subtitle)
        destination.append(coordinate)
        destinationSelected = true
        dropCount += 1
        
        if dropCount == 3 {
            addPolygonOnMap()
            addDistanceLable()
        }
    }
    
    func displayLocationErrorAlert(){
        citySelection = false
        let alertController = UIAlertController(title: "Max Location Selection", message: "You already selected the maximum no of places", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    //MARK: - draw route between two places
    @IBAction func drawRoute() {
        if destination.count == 3 {
            mapView.removeOverlays(mapView.overlays)
            drawDestinationRoutes(sourceCoordinate: destination[0], destinationCoordinate: destination[1])
            drawDestinationRoutes(sourceCoordinate: destination[1], destinationCoordinate: destination[2])
            drawDestinationRoutes(sourceCoordinate: destination[2], destinationCoordinate: destination[0])
            
        }else{
            let alertController = UIAlertController(title: "Max Location Selection", message: "Please select 3 location to continue", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            present(alertController, animated: true, completion: nil)
        }
    }
    
    func removeRroute(){
        for annotation in mapView.annotations {
            mapView.removeAnnotation(annotation)
        }
        mapView.removeOverlays(mapView.overlays)
    }
    
    //MARK: - polygon method
    func addPolygonOnMap() {
        if  destination.count > 0 {
            let polygon = MKPolygon(coordinates: destination, count: destination.count)
            mapView.addOverlay(polygon)
        }
    }
    
    //MARK: - display user location method
    func displayLocation(latitude: CLLocationDegrees,
                         longitude: CLLocationDegrees,
                         title: String,
                         subtitle: String) {
        DispatchQueue.main.async {
            let latDelta: CLLocationDegrees = 0.05
            let lngDelta: CLLocationDegrees = 0.05
            
            let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lngDelta)
            let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let region = MKCoordinateRegion(center: location, span: span)
            self.mapView.setRegion(region, animated: true)
            
            let annotation = MKPointAnnotation()
            annotation.title = title
            annotation.subtitle = subtitle
            annotation.coordinate = location
            self.mapView.addAnnotation(annotation)
        }
    }
    
    //MARK: - didupdatelocation method
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        removePin()

        let userLocation = locations[0]
        userCurrentLocation = userLocation.coordinate
        let latitude = userLocation.coordinate.latitude
        let longitude = userLocation.coordinate.longitude
        
        getLocationAddress(latitude: latitude, longitude: longitude)
        self.displayLocation(latitude: latitude, longitude: longitude, title: userCurrentLocationTitle, subtitle: "")
        
    }
    
    //MARK: - remove pin from map
    func removePin() {
        for annotation in mapView.annotations {
            mapView.removeAnnotation(annotation)
        }
    }
    
    func removeAnnotation(coordinate : CLLocationCoordinate2D){
        for annotation in mapView.annotations {
            if annotation.coordinate.latitude == coordinate.latitude && annotation.coordinate.longitude == coordinate.longitude{
                mapView.removeAnnotation(annotation)
            }
        }
    }
    
    //MARK: - Draw Routes
    
    func drawDestinationRoutes(sourceCoordinate : CLLocationCoordinate2D , destinationCoordinate : CLLocationCoordinate2D){
        
        let sourcePlaceMark = MKPlacemark(coordinate: sourceCoordinate)
        let destinationPlaceMark = MKPlacemark(coordinate: destinationCoordinate)
              
        let directionRequest = MKDirections.Request()
        
        directionRequest.source = MKMapItem(placemark: sourcePlaceMark)
        directionRequest.destination = MKMapItem(placemark: destinationPlaceMark)
        
        directionRequest.transportType = .automobile
        
        let directions = MKDirections(request: directionRequest)
        directions.calculate { (response, error) in
            guard let directionResponse = response else {return}
            
            let route = directionResponse.routes[0]
            
            self.mapView.addOverlay(route.polyline, level: .aboveRoads)
            
            let rect = route.polyline.boundingMapRect
            
            self.mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 100, left: 100, bottom: 100, right: 100), animated: true)
        }
    }
    
     func calculatedistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
        let from = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let to = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return from.distance(from: to)/1000
    }
    
    func getLocationAddress(latitude: CLLocationDegrees, longitude : CLLocationDegrees){
        
        var center : CLLocationCoordinate2D = CLLocationCoordinate2D()
        let ceo: CLGeocoder = CLGeocoder()
        center.latitude = latitude
        center.longitude = longitude
        var address = ""
        let loc: CLLocation = CLLocation(latitude:center.latitude, longitude: center.longitude)
        
        ceo.reverseGeocodeLocation(loc, completionHandler:
                                    {(placemarks, error) in
            if (error != nil)
            {
                print("reverse geodcode fail: \(error!.localizedDescription)")
            }
            let pm = placemarks! as [CLPlacemark]
            
            if pm.count > 0 {
                if let placemark = placemarks?[0] {

                    if placemark.name != nil {
                        address += placemark.name! + " "
                    }
                    
                    if placemark.subThoroughfare != nil {
                        address += placemark.subThoroughfare! + " "
                    }
                    
                    if placemark.thoroughfare != nil {
                        address += placemark.thoroughfare! + "\n"
                    }
                    
                    if placemark.subLocality != nil {
                        address += placemark.subLocality! + "\n"
                    }
                    
                    if placemark.subAdministrativeArea != nil {
                        address += placemark.subAdministrativeArea! + "\n"
                        //                                location = placemark.subAdministrativeArea!
                    }
                    
                    if placemark.postalCode != nil {
                        address += placemark.postalCode! + "\n"
                    }
                    
                    if placemark.country != nil {
                        address += placemark.country! + "\n"
                    }
                    self.userAddress = address
                }
            }
        })
    }
}
extension ViewController: MKMapViewDelegate {
    //MARK: - viewFor annotation method
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        if citySelection {
            let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "droppablePin")
            annotationView.animatesDrop = true
            annotationView.pinTintColor = #colorLiteral(red: 0.3647058904, green: 0.06666667014, blue: 0.9686274529, alpha: 1)
            annotationView.image = UIImage(named: "ic_place_2x")
            annotationView.canShowCallout = true
            annotationView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            return annotationView
        }else{
            let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "customPin") ?? MKMarkerAnnotationView()
            annotationView.image = UIImage(named: "ic_place_2x")
            annotationView.canShowCallout = true
            annotationView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            return annotationView
        }
    }
    //MARK: - callout accessory control tapped
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let anno = view.annotation
        let annotationTitle = anno?.title as? String ?? ""
        let annotaionCoordinate = anno?.coordinate
        var title = ""
        var subtitle = "User Address : " + userAddress

        if annotationTitle != userCurrentLocationTitle {
            title =  annotationTitle
            if let userLocation = userCurrentLocation {
                if let destination = annotaionCoordinate {
                let distance = calculatedistance(from: userLocation, to: destination)
                subtitle = subtitle + " . Distance : " + String(format: "%.2f", distance) + " km"
            }
        }
           
        }else{
            title = annotationTitle
        }
            
        let alertController = UIAlertController(title: title, message: subtitle, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
        
    }
    
    //MARK: - rendrer for overlay func
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer{
        if overlay is MKPolyline {
            let rendrer = MKPolylineRenderer(overlay: overlay)
            rendrer.strokeColor = UIColor.red
//            rendrer.lineDashPattern = transportType == .walking ? [0,10] : nil
            rendrer.lineWidth = 3
            return rendrer
        } else if overlay is MKPolygon {
            let rendrer = MKPolygonRenderer(overlay: overlay)
            rendrer.fillColor = UIColor.red.withAlphaComponent(0.6)
  
            rendrer.strokeColor = UIColor.green
            rendrer.lineWidth = 2
            return rendrer
        }
        return MKOverlayRenderer()
    }
}

extension CLLocationCoordinate2D: Equatable {
    
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        
        let maxLat = lhs.latitude + 0.005
        let minLat = lhs.latitude - 0.005
        
        let maxLong = lhs.longitude + 0.005
        let minLong = lhs.longitude - 0.005
        
        return (maxLat >= rhs.latitude && rhs.latitude > minLat ) && (maxLong >= rhs.longitude && rhs.longitude > minLong)
    }
}

extension ViewController {
    
    func addDistanceLable(){
        let pointA = getpointFromCoordinate(coordinate: destination[0])
        let pointB = getpointFromCoordinate(coordinate: destination[1])
        let pointC = getpointFromCoordinate(coordinate: destination[2])
        
        let distance = calculatedistance(from: destination[0], to: destination[1])
        self.createDistanceLable(text:String(format: "%.2f", distance), from: pointA,to: pointB)
            
        let distance2 = calculatedistance(from: destination[1], to: destination[2])
        
        self.createDistanceLable(text:String(format: "%.2f", distance2), from: pointB,to: pointC)
        
        let distance3 = calculatedistance(from: destination[2], to: destination[0])
        
        self.createDistanceLable(text:String(format: "%.2f", distance3), from: pointC,to: pointB)
    }
    
    func createDistanceLable(text : String ,from : CGPoint, to : CGPoint){
        
        let position = getCenterPoints(from: from, to: to)
        
        let label = UILabel(frame: CGRect(x: position.x, y: position.y, width: 100, height: 45))
            label.textAlignment = .center
            label.text = text + " km"
        label.backgroundColor = UIColor.blue
        label.textColor = UIColor.white
            self.mapView.addSubview(label)
        self.distanceLables.append(label)
    }
    
    private func getCenterPoints(from: CGPoint, to: CGPoint) -> CGPoint {
        let dx = (from.x + to.x)/2
        let dy = (from.y + from.y)/2
        
        return CGPoint(x: dx, y: dy)
    }
    
    func getpointFromCoordinate(coordinate : CLLocationCoordinate2D) -> CGPoint{
        let point = mapView.convert(coordinate, toPointTo: mapView)
        let pointInNewView = mapView.convert(point, from: mapView)
        return pointInNewView
    }
}


