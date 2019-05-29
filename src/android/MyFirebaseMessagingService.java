package com.gae.scaffolder.plugin;

import android.app.ActivityManager;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.media.RingtoneManager;
import android.net.Uri;
import android.os.PowerManager;
import android.support.v4.app.NotificationCompat;
import android.util.Log;

import java.util.Date;
import java.util.List;
import java.util.Map;
import java.util.HashMap;

import com.google.firebase.messaging.FirebaseMessagingService;
import com.google.firebase.messaging.RemoteMessage;

import org.json.JSONException;
import org.json.JSONObject;

import com.mozzaz.lifetiles.MainActivity;
/**
 * Created by Felipe Echanique on 08/06/2016.
 */
public class MyFirebaseMessagingService extends FirebaseMessagingService {

    private static final String TAG = "FCMPlugin";

    /**
     * Called when message is received.
     *
     * @param remoteMessage Object representing the message received from Firebase Cloud Messaging.
     */
    // [START receive_message]
    @Override
    public void onMessageReceived(RemoteMessage remoteMessage) {
        // TODO(developer): Handle FCM messages here.
        // If the application is in the foreground handle both data and notification messages here.
        // Also if you intend on generating your own notifications as a result of a received FCM
        // message, here is where that should be initiated. See sendNotification method below.
        Log.d(TAG, "==> MyFirebaseMessagingService onMessageReceived");

        if( remoteMessage.getNotification() != null){
            Log.d(TAG, "\tNotification Title: " + remoteMessage.getNotification().getTitle());
            Log.d(TAG, "\tNotification Message: " + remoteMessage.getNotification().getBody());
        }

        Map<String, Object> data = new HashMap<String, Object>();
        data.put("wasTapped", false);
        for (String key : remoteMessage.getData().keySet()) {
            Object value = remoteMessage.getData().get(key);
            Log.d(TAG, "\tKey: " + key + " Value: " + value);
            data.put(key, value);
        }

        Log.d(TAG, "\tNotification Data: " + data.toString());
        FCMPlugin.sendPushPayload( data );
        //sendNotification(remoteMessage.getNotification().getTitle(), remoteMessage.getNotification().getBody(), remoteMessage.getData());
        if (data.size()==2){
            if (data.get("message")!=null){
                try {

                    JSONObject messageData = new JSONObject(data.get("message").toString());
                    String notificationType = messageData.getString("type");
                    if (notificationType!=null ){
                        if (notificationType.equals("call")){
                            long timeStamp = Long.parseLong(messageData.getString("time"));
                            long currentTime = System.currentTimeMillis();
                            boolean isFirstNotification = messageData.getBoolean("isFirstNotification");
                            if ((currentTime-timeStamp)<6000){
                                PowerManager pm = (PowerManager)getSystemService(POWER_SERVICE);
                                PowerManager.WakeLock wakeLock = pm.newWakeLock(PowerManager.FULL_WAKE_LOCK | PowerManager.ACQUIRE_CAUSES_WAKEUP, "TRAININGCOUNTDOWN");
                                Intent intent = new Intent(getApplicationContext(), MainActivity.class);
                                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP);
                                intent.putExtra("cdvStartInBackground", true);
                                String firstName = messageData.getString("firstName");
                                String lastName = messageData.getString("lastName");
                                wakeLock.acquire(60000);
                                Map<String, Object> data1 = new HashMap<String, Object>();
                                data1.put("wasTapped", false);

                                sendNotification("Lifetiles Pro", "Call From: "+firstName +" "+lastName, notificationType);

                                if(isFirstNotification){
                                    startActivity(intent);
                                }

                            }
                        }
                        else if (notificationType.equals("missedCall") || notificationType.equals("callerEndCall")){
                            long timeStamp = Long.parseLong(messageData.getString("time"));
                            String firstName = messageData.getString("firstName");
                            String lastName = messageData.getString("lastName");
                            Map<String, Object> data1 = new HashMap<String, Object>();
                            data1.put("wasTapped", false);
                            String callType=messageData.getString("CommunicationType");
                            String notificatonmsg= "Missed "+callType+" From:";
                            sendNotification("Lifetiles Pro", notificatonmsg +firstName +" "+lastName, notificationType);
                        }

                    }

//                    }
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            }
        }
    }
    // [END receive_message]
    private boolean isAppOnForeground(Context context) {
        ActivityManager activityManager = (ActivityManager) context.getSystemService(Context.ACTIVITY_SERVICE);
        List<ActivityManager.RunningAppProcessInfo> appProcesses = activityManager.getRunningAppProcesses();
        if (appProcesses == null) {
            return false;
        }
        final String packageName = context.getPackageName();
        for (ActivityManager.RunningAppProcessInfo appProcess : appProcesses) {
            if (appProcess.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND && appProcess.processName.equals(packageName)) {
                return true;
            }
        }
        return false;
    }
    /**
     * Create and show a simple notification containing the received FCM message.
     *
     * @param content FCM message body received.
     */
    private void sendNotification(String title, String content, String notificationType) {

        Uri defaultSoundUri= RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION);
        NotificationManager mNotificationManager =
                (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel("default",
                    "gcm",
                    NotificationManager.IMPORTANCE_HIGH);
            channel.setDescription("YOUR_NOTIFICATION_CHANNEL_DISCRIPTION");
            channel.enableVibration(true);
            channel.setVibrationPattern(new long[]{100, 200, 300, 400, 500, 400, 300, 200, 400});
            mNotificationManager.createNotificationChannel(channel);
        }
        NotificationCompat.Builder mBuilder = new NotificationCompat.Builder(getApplicationContext(), "default")
                .setSmallIcon(getApplicationInfo().icon) // notification icon
                .setContentTitle(title) // title for notification
                .setContentText(content)// message for notification
                .setSound(defaultSoundUri) // set alarm sound for notification
                .setAutoCancel(true) // clear notification after click
                .setPriority(4)
                .setVibrate(new long[]{100, 200, 300, 400, 500, 400, 300, 200, 400});

        Intent intent = new Intent(getApplicationContext(), FCMPluginActivity.class);
        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
        PendingIntent pi = PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_ONE_SHOT);
        mBuilder.setContentIntent(pi);
        if(notificationType.equals("call")){
            if(!isAppOnForeground(getApplicationContext())){
                mNotificationManager.cancel(0);
                mNotificationManager.notify(0, mBuilder.build());
            }
            else{
                mNotificationManager.cancel(0);
            }
        }
        else if(notificationType.equals("missedCall")||notificationType.equals("callerEndCall")){
            int id = (int)System.currentTimeMillis();
            mNotificationManager.cancel(0);
            mNotificationManager.notify(id, mBuilder.build());

        }


    }
}
