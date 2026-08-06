import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../core/storage.dart';
import '../../core/theme.dart';
import '../../core/app_logger.dart';

/// فرم اختیاری ویرایش مشخصات «صاحب بار / باربری» از بخش پروفایل.
class CompanyProfileScreen extends StatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // 1 = شخص حقیقی (صاحب بار) ، 2 = شخص حقوقی (شرکت باربری)
  int _entityType = 1;

  final _nameCtrl = TextEditingController();
  final _registrationNoCtrl = TextEditingController();
  final _economicCodeCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _postalCodeCtrl = TextEditingController();

  List<Map<String, dynamic>> _provinces = [];
  List<Map<String, dynamic>> _cities = [];
  int? _provinceId;
  int? _cityId;

  bool _loadingProvinces = true;
  bool _loadingCities = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadProvinces();
    await _prefillFromCache();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _registrationNoCtrl.dispose();
    _economicCodeCtrl.dispose();
    _addressCtrl.dispose();
    _postalCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _prefillFromCache() async {
    final userJson = await AppStorage.getUserJson();
    if (userJson == null) return;
    try {
      final data = jsonDecode(userJson);
      final company = data['company'];
      final user = data['user'];
      if (company is Map) {
        if (company['company_name'] != null) {
          _nameCtrl.text = company['company_name'].toString();
        }
        if (company['entity_type'] != null) {
          _entityType =
              int.tryParse(company['entity_type'].toString()) ?? _entityType;
        }
        _registrationNoCtrl.text = company['registration_no']?.toString() ?? '';
        _economicCodeCtrl.text = company['economic_code']?.toString() ?? '';
        _addressCtrl.text = company['address']?.toString() ?? '';
        _postalCodeCtrl.text = company['postal_code']?.toString() ?? '';

        final provinceId = int.tryParse(
          company['province_id']?.toString() ?? '',
        );
        final cityId = int.tryParse(company['city_id']?.toString() ?? '');
        if (provinceId != null &&
            provinceId > 0 &&
            _provinces.any((p) => p['id'].toString() == '$provinceId')) {
          _provinceId = provinceId;
          await _loadCities(provinceId);
          if (cityId != null &&
              cityId > 0 &&
              _cities.any((c) => c['id'].toString() == '$cityId')) {
            _cityId = cityId;
          }
        }
      } else if (user is Map && user['full_name'] != null) {
        _nameCtrl.text = user['full_name'].toString();
      }
      if (mounted) setState(() {});
    } catch (e, st) {
      AppLogger.error('Fetch support tickets', e, st);
    }
  }

  Future<void> _loadProvinces() async {
    setState(() => _loadingProvinces = true);
    try {
      final res = await ApiClient.getJson(AppConstants.provincesEndpoint);
      if (res['ok'] == true && res['items'] is List) {
        _provinces = (res['items'] as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingProvinces = false);
    }
  }

  Future<void> _loadCities(int provinceId) async {
    setState(() {
      _loadingCities = true;
      _cities = [];
      _cityId = null;
    });
    try {
      final res = await ApiClient.getJson(
        '${AppConstants.citiesEndpoint}?province_id=$provinceId',
      );
      if (res['ok'] == true && res['items'] is List) {
        _cities = (res['items'] as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (e) {
      if (mounted) {
        final msg = e is ApiException ? e.message : 'خطا در دریافت شهرها';
        _toast(msg, Colors.red);
      }
    } finally {
      if (mounted) setState(() => _loadingCities = false);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if ((_provinceId == null) != (_cityId == null)) {
      _toast('استان و شهر را با هم انتخاب کنید', Colors.red);
      return;
    }

    setState(() => _saving = true);
    try {
      final body = {
        'entity_type': _entityType,
        'company_name': _nameCtrl.text.trim(),
        'province_id': _provinceId,
        'city_id': _cityId,
        'address': _addressCtrl.text.trim(),
        'postal_code': _postalCodeCtrl.text.trim(),
      };
      if (_entityType == 2) {
        body['registration_no'] = _registrationNoCtrl.text.trim();
        body['economic_code'] = _economicCodeCtrl.text.trim();
      }

      final res = await ApiClient.postJson(
        AppConstants.companyProfileEndpoint,
        body,
      );

      if (res['company'] != null) {
        // پاسخ profile شامل یک payload تو‌در‌تو است؛ کش باید همیشه شکل
        // استاندارد {user, company, onboarding} را حفظ کند.
        final fresh = await ApiClient.getJson(AppConstants.meEndpoint);
        if (fresh['ok'] == true) {
          await AppStorage.setUserJson(jsonEncode(fresh));
        }
      }

      if (!mounted) return;
      _toast('پروفایل با موفقیت ثبت شد', Colors.green);
      if (Navigator.of(context).canPop()) {
        context.pop();
      } else {
        context.go('/dashboard');
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'خطا در ثبت اطلاعات';
      _toast(msg, Colors.red);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String m, Color c) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(m), backgroundColor: c));
  }

  @override
  Widget build(BuildContext context) {
    final isLegal = _entityType == 2;

    return Scaffold(
      appBar: AppBar(title: const Text('اطلاعات باربری')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _ProfileHeader(
                  title: 'مشخصات صاحب بار / باربری',
                  subtitle:
                      'این اطلاعات اختیاری است و هر زمان بخواهید قابل ویرایش است.',
                ),
                const SizedBox(height: 16),

                _NiceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'نوع ثبت‌نام',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _EntityChip(
                              title: 'شخص حقیقی',
                              subtitle: 'صاحب بار',
                              icon: Icons.person_rounded,
                              selected: !isLegal,
                              onTap: () => setState(() => _entityType = 1),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _EntityChip(
                              title: 'شخص حقوقی',
                              subtitle: 'شرکت باربری',
                              icon: Icons.business_rounded,
                              selected: isLegal,
                              onTap: () => setState(() => _entityType = 2),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _NiceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLegal ? 'نام شرکت باربری' : 'نام و نام خانوادگی',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                          hintText: isLegal
                              ? 'مثال: باربری آموت ترابر'
                              : 'مثال: محمد محمدی',
                          prefixIcon: Icon(
                            isLegal
                                ? Icons.business_rounded
                                : Icons.person_outline_rounded,
                          ),
                        ),
                        validator: (v) => (v?.trim().isEmpty ?? true)
                            ? 'این فیلد الزامی است'
                            : null,
                      ),

                      if (isLegal) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'شماره ثبت',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _registrationNoCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            hintText: 'شماره ثبت شرکت',
                            prefixIcon: Icon(Icons.numbers_rounded),
                          ),
                          validator: (v) => (v?.trim().isEmpty ?? true)
                              ? 'شماره ثبت الزامی است'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'کد اقتصادی (اختیاری)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _economicCodeCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            hintText: 'کد اقتصادی',
                            prefixIcon: Icon(Icons.account_balance_rounded),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _NiceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'موقعیت مکانی',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // استان
                      const Text(
                        'استان (اختیاری)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _loadingProvinces
                          ? const LinearProgressIndicator()
                          : DropdownButtonFormField<int>(
                              value: _provinceId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.map_outlined),
                              ),
                              hint: const Text('انتخاب استان'),
                              items: _provinces
                                  .map(
                                    (p) => DropdownMenuItem<int>(
                                      value: p['id'] as int,
                                      child: Text(p['name'].toString()),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                setState(() => _provinceId = val);
                                if (val != null) _loadCities(val);
                              },
                            ),
                      const SizedBox(height: 20),

                      // شهر
                      const Text(
                        'شهر (اختیاری)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _loadingCities
                          ? const LinearProgressIndicator()
                          : DropdownButtonFormField<int>(
                              value: _cityId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.location_city_rounded),
                              ),
                              hint: Text(
                                _provinceId == null
                                    ? 'ابتدا استان را انتخاب کنید'
                                    : 'انتخاب شهر',
                              ),
                              items: _cities
                                  .map(
                                    (c) => DropdownMenuItem<int>(
                                      value: c['id'] as int,
                                      child: Text(c['name'].toString()),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) => setState(() => _cityId = val),
                            ),
                      const SizedBox(height: 20),

                      const Text(
                        'آدرس (اختیاری)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _addressCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'آدرس دفتر / محل بارگیری',
                          prefixIcon: Icon(Icons.home_outlined),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'کد پستی (اختیاری)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _postalCodeCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: const InputDecoration(
                          hintText: 'کد پستی ۱۰ رقمی',
                          prefixIcon: Icon(Icons.markunread_mailbox_outlined),
                        ),
                        validator: (value) {
                          final postalCode = value?.trim() ?? '';
                          if (postalCode.isNotEmpty &&
                              postalCode.length != 10) {
                            return 'کد پستی باید ۱۰ رقم باشد';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _submit,
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'ثبت و ورود به برنامه',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EntityChip extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _EntityChip({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withOpacity(0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppTheme.primary : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? AppTheme.primary : Colors.grey.shade500,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: selected ? AppTheme.primary : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _ProfileHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppTheme.secondary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.badge_outlined, color: AppTheme.secondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NiceCard extends StatelessWidget {
  final Widget child;
  const _NiceCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }
}
