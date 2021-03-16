//"use strict";
function Launcher() {}

var exec = require('cordova/exec');

Launcher.prototype.FLAG_ACTIVITY_NEW_TASK = 0x10000000;

Launcher.prototype.launch = function(options, successCallback, errorCallback) {
	options = options || {};
	options.successCallback = options.successCallback || successCallback;
	options.errorCallback = options.errorCallback || errorCallback;
	exec(options.successCallback || null, options.errorCallback || null, "Launcher", "launch", [options]);
};

Launcher.install = function () {
	if (!window.plugins) {
		window.plugins = {};
	}

	window.plugins.launcher = new Launcher();
	return window.plugins.launcher;
};

cordova.addConstructor(Launcher.install);
