package com.thevillages.cordova.plugin.arcmap;

import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.ComponentName;
import android.content.Intent;
import android.util.Log;
import android.content.pm.ActivityInfo;
import android.content.pm.PackageManager;
import android.content.pm.PackageManager.NameNotFoundException;
import android.os.Bundle;
import java.lang.reflect.Array;
import java.util.List;
import java.util.Collection;
import java.util.Map;
import java.util.Set;

import com.thevillages.maplib.TravelType;
import com.thevillages.maplib.VillageRoute;

public class Launcher extends CordovaPlugin {

	public static final String TAG = "Launcher Plugin";
	public static final String ACTION_LAUNCH = "launch";
	public static final int LAUNCH_REQUEST = 0;

	private CallbackContext callback;

	private abstract class LauncherRunnable implements Runnable {
		public CallbackContext callbackContext;
		LauncherRunnable(CallbackContext cb) {
			this.callbackContext = cb;
		}
	}

	@Override
	public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
		callback = callbackContext;
		if (ACTION_LAUNCH.equals(action)) {
			return launch(args);
		}
		return false;
	}

	private ActivityInfo getAppInfo(final Intent intent, final String appPackageName) {
		final PackageManager pm = webView.getContext().getPackageManager();
		try {
			Log.d(TAG, pm.getApplicationInfo(appPackageName, 0) + "");
		}catch (NameNotFoundException e) {
			Log.i(TAG, "No info found for package: " + appPackageName);
		}
		return null;
	}

	private boolean launch(JSONArray args) throws JSONException {
		final JSONObject options = args.getJSONObject(0);
		VillageRoute extras = null;
		if (options.has("extras")) {
			extras = createExtras(options.getJSONArray("extras"));
		} else {
			extras = new VillageRoute();
		}

		if (options.has("packageName") && (options.has("activityName"))) {
			launchActivity(options.getString("packageName"), options.getString("activityName"), extras);
			return true;
		}

		return false;
	}

	private VillageRoute createExtras(JSONArray extrasObj) throws JSONException {

		VillageRoute villageRoute = new VillageRoute();
		for (int i = 0, size = extrasObj.length(); i < size; i++) {
			JSONObject extra = extrasObj.getJSONObject(i);
			// process stops
			if (extra.has("name") && extra.has("gisLong") && extra.has("gisLat")) {
				String extraName = extra.getString("name");
				double gisLong = extra.getDouble("gisLong");
				double gisLat = extra.getDouble("gisLat");
				villageRoute.addStop(extraName, gisLong, gisLat);
			}
			else if (extra.has("name") && extra.has("value") ) {
				// get traveltype
				try {
					String extraName = extra.getString("name");
					int value = extra.getInt("value");
					villageRoute.setTravelType(TravelType.valueOf(value));
				} catch (Exception e) {
					Log.e(TAG, "Error processing extra. Skipping: " + extra);
				}
			} else {
				Log.e(TAG, "Extras must have a name, value, and datatype.");
			}
		}

		Log.d(TAG, "EXTRAS");

		return villageRoute;
	}

	// we are using this one to launch activity from maplib aar.
	private void launchActivity(final String packageName, final String ActivityName,  final VillageRoute extras) {
		final CordovaInterface mycordova = cordova;
		final CordovaPlugin plugin = this;
		Log.i(TAG, "Trying to launch activity: " + packageName);
		cordova.getThreadPool().execute(new LauncherRunnable(this.callback) {
			public void run() {
				final PackageManager pm = plugin.webView.getContext().getPackageManager();
				Intent  intent = pm.getLaunchIntentForPackage(packageName);
				final Intent launchIntent =  new Intent(Intent.ACTION_VIEW);
				launchIntent.setClassName(plugin.webView.getContext(), ActivityName);
				ComponentName cn = launchIntent.resolveActivity(pm);

				boolean appNotFound = launchIntent == null;

				if (!appNotFound) {
					try {
						launchIntent.putExtra("com.thevillages.maplib.VillageRoute", extras);
						mycordova.startActivityForResult(plugin, launchIntent, LAUNCH_REQUEST);
						((Launcher) plugin).callbackLaunched();
					} catch (ActivityNotFoundException e) {
						Log.e(TAG, "Error: Activity for package" + packageName + " was not found.");
						e.printStackTrace();
						callbackContext.error("Activity not found for package name " + packageName);
					}
				} else {
					callbackContext.error("App not found for package name.");
				}
			}
		});
	}

	@Override
	public void onActivityResult(int requestCode, int resultCode, Intent intent) {
		super.onActivityResult(requestCode, resultCode, intent);
		if (requestCode == LAUNCH_REQUEST) {
			if (resultCode == Activity.RESULT_OK || resultCode == Activity.RESULT_CANCELED) {
				JSONObject json = new JSONObject();
				try {
					json.put("isActivityDone", true);
				} catch(JSONException ignored) {}
				if (intent != null) {
					Bundle extras = intent.getExtras();
					if (extras != null) {
						JSONObject jsonExtras = new JSONObject();
						Set<String> keys = extras.keySet();
						for (String key : keys) {
							try {
								jsonExtras.put(key, wrap(extras.get(key)));
							} catch(JSONException ignored) {}
						}
						try {
							json.put("extras", jsonExtras);
						} catch(JSONException ignored) {}
					}

					try {
						json.put("data", intent.getDataString());
					} catch(JSONException ignored) {}
				}
				callback.success(json);
			} else {
				callback.error("Activity failed (" + resultCode + ").");
			}
		}
	}

	public void callbackLaunched() {
		try {
			JSONObject json = new JSONObject();
			json.put("isLaunched", true);
			PluginResult result = new PluginResult(PluginResult.Status.OK, json);
			result.setKeepCallback(true);
			callback.sendPluginResult(result);
		} catch (JSONException e) {
			PluginResult result = new PluginResult(PluginResult.Status.OK, "{'isLaunched':true}");
			result.setKeepCallback(true);
			callback.sendPluginResult(result);
		}
	}

	private Object wrap(Object o) {
		if (o == null) {
			return JSONObject.NULL;
		}
		if (o instanceof JSONArray || o instanceof JSONObject) {
			return o;
		}
		if (o.equals(JSONObject.NULL)) {
			return o;
		}
		try {
			if (o instanceof Collection) {
				return new JSONArray((Collection) o);
			} else if (o.getClass().isArray()) {
				JSONArray jsa = new JSONArray();
				int length = Array.getLength(o);
				for (int i = 0; i < length; i += 1) {
					jsa.put(wrap(Array.get(o, i)));
				}
				return jsa;
			}
			if (o instanceof Map) {
				return new JSONObject((Map) o);
			}
			if (o instanceof Boolean ||
					o instanceof Byte ||
					o instanceof Character ||
					o instanceof Double ||
					o instanceof Float ||
					o instanceof Integer ||
					o instanceof Long ||
					o instanceof Short ||
					o instanceof String) {
				return o;
			}
			if (o.getClass().getPackage().getName().startsWith("java.")) {
				return o.toString();
			}
		} catch (Exception ignored) {
		}
		return null;
	}
}