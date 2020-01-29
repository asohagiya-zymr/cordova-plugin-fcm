package com.gae.scaffolder.plugin;

import com.crashlytics.android.Crashlytics;
import io.fabric.sdk.android.Fabric;
import com.google.firebase.FirebaseApp;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaInterface;
import android.util.Log;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.os.Bundle;

import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.iid.FirebaseInstanceId;

import java.io.IOException;
import java.util.Map;

public class FCMPlugin extends CordovaPlugin {
 
	private static final String TAG = "FCMPlugin";
	
	public static CordovaWebView gWebView;
	public static String notificationCallBack = "FCMPlugin.onNotificationReceived";
	public static String tokenRefreshCallBack = "FCMPlugin.onTokenRefreshReceived";
	public static Boolean notificationCallBackReady = false;
	public static Map<String, Object> lastPush = null;
	 
	public FCMPlugin() {}
	
	public void initialize(CordovaInterface cordova, CordovaWebView webView) {
		super.initialize(cordova, webView);
		cordova.getThreadPool().execute(new Runnable() {
            public void run() {
				FirebaseApp.initializeApp(cordova.getActivity().getApplicationContext());
			}
		});
		gWebView = webView;
		Log.d(TAG, "==> FCMPlugin initialize");
		FirebaseMessaging.getInstance().subscribeToTopic("android");
		FirebaseMessaging.getInstance().subscribeToTopic("all");
	}
	 
	public boolean execute(final String action, final JSONArray args, final CallbackContext callbackContext) throws JSONException {

		Log.d(TAG,"==> FCMPlugin execute: "+ action);
		
		try{
			// READY //
			if (action.equals("ready")) {
				//
				callbackContext.success();
			}
			// GET TOKEN //
			else if (action.equals("getToken")) {
				cordova.getActivity().runOnUiThread(new Runnable() {
					public void run() {
						try{
							String token = FirebaseInstanceId.getInstance().getToken();
							callbackContext.success( FirebaseInstanceId.getInstance().getToken() );
							Log.d(TAG,"\tToken: "+ token);
						}catch(Exception e){
							Log.d(TAG,"\tError retrieving token");
						}
					}
				});
			}
			// NOTIFICATION CALLBACK REGISTER //
			else if (action.equals("registerNotification")) {
				notificationCallBackReady = true;
				cordova.getActivity().runOnUiThread(new Runnable() {
					public void run() {
						if(lastPush != null) FCMPlugin.sendPushPayload( lastPush );
						lastPush = null;
						callbackContext.success();
					}
				});
			}
			// UN/SUBSCRIBE TOPICS //
			else if (action.equals("subscribeToTopic")) {
				cordova.getThreadPool().execute(new Runnable() {
					public void run() {
						try{
							FirebaseMessaging.getInstance().subscribeToTopic( args.getString(0) );
							callbackContext.success();
						}catch(Exception e){
							callbackContext.error(e.getMessage());
						}
					}
				});
			}
			else if (action.equals("unsubscribeFromTopic")) {
				cordova.getThreadPool().execute(new Runnable() {
					public void run() {
						try{
							FirebaseMessaging.getInstance().unsubscribeFromTopic( args.getString(0) );
							callbackContext.success();
						}catch(Exception e){
							callbackContext.error(e.getMessage());
						}
					}
				});
			}
			else if (action.equals("deleteInstance")){
				cordova.getActivity().runOnUiThread(new Runnable() {
					public void run() {
						try{
							new Thread(new Runnable() {
								@Override
								public void run() {
									try {
										FirebaseInstanceId.getInstance().deleteInstanceId();
									} catch (IOException e) {
										e.printStackTrace();
									}
								}
							}).start();
							callbackContext.success();
						}catch(Exception e){
							callbackContext.error(e.getMessage());
						}
					}
				});
			}
			else if (action.equals("logError")) {
				cordova.getThreadPool().execute(new Runnable() {
					public void run() {
						try {
							Crashlytics.logException(new Exception(args.getString(0)));
							callbackContext.success();
						} catch (Exception e) {
							Crashlytics.log(e.getMessage());
							e.printStackTrace();
							callbackContext.error(e.getMessage());
						}
					}
				});
			}
			else if (action.equals("log")) {
				cordova.getThreadPool().execute(new Runnable() {
					public void run() {
						try {
							Crashlytics.log(args.getString(0));
							callbackContext.success();
						} catch (Exception e) {
							Crashlytics.logException(new Exception(e.getMessage()));
							e.printStackTrace();
							callbackContext.error(e.getMessage());
						}
					}
				});
			}
			else if (action.equals("setString")) {
				cordova.getThreadPool().execute(new Runnable() {
					public void run() {
						try {
							Crashlytics.setString(args.getString(0), args.getString(1));
							callbackContext.success();
						} catch (Exception e) {
							Crashlytics.log(e.getMessage());
							e.printStackTrace();
							callbackContext.error(e.getMessage());
						}
					}
				});
			}
			else if (action.equals("setBool")) {
				cordova.getThreadPool().execute(new Runnable() {
					public void run() {
						try {
							Crashlytics.setBool(args.getString(0), args.getBoolean(1));
							callbackContext.success();
						} catch (Exception e) {
							Crashlytics.log(e.getMessage());
							e.printStackTrace();
							callbackContext.error(e.getMessage());
						}
					}
				});
			}
			else if (action.equals("setDouble")) {
				cordova.getThreadPool().execute(new Runnable() {
					public void run() {
						try {
							Crashlytics.setDouble(args.getString(0), args.getDouble(1));
							callbackContext.success();
						} catch (Exception e) {
							Crashlytics.log(e.getMessage());
							e.printStackTrace();
							callbackContext.error(e.getMessage());
						}
					}
				});
			}
			else if (action.equals("setFloat")) {
				cordova.getThreadPool().execute(new Runnable() {
					public void run() {
						try {
							Crashlytics.setFloat(args.getString(0), (float) args.getDouble(1));
							callbackContext.success();
						} catch (Exception e) {
							Crashlytics.log(e.getMessage());
							e.printStackTrace();
							callbackContext.error(e.getMessage());
						}
					}
				});
			}
			else if (action.equals("setInt")) {
				cordova.getThreadPool().execute(new Runnable() {
					public void run() {
						try {
							Crashlytics.setInt(args.getString(0), args.getInt(1));
							callbackContext.success();
						} catch (Exception e) {
							Crashlytics.log(e.getMessage());
							e.printStackTrace();
							callbackContext.error(e.getMessage());
						}
					}
				});
			}
			else if (action.equals("setCrashlyticsUserId")) {
				cordova.getActivity().runOnUiThread(new Runnable() {
					public void run() {
						try {
							Crashlytics.setUserIdentifier(args.getString(0));
							callbackContext.success();
						} catch (Exception e) {
							Crashlytics.logException(e);
							callbackContext.error(e.getMessage());
						}
					}
				});
			}
			else{
				callbackContext.error("Method not found");
				return false;
			}
		}catch(Exception e){
			Log.d(TAG, "ERROR: onPluginAction: " + e.getMessage());
			callbackContext.error(e.getMessage());
			return false;
		}
		
		//cordova.getThreadPool().execute(new Runnable() {
		//	public void run() {
		//	  //
		//	}
		//});
		
		//cordova.getActivity().runOnUiThread(new Runnable() {
        //    public void run() {
        //      //
        //    }
        //});
		return true;
	}
	
	public static void sendPushPayload(Map<String, Object> payload) {
		Log.d(TAG, "==> FCMPlugin sendPushPayload");
		Log.d(TAG, "\tnotificationCallBackReady: " + notificationCallBackReady);
		Log.d(TAG, "\tgWebView: " + gWebView);
	    try {
		    JSONObject jo = new JSONObject();
			for (String key : payload.keySet()) {
			    jo.put(key, payload.get(key));
				Log.d(TAG, "\tpayload: " + key + " => " + payload.get(key));
            }
			String callBack = "javascript:" + notificationCallBack + "(" + jo.toString() + ")";
			if(notificationCallBackReady && gWebView != null){
				Log.d(TAG, "\tSent PUSH to view: " + callBack);
				gWebView.sendJavascript(callBack);
			}else {
				Log.d(TAG, "\tView not ready. SAVED NOTIFICATION: " + callBack);
				lastPush = payload;
			}
		} catch (Exception e) {
			Log.d(TAG, "\tERROR sendPushToView. SAVED NOTIFICATION: " + e.getMessage());
			lastPush = payload;
		}
	}

	public static void sendTokenRefresh(String token) {
		Log.d(TAG, "==> FCMPlugin sendRefreshToken");
	  try {
			String callBack = "javascript:" + tokenRefreshCallBack + "('" + token + "')";
			gWebView.sendJavascript(callBack);
		} catch (Exception e) {
			Log.d(TAG, "\tERROR sendRefreshToken: " + e.getMessage());
		}
	}
  
  @Override
	public void onDestroy() {
		gWebView = null;
		notificationCallBackReady = false;
	}
} 
