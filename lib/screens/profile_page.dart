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

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ModalRoute.of(context)?.settings.name != '/profile') {

        }
      });
      return fui.ProfileScreen(
        providers: [fui.EmailAuthProvider()],
        actions: [
          fui.SignedOutAction((context) {
            globalProvider.changeCurrentIdx(0); // Go to shop
          }),
          fui.AccountDeletedAction((context, user) {
            globalProvider.changeCurrentIdx(0); // Go to shop
          }),
        ],
        avatarSize: 80,
      );
    }

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

            },
          ),
          IconButton(
            // Button to go to FirebaseUI's full profile screen for more options
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/profile',
              );
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
