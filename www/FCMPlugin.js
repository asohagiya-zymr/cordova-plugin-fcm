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

var fcmPlugin = new FCMPlugin();
module.exports = fcmPlugin;