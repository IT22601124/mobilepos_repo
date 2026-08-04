import 'package:mpos/utils/app_localizations.dart';
import 'package:mpos/utils/custom_snackbar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mpos/dio_client/dio_client.dart';
import 'package:mpos/resources/api_routes.dart';
import 'package:mpos/utils/app_back_scope.dart';

class StoreManagementScreen extends StatefulWidget {
  const StoreManagementScreen({super.key});

  @override
  State<StoreManagementScreen> createState() => _StoreManagementScreenState();
}

class _StoreManagementScreenState extends State<StoreManagementScreen> {
  final Dio _dio = DioClient().dio;
  final ImagePicker _imagePicker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  final _storeNameController = TextEditingController();
  final _legalNameController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _taxNumberController = TextEditingController();
  final _currencyCodeController = TextEditingController(text: 'LKR');
  final _receiptFooterController = TextEditingController();

  bool _status = true;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingLogo = false;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _legalNameController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _taxNumberController.dispose();
    _currencyCodeController.dispose();
    _receiptFooterController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final response = await _dio.get(ApiRoutes.storeProfile);
      final data = _asMap(response.data);
      final profile = _extractStoreProfile(data);

      setState(() => _profile = profile.isEmpty ? null : profile);
      _fillForm(_profile);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        setState(() => _profile = null);
        _fillForm(null);
      } else {
        _showSnack(_messageFor(error), isError: true);
      }
    } catch (error) {
      _showSnack(error.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _fillForm(Map<String, dynamic>? profile) {
    _storeNameController.text = profile?['store_name']?.toString() ?? '';
    _legalNameController.text = profile?['legal_name']?.toString() ?? '';
    _addressLine1Controller.text = profile?['address_line1']?.toString() ?? '';
    _addressLine2Controller.text = profile?['address_line2']?.toString() ?? '';
    _cityController.text = profile?['city']?.toString() ?? '';
    _phoneController.text = profile?['phone']?.toString() ?? '';
    _emailController.text = profile?['email']?.toString() ?? '';
    _taxNumberController.text = profile?['tax_number']?.toString() ?? '';
    _currencyCodeController.text =
        profile?['currency_code']?.toString() ?? 'LKR';
    _receiptFooterController.text =
        profile?['receipt_footer']?.toString() ?? '';
    _status = _asBool(profile?['status'], fallback: true);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final payload = {
      'store_name': _storeNameController.text.trim(),
      'legal_name': _legalNameController.text.trim(),
      'address_line1': _addressLine1Controller.text.trim(),
      'address_line2': _addressLine2Controller.text.trim(),
      'city': _cityController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'tax_number': _taxNumberController.text.trim(),
      'currency_code': _currencyCodeController.text.trim(),
      'receipt_footer': _receiptFooterController.text.trim(),
      'status': _status,
    };

    try {
      setState(() => _isSaving = true);
      final response = _profile == null
          ? await _dio.post(ApiRoutes.storeProfile, data: payload)
          : await _dio.put(ApiRoutes.storeProfile, data: payload);
      final data = _asMap(response.data);
      final profile = _extractStoreProfile(data);
      if (profile.isNotEmpty) {
        setState(() => _profile = profile);
        _fillForm(profile);
      }
      _showSnack(context.tr('store_profile_saved'));
    } catch (error) {
      _showSnack(_messageFor(error), isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _uploadLogo() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    try {
      setState(() => _isUploadingLogo = true);
      final formData = FormData.fromMap({
        'logo': await MultipartFile.fromFile(
          picked.path,
          filename: picked.name,
        ),
      });
      final response = await _dio.post(
        ApiRoutes.storeProfileLogo,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      final data = _asMap(response.data);
      final profile = _extractStoreProfile(data);
      if (profile.isNotEmpty) {
        setState(() => _profile = profile);
      } else {
        await _loadProfile();
      }
      _showSnack(context.tr('store_logo_uploaded'));
    } catch (error) {
      _showSnack(_messageFor(error), isError: true);
    } finally {
      if (mounted) setState(() => _isUploadingLogo = false);
    }
  }

  String _logoUrl(Map<String, dynamic>? profile) {
    if (profile == null) return '';

    final logoUrl = profile['logo_url']?.toString() ?? '';
    final logo = profile['logo']?.toString() ?? '';

    if (logoUrl.isNotEmpty) {
      return logoUrl.replaceFirst('http://localhost:5000', ApiRoutes.serverUrl);
    }
    if (logo.startsWith('http')) {
      return logo.replaceFirst('http://localhost:5000', ApiRoutes.serverUrl);
    }
    if (logo.startsWith('/uploads')) return '${ApiRoutes.serverUrl}$logo';

    return '';
  }

  Map<String, dynamic> _asMap(dynamic payload) {
    if (payload is Map<String, dynamic>) return payload;
    if (payload is Map) return Map<String, dynamic>.from(payload);
    return {};
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

  bool _asBool(dynamic value, {required bool fallback}) {
    if (value is bool) return value;
    if (value == null) return fallback;
    final text = value.toString().toLowerCase();
    if (['true', '1', 'active', 'yes'].contains(text)) return true;
    if (['false', '0', 'inactive', 'no'].contains(text)) return false;
    return fallback;
  }

  String _messageFor(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      final data = error.response?.data;
      if (status != null) return 'API $status: ${data ?? error.message}';
      return error.message ?? 'Network request failed';
    }
    return error.toString();
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    if (isError) {
      CustomSnackBar.error(context, message);
    } else {
      CustomSnackBar.success(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final logoUrl = _logoUrl(_profile);

    return AppBackScope(
      fallbackRoute: '/mainNavigation',
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            context.tr('store_management'),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _LogoCard(
                        logoUrl: logoUrl,
                        isUploading: _isUploadingLogo,
                        onUpload: _uploadLogo,
                      ),
                      const SizedBox(height: 12),
                      _SectionCard(
                        title: context.tr('store_details'),
                        children: [
                          _StoreField(
                            label: context.tr('store_name'),
                            controller: _storeNameController,
                            required: true,
                          ),
                          _StoreField(
                            label: context.tr('legal_name'),
                            controller: _legalNameController,
                          ),
                          _StoreField(
                            label: context.tr('address'),
                            controller: _addressLine1Controller,
                            required: true,
                          ),
                          _StoreField(
                            label: '',
                            controller: _addressLine2Controller,
                          ),
                          _StoreField(
                            label: context.tr('city'),
                            controller: _cityController,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _SectionCard(
                        title: context.tr('contact_receipt'),
                        children: [
                          _StoreField(
                            label: context.tr('phone'),
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                          ),
                          _StoreField(
                            label: context.tr('email'),
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          _StoreField(
                            label: context.tr('tax_number'),
                            controller: _taxNumberController,
                          ),
                          _StoreField(
                            label: context.tr('currency'),
                            controller: _currencyCodeController,
                            required: true,
                          ),
                          _StoreField(
                            label: context.tr('receipt_footer'),
                            controller: _receiptFooterController,
                            maxLines: 3,
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              context.tr('active'),
                              style: const TextStyle(fontWeight: FontWeight.w900),
                            ),
                            value: _status,
                            onChanged: (value) =>
                                setState(() => _status = value),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveProfile,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          _profile == null ? context.tr('create_store') : context.tr('save_store'),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _LogoCard extends StatelessWidget {
  final String logoUrl;
  final bool isUploading;
  final VoidCallback onUpload;

  const _LogoCard({
    required this.logoUrl,
    required this.isUploading,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _storeCardDecoration(context),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 72,
              height: 72,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: logoUrl.isEmpty
                  ? Icon(
                      Icons.storefront,
                      color: Theme.of(context).colorScheme.primary,
                      size: 34,
                    )
                  : Image.network(
                      logoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.broken_image_outlined,
                        color: Color(0xFF6B7280),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('store_logo'),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                OutlinedButton.icon(
                  onPressed: isUploading ? null : onUpload,
                  icon: isUploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file_outlined, size: 18),
                  label: Text(context.tr('upload')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _storeCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _StoreField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool required;
  final int maxLines;

  const _StoreField({
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.required = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return context.tr('required_field');
                }
                return null;
              }
            : null,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

BoxDecoration _storeCardDecoration(BuildContext context) {
  return BoxDecoration(
    color: Theme.of(context).cardColor,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Theme.of(context).dividerColor),
  );
}
