
@objc(Launcher) class Launcher : CDVPlugin {
  @objc(launch:)
  func launch(command: CDVInvokedUrlCommand) {
    var pluginResult = CDVPluginResult(
      status: CDVCommandStatus_ERROR
    )

    let parms = command.arguments[0] as! NSDictionary
    let stops = parms.value(forKey: "stops") as! NSArray
   
    var points: [ArcLocation] = []
    for elem in stops {
        let s = elem as! NSDictionary
        points.append( ArcLocation(list: s)!)
    }
    // get distination address
    let address = points.last?.name

    let tt = parms.value(forKey: "travelType") as! Int

    let routeInfo = ArcRoute(withStops: points, travelType: RouteType(rawValue: tt)!)
    let  mapCtrl = NavigateRouteViewController(withRouteInfo: routeInfo)
    mapCtrl.modalPresentationStyle = .fullScreen
    self.viewController?.present(mapCtrl, animated: true, completion: nil)

    pluginResult = CDVPluginResult( status: CDVCommandStatus_OK, messageAs: address )

    self.commandDelegate!.send(
      pluginResult,
      callbackId: command.callbackId
    )
  }

  @objc(canLaunch:)
  func canLaunch(command: CDVInvokedUrlCommand) {
    let pluginResult = CDVPluginResult(
      status: CDVCommandStatus_ERROR
    )

     self.commandDelegate!.send(
      pluginResult,
      callbackId: command.callbackId
    )
  }
}
