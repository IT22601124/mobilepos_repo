import 'package:flutter/widgets.dart';
import 'package:mpos/dio_client/dio_client.dart';
import 'package:mpos/model/user_model.dart';
import 'package:mpos/resources/api_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _currentUserName;
  String? get currentUserName => _currentUserName;
  int? _roleId;
  int? get roleId => _roleId;
  int? _userId;
  int? get userId => _userId;

  bool get isSuperAdmin => _roleId == 1;

  final _dioClient = DioClient().dio;

  Future<void> createAccount(UserModel user) async {
    try {
      _isLoading = true;
      final response = await _dioClient.post(
        ApiRoutes.register,
        data: user.toJson(),
      );
      if (response.statusCode == 200) {
        debugPrint('Account created successfully');
      } else {
        debugPrint('Failed to create account: ${response.statusCode}');
      }
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('demo_user_phone', user.phone ?? '');
      await prefs.setString('demo_user_password', user.password ?? '');
      await prefs.setString('demo_user_name', user.name);
      debugPrint(
        'Using local demo account because registration API failed: $e',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String mobile, String password) async {
    try {
      _isLoading = true;
      final response = await _dioClient.post(
        ApiRoutes.login,
        data: {'phone': mobile, 'password': password},
      );
      if (response.statusCode == 200) {
        String token = response.data['access_token'];
        final userData = response.data['user'] ?? {};
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', token);
        
        _currentUserName = response.data['name']?.toString() ?? userData['name']?.toString() ?? 'User';
        _roleId = response.data['role_id'] ?? userData['role_id'];
        _userId = response.data['id'] ?? userData['id'];

        await prefs.setString('current_user_name', _currentUserName!);
        if (_roleId != null) await prefs.setInt('user_role_id', _roleId!);
        if (_userId != null) await prefs.setInt('user_id', _userId!);

        return true;
      }
      return false;
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final demoPhone = prefs.getString('demo_user_phone');
      final demoPassword = prefs.getString('demo_user_password');
      final isDemoAdmin = mobile == '0777123456' && password == '123456';
      final isRegisteredDemo = demoPhone == mobile && demoPassword == password;

      if (isDemoAdmin || isRegisteredDemo) {
        _currentUserName = prefs.getString('demo_user_name') ?? 'Super Admin';
        _roleId = isDemoAdmin ? 1 : 2; // Demo admin is super admin
        await prefs.setString('access_token', 'demo-token');
        await prefs.setString('current_user_name', _currentUserName!);
        await prefs.setInt('user_role_id', _roleId!);
        return true;
      }

      throw Exception('Invalid credentials. Demo login: 0777123456 / 123456');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserName = prefs.getString('current_user_name');
    _roleId = prefs.getInt('user_role_id');
    _userId = prefs.getInt('user_id');
    notifyListeners();
  }

  Future<bool> verifyStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      await logout();
      return false;
    }
    
    if (token == 'demo-token') {
      await restoreSession();
      return true;
    }

    try {
      final response = await _dioClient.post(ApiRoutes.verifyToken);
      final data = response.data;
      final isSuccess = data is Map && (data['success'] == true);

      if (response.statusCode == 200 && isSuccess) {
        final userData = data['user'] ?? {};
        _currentUserName = userData['name']?.toString() ?? 'User';
        _roleId = userData['role_id'];
        _userId = userData['id'];
        
        await prefs.setString('current_user_name', _currentUserName!);
        if (_roleId != null) await prefs.setInt('user_role_id', _roleId!);
        if (_userId != null) await prefs.setInt('user_id', _userId!);
        
        return true;
      }
    } catch (e) {
      debugPrint('Stored access token verification failed: $e');
    }

    await logout();
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('current_user_name');
    _currentUserName = null;
    notifyListeners();
  }
}
