import 'dart:convert';
import 'dart:io' show Platform; // Платформыг шалгахад ашиглана
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firebase_auth/firebase_auth.dart'
    as fb_auth; // Нэр давхцахаас сэргийлж alias ашигласан
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Firebase Cloud Messaging
import 'package:shop/main.dart';
// Загваруудыг импортлох
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../models/comment_model.dart';

// Api үйлчилгээ импортлох
import 'package:shop/services/api_service.dart';

import '../repository/repository.dart';


class GlobalProvider extends ChangeNotifier {

  final repo = MyRepository();
  final ApiService apiService = ApiService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final fb_auth.FirebaseAuth _firebaseAuth =
      fb_auth.FirebaseAuth.instance;
  final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  // Хэрэглэгчийн төлөв
  fb_auth.User? _firebaseUser;
  UserModel? currentUser;

  // Бүтээгдэхүүний төлөв
  List<ProductModel> products = [];

  // Сагсны төлөв (Firestore дээр суурилсан)
  List<ProductModel> _cartItems = [];
  List<ProductModel> get cartItems => List.unmodifiable(_cartItems);

  // Дуртай бүтээгдэхүүний төлөв (Firestore дээр суурилсан)
  List<ProductModel> _favorites = [];
  List<ProductModel> get favorites => List.unmodifiable(_favorites);

  // Сэтгэгдлийн төлөв (Firestore дээр суурилсан)
  List<CommentModel> _productComments = [];
  List<CommentModel> get productComments => List.unmodifiable(_productComments);
  bool _isLoadingComments = false;
  bool get isLoadingComments => _isLoadingComments;

  bool _isLoadingComment = false;
  bool get isLoadingComment => _isLoadingComment;

  List<RemoteMessage> _receivedNotifications = [];
  List<RemoteMessage> get receivedNotifications =>
      List.unmodifiable(_receivedNotifications);

  int currentIdx = 0;


  Locale _locale = const Locale('en');
  Locale get locale => _locale;
  Map<String, String> localizedStrings = {};

  GlobalProvider() {
    _listenToAuthStateChanges();
    loadProducts();
    loadLocale();
    _initFCM();
  }

  void _listenToAuthStateChanges() {
    _firebaseAuth.authStateChanges().listen((fb_auth.User? user) {
      if (user == null) {
        print('Хэрэглэгч гарсан байна!');
        handleUserLogout();
      } else {
        print('Хэрэглэгч нэвтэрсэн: ${user.uid}');
        handleUserLogin(user);
      }
    });
  }


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
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
    } else {
    }

    String? token = await _firebaseMessaging.getToken();
    _sendTokenToServer(
      token,
    );
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Урд талын мэдэгдэл хүлээн авлаа:');
      print('Мессежийн өгөгдөл: ${message.data}');
      if (message.notification != null) {
        print(
          'Мэдэгдэл: ${message.notification?.title} / ${message.notification?.body}',
        );

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

      if (message.notification != null) {
        print(
          'Мэдэгдэл: ${message.notification?.title} / ${message.notification?.body}',
        );
      }
      _receivedNotifications.add(message);
      notifyListeners();
    });


    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      if (initialMessage.notification != null) {
        print(
          'Мэдэгдэл: ${initialMessage.notification?.title} / ${initialMessage.notification?.body}',
        );
      }
      _receivedNotifications.add(initialMessage);
      notifyListeners();
    }
  }

  void _sendTokenToServer(String? token) {
    if (token == null) return;
    if (_firebaseUser != null) {
      _firestore.collection('users').doc(_firebaseUser!.uid).update({
        'fcmTokens': FieldValue.arrayUnion([
          token,
        ]),
      });
    }
  }

  Future<void> loadProducts() async {
    if (products.isNotEmpty) return;
    try {
      products = await repo.fetchProductData();
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


  Future<void> _loadOrCreateUserInFirestore(
      fb_auth.User firebaseUser, {
        bool isNewUser = false,
        String? displayName,
      }) async {
    final userDocRef = _firestore.collection('users').doc(firebaseUser.uid);
    final docSnapshot = await userDocRef.get();

    if (docSnapshot.exists && !isNewUser) {
      currentUser = UserModel.fromFirestore(docSnapshot);
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
      String? token = await _firebaseMessaging.getToken();
      _sendTokenToServer(token);
    } else {
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
    _receivedNotifications.clear();

    for (var prod in products) {
      prod.isFavorite = false;
    }
    currentIdx = 0;
    notifyListeners();
  }

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
    } catch (e) {
      _cartItems.clear();
    }
  }

  Future<void> addToCart(ProductModel item) async {
    if (_firebaseUser == null) {
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

  // --- ДУРТАЙ БҮТЭЭГДЭХҮҮНИЙ АРГУУД (Firestore дээр суурилсан) ---
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
        'Дуртай бүтээгдэхүүнүүд Firestore-оос ачаалагдсан: ${_favorites.length}',
      );
    } catch (e) {
      print('Дуртай бүтээгдэхүүнүүдийг Firestore-оос ачаалахад алдаа гарлаа: $e');
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
        "Хэрэглэгч нэвтрээгүй эсвэл бүтээгдэхүүний ID null байна. Дуртайд нэмэх/хасах боломжгүй.",
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

  Future<void> fetchProductComments(String productId) async {
    _isLoadingComments = true;
    _productComments.clear();
    notifyListeners();

    if (productId.isEmpty) {
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

    } catch (e) {
      _productComments = [];
    }
    _isLoadingComments = false;
    notifyListeners();
  }

  Future<bool> addProductComment(String productId, String content) async {
    if (_firebaseUser == null) {
      return false;
    }
    _isLoadingComment = true;
    notifyListeners();
    if (productId.isEmpty || content.trim().isEmpty) {
      _isLoadingComment = false;
      notifyListeners();
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
      _isLoadingComment = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoadingComment = false;
      notifyListeners();
      return false;
    }
  }

  // --- НАВИГАЦИЙН АРГУУД ---
  void changeCurrentIdx(int idx) {
    currentIdx = idx;
    notifyListeners();
  }

  // --- ХЭЛ & ЛОКАЛИЗАЦИЙН АРГУУД ---
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
      print("Алдаа гарлаа $langCode хэлний файлыг ачаалахад: $e");
      if (langCode != 'en') {
        print("Англи хэл рүү шилжиж байна.");
        await _loadLocalizedStrings('en');
      } else {
        localizedStrings = {};
        print(
          "Англи хэлний файлыг ачаалахад алдаа гарлаа. Орчуулгын өгөгдөл байхгүй байна.",
        );
      }
    }
  }
}

