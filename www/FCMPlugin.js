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
// ENABLE OR DISABLE APP START FROM NOTIFICATION //
FCMPlugin.prototype.toggleNotificationStart = function(enabled, success, error){
	exec(success,error,"FCMPlugin", 'toggleNotificationStart', (typeof enabled === "undefined" || typeof enabled === "null") ? [] : [enabled]);
}
// FIRE READY //
exec(function(result){ console.log("FCMPlugin Ready OK") }, function(result){ console.log("FCMPlugin Ready ERROR") }, "FCMPlugin",'ready',[]);





var fcmPlugin = new FCMPlugin();
module.exports = fcmPlugin;