//
//  MapConstants.swift
//  testPluginApp
//
//  Created by WebDev on 12/17/20.
//

import Foundation
import ArcGIS


struct ArcLocation {
    var address: String = ""
    var longitude: Double = 0
    var latitude: Double = 0
    var route: RouteType = RouteType.CAR
}

struct TestPoints {
    // Y center point for the villages east of brownwood off of 44.
    static let latitude = 28.82479334
    // x
    static let longitude = -81.98671583
    // barns and knobles
    static let lslLong = -81.976787349
    static let lslLat =   28.908179615
    
    static let shooters_world = "Shooters World"
    static let swLat = 28.849218843817695
    static let swLong = -82.02131201965173
    
    
    static let   address = "Cane Garden Country club"
    static let gisLong = -81.99463648
    static let gisLat = 28.89330536
    
    // mvp brownwood -82.022588, 28.845312
    static let mvp_y = 28.845312
    static let mvp_x = -82.022588
}

enum RouteType: Int {
    case CAR, GOLF_CART
}

extension URL {
    static let myAppRoutingServiceAsync = URL(string: "https://utility.arcgis.com/usrsvcs/appservices/xEbX1CD0AIA0MxBV/rest/services/World/Route/GPServer")!
    static let myAppRoutingService = URL(string: "https://utility.arcgis.com/usrsvcs/appservices/TQKETvSAQTsJB55I/rest/services/World/Route/NAServer/Route_World")!
    static let worldRoutingService = URL(string: "https://arc7.thevillages.com/arcgis/rest/services/JWCAR_ROUTES_NOZ_TEST/NAServer/Route")!
    static let carRoutingService = URL(string: "https://arc7.thevillages.com/arcgis/rest/services/CARROUTES/NAServer/Route")!
    static let golfRoutingService = URL(string: "https://arc7.thevillages.com/arcgis/rest/services/GOLFCROUTE2/NAServer/Route")!
    static let villagesMapService = URL(string: "https://arc7.thevillages.com/arcgis/rest/services/PUBLICMAP26/MapServer")!
}
/// Add title property to arcgis load atatus
/// extension method
extension AGSLoadStatus {
    /// The human readable name of the load status.
    var title: String {
        switch self {
        case .loaded:
            return "Loaded"
        case .loading:
            return "Loading"
        case .failedToLoad:
            return "Failed to Load"
        case .notLoaded:
            return "Not Loaded"
        case .unknown:
            fallthrough
        @unknown default:
            return "Unknown"
        }
    }
}

