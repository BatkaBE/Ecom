import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart' as fui; // Firebase UI
import 'package:firebase_auth/firebase_auth.dart' as fb_auth; // Firebase Auth
import '../provider/globalprovider.dart';
import '../models/user_model.dart'; // Your UserModel

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final globalProvider = Provider.of<GlobalProvider>(context);
    final UserModel? appUser = globalProvider.currentUser;
    final fb_auth.User? firebaseUser =
        fb_auth.FirebaseAuth.instance.currentUser;

    if (firebaseUser == null || appUser == null) {
      // This part will show if the user is not logged in.
      // FirebaseUI's ProfileScreen also handles this by showing sign-in options.
      // We can navigate to the FirebaseUI ProfileScreen which handles login/signup.
      // Or show a custom message. For consistency, we'll use FirebaseUI's screen.
      // The main navigation in MyApp should ideally show SignInScreen directly
      // if currentIdx points here and user is null.
      // For now, let's assume we always want to show FirebaseUI's ProfileScreen
      // which will prompt login if needed.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ModalRoute.of(context)?.settings.name != '/profile') {
          // Only push if not already on /profile to avoid loop
          // if /profile is the entry point for unauthenticated users.
          // However, with StreamBuilder in main.dart, this might not be needed
          // as unauth users are directed to SignInScreen.
        }
      });
      // If you want the Profile tab to always lead to FirebaseUI's profile:
      return fui.ProfileScreen(
        providers: [fui.EmailAuthProvider()],
        actions: [
          fui.SignedOutAction((context) {
            // globalProvider.handleUserLogout(); // Already handled by auth listener
            globalProvider.changeCurrentIdx(0); // Go to shop
            // StreamBuilder in main.dart will navigate to SignInScreen
          }),
          // You can add more actions, e.g., for editing profile details
          // that are stored in your Firestore `UserModel`.
          fui.AccountDeletedAction((context, user) {
            // globalProvider.handleUserLogout(); // Already handled
            globalProvider.changeCurrentIdx(0); // Go to shop
          }),
        ],
        avatarSize: 80,
      );
    }

    // If logged in, show custom profile details from appUser (your UserModel)
    // and can still use FirebaseUI actions if desired.
    return Scaffold(
      appBar: AppBar(
        title: Text(
          globalProvider.localizedStrings['profile_title'] ?? 'My Profile',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await fb_auth.FirebaseAuth.instance.signOut();
              // GlobalProvider's authStateChanges listener will handleUserLogout()
              // and StreamBuilder in MyApp will navigate.
              // globalProvider.changeCurrentIdx(0); // Optionally navigate immediately
            },
          ),
          IconButton(
            // Button to go to FirebaseUI's full profile screen for more options
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/profile',
              ); // Navigates to the FirebaseUI ProfileScreen route
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          // Changed to ListView for scrollability
          children: [
            Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage:
                        appUser.avatarUrl != null &&
                                appUser.avatarUrl!.isNotEmpty
                            ? NetworkImage(appUser.avatarUrl!)
                            : null,
                    child:
                        appUser.avatarUrl == null || appUser.avatarUrl!.isEmpty
                            ? const Icon(Icons.person, size: 50)
                            : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${appUser.name.firstname} ${appUser.name.lastname}'
                            .trim()
                            .isEmpty
                        ? (appUser.username ?? 'User')
                        : '${appUser.name.firstname} ${appUser.name.lastname}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(appUser.email, style: const TextStyle(fontSize: 16)),
                  if (appUser.phone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(appUser.phone, style: const TextStyle(fontSize: 16)),
                  ],
                  if (appUser.address.city.isNotEmpty ||
                      appUser.address.street.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${appUser.address.street}, ${appUser.address.city}'
                          .trim()
                          .replaceAll(RegExp(r'^, |,$'), ''),
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Language selection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.language),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: globalProvider.locale.languageCode,
                        items: const [
                          DropdownMenuItem(value: 'en', child: Text('English')),
                          DropdownMenuItem(value: 'mn', child: Text('Монгол')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            globalProvider.setLocale(value);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to FirebaseUI's profile screen for account management
                      Navigator.pushNamed(context, '/profile');
                    },
                    child: Text(
                      globalProvider.localizedStrings['manage_account'] ??
                          'Manage Account',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
