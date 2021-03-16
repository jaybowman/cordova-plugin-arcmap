//
//  NavigateRouteViewController.swift
//  testPluginApp
//
//  Created by WebDev on 12/31/20.
//
import ArcGIS
import UIKit
import AVFoundation

class NavigateRouteViewController: UIViewController  {
    private var mapLoadStatusObservable: NSKeyValueObservation?
    private var inputParams: ArcLocation = ArcLocation()
       
    @IBOutlet var navTitle: UINavigationItem!
    @IBOutlet var directionLabel: UILabel!
    @IBOutlet var directionImage: UIImageView!
    @IBOutlet var distanceLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var navigationBarButtonItem: UIBarButtonItem!
    @IBOutlet var recenterBarButtonItem: UIBarButtonItem!
    @IBOutlet var mapView: AGSMapView! {
        didSet {
            //mapView.map = AGSMap(basemap:  .openStreetMap())
            // use the villages map server
            initMap()
            
            //mapView.graphicsOverlays.add(makeRouteOverlay())
        }
    }
    
    // MARK: Instance properties
       /// The route task to solve the route between stops, using the online routing service.
       var routeTask = AGSRouteTask(url: .carRoutingService)
       /// The route result solved by the route task.
       var routeResult: AGSRouteResult!
       /// The route tracker for navigation. Use delegate methods to update tracking status.
       var routeTracker: AGSRouteTracker!
       /// A list to keep track of directions solved by the route task.
       var directionsList: [AGSDirectionManeuver] = []       
       /// The original view point that can be reset later on.
       var defaultViewPoint: AGSViewpoint?
       /// The initial location for the solved route.
       var initialLocation: AGSLocation!
       /// The graphic (with a dashed line symbol) to represent the route ahead.
       let routeAheadGraphic = AGSGraphic(geometry: nil, symbol: AGSSimpleLineSymbol(style: .solid, color: .systemRed, width: 3))
       /// The graphic to represent the route that's been traveled (initially empty).
       let routeTraveledGraphic = AGSGraphic(geometry: nil, symbol: AGSSimpleLineSymbol(style: .solid, color: .systemBlue, width: 3))
       /// Current location from mapview locationdisplay
       var startLocation = AGSPoint(x: -82.022588, y: 28.845312, spatialReference: .wgs84())
       //GISLat":28.843378630,"GISLong":-82.015351990 Petrosky PL
       var destinationLocation:  AGSPoint?
       // The actural route graphic for testing
       let actualRouteGraphic = AGSGraphic(geometry: nil, symbol: AGSSimpleLineSymbol(style: .solid, color: .green, width: 3))
    
       /// A formatter to format a time value into human readable string.
       let timeFormatter: DateComponentsFormatter = {
           let formatter = DateComponentsFormatter()
           formatter.allowedUnits = [.hour, .minute]
           formatter.unitsStyle = .full
           return formatter
       }()
       /// An AVSpeechSynthesizer for text to speech.
       let speechSynthesizer = AVSpeechSynthesizer()
       
      
    init (location: ArcLocation){
        super.init(nibName: nil, bundle: nil)
        licenseApplication()
        
     // FOR DEBUGGING ONLY
     // AGSRequestConfiguration.global().debugLogRequests = true
     //  let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
     //  AGSRequestConfiguration.global().debugLogFileURL = URL(fileURLWithPath: "debug.md", relativeTo: documentURL)
        
        inputParams = location
        destinationLocation = AGSPoint(x: location.longitude, y: location.latitude, spatialReference: .wgs84())
        
        if inputParams.route == RouteType.GOLF_CART {
            routeTask = .init(url: .golfRoutingService)
        }
              
    }
        
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: Instance methods
    
    
    func licenseApplication() {
        do {
            try AGSArcGISRuntimeEnvironment.setLicenseKey(.licenseKey)
        } catch {
            print("[Error: ArcGISRuntimeEnvronemnt] \(error.localizedDescription)")
        }
    }
    
    func initMap() {
        let layer = AGSArcGISTiledLayer(url: .villagesMapService)
        let base = AGSBasemap(baseLayer: layer)
        mapView.map = AGSMap(basemap: base)
        let point = AGSPoint(x: TestPoints.longitude, y: TestPoints.latitude, spatialReference: AGSSpatialReference.wgs84())
        let vpoint = AGSViewpoint.init(center: point, scale: 54000)
        mapView.map!.initialViewpoint = vpoint
                
//        mapLoadStatusObservable = mapView.map!.observe(\.loadStatus, options: .initial) { [weak self] (_, _) in
//               //update the banner label on main thread
//            DispatchQueue.main.async { [weak self] in
//                self?.setStatus(message: "Status: \(String(describing: self?.mapView.map!.loadStatus.title))")
//            }
//            if self?.mapView.map?.loadStatus == .loaded {
//               self?.setupLocationDisplay()
//            }
//        }
       // mapView.touchDelegate = self
    }
    
    // This will cause a location display datasource change event and we can capture the current location.
    func setupLocationDisplay () {
        mapView.locationDisplay.autoPanMode = .navigation
        mapView.locationDisplay.wanderExtentFactor = 0.5
        mapView.locationDisplay.locationChangedHandler = { [weak self] (location) in
            guard let self = self else {return}
           
            self.startLocation = location.position!
            
            self.mapView.graphicsOverlays.add(self.makeRouteOverlay())
            
            self.mapView.locationDisplay.locationChangedHandler = nil
            
            self.mapView.locationDisplay.stop()
            
        }
        
        mapView.locationDisplay.start(completion:) {[weak self] (error) in
            guard let self = self else {return}
            if let error = error {
                print(error)
                return
            }
            
            if self.mapView.locationDisplay.started {
                print("Location display started.")
                //self.mapView.locationDisplay.stop()
             
                //self.mapView.locationDisplay.locationChangedHandler = nil
            }
        }
    }
          
    func presentAlert(error: Error){
        let alert = UIAlertController( title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        let dismiss = UIAlertAction (title: "Dismiss", style: .default, handler: nil)
        alert.addAction(dismiss)
        present(alert, animated: true, completion: nil)
    }
    
    /// A wrapper function for operations after the route is solved by an `AGSRouteTask`.
    ///
    /// - Parameter result: The result of the solve route operation.
    func didSolveRoute(with result: Result<AGSRouteResult, Error>) {
        switch result {
        case .success(let routeResult):
            self.routeResult = routeResult
            setNavigation(with: routeResult)
            navigationBarButtonItem.isEnabled = true
        case .failure(let error):
            print(error)
            setStatus(message: "Failed to solve route.")
            navigationBarButtonItem.isEnabled = false
        }
    }
    
    /// Make a graphics overlay with graphics.
    ///
    /// - Returns: A new `AGSGraphicsOverlay` object.
    func makeRouteOverlay() -> AGSGraphicsOverlay {
        // The graphics overlay for the polygon and points.
        let graphicsOverlay = AGSGraphicsOverlay()
        // Create a graphic for the start location.
        let startSymbol = AGSSimpleMarkerSymbol(style: .diamond, color: .green, size: 20)
        let startGraphic = AGSGraphic(geometry: startLocation, symbol: startSymbol)
        // Create a graphic for the destination location.
        let destinationSymbol = AGSSimpleMarkerSymbol(style: .X, color: .red, size: 20)
        let destinationGraphic = AGSGraphic(geometry: destinationLocation, symbol: destinationSymbol)
        // Add graphics to the graphics overlay.
        graphicsOverlay.graphics.addObjects(from: [startGraphic, destinationGraphic, routeAheadGraphic, routeTraveledGraphic])
        return graphicsOverlay
    }
    
    /// Create the stops for the navigation.
    ///
    /// - Returns: An array of `AGSStop` objects.
    //MARK:Use this for simulation
    func makeStops() -> [AGSStop] {
        let stop1 = AGSStop(point: startLocation)
        stop1.name = "current location"
        let stop2 = AGSStop(point: destinationLocation!)
        stop2.name = inputParams.address
        return [stop1, stop2]
    }
    
    /// Make a route tracker to provide navigation information.
    ///
    /// - Parameter result: An `AGSRouteResult` object used to configure the route tracker.
    /// - Returns: An `AGSRouteTracker` object.
    func makeRouteTracker(result: AGSRouteResult) -> AGSRouteTracker {
        let tracker = AGSRouteTracker(routeResult: result, routeIndex: 0, skipCoincidentStops: true)!
        if routeTask.routeTaskInfo().supportsRerouting {
            tracker.enableRerouting(with: routeTask, routeParameters: routeParameters!, strategy: .toNextWaypoint, visitFirstStopOnStart: false) { error in
                if let error = error {
                    print(error)
                }
            }
        }
        tracker.delegate = self
        tracker.voiceGuidanceUnitSystem = Locale.current.usesMetricSystem ? .metric : .imperial
        return tracker
    }
   
    /// The location data source provided by a local GPX file.
    var gpxDataSource: AGSGPXLocationDataSource?
    
    /// Set route tracker, data source, and location display with a solved route result.
    ///
    /// - Parameter routeResult: An `AGSRouteResult` object.
    func setNavigation(with routeResult: AGSRouteResult) {
        // Set the route tracker
        routeTracker = makeRouteTracker(result: routeResult)
        
        // Set the mock location data source.
        let firstRoute = routeResult.routes.first!
        directionsList = firstRoute.directionManeuvers
        // GET Distance and time
        let distanceRemaining =  Double(round(100*(firstRoute.totalLength / 1609.3))/100)
        let timeRemaining = timeFormatter.string(from: TimeInterval(firstRoute.travelTime * 60 * 3))! // add fudge factor of 4
        
        let distanceText = """
        \(distanceRemaining) mi
        """
        let timeText = """
        \(timeRemaining)
        """
        DispatchQueue.main.async { [self] in
            self.distanceLabel.text = distanceText
            self.timeLabel.text = timeText
        }
        
        // Create the data source from a local GPX file.
        //let gpxDataSource = AGSGPXLocationDataSource(name: "TESTROUTE")
        //self.gpxDataSource = gpxDataSource
        //MARK: Line 205 is for simulation. Line 207 is for using your own location
        // Create a route tracker location data source to snap the location display to the route.
        //let routeTrackerLocationDataSource = AGSRouteTrackerLocationDataSource(routeTracker: routeTracker, locationDataSource: gpxDataSource)

        let routeTrackerLocationDataSource = AGSRouteTrackerLocationDataSource(routeTracker: routeTracker)
        
        // Set location display.
        mapView.locationDisplay.dataSource = routeTrackerLocationDataSource
        recenter()
        
        // Update graphics and viewpoint.
        let firstRouteGeometry = firstRoute.routeGeometry!
        updateRouteGraphics(remaining: firstRouteGeometry)
        updateViewpoint(geometry: firstRouteGeometry)
    }
    
    
    /// Update the viewpoint so that it reflects the original viewpoint when the example is loaded.
    ///
    /// - Parameter result: An `AGSGeometry` object used to update the view point.
    func updateViewpoint(geometry: AGSGeometry) {
        // Show the resulting route on the map and save a reference to the route.
        if let viewPoint = defaultViewPoint {
            // Reset to initial view point with animation.
            mapView.setViewpoint(viewPoint, completion: nil)
        } else {
            mapView.setViewpointGeometry(geometry) { [weak self] _ in
                // Get the initial zoomed view point.
                self?.defaultViewPoint = self?.mapView.currentViewpoint(with: .centerAndScale)
            }
        }
    }
        
    
    // MARK: UI
    func setStatus(message: String) {
        directionLabel.text = message
    }
    
    // MARK: Actions
    @IBAction func directionsButton(_ sender: Any) {
        // show modal popup
        var dirlist = [String]()
        for item in directionsList {
            dirlist.append(item.directionText )           
        }
        let listModalView = DirectionsViewController(directions: dirlist)
        listModalView.modalPresentationStyle = .automatic
        self.present(listModalView, animated: true, completion: nil)
        
    }
    @IBAction func navBarBackButton(_ sender: UIBarButtonItem) {
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func startnavigation(_ sender: Any) {
      
        navigationBarButtonItem.image = UIImage(systemName: "stop.fill")
        
        if mapView.locationDisplay.started {
            reset()
            return
        }
                  
        // Start the location data source and location display.
        mapView.locationDisplay.start(completion: ) { (error) in
            if let error = error {
                print(error)
            }
        }
    }
    
       
    func reset() {
         // Stop the speech, if there is any.
        speechSynthesizer.stopSpeaking(at: .immediate)
        // Reset to the starting location for location display.
        guard let initialLocation = mapView.locationDisplay.location else { return }
        mapView.locationDisplay.dataSource.didUpdate(initialLocation)
        
        // Stop the location display as well as datasource generation, if reset before the end is reached.
        mapView.locationDisplay.stop()
        mapView.locationDisplay.autoPanModeChangedHandler = nil
        mapView.locationDisplay.autoPanMode = .off
        directionsList.removeAll()
        setStatus(message: "Directions are shown here.")
        
        // Reset the navigation.
        setNavigation(with: routeResult)
        // toggle  buttons image.
        navigationBarButtonItem.image = UIImage(systemName: "location.fill")
    }
    
    @IBAction func recenter(_ sender: UIBarButtonItem) {
           recenter()
    }
    func recenter() {
        mapView.locationDisplay.autoPanMode = .navigation
        recenterBarButtonItem.isEnabled = false
        mapView.locationDisplay.autoPanModeChangedHandler = { [weak self] _ in
            DispatchQueue.main.async { [weak self] in
                self?.recenterBarButtonItem.isEnabled = true
                self?.mapView.locationDisplay.autoPanModeChangedHandler = nil
            }
        }
    }
    
    func solveRoute() {
        // Solve the route as map loads.
        routeTask.defaultRouteParameters { [weak self] (params: AGSRouteParameters?, error: Error?) in
            guard let self = self else { return }
            if let params = params {
                // Explicitly set values for parameters.
                params.returnDirections = true
                params.returnStops = true
                params.returnRoutes = true
                params.outputSpatialReference = .wgs84()
                params.setStops(self.makeStops())
                self.routeParameters = params
                self.routeTask.solveRoute(with: params) { [weak self] (result, error) in
                    if let result = result {
                        self?.didSolveRoute(with: .success(result))
                    } else if let error = error {
                        self?.didSolveRoute(with: .failure(error))
                    }
                }
            } else if let error = error {
                print(error)
                self.setStatus(message: "Failed to get route parameters.")
            }
        }
    }
    
    // MARK: UIViewController
    var routeParameters: AGSRouteParameters!
    
    override func viewDidLoad() {
        super.viewDidLoad()
               
        // Add the source code button item to the right of navigation bar.
        //(navigationItem.rightBarButtonItem as? SourceCodeBarButtonItem)?.filenames = //["NavigateRouteViewController"]
        // Avoid the overlap between the status label and the map content.
        
        navTitle.title = inputParams.address
        let navigationBarAppearance = UINavigationBar.appearance();
        navigationBarAppearance.tintColor = UIColor.white
        //navigationBarAppearance.barTintColor = UIColor(red: 0, green: 73, blue: 44, alpha: 0)
        navigationBarAppearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
        
        mapView.contentInset.top = CGFloat(directionLabel.numberOfLines) * directionLabel.font.lineHeight
        
        setupLocationDisplay()
        
        distanceLabel.text = "Distance"
        timeLabel.text = "Hours:Minutes"
               
    }
  
      
    override func viewDidAppear(_ animated: Bool) {
              
        print(self.startLocation )
        //setupLocationDisplay()
     
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.solveRoute()
        }
              
    }
       
    
    func setExtent(routeGeometry: AGSGeometry, actualGeometry: AGSGeometry){
        // add actual geoemtery to mapview.
        
        let envelope = AGSGeometryEngine.combineExtents(ofGeometries: [routeGeometry, actualGeometry])
        mapView.setViewpointGeometry(envelope!)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Only reset when the route is successfully solved.
        if routeResult != nil {
            reset()
        }
    }
  
    func getDirectionImage(direction: String) -> UIImage {
        var imgName = "square"
        if direction.contains("Turn left") {
            imgName = "arrow.turn.up.left"
        }
        else  if direction.contains("Turn right") {
            imgName = "arrow.turn.up.right"
        }
        else  if direction.contains("Bear left") {
            imgName = "arrow.up.left"
        }
        else  if direction.contains("Bear right") {
            imgName = "arrow.up.right"
        }
        else  if direction.contains("Continue") {
            imgName = "arrow.up"
        }
        else  if direction.contains("U-turn") {
            imgName = "arrow.uturn.down"
        }
        else  if direction.contains("Go north") {
            imgName = "arrow.up"
        }
        else  if direction.contains("Go east") {
            imgName = "arrow.right"
        }
        else  if direction.contains("Go south") {
            imgName = "arrow.down"
        }
        else  if direction.contains("Sharp Left") {
            imgName = "arrow.left"
        }
        else if direction.contains("Finish") || direction.contains("Final Destination") {
            imgName = "flag"
        }
        
        return UIImage(systemName: imgName)!
    }
    
}

// MARK: - AGSRouteTrackerDelegate

extension NavigateRouteViewController: AGSRouteTrackerDelegate {
    
    func routeTracker(_ routeTracker: AGSRouteTracker, didGenerateNewVoiceGuidance voiceGuidance: AGSVoiceGuidance) {
        setSpeakDirection(with: voiceGuidance.text)
    }
    
    func routeTracker(_ routeTracker: AGSRouteTracker, didUpdate trackingStatus: AGSTrackingStatus) {
        updateTrackingStatusDisplay(routeTracker: routeTracker, status: trackingStatus)
    }
    
    func setSpeakDirection(with text: String) {
        speechSynthesizer.stopSpeaking(at: .word)
        speechSynthesizer.speak(AVSpeechUtterance(string: text))
    }
    
    func updateTrackingStatusDisplay(routeTracker: AGSRouteTracker, status: AGSTrackingStatus) {
        var statusText = ""
        var distanceText = ""
        var timeText = ""
        
        switch status.destinationStatus {
        case .notReached, .approaching:
            let distanceRemaining = status.routeProgress.remainingDistance.displayText + " " + status.routeProgress.remainingDistance.displayTextUnits.abbreviation
            let timeRemaining = timeFormatter.string(from: TimeInterval(status.routeProgress.remainingTime * 60))!
            
            distanceText = """
            \(distanceRemaining)
            """
            timeText = """
            \(timeRemaining)
            """
            if status.currentManeuverIndex + 1 < directionsList.count {
                let nextDirection = directionsList[status.currentManeuverIndex + 1].directionText
                statusText = "\(nextDirection)"
            }
        case .reached:
            if status.remainingDestinationCount > 1 {
                statusText = "Intermediate stop reached, continue to next stop."
                routeTracker.switchToNextDestination()
            } else {
                statusText = "Final destination reached."
                mapView.locationDisplay.stop()
            }
        default:
            return
        }
        updateRouteGraphics(remaining: status.routeProgress.remainingGeometry, traversed: status.routeProgress.traversedGeometry)
        setStatus(message: statusText)
        distanceLabel.text = distanceText
        timeLabel.text = timeText
        directionImage.image = getDirectionImage(direction: statusText)
    }
    
    func updateRouteGraphics(remaining: AGSGeometry?, traversed: AGSGeometry? = nil) {
        routeAheadGraphic.geometry = remaining
        routeTraveledGraphic.geometry = traversed
    }
    
    func routeTrackerRerouteDidStart(_ routeTracker: AGSRouteTracker) {
        setStatus(message: "Reroute started event!")
        print("Reroute started")
    }
    
    func routeTracker(_ routeTracker: AGSRouteTracker, rerouteDidCompleteWith trackingStatus: AGSTrackingStatus?, error: Error?) {
        setStatus(message: "Reroute completion event!")
        print ("*** Reroute completed ***")
        if let error = error {
            print(error)

        } else if let status = trackingStatus {
            directionsList = status.routeResult.routes.first!.directionManeuvers
        }
    }
}

// MARK: - AGSLocationChangeHandlerDelegate

extension NavigateRouteViewController: AGSLocationChangeHandlerDelegate {
    func locationDataSource(_ locationDataSource: AGSLocationDataSource, locationDidChange location: AGSLocation) {
        // Update the tracker location with the new location from the simulated data source.
        routeTracker?.trackLocation(location) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.setStatus(message: error.localizedDescription)
                self.routeTracker.delegate = nil
            }
        }
    }
}
