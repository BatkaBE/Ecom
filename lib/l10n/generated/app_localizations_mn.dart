// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Mongolian (`mn`).
class AppLocalizationsMn extends AppLocalizations {
  AppLocalizationsMn([String locale = 'mn']) : super(locale);

  @override
  String get shop => 'Бараанууд';

  @override
  String get basket => 'Сагс';

  @override
  String get basketState => 'Сагс хоосон байна';

  @override
  String get favorites => 'Хадгалсан';

  @override
  String get profile => 'Профайл';

  @override
  String get myProfile => 'Миний Профайл';

  @override
  String get myOrders => 'Миний Захиалгууд';

  @override
  String get shippingAddresses => 'Хүргэлтийн Хаягууд';

  @override
  String get paymentMethods => 'Төлбөрийн Хэрэгслүүд';

  @override
  String get promotionCodes => 'Урамшууллын Кодууд';

  @override
  String get myReviews => 'Миний Сэтгэгдэл';

  @override
  String get settings => 'Тохиргоо';

  @override
  String priceLabel(Object price) {
    return 'Үнэ: $price';
  }

  @override
  String categoryLabel(Object category) {
    return 'Ангилал: $category';
  }

  @override
  String ratingLabel(Object count, Object rating) {
    return 'Үнэлгээ: $rating ($count)';
  }

  @override
  String get total => 'Нийт';

  @override
  String get paymentSuccess => 'Төлбөр амжилттай төлөгдлөө';

  @override
  String get buy => 'Худалдаж авах';
}
