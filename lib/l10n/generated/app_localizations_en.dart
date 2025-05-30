// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get shop => 'Products';

  @override
  String get basket => 'Cart';

  @override
  String get basketState => 'Cart is empty';

  @override
  String get favorites => 'Favorites';

  @override
  String get profile => 'Profile';

  @override
  String get myProfile => 'My Profile';

  @override
  String get myOrders => 'My Orders';

  @override
  String get shippingAddresses => 'Shipping Addresses';

  @override
  String get paymentMethods => 'Payment Methods';

  @override
  String get promotionCodes => 'Promotion Codes';

  @override
  String get myReviews => 'My Reviews';

  @override
  String get settings => 'Settings';

  @override
  String priceLabel(Object price) {
    return 'Price: $price';
  }

  @override
  String categoryLabel(Object category) {
    return 'Category: $category';
  }

  @override
  String ratingLabel(Object count, Object rating) {
    return 'Rating: $rating ($count)';
  }

  @override
  String get total => 'Total';

  @override
  String get paymentSuccess => 'Payment is successfull';

  @override
  String get buy => 'Buy';
}
