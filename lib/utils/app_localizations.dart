import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  late Map<String, String> _localizedStrings;

  static const Map<String, Map<String, String>> _translations = {
    'en': {
      'settings': 'Settings',
      'language': 'Language',
      'choose_language': 'Choose Language',
      'english': 'English',
      'sinhala': 'Sinhala',
      'theme': 'Theme',
      'dark_mode': 'Dark Mode',
      'light_mode': 'Light Mode',
      'reports': 'Reports',
      'products': 'Products',
      'stocks': 'Stocks',
      'categories': 'Categories',
      'brands': 'Brands',
      'units': 'Units',
      'suppliers': 'Suppliers',
      'product_suppliers': 'Product Suppliers',
      'stock_movements': 'Stock Movements',
      'batches': 'Batches',
      'images': 'Images',
      'taxes': 'Taxes',
      'discounts': 'Discounts',
      'variants': 'Variants',
      'customers': 'Customers',
      'credit_ledger': 'Credit Ledger',
      'branches': 'Branches',
      'roles': 'Roles',
      'users': 'Users',
      'pos_sales': 'POS Sales',
      'pos_management': 'POS Management',
      'management_subtitle': 'Reports, stock, cashiers and credit',
      'live_api': 'Live API',
      'dashboard': 'Dashboard',
      'logout': 'Logout',
    },
    'si': {
      'settings': 'සැකසුම්',
      'language': 'භාෂාව',
      'choose_language': 'භාෂාව තෝරන්න',
      'english': 'ඉංග්‍රීසි',
      'sinhala': 'සිංහල',
      'theme': 'තේමාව',
      'dark_mode': 'අඳුරු මාදිලිය',
      'light_mode': 'ආලෝක මාදිලිය',
      'reports': 'වාර්තා',
      'products': 'නිෂ්පාදන',
      'stocks': 'තොග',
      'categories': 'ප්‍රවර්ග',
      'brands': 'වෙළඳ නාම',
      'units': 'ඒකක',
      'suppliers': 'සැපයුම්කරුවන්',
      'product_suppliers': 'නිෂ්පාදන සැපයුම්කරුවන්',
      'stock_movements': 'තොග චලනයන්',
      'batches': 'කාණ්ඩ',
      'images': 'රූප',
      'taxes': 'බදු',
      'discounts': 'වට්ටම්',
      'variants': 'ප්‍රභේද',
      'customers': 'ගනුදෙනුකරුවන්',
      'credit_ledger': 'ණය ලෙජරය',
      'branches': 'ශාඛා',
      'roles': 'භූමිකාවන්',
      'users': 'පරිශීලකයන්',
      'pos_sales': 'POS අලෙවිය',
      'pos_management': 'POS කළමනාකරණය',
      'management_subtitle': 'වාර්තා, තොග, අයකැමි සහ ණය',
      'live_api': 'සජීවී API',
      'dashboard': 'පුවරුව',
      'logout': 'ඉවත් වන්න',
    },
  };

  void load() {
    _localizedStrings = _translations[locale.languageCode] ?? _translations['en']!;
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'si'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension TranslateExtension on BuildContext {
  String tr(String key) {
    return AppLocalizations.of(this)?.translate(key) ?? key;
  }
}
