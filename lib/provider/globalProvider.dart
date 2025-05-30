// lib/provider/global_provider.dart
import 'dart:convert';
import 'dart:io' show Platform; // Platform-ийг шалгахад ашиглана
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firebase_core/firebase_core.dart'; // Firebase Core-ийг нэмэх
import 'package:firebase_auth/firebase_auth.dart'
    as fb_auth; // Aliased to avoid conflict
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Firebase-ийн Cloud Messaging сан
import 'package:shop/main.dart';
// model-уудыг импортлох
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../models/comment_model.dart';

//Api Service ийг импортлох
import 'package:shop/services/api_service.dart';

// Background message handler (top-level function)
// Энэ функц нь аппликешны context-ээс гадуур ажиллах ёстой.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
  print('Message data: ${message.data}');
  print(
    'Message notification: ${message.notification?.title} / ${message.notification?.body}',
  );
  // Энд хүлээн авсан мэдэгдлийг боловсруулах логикийг нэмж болно.
}

class GlobalProvider extends ChangeNotifier {
  // Services
  final ApiService apiService = ApiService(); // If used for other API calls
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final fb_auth.FirebaseAuth _firebaseAuth =
      fb_auth.FirebaseAuth.instance; // Instance of FirebaseAuth
  final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance; // FCM instance

  // User State/ хэрэглэгчийн төлөв
  fb_auth.User? _firebaseUser; // Current Firebase Authenticated User
  UserModel? currentUser; // Your custom UserModel

  // Product State/бүтээгдэхүүний төлөв
  List<ProductModel> products = [];

  // Cart State/Сагсны төлөв(Firestore based)
  List<ProductModel> _cartItems = [];
  List<ProductModel> get cartItems => List.unmodifiable(_cartItems);

  // Favorites State/ дуртай төлөв (Firestore based)
  List<ProductModel> _favorites = [];
  List<ProductModel> get favorites => List.unmodifiable(_favorites);

  // Comments State/ Сэтгэгдлийн төлөв (Firestore based)
  List<CommentModel> _productComments = [];
  List<CommentModel> get productComments => List.unmodifiable(_productComments);
  bool _isLoadingComments = false;
  bool get isLoadingComments => _isLoadingComments;

  // Notifications State/ мэдэгдлийн төлөв (Firebase Cloud Messaging)
  List<RemoteMessage> _receivedNotifications = [];
  List<RemoteMessage> get receivedNotifications =>
      List.unmodifiable(_receivedNotifications);

  // Navigation State / Навигацийн төлөв
  int currentIdx = 0;

  // Localization State / хэлний тохиргоог хадгалах локал
  Locale _locale = const Locale('en'); // Default locale
  Locale get locale => _locale;
  Map<String, String> localizedStrings = {};

  // --- INITIALIZATION & AUTH LISTENER ---
  GlobalProvider() {
    _listenToAuthStateChanges(); // Firebase Auth-ийг холбох listeners-ийг эхлүүлэх
    loadProducts(); // Json файлыг ачаалалж бүтээгдэхүүнүүдийг ачаалах
    loadLocale(); // локалд хэлний тохиргоог хадгалах
    _initFCM(); // Fcm-ийг эхлүүлэх
  }

  void _listenToAuthStateChanges() {
    _firebaseAuth.authStateChanges().listen((fb_auth.User? user) {
      if (user == null) {
        print('Хэрэглэгч системээс гарсан байна!');
        handleUserLogout();
      } else {
        print('Хэрэглэгч нэвтэрсэн: ${user.uid}');
        handleUserLogin(user);
      }
    });
  }

  // --- FCM INITIALIZATION & HANDLERS ---
  /// Firebase Cloud Messaging (FCM) -ийг эхлүүлэх
  Future<void> _initFCM() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Хэрэglэгч мэдэгдэл хүлээн авах зөвшөөрөл өгсөн.');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('Хэрэглэгч түр зөвшөөрөл өгсөн.');
    } else {
      print('Хэрэглэгч зөвшөөрөл өгөөгүй эсвэл татгалзсан.');
    }

    // Get FCM token
    // Энэ токенийг серверт илгээж, тухайн төхөөрөмж рүү чиглэсэн мэдэгдэл илгээхэд ашиглана.
    String? token = await _firebaseMessaging.getToken();
    print("FirebaseMessaging Token: $token");
    _sendTokenToServer(
      token,
    ); // Сервер лүү токен илгээх функц (шаардлагатай бол)
    // Firebase Cloud Messaging-ийн background message handler-ийг тохируулах
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground мэдэгдэл хүлээн авлаа:');
      print('Message data: ${message.data}');
      if (message.notification != null) {
        print(
          'Message notification: ${message.notification?.title} / ${message.notification?.body}',
        );
        // --- Энд context ашиглан дэлгэц дээр харуулна ---
        // Та GlobalKey ашиглаж болно:
        navigatorKey.currentState?.overlay?.context != null
            ? ScaffoldMessenger.of(
              navigatorKey.currentState!.overlay!.context,
            ).showSnackBar(
              SnackBar(
                content: Text(
                  '${message.notification!.title ?? ""}\n${message.notification!.body ?? ""}',
                ),
                duration: Duration(seconds: 3),
              ),
            )
            : null;
      }
      _receivedNotifications.add(message);
      notifyListeners();
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Background/Terminated-аас апп-г нээсэн мэдэгдэл:');
      print('Message data: ${message.data}');
      if (message.notification != null) {
        print(
          'Message notification: ${message.notification?.title} / ${message.notification?.body}',
        );
      }
      _receivedNotifications.add(message);
      // Энд тухайн мэдэгдэлтэй холбоотой дэлгэц рүү шилжих гэх мэт үйлдлийг хийж болно.
      // Жишээ нь: Navigator.pushNamed(context, '/notification_details', arguments: message.data);
      notifyListeners();
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print('Terminated-аас апп-г нээсэн анхны мэдэгдэл:');
      print('Message data: ${initialMessage.data}');
      if (initialMessage.notification != null) {
        print(
          'Message notification: ${initialMessage.notification?.title} / ${initialMessage.notification?.body}',
        );
      }
      _receivedNotifications.add(initialMessage);
      // Энд мөн адил тусгай дэлгэц рүү шилжих логик хийж болно.
      notifyListeners();
    }
  }

  void _sendTokenToServer(String? token) {
    if (token == null) return;
    // Энэ функцийг хэрэгжүүлж, хэрэглэгчийн FCM токенийг өөрийн сервер лүү илгээнэ.
    // Жишээ нь, хэрэглэгч нэвтэрсэн үед Firestore-д хадгалах:
    if (_firebaseUser != null) {
      _firestore.collection('users').doc(_firebaseUser!.uid).update({
        'fcmTokens': FieldValue.arrayUnion([
          token,
        ]), // Нэг хэрэглэгч олон төхөөрөмжтэй байж болно
      });
    }
    print("FCM Token сервер лүү илгээхэд бэлэн: $token");
  }

  // --- PRODUCT METHODS ---
  Future<void> loadProducts() async {
    if (products.isNotEmpty) return;

    try {
      final jsonStr = await rootBundle.loadString('assets/products.json');
      final List<dynamic> list = json.decode(jsonStr);
      products = ProductModel.fromList(list);
      print('Бүтээгдэхүүнүүд ачааллагдлаа: ${products.length} ш');

      if (_firebaseUser != null && _favorites.isNotEmpty) {
        await _updateProductsFavoriteStatus();
      }
    } catch (e) {
      print('Бүтээгдэхүүн ачаалахад алдаа гарлаа: $e');
      products = [];
    }
    notifyListeners();
  }

  void setProducts(List<ProductModel> data) {
    products = data;
    if (_firebaseUser != null) {
      _updateProductsFavoriteStatus();
    }
    notifyListeners();
  }

  // --- AUTHENTICATION METHODS ---
  Future<void> _loadOrCreateUserInFirestore(
    fb_auth.User firebaseUser, {
    bool isNewUser = false,
    String? displayName,
  }) async {
    final userDocRef = _firestore.collection('users').doc(firebaseUser.uid);
    final docSnapshot = await userDocRef.get();

    if (docSnapshot.exists && !isNewUser) {
      currentUser = UserModel.fromFirestore(docSnapshot);
      print(
        'Хэрэглэгчийн мэдээлэл Firestore-оос ачааллагдлаа: ${currentUser?.email}',
      );
    } else {
      String? effectiveDisplayName = displayName ?? firebaseUser.displayName;
      String email = firebaseUser.email ?? 'no-email@example.com';

      String firstName = '';
      String lastName = '';
      if (effectiveDisplayName != null && effectiveDisplayName.isNotEmpty) {
        List<String> nameParts = effectiveDisplayName.split(' ');
        firstName = nameParts.first;
        if (nameParts.length > 1) {
          lastName = nameParts.sublist(1).join(' ');
        }
      }

      currentUser = UserModel(
        id: firebaseUser.uid,
        email: email,
        username:
            firebaseUser.email?.split('@')[0] ??
            'user_${firebaseUser.uid.substring(0, 5)}',
        name: NameModel(firstname: firstName, lastname: lastName),
        phone: firebaseUser.phoneNumber ?? '',
        address: Address(city: '', street: ''),
        avatarUrl: firebaseUser.photoURL,
      );
      await userDocRef.set(currentUser!.toFirestore());
      print(
        'Шинэ хэрэглэгч Firestore-д үүсгэгдлээ/шинэчлэгдлээ: ${currentUser?.email}',
      );
      // Шинэ хэрэглэгч бол FCM токен шууд хадгалах
      String? token = await _firebaseMessaging.getToken();
      _sendTokenToServer(token);
    }
  }

  Future<void> handleUserLogin(
    fb_auth.User firebaseUser, {
    bool isNewUser = false,
    String? displayName,
  }) async {
    _firebaseUser = firebaseUser;
    await _loadOrCreateUserInFirestore(
      firebaseUser,
      isNewUser: isNewUser,
      displayName: displayName,
    );

    if (currentUser != null) {
      await _loadUserCartFromFirestore();
      await _loadUserFavoritesFromFirestore();
      // Хэрэглэгч нэвтэрсэн үед FCM токенийг дахин шалгаж/шинэчлэх
      String? token = await _firebaseMessaging.getToken();
      _sendTokenToServer(token);
    } else {
      print(
        "Алдаа: Нэвтрэх оролдлогын дараа currentUser (UserModel) null байна.",
      );
      _cartItems.clear();
      _favorites.clear();
      await _updateProductsFavoriteStatus();
    }
    notifyListeners();
  }

  void handleUserLogout() {
    _firebaseUser = null;
    currentUser = null;
    _cartItems.clear();
    _favorites.clear();
    _productComments.clear();
    _receivedNotifications
        .clear(); // Хэрэглэгч гарахад хүлээн авсан мэдэгдлийг цэвэрлэх

    for (var prod in products) {
      prod.isFavorite = false;
    }
    currentIdx = 0;
    notifyListeners();
  }

  // --- CART METHODS (Firestore based) ---
  Future<void> _loadUserCartFromFirestore() async {
    if (_firebaseUser == null) {
      _cartItems.clear();
      return;
    }
    try {
      final cartSnap =
          await _firestore
              .collection('users')
              .doc(_firebaseUser!.uid)
              .collection('cart')
              .get();

      _cartItems =
          cartSnap.docs.map((doc) {
            final data = doc.data();
            return ProductModel.fromJson({...data, 'id': data['id'] ?? doc.id});
          }).toList();
      print('Сагс Firestore-оос ачааллагдлаа: ${_cartItems.length} ш');
    } catch (e) {
      print('Сагс Firestore-оос ачаалахад алдаа гарлаа: $e');
      _cartItems.clear();
    }
  }

  Future<void> addToCart(ProductModel item) async {
    if (_firebaseUser == null) {
      print("Хэрэглэгч нэвтрээгүй байна. Сагсанд нэмэх боломжгүй.");
      return;
    }
    if (item.id == null) {
      print('Бүтээгдэхүүний ID null байна, сагсанд нэмэх боломжгүй.');
      return;
    }

    final String itemIdString = item.id.toString();
    final existingItemIndex = _cartItems.indexWhere(
      (p) => p.id.toString() == itemIdString,
    );

    if (existingItemIndex != -1) {
      _cartItems[existingItemIndex].count++;
      await _firestore
          .collection('users')
          .doc(_firebaseUser!.uid)
          .collection('cart')
          .doc(itemIdString)
          .update({'count': _cartItems[existingItemIndex].count});
    } else {
      item.count = 1;
      _cartItems.add(item);
      await _firestore
          .collection('users')
          .doc(_firebaseUser!.uid)
          .collection('cart')
          .doc(itemIdString)
          .set(item.toJson());
    }
    notifyListeners();
  }

  Future<void> removeFromCart(ProductModel item) async {
    if (_firebaseUser == null || item.id == null) return;
    final String itemIdString = item.id.toString();
    _cartItems.removeWhere((p) => p.id.toString() == itemIdString);
    await _firestore
        .collection('users')
        .doc(_firebaseUser!.uid)
        .collection('cart')
        .doc(itemIdString)
        .delete();
    notifyListeners();
  }

  Future<void> increaseQuantity(ProductModel item) async {
    if (_firebaseUser == null || item.id == null) return;
    final String itemIdString = item.id.toString();
    final p = _cartItems.firstWhere((p) => p.id.toString() == itemIdString);
    p.count++;
    await _firestore
        .collection('users')
        .doc(_firebaseUser!.uid)
        .collection('cart')
        .doc(itemIdString)
        .update({'count': p.count});
    notifyListeners();
  }

  Future<void> decreaseQuantity(ProductModel item) async {
    if (_firebaseUser == null || item.id == null) return;
    final String itemIdString = item.id.toString();
    final p = _cartItems.firstWhere((p) => p.id.toString() == itemIdString);
    p.count--;
    if (p.count <= 0) {
      _cartItems.remove(p);
      await _firestore
          .collection('users')
          .doc(_firebaseUser!.uid)
          .collection('cart')
          .doc(itemIdString)
          .delete();
    } else {
      await _firestore
          .collection('users')
          .doc(_firebaseUser!.uid)
          .collection('cart')
          .doc(itemIdString)
          .update({'count': p.count});
    }
    notifyListeners();
  }

  double get cartTotal => _cartItems.fold(
    0,
    (sum, item) => sum + ((item.price ?? 0.0) * item.count),
  );

  // --- FAVORITES METHODS (Firestore based) ---
  Future<void> _loadUserFavoritesFromFirestore() async {
    if (_firebaseUser == null) {
      _favorites.clear();
      await _updateProductsFavoriteStatus();
      return;
    }
    try {
      final favSnap =
          await _firestore
              .collection('users')
              .doc(_firebaseUser!.uid)
              .collection('favorites')
              .get();
      _favorites =
          favSnap.docs.map((doc) {
            final data = doc.data();
            return ProductModel.fromJson({...data, 'id': data['id'] ?? doc.id});
          }).toList();
      print(
        'Дуртай бүтээгдэхүүн Firestore-оос ачааллагдлаа: ${_favorites.length} ш',
      );
    } catch (e) {
      print('Дуртай бүтээгдэхүүн Firestore-оос ачаалахад алдаа гарлаа: $e');
      _favorites.clear();
    }
    await _updateProductsFavoriteStatus();
  }

  Future<void> _updateProductsFavoriteStatus() async {
    for (var prod in products) {
      prod.isFavorite = _favorites.any(
        (fav) => fav.id.toString() == prod.id.toString(),
      );
    }
  }

  Future<void> toggleFavorite(ProductModel item) async {
    if (_firebaseUser == null || item.id == null) {
      print(
        "Хэрэглэгч нэвтрээгүй эсвэл барааны ID null байна. Дуртайд нэмэх/хасах боломжгүй.",
      );
      return;
    }

    final String itemIdString = item.id.toString();
    final productInMainList = products.firstWhere(
      (p) => p.id.toString() == itemIdString,
      orElse: () => item,
    );

    final isCurrentlyFavorite = _favorites.any(
      (p) => p.id.toString() == itemIdString,
    );

    productInMainList.isFavorite = !isCurrentlyFavorite;

    if (isCurrentlyFavorite) {
      _favorites.removeWhere((p) => p.id.toString() == itemIdString);
      await _firestore
          .collection('users')
          .doc(_firebaseUser!.uid)
          .collection('favorites')
          .doc(itemIdString)
          .delete();
    } else {
      final ProductModel favoriteToAdd = ProductModel.fromJson(item.toJson())
        ..isFavorite = true;
      _favorites.add(favoriteToAdd);
      await _firestore
          .collection('users')
          .doc(_firebaseUser!.uid)
          .collection('favorites')
          .doc(itemIdString)
          .set(favoriteToAdd.toJson());
    }
    notifyListeners();
  }

  bool isFavorite(ProductModel item) {
    if (item.id == null) return false;
    return _favorites.any((p) => p.id.toString() == item.id.toString());
  }

  // --- COMMENTS METHODS (Firestore based) ---
  Future<void> fetchProductComments(String productId) async {
    _isLoadingComments = true;
    _productComments.clear();
    notifyListeners();

    if (productId.isEmpty) {
      print(
        'Сэтгэгдэл ачаалахад бүтээгдэхүүний ID хоосон байна. Сэтгэгдлүүд цэвэрлэгдсэн хэвээр үлдэнэ.',
      );
      _isLoadingComments = false;
      notifyListeners();
      return;
    }

    try {
      final commentsSnapshot =
          await _firestore
              .collection('products')
              .doc(productId)
              .collection('comments')
              .orderBy('timestamp', descending: true)
              .get();

      _productComments =
          commentsSnapshot.docs
              .map((doc) => CommentModel.fromFirestore(doc))
              .toList();
      print(
        '$productId бүтээгдэхүүний ${_productComments.length} сэтгэгдэл ачааллагдлаа.',
      );
    } catch (e) {
      print('$productId бүтээгдэхүүний сэтгэгдэл ачаалахад алдаа гарлаа: $e');
      _productComments = [];
    }
    _isLoadingComments = false;
    notifyListeners();
  }

  Future<bool> addProductComment(String productId, String content) async {
    if (_firebaseUser == null) {
      print('Хэрэглэгч нэвтрээгүй байна. Сэтгэгдэл нэмэх боломжгүй.');
      return false;
    }
    if (productId.isEmpty || content.trim().isEmpty) {
      print('Бүтээгдэхүүний ID эсвэл сэтгэгдлийн агуулга хоосон байна.');
      return false;
    }

    final fb_auth.User loggedInFirebaseUser = _firebaseUser!;
    final String username =
        currentUser?.name.firstname.isNotEmpty == true
            ? '${currentUser!.name.firstname} ${currentUser!.name.lastname}'
                .trim()
            : (loggedInFirebaseUser.displayName?.isNotEmpty == true
                ? loggedInFirebaseUser.displayName!
                : (loggedInFirebaseUser.email?.split('@')[0] ?? 'Anonymous'));
    final String? avatarUrl =
        currentUser?.avatarUrl ?? loggedInFirebaseUser.photoURL;

    final newCommentData = CommentModel(
      id: '',
      productId: productId,
      userId: loggedInFirebaseUser.uid,
      username: username,
      userAvatarUrl: avatarUrl,
      content: content.trim(),
      timestamp: Timestamp.now(),
    );

    try {
      final commentDocRef = await _firestore
          .collection('products')
          .doc(productId)
          .collection('comments')
          .add(newCommentData.toFirestore());

      final addedComment = CommentModel(
        id: commentDocRef.id,
        productId: newCommentData.productId,
        userId: newCommentData.userId,
        username: newCommentData.username,
        userAvatarUrl: newCommentData.userAvatarUrl,
        content: newCommentData.content,
        timestamp: newCommentData.timestamp,
      );
      _productComments.insert(0, addedComment);

      print(
        '$productId бүтээгдэхүүнд ${commentDocRef.id} ID-тай сэтгэгдэл амжилттай нэмэгдлээ.',
      );
      notifyListeners();
      return true;
    } catch (e) {
      print('$productId бүтээгдэхүүний сэтгэгдэл нэмэхэд алдаа гарлаа: $e');
      return false;
    }
  }

  // --- NAVIGATION METHODS ---
  void changeCurrentIdx(int idx) {
    currentIdx = idx;
    notifyListeners();
  }

  // --- LANGUAGE & LOCALIZATION METHODS ---
  Future<void> loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('language_code') ?? 'en';
    _locale = Locale(langCode);
    await _loadLocalizedStrings(langCode);
  }

  Future<void> setLocale(String languageCode) async {
    _locale = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);
    await _loadLocalizedStrings(languageCode);
    notifyListeners();
  }

  Future<void> _loadLocalizedStrings(String langCode) async {
    try {
      final jsonStr = await rootBundle.loadString('assets/lan/$langCode.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonStr);
      localizedStrings = jsonMap.map(
        (key, value) => MapEntry(key, value.toString()),
      );
    } catch (e) {
      print("$langCode хэлний файл ачаалахад алдаа гарлаа: $e");
      if (langCode != 'en') {
        print("Англи хэл рүү шилжиж байна.");
        await _loadLocalizedStrings('en');
      } else {
        localizedStrings = {};
        print(
          "Англи хэлний файл ачаалахад алдаа гарлаа. Орчуулгын мэдээлэл байхгүй.",
        );
      }
    }
  }
}
