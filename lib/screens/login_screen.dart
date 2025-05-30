// screens/login_wrapper_screen.dart (New or renamed from login_screen.dart)
import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:provider/provider.dart';
import '../provider/globalprovider.dart'; // If needed for AuthStateChangeAction

class LoginWrapperScreen extends StatelessWidget {
  const LoginWrapperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SignInScreen(
      providers: [
        EmailAuthProvider(),
        // Add other providers if you've configured them in Firebase console
        // e.g. GoogleProvider(clientId: "YOUR_WEB_CLIENT_ID"),
      ],
      actions: [
        ForgotPasswordAction((context, email) {
          Navigator.pushNamed(
            context,
            '/forgot-password', // Ensure this route exists in main.dart
            arguments: {'email': email},
          );
        }),
        AuthStateChangeAction<SignedIn>((context, state) {
          // This is called after a successful sign-in.
          // User data loading is now handled by the listener in main.dart's GlobalProvider.
          // Navigation is handled by StreamBuilder in MyApp.
          // You could do additional first-time setup here if needed.
          print("User signed in via LoginWrapperScreen: ${state.user?.uid}");
          // If not using StreamBuilder for navigation directly in MyApp's home:
          // Navigator.pushReplacementNamed(context, '/shop');
        }),
        AuthStateChangeAction<UserCreated>((context, state) {
          var user = state.credential.user;
          if (user == null) return;

          String? displayName = user.displayName; // Or a default
          if (user.displayName == null && user.email != null) {
            displayName = user.email!.split('@')[0];
            user.updateDisplayName(displayName);
          }

          Provider.of<GlobalProvider>(
            context,
            listen: false,
          ).handleUserLogin(user, isNewUser: true, displayName: displayName);
          // Navigator.pushReplacementNamed(context, '/shop'); // If needed
        }),
      ],
    );
  }
}
