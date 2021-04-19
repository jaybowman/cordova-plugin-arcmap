var fs = require("fs");
var path = require("path");


function rootBuildGradleExists() {
  var target = path.join("platforms", "android", "repositories.gradle");
  console.log(target);
  return fs.existsSync(target);
}

/*
 * Helper function to read the build.gradle that sits at the root of the project
 */
function readRootBuildGradle() {
  var target = path.join("platforms", "android", "repositories.gradle");
  
  return fs.readFileSync(target, "utf-8");
}

/*
 * NOT USED
 * Added a dependency on 'com.google.gms' based on the position of the know 'com.android.tools.build' dependency in the build.gradle
 */
function addDependencies(buildGradle) {
  // find the known line to match
  var match = buildGradle.match(/^(\s*)classpath 'com.android.tools.build(.*)/m);
  var whitespace = match[1];
  
  // modify the line to add the necessary dependencies
  var googlePlayDependency = whitespace + 'classpath \'com.google.gms:google-services:4.1.0\' // google-services dependency from cordova-plugin-firebase';
  var fabricDependency = whitespace + 'classpath \'io.fabric.tools:gradle:1.25.4\' // fabric dependency from cordova-plugin-firebase'
  var modifiedLine = match[0] + '\n' + googlePlayDependency + '\n' + fabricDependency;
  
  // modify the actual line
  return buildGradle.replace(/^(\s*)classpath 'com.android.tools.build(.*)/m, modifiedLine);
}

/*
 * Add 'arcgis' to the repository repo list
 */
function addRepos(buildGradle) {
  // find the known line to match
  var match = buildGradle.match(/^(\s*)jcenter\(\)/m);
  var whitespace = match[0];
  // modify the line to add the necessary repo 
  var fabricMavenRepo = whitespace + ' maven { url \'https://jitpack.io\' } \n  maven { url \'https://esri.jfrog.io/artifactory/arcgis\'  }';
  var modifiedLine =   match[0] + '\n' + fabricMavenRepo;
  // modify the actual line
  buildGradle = buildGradle.replace(/^(\s*)jcenter\(\)/m, modifiedLine);

  // update the all projects grouping
  var allProjectsIndex = buildGradle.indexOf('allprojects');
  if (allProjectsIndex > 0) {
    // split the string on allprojects because jcenter is in both groups and we need to modify the 2nd instance
    var firstHalfOfFile = buildGradle.substring(0, allProjectsIndex);
    var secondHalfOfFile = buildGradle.substring(allProjectsIndex);

    // Add google() to the allprojects section of the string
    match = secondHalfOfFile.match(/^(\s*)jcenter\(\)/m);
  
    var mavenRepo = whitespace + ' maven { url \'https://jitpack.io\' } // from cordova-plugin-arcgis ';
    var arcgisRepo = whitespace + ' maven { url \'https://esri.jfrog.io/artifactory/arcgis\'  } // from cordova-plugin-arcmap';
  
    modifiedLine = match[0] + '\n' + mavenRepo + '\n' + arcgisRepo;
    // modify the part of the string that is after 'allprojects'
    secondHalfOfFile = secondHalfOfFile.replace(/^(\s*)jcenter\(\)/m, modifiedLine);

    // recombine the modified line
    buildGradle = firstHalfOfFile + secondHalfOfFile;
  } else {
    // this should not happen, but if it does, we should try to add the dependency to the buildscript
    match = buildGradle.match(/^(\s*)jcenter\(\)/m);
    var googlesMavenRepo = whitespace + ' maven { url \'https://jitpack.io\' } \n  maven { url \'https://esri.jfrog.io/artifactory/arcgis\'  } // from cordova-plugin-arcmap';
    modifiedLine = match[0] + '\n' + googlesMavenRepo;
    // modify the part of the string that is after 'allprojects'
    buildGradle = buildGradle.replace(/^(\s*)jcenter\(\)/m, modifiedLine);
  }

  return buildGradle;
}

/*
 * Helper function to write to the build.gradle that sits at the root of the project
 */
function writeRootBuildGradle(contents) {
  var target = path.join("platforms", "android", "build.gradle");
  fs.writeFileSync(target, contents);
}

module.exports = {

  modifyRootBuildGradle: function() {
    // be defensive and don't crash if the file doesn't exist
    if (!rootBuildGradleExists) {
      console.log("build.gradle not found!");
      return;
    }
    console.log("found build.gradle ");

    var buildGradle = readRootBuildGradle();


    // Add 
    //buildGradle = addDependencies(buildGradle);
  
    // Add arcgis's Maven Repo
    buildGradle = addRepos(buildGradle);

    writeRootBuildGradle(buildGradle);
  },

  restoreRootBuildGradle: function() {
    // be defensive and don't crash if the file doesn't exist
    if (!rootBuildGradleExists) {
      return;
    }

    var buildGradle = readRootBuildGradle();

    // remove any lines we added
    buildGradle = buildGradle.replace(/(?:^|\r?\n)(.*)cordova-plugin-arcmap*?(?=$|\r?\n)/g, '');
  
    writeRootBuildGradle(buildGradle);
  }
};