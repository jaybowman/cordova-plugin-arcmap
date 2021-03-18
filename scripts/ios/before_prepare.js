/*
 * script to modify the podfile on platform install.
 * runs on before_prepare event.
 */

const fs = require("fs");
const path = require("path");
const utilities = require("../lib/utilities");

var IOS_DIR = 'platforms/ios/podfile';
var PLATFORM_IOS = "'13.0'";

module.exports = function(context) {
    
   editPodfile(context);    
};

var editPodfile = function (context) {
   
    var target = path.join("platforms", "ios", "podfile");
    
    if (!utilities.fileExists(IOS_DIR)) {
        console.log("Cordova-plugin-arcmap can't find file " + IOS_DIR);
        return;
    }

    var podfile = fs.readFileSync(IOS_DIR).toString();
    //console.log(podfile);

    var modifiedPodfile = podfile.replace(/'1[0-2].0'/m, PLATFORM_IOS);
   
    fs.writeFileSync(target, modifiedPodfile);
    console.log("Cordova-plugin-arcmap updateded podfile.");
};
