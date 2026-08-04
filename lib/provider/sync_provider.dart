import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mpos/database/database_helper.dart';
import 'package:mpos/dio_client/dio_client.dart';
import 'package:mpos/resources/api_routes.dart';

class SyncProvider extends ChangeNotifier {
  final _db = DatabaseHelper();
  final _dio = DioClient().dio;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  int _pendingCount = 0;
  int get pendingCount => _pendingCount;

  SyncProvider() {
    _updatePendingCount();
  }

  Future<void> _updatePendingCount() async {
    final queue = await _db.getQueue();
    _pendingCount = queue.length;
    notifyListeners();
  }

  // --- Catalog Sync ---

  Future<Map<String, dynamic>> loadCatalogData(bool isOnline) async {
    if (isOnline) {
      try {
        final responses = await Future.wait([
          _dio.get(ApiRoutes.products),
          _dio.get(ApiRoutes.categories),
          _dio.get(ApiRoutes.posSettings),
          _dio.get(ApiRoutes.storeProfile),
        ]);

        // Save to local DB for next offline use
        final products = _extractRows(responses[0].data);
        final categories = _extractRows(responses[1].data)
            .map((e) => e['name']?.toString() ?? '')
            .where((name) => name.isNotEmpty)
            .toList();
        
        await _db.saveProducts(products.map(_formatProductForDb).toList());
        await _db.saveCategories(categories);
        
        final settings = _asMap(responses[2].data);
        final storeProfile = _asMap(responses[3].data);
        
        // Extract nested profile if present
        final profileData = _extractStoreProfile(storeProfile);
        await _db.saveStoreProfile(profileData); 

        return {
          'products': products,
          'categories': categories,
          'settings': settings,
          'storeProfile': profileData,
          'source': 'online'
        };
      } catch (e) {
        debugPrint('Sync failed, falling back to local: $e');
      }
    }

    // Offline or Online failed
    final localProducts = await _db.getProducts();
    final localCategories = await _db.getCategories();
    final localSettings = await _db.getStoreProfile();

    return {
      'products': localProducts,
      'categories': localCategories,
      'settings': localSettings,
      'storeProfile': localSettings,
      'source': 'local'
    };
  }

  Map<String, dynamic> _extractStoreProfile(Map<String, dynamic> payload) {
    for (final key in ['store_profile', 'storeProfile', 'profile', 'data']) {
      final value = _asMap(payload[key]);
      if (value.isNotEmpty) return value;
    }
    if (payload.containsKey('store_name') ||
        payload.containsKey('legal_name')) {
      return payload;
    }
    return {};
  }

  // --- Sale Submission ---

  Future<void> processSale(Map<String, dynamic> payload, bool isOnline) async {
    if (isOnline) {
      try {
        await _dio.post(ApiRoutes.posSales, data: payload);
        return;
      } catch (e) {
        debugPrint('Online sale POST failed, queueing: $e');
      }
    }

    // Offline or Online failed -> Add to Queue
    await _db.addToQueue(ApiRoutes.posSales, payload);
    await _updatePendingCount();
  }

  // --- Background Sync Task ---

  Future<void> syncQueue() async {
    if (_isSyncing) return;
    
    final queue = await _db.getQueue();
    if (queue.isEmpty) return;

    _isSyncing = true;
    notifyListeners();

    for (var item in queue) {
      try {
        final id = item['id'];
        final endpoint = item['endpoint'];
        final payload = item['payload'];

        final response = await _dio.post(endpoint, data: payload);
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          await _db.removeFromQueue(id);
        }
      } catch (e) {
        debugPrint('Failed to sync item ${item['id']}: $e');
        await _db.incrementRetryCount(item['id']);
      }
    }

    await _updatePendingCount();
    _isSyncing = false;
    notifyListeners();
  }

  // --- Helpers ---

  Map<String, dynamic> _formatProductForDb(Map<String, dynamic> item) {
    final category = item['category'];
    final unit = item['unit'];
    return {
      'id': item['id'],
      'name': item['name']?.toString() ?? 'Unnamed',
      'sku': (item['product_code'] ?? item['sku'] ?? item['barcode'] ?? item['id']).toString(),
      'barcode': item['barcode']?.toString(),
      'product_code': item['product_code']?.toString(),
      'price': _toDouble(item['selling_price'] ?? item['price']),
      'stock': _toDouble(item['stock_quantity'] ?? item['stock']),
      'category': category is Map ? category['name']?.toString() : item['category_name']?.toString(),
      'unit_name': unit is Map ? unit['short_name'] : item['unit_short_name'],
      'is_weighted': (item['is_weighted'] == true || item['is_weighted'] == 1) ? 1 : 0,
      'tax_rate': _toDouble(item['tax_rate']),
      'discount_rate': _toDouble(item['discount_rate']),
    };
  }

  List<Map<String, dynamic>> _extractRows(dynamic payload) {
    if (payload is List) return payload.map((e) => _asMap(e)).toList();
    if (payload is Map) {
      for (final key in ['products', 'categories', 'data', 'rows', 'items']) {
        if (payload[key] is List) return (payload[key] as List).map((e) => _asMap(e)).toList();
      }
    }
    return [];
  }

  Map<String, dynamic> _asMap(dynamic payload) {
    if (payload is Map<String, dynamic>) return payload;
    if (payload is Map) return Map<String, dynamic>.from(payload);
    return {};
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
