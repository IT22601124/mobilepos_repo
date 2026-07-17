import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../firebase_options.dart';

class FirebaseNotifications {

  Future<void> requestPermission() async {
   try{
     FirebaseMessaging messaging = FirebaseMessaging.instance;

     NotificationSettings settings =
     await messaging.requestPermission(
       alert: true,
       badge: true,
       sound: true,
     );

     print(settings.authorizationStatus);
   }
   catch(e)
    {
      throw Exception('error firebase messaging');
    }
  }

  Future<void> getToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    print("FCM TOKEN");
    print(token);
  }

  Future<void> firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {

    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    print(message.messageId);
  }
}