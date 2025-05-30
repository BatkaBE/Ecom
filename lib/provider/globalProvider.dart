// lib/provider/global_provider.dart
import 'dart:convert';
import 'dart:io' show Platform; // Платформыг шалгахад ашиглана
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firebase_core/firebase_core.dart'; // Firebase үндсэн сан
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

// Арын горимын мессежийн боловсруулагч (top-level function)
// Энэ функц нь апп-н контекстээс гадуур ажиллах ёстой.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Арын горимд мессеж боловсруулж байна: ${message.messageId}");
  print('Мессежийн өгөгдөл: ${message.data}');
  print(
    'Мэдэгдэл: ${message.notification?.title} / ${message.notification?.body}',
  );
  // Хүлээн авсан мэдэгдлийг боловсруулах логикийг энд нэмнэ үү.
}

class GlobalProvider extends ChangeNotifier {
  // Үйлчилгээнүүд
  final ApiService apiService = ApiService(); // Бусад API дуудлагад ашиглагдвал
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final fb_auth.FirebaseAuth _firebaseAuth =
      fb_auth.FirebaseAuth.instance; // FirebaseAuth-ийн instance
  final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance; // FCM-ийн instance

  // Хэрэглэгчийн төлөв
  fb_auth.User? _firebaseUser; // Одоогийн Firebase-аар нэвтэрсэн хэрэглэгч
  UserModel? currentUser; // Таны өөрийн UserModel

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

  // Сэтгэгдэл ачаалж байгаа төлөв
  bool _isLoadingComment = false;
  bool get isLoadingComment => _isLoadingComment;

  // Мэдэгдлийн төлөв (Firebase Cloud Messaging)
  List<RemoteMessage> _receivedNotifications = [];
  List<RemoteMessage> get receivedNotifications =>
      List.unmodifiable(_receivedNotifications);

  // Навигацийн төлөв
  int currentIdx = 0;

  // Локализацийн төлөв
  Locale _locale = const Locale('en'); // Анхдагч локаль
  Locale get locale => _locale;
  Map<String, String> localizedStrings = {};

  // --- ЭХЛҮҮЛЭЛТ & АУТЕНТИКАЦИЙН СОНСОГЧ ---
  GlobalProvider() {
    _listenToAuthStateChanges(); // Firebase Auth сонсогчдыг эхлүүлэх
    loadProducts(); // JSON файлаас бүтээгдэхүүнүүдийг ачаалах
    loadLocale(); // Локал тохиргоог ачаалах
    _initFCM(); // FCM-г эхлүүлэх
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

  // --- FCM ЭХЛҮҮЛЭЛТ & БОЛОВСРУУЛАГЧИД ---
  /// Firebase Cloud Messaging (FCM)-г эхлүүлэх
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
      print('Хэрэглэгч мэдэгдлийн зөвшөөрөл өгсөн.');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('Хэрэглэгч түр зөвшөөрөл өгсөн.');
    } else {
      print('Хэрэглэгч зөвшөөрөл өгөөгүй эсвэл татгалзсан.');
    }

    // FCM токен авах
    // Энэ токеныг сервер рүү илгээж, энэ төхөөрөмж рүү чиглэсэн мэдэгдэл илгээх боломжтой.
    String? token = await _firebaseMessaging.getToken();
    print("FirebaseMessaging Token: $token");
    _sendTokenToServer(
      token,
    ); // Токеныг сервер рүү илгээх функц (хэрэгтэй бол)
    // Firebase Cloud Messaging арын горимын мессежийн боловсруулагчийг тохируулах
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Урд талын мэдэгдэл хүлээн авлаа:');
      print('Мессежийн өгөгдөл: ${message.data}');
      if (message.notification != null) {
        print(
          'Мэдэгдэл: ${message.notification?.title} / ${message.notification?.body}',
        );
        // --- Мэдэгдлийг дэлгэц дээр харуулах ---
        // GlobalKey ашиглаж болно:
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
      print('Апп арын горим/хаагдсан төлөвөөс мэдэгдлээр нээгдсэн');
      print('Мессежийн өгөгдөл: ${message.data}');
      if (message.notification != null) {
        print(
          'Мэдэгдэл: ${message.notification?.title} / ${message.notification?.body}',
        );
      }
      _receivedNotifications.add(message);
      // Энд мэдэгдлийн дагуу тодорхой дэлгэц рүү шилжиж болно.
      // Жишээ: Navigator.pushNamed(context, '/notification_details', arguments: message.data);
      notifyListeners();
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print('Апп мэдэгдлээр хаагдсан төлөвөөс нээгдсэн');
      print('Мессежийн өгөгдөл: ${initialMessage.data}');
      if (initialMessage.notification != null) {
        print(
          'Мэдэгдэл: ${initialMessage.notification?.title} / ${initialMessage.notification?.body}',
        );
      }
      _receivedNotifications.add(initialMessage);
      // Хэрэгтэй бол энд тодорхой дэлгэц рүү шилжиж болно.
      notifyListeners();
    }
  }

  void _sendTokenToServer(String? token) {
    if (token == null) return;
    // Хэрэглэгчийн FCM токеныг сервер рүү илгээх эсвэл Firestore-д хадгалах.
    // Жишээ: Хэрэглэгч нэвтэрсэн үед Firestore-д хадгалах:
    if (_firebaseUser != null) {
      _firestore.collection('users').doc(_firebaseUser!.uid).update({
        'fcmTokens': FieldValue.arrayUnion([
          token,
        ]), // Хэрэглэгч олон төхөөрөмжтэй байж болно
      });
    }
    print("FCM токеныг сервер рүү илгээхэд бэлэн: $token");
  }

  // --- БҮТЭЭГДЭХҮҮНИЙ АРГУУД ---
  Future<void> loadProducts() async {
    if (products.isNotEmpty) return;

    try {
      final jsonStr = await rootBundle.loadString('assets/products.json');
      final List<dynamic> list = json.decode(jsonStr);
      products = ProductModel.fromList(list);
      print('Бүтээгдэхүүнүүд ачаалагдсан: ${products.length}');
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

  // --- АУТЕНТИКАЦИЙН АРГУУД ---
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
        'Хэрэглэгчийн өгөгдөл Firestore-оос ачаалагдсан: ${currentUser?.email}',
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
        'Шинэ хэрэглэгч Firestore-д үүсгэгдсэн/шинэчлэгдсэн: ${currentUser?.email}',
      );
      // Хэрэв шинэ хэрэглэгч бол FCM токеныг шууд хадгална
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
      // Хэрэглэгч нэвтэрсэн үед FCM токеныг шалгаж/шинэчилнэ
      String? token = await _firebaseMessaging.getToken();
      _sendTokenToServer(token);
    } else {
      print(
        "Алдаа: currentUser (UserModel) нь нэвтрэх оролдлогын дараа null байна.",
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
    _receivedNotifications.clear(); // Гарах үед хүлээн авсан мэдэгдлүүдийг цэвэрлэх

    for (var prod in products) {
      prod.isFavorite = false;
    }
    currentIdx = 0;
    notifyListeners();
  }

  // --- САГСНЫ АРГУУД (Firestore дээр суурилсан) ---
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
      print('Сагс Firestore-оос ачаалагдсан: ${_cartItems.length}');
    } catch (e) {
      print('Сагсыг Firestore-оос ачаалахад алдаа гарлаа: $e');
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

  // --- СЭТГЭГДЛИЙН АРГУУД (Firestore дээр суурилсан) ---
  Future<void> fetchProductComments(String productId) async {
    _isLoadingComments = true;
    _productComments.clear();
    notifyListeners();

    if (productId.isEmpty) {
      print(
        'Бүтээгдэхүүний ID хоосон байна. Сэтгэгдлүүд цэвэрлэгдсэн хэвээр байна.',
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
        '$productId бүтээгдэхүүнд ${_productComments.length} сэтгэгдэл ачаалагдсан.',
      );
    } catch (e) {
      print('Сэтгэгдлүүдийг $productId бүтээгдэхүүнд ачаалахад алдаа гарлаа: $e');
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
    _isLoadingComment = true;
    notifyListeners();
    if (productId.isEmpty || content.trim().isEmpty) {
      print('Бүтээгдэхүүний ID эсвэл сэтгэгдлийн агуулга хоосон байна.');
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

      print(
        'Сэтгэгдэл ID ${commentDocRef.id} амжилттай $productId бүтээгдэхүүнд нэмэгдсэн.',
      );
      _isLoadingComment = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Сэтгэгдлийг $productId бүтээгдэхүүнд нэмэхэд алдаа гарлаа: $e');
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

