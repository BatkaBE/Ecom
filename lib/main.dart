import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart' as firebase_ui;
import 'package:firebase_ui_localizations/firebase_ui_localizations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firebase_options.dart';
import 'provider/globalprovider.dart';
import 'screens/home_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> setupFlutterNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  String? token = await FirebaseMessaging.instance.getToken();
  print('FCM Registration Token: $token');
  await setupFlutterNotifications();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Request notification permissions (iOS, Android 13+)
  await FirebaseMessaging.instance.requestPermission();

  FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) {
    print('FCM Token refreshed: $fcmToken');
  }).onError((err) {
    print('Error getting FCM token: $err');
  });

  final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
  if (apnsToken != null) {
    print('APNS Token: $apnsToken');
  }

  final globalProvider = GlobalProvider();
  await globalProvider.loadLocale();

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      flutterLocalNotificationsPlugin.show(
        message.notification.hashCode,
        message.notification!.title,
        message.notification!.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'This channel is used for important notifications.',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
      );
    }
  });

  runApp(
    ChangeNotifierProvider(
      create: (_) => globalProvider,
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GlobalProvider>(
      builder:
          (context, provider, _) => MaterialApp(
            navigatorKey: navigatorKey,
            home: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasData) {
                  return const HomePage();
                }

                return firebase_ui.SignInScreen(
                  providers: [
                    firebase_ui.EmailAuthProvider(),
                    // Add other providers if needed (e.g., Google)
                  ],
                  actions: [
                    firebase_ui.ForgotPasswordAction((context, email) {
                      Navigator.pushNamed(
                        context,
                        '/forgot-password',
                        arguments: {'email': email},
                      );
                    }),
                    firebase_ui.AuthStateChangeAction((context, state) {
                      if (state is firebase_ui.SignedIn ||
                          state is firebase_ui.UserCreated) {
                        final user =
                            state is firebase_ui.SignedIn
                                ? state.user
                                : (state as firebase_ui.UserCreated)
                                    .credential
                                    .user;

                        if (user == null) return;

                        final isNewUser = state is firebase_ui.UserCreated;

                        if (isNewUser &&
                            user.displayName == null &&
                            user.email != null) {
                          final displayName = user.email!.split('@')[0];
                          user.updateDisplayName(displayName);
                          Provider.of<GlobalProvider>(
                            context,
                            listen: false,
                          ).handleUserLogin(
                            user,
                            isNewUser: true,
                            displayName: displayName,
                          );
                        } else {
                          Provider.of<GlobalProvider>(
                            context,
                            listen: false,
                          ).handleUserLogin(user, isNewUser: isNewUser);
                        }
                      }
                    }),
                  ],
                );
              },
            ),
            routes: {
              '/shop': (_) => const HomePage(),
              '/profile':
                  (_) => firebase_ui.ProfileScreen(
                    providers: [firebase_ui.EmailAuthProvider()],
                    actions: [
                      firebase_ui.SignedOutAction((context) {
                        Provider.of<GlobalProvider>(
                          context,
                          listen: false,
                        ).changeCurrentIdx(0);
                      }),
                    ],
                    avatarSize: 80,
                  ),
              '/forgot-password':
                  (_) => const firebase_ui.ForgotPasswordScreen(),
            },
            locale: provider.locale,
            supportedLocales: const [Locale('en'), Locale('mn')],
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              FirebaseUILocalizations.delegate,
            ],
          ),
    );
  }
}
