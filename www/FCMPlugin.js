var exec = require('cordova/exec');
var initPayload = null;

function FCMPlugin() { 
  console.log("FCMPlugin.js: is created");
}

// SUBSCRIBE TO TOPIC //
FCMPlugin.prototype.subscribeToTopic = function( topic, success, error ){
  exec(success, error, "FCMPlugin", 'subscribeToTopic', [topic]);
}
// UNSUBSCRIBE FROM TOPIC //
FCMPlugin.prototype.unsubscribeFromTopic = function( topic, success, error ){
  exec(success, error, "FCMPlugin", 'unsubscribeFromTopic', [topic]);
}
// NOTIFICATION CALLBACK //
FCMPlugin.prototype.onNotification = function( callback, success, error ){
  FCMPlugin.prototype.onNotificationReceived = callback;
  exec(success, error, "FCMPlugin", 'registerNotification',[]);
  if(!!initPayload) {
    callback(initPayload);
    initPayload = null;
  }
}
// TOKEN REFRESH CALLBACK //
FCMPlugin.prototype.onTokenRefresh = function( callback ){
  FCMPlugin.prototype.onTokenRefreshReceived = callback;
}
// GET TOKEN //
FCMPlugin.prototype.getToken = function( success, error ){
  exec(success, error, "FCMPlugin", 'getToken', []);
}
// GET APNS TOKEN //
FCMPlugin.prototype.getAPNSToken = function (success, error) {
  if (cordova.platformId !== "ios") {
    success(null);
    return;
  }
  exec(success, error, "FCMPlugin", "getAPNSToken", []);
};
//DELETE INSTANCE
FCMPlugin.prototype.deleteInstance = function( success, error ){
  exec(success, error, "FCMPlugin", 'deleteInstance', []);
}
// DEFAULT NOTIFICATION CALLBACK //
FCMPlugin.prototype.onNotificationReceived = function(payload){
  initPayload = payload;
  console.log("Received push notification")
  console.log(payload)
}
// DEFAULT TOKEN REFRESH CALLBACK //
FCMPlugin.prototype.onTokenRefreshReceived = function(token){
  console.log("Received token refresh")
  console.log(token)
}
// FIRE READY //
exec(function(result){ console.log("FCMPlugin Ready OK") }, function(result){ console.log("FCMPlugin Ready ERROR") }, "FCMPlugin",'ready',[]);

// CRASHLYTICS //
FCMPlugin.prototype.crashlytics = {};

FCMPlugin.prototype.crashlytics.logError = function(errorMessage, success, error) {
    if(typeof success != "function") success = function(){};
    if(typeof error != "function") error = function(){};
    exec(success, error, "FCMPlugin", 'logError', [errorMessage]);
}

FCMPlugin.prototype.crashlytics.log = function(message, success, error) {
    if(typeof success != "function") success = function(){};
    if(typeof error != "function") error = function(){};
    exec(success, error, "FCMPlugin", 'log', [message]);
}

FCMPlugin.prototype.crashlytics.setString = function(key, value, success, error) {
    if(typeof success != "function") success = function(){};
    if(typeof error != "function") error = function(){};
    exec(success, error, "FCMPlugin", 'setString', [key, value]);
}

FCMPlugin.prototype.crashlytics.setBool = function(key, value, success, error) {
    if(typeof success != "function") success = function(){};
    if(typeof error != "function") error = function(){};
    exec(success, error, "FCMPlugin", 'setBool', [key, value]);
}

FCMPlugin.prototype.crashlytics.setDouble = function(key, value, success, error) {
    if(typeof success != "function") success = function(){};
    if(typeof error != "function") error = function(){};
    exec(success, error, "FCMPlugin", 'setDouble', [key, value]);
}

FCMPlugin.prototype.crashlytics.setFloat = function(key, value, success, error) {
    if(typeof success != "function") success = function(){};
    if(typeof error != "function") error = function(){};
    exec(success, error, "FCMPlugin", 'setFloat', [key, value]);
}

FCMPlugin.prototype.crashlytics.setInt = function(key, value, success, error) {
    if(typeof success != "function") success = function(){};
    if(typeof error != "function") error = function(){};
    exec(success, error, "FCMPlugin", 'setInt', [key, value]);
}

FCMPlugin.prototype.crashlytics.setUserId = function(userId, success, error) {
    if(typeof success != "function") success = function(){};
    if(typeof error != "function") error = function(){};
    exec(success, error, "FCMPlugin", 'setCrashlyticsUserId', [userId]);
}

FCMPlugin.prototype.call = {};

FCMPlugin.prototype.call.startRing = function(name, isVideo, success, error) {
    if(typeof success != "function") success = function(){};
    if(typeof error != "function") error = function(){};
    exec(success, error, "FCMPlugin", 'callStartRing', [name, isVideo]);
}

FCMPlugin.prototype.call.stopRing = function(isMissed, name, isVideo, success, error) {
    if(typeof success != "function") success = function(){};
    if(typeof error != "function") error = function(){};
    if(isMissed) {
        exec(success, error, "FCMPlugin", 'callStopRing', [isMissed, name, isVideo]);
    }
    else {
        exec(success, error, "FCMPlugin", 'callStopRing', []);
    }
}

FCMPlugin.prototype.call._callAcceptHandler = function(){
    console.log("Call Accepted");
}

FCMPlugin.prototype.call._callDeclineHandler = function(){
    console.log("Call Accepted");
}

FCMPlugin.prototype.call.setCallAcceptHandler = function(callback, success, error) {
    if(typeof callback == "function") {
        FCMPlugin.prototype.call._callAcceptHandler = callback;
        success();
        return;
    }
    error();
}

FCMPlugin.prototype.call.setCallDeclineHandler = function(callback, success, error) {
    if(typeof callback == "function") {
        FCMPlugin.prototype.call._callDeclineHandler = callback;
        success();
        return;
    }
    error();
}

var fcmPlugin = new FCMPlugin();
module.exports = fcmPlugin;