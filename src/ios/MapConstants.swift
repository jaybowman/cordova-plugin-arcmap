//
//  MapConstants.swift
//  testPluginApp
//
//  Created by WebDev on 12/17/20.
//

import Foundation
import ArcGIS

struct ArcLocation {
    var name: String = ""
    var gisLong: Double = 0
    var gisLat: Double = 0
    init?(list: NSDictionary){
        guard let name = list["name"] as? String,
              let long = list["gisLong"] as? Double,
              let lat = list["gisLat"] as? Double
        else {
            return nil
        }
        
        self.name = name
        self.gisLong = long
        self.gisLat = lat
    }
}
struct ArcRoute {
    var stops: [ArcLocation] = []
    var route: RouteType = RouteType.CAR
    
    init(withStops: [ArcLocation], travelType: RouteType){
        stops = withStops
        route = travelType
    }
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

extension UIColor {
    static let villagesGreen = UIColor(hex: "#00492B")
    convenience init(hex: String){
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

           if (cString.hasPrefix("#")) {
               cString.remove(at: cString.startIndex)
           }

           var rgbValue:UInt64 = 0
           Scanner(string: cString).scanHexInt64(&rgbValue)

        self.init(
               red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
               green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
               blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
               alpha: CGFloat(1.0)
           )
    }
}
