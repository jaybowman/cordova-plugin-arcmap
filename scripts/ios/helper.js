var fs = require("fs");
var path = require("path");
var utilities = require("../lib/utilities");

/**
 * This is used as the display text for the build phase block in XCode as well as the
 * inline comments inside of the .pbxproj file for the build script phase block.
 */
var comment = "\"ArcGIS\"";

module.exports = {

  /**
     * Used to get the path to the XCode project's .pbxproj file.
     *
     * @param {object} context - The Cordova context.
     * @returns The path to the XCode project's .pbxproj file.
     */
  getXcodeProjectPath: function (context) {

    var appName = utilities.getAppName(context);

    return path.join("platforms", "ios", appName + ".xcodeproj", "project.pbxproj");
  },

/*
  download and install arcGIS Runtimeframework sdk.
*/
getArcGISRuntimeFramework: function (context, xcodeProjectPath){

  //download framework
  // https://developers.arcgis.com/downloads/#ios

  // install package. 

  
}

};