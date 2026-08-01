import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';

/// صفحه‌ی «اعلام بار جدید» توسط باربری/صاحب بار.
/// منطق فیلدها مطابق فرم اعلام بار پنل ادمین است.
class CreateLoadScreen extends StatefulWidget {
  /// اگر داخل تب نمایش داده شود AppBar مخصوص خودش را دارد؛
  /// اگر به‌صورت صفحه‌ی مستقل باز شود (مثلاً از داشبورد) هم درست کار می‌کند.
  final bool embedded;
  final VoidCallback? onSubmitted;

  const CreateLoadScreen({super.key, this.embedded = false, this.onSubmitted});

  @override
  State<CreateLoadScreen> createState() => _CreateLoadScreenState();
}

class _CreateLoadScreenState extends State<CreateLoadScreen> {
  final _formKey = GlobalKey<FormState>();

  int _loadType = 1; // 1 دربستی / 2 روباری
  int _priceType = 1; // 1 سرویسی / 2 تنی
  bool _isTonnageFree = false;
  bool _hasInsurance = false;

  // انتخاب‌ها
  int? _originCityId;
  String? _originCityText;
  int? _destCityId;
  String? _destCityText;
  int? _cargoTypeId;
  String? _cargoText;
  int? _vehicleTypeId;

  List<Map<String, dynamic>> _vehicleTypes = [];
  bool _loadingVehicles = true;

  final _weightCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _insuranceValueCtrl = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadVehicleTypes();
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _priceCtrl.dispose();
    _phoneCtrl.dispose();
    _descCtrl.dispose();
    _insuranceValueCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadVehicleTypes() async {
    try {
      final res = await ApiClient.getJson(AppConstants.vehicleTypesEndpoint);
      if (res['ok'] == true && res['items'] is List) {
        // فقط انواعی که عنوان دارند
        _vehicleTypes = (res['items'] as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingVehicles = false);
    }
  }

  String _digitsOnly(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_originCityId == null) return _toast('شهر مبدا را انتخاب کنید', Colors.red);
    if (_destCityId == null) return _toast('شهر مقصد را انتخاب کنید', Colors.red);
    if (_cargoTypeId == null) return _toast('نوع کالا را انتخاب کنید', Colors.red);
    if (_vehicleTypeId == null) {
      return _toast('نوع بارگیر را انتخاب کنید', Colors.red);
    }
    if (!_isTonnageFree && _weightCtrl.text.trim().isEmpty) {
      return _toast('وزن بار را وارد کنید یا تناژ آزاد را بزنید', Colors.red);
    }

    setState(() => _saving = true);
    try {
      final body = <String, dynamic>{
        'load_type': _loadType,
        'price_type': _priceType,
        'origin_city_id': _originCityId,
        'dest_city_id': _destCityId,
        'cargo_type_id': _cargoTypeId,
        'primary_vehicle_type_id': _vehicleTypeId,
        'is_tonnage_free': _isTonnageFree ? '1' : '0',
        'weight': _isTonnageFree ? null : _weightCtrl.text.trim(),
        'proposed_price': _digitsOnly(_priceCtrl.text),
        'phone_coordination': _phoneCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'has_insurance': _hasInsurance ? '1' : '0',
        'insurance_value': _hasInsurance
            ? _digitsOnly(_insuranceValueCtrl.text)
            : null,
      };

      final res = await ApiClient.postJson(
        AppConstants.companyLoadsEndpoint,
        body,
      );

      if (res['ok'] == true) {
        if (!mounted) return;
        _toast('بار با موفقیت اعلام شد ✅', Colors.green);
        _resetForm();
        widget.onSubmitted?.call();
      } else {
        throw Exception(res['message'] ?? 'خطا در ثبت بار');
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e is ApiException ? e.message : 'خطا در ثبت بار';
      _toast(msg, Colors.red);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _resetForm() {
    setState(() {
      _originCityId = null;
      _originCityText = null;
      _destCityId = null;
      _destCityText = null;
      _cargoTypeId = null;
      _cargoText = null;
      _vehicleTypeId = null;
      _isTonnageFree = false;
      _hasInsurance = false;
      _weightCtrl.clear();
      _priceCtrl.clear();
      _descCtrl.clear();
      _insuranceValueCtrl.clear();
    });
  }

  void _toast(String m, Color c) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(m), backgroundColor: c));
  }

  Future<void> _openCitySearch(bool isOrigin) async {
    final picked = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _SearchSheet(
        title: 'جستجوی شهر مبدا/مقصد',
        endpoint: AppConstants.citiesSearchEndpoint,
        hint: 'نام شهر یا استان (مثلا: مشهد)',
      ),
    );
    if (picked != null) {
      setState(() {
        if (isOrigin) {
          _originCityId = picked['id'] as int;
          _originCityText = picked['text'] as String;
        } else {
          _destCityId = picked['id'] as int;
          _destCityText = picked['text'] as String;
        }
      });
    }
  }

  Future<void> _openCargoSearch() async {
    final picked = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _SearchSheet(
        title: 'جستجوی نوع کالا',
        endpoint: AppConstants.cargosSearchEndpoint,
        hint: 'نام کالا (مثلا: سیمان)',
      ),
    );
    if (picked != null) {
      setState(() {
        _cargoTypeId = picked['id'] as int;
        _cargoText = picked['text'] as String;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // نوع بار
            _SectionTitle('نوع بار'),
            Row(
              children: [
                Expanded(
                  child: _ToggleChip(
                    label: 'دربستی',
                    selected: _loadType == 1,
                    onTap: () => setState(() => _loadType = 1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ToggleChip(
                    label: 'روباری',
                    selected: _loadType == 2,
                    onTap: () => setState(() => _loadType = 2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // مبدا و مقصد
            _SectionTitle('مسیر حمل'),
            _PickerField(
              label: 'شهر مبدا',
              value: _originCityText,
              icon: Icons.my_location_rounded,
              onTap: () => _openCitySearch(true),
            ),
            const SizedBox(height: 12),
            _PickerField(
              label: 'شهر مقصد',
              value: _destCityText,
              icon: Icons.location_on_rounded,
              onTap: () => _openCitySearch(false),
            ),
            const SizedBox(height: 20),

            // کالا و بارگیر
            _SectionTitle('مشخصات بار'),
            _PickerField(
              label: 'نوع کالا',
              value: _cargoText,
              icon: Icons.inventory_2_outlined,
              onTap: _openCargoSearch,
            ),
            const SizedBox(height: 12),
            const Text(
              'نوع بارگیر مورد نیاز',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _loadingVehicles
                ? const LinearProgressIndicator()
                : DropdownButtonFormField<int>(
                    value: _vehicleTypeId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.local_shipping_outlined),
                    ),
                    hint: const Text('انتخاب بارگیر'),
                    items: _vehicleTypes
                        .map(
                          (v) => DropdownMenuItem<int>(
                            value: v['id'] as int,
                            child: Text(v['title'].toString()),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _vehicleTypeId = val),
                  ),
            const SizedBox(height: 16),

            // وزن
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _weightCtrl,
                    enabled: !_isTonnageFree,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: InputDecoration(
                      labelText: _loadType == 1
                          ? 'وزن بار (تن)'
                          : 'وزن بار (کیلوگرم)',
                      prefixIcon: const Icon(Icons.scale_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    Checkbox(
                      value: _isTonnageFree,
                      onChanged: (v) =>
                          setState(() => _isTonnageFree = v ?? false),
                    ),
                    const Text('تناژ آزاد', style: TextStyle(fontSize: 11)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // قیمت
            _SectionTitle('کرایه'),
            Row(
              children: [
                Expanded(
                  child: _ToggleChip(
                    label: 'صافی سرویسی',
                    selected: _priceType == 1,
                    onTap: () => setState(() => _priceType = 1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ToggleChip(
                    label: 'صافی تنی',
                    selected: _priceType == 2,
                    onTap: () => setState(() => _priceType = 2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _ThousandsFormatter(),
              ],
              decoration: const InputDecoration(
                labelText: 'کرایه پیشنهادی (تومان)',
                hintText: 'مثال: 5,000,000',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),
            const SizedBox(height: 20),

            // تماس و توضیحات
            _SectionTitle('اطلاعات تماس'),
            Directionality(
              textDirection: TextDirection.ltr,
              child: TextFormField(
                controller: _phoneCtrl,
                textAlign: TextAlign.left,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                decoration: const InputDecoration(
                  hintText: 'شماره تماس هماهنگی (09xxxxxxxxx)',
                  hintTextDirection: TextDirection.ltr,
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'شماره تماس الزامی است';
                  if (v.length < 11 || !v.startsWith('09')) {
                    return 'شماره تماس نامعتبر است';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'توضیحات برای راننده (اختیاری)',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 12),

            // بیمه
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _hasInsurance,
              onChanged: (v) => setState(() => _hasInsurance = v),
              title: const Text(
                'نیاز به صدور بیمه‌نامه و بارنامه رسمی',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              activeColor: AppTheme.primary,
            ),
            if (_hasInsurance)
              TextFormField(
                controller: _insuranceValueCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _ThousandsFormatter(),
                ],
                decoration: const InputDecoration(
                  labelText: 'ارزش واقعی کالا (تومان)',
                  prefixIcon: Icon(Icons.verified_user_outlined),
                ),
              ),

            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _submit,
                icon: const Icon(Icons.campaign_rounded),
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
                        'ثبت نهایی و اعلام بار',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );

    if (widget.embedded) {
      return body;
    }
    return Scaffold(
      appBar: AppBar(title: const Text('اعلام بار جدید')),
      body: SafeArea(child: body),
    );
  }
}

// ---------------------------------------------------------------------------
//  ویجت‌های کمکی
// ---------------------------------------------------------------------------

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.secondary,
        ),
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withOpacity(0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.primary : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: selected ? AppTheme.primary : Colors.black54,
          ),
        ),
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  final String label;
  final String? value;
  final IconData icon;
  final VoidCallback onTap;

  const _PickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final has = value != null && value!.isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.secondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                has ? value! : label,
                style: TextStyle(
                  color: has ? Colors.black87 : Colors.grey.shade500,
                  fontWeight: has ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

/// بوتم‌شیت جستجوی زنده (برای شهرها و کالاها)
class _SearchSheet extends StatefulWidget {
  final String title;
  final String endpoint;
  final String hint;

  const _SearchSheet({
    required this.title,
    required this.endpoint,
    required this.hint,
  });

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  Timer? _debounce;
  int _requestSequence = 0;

  void _scheduleSearch(String rawQuery) {
    _debounce?.cancel();
    final query = rawQuery.trim();
    if (query.length < 2) {
      _requestSequence++;
      setState(() {
        _results = [];
        _loading = false;
      });
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _search(query),
    );
  }

  Future<void> _search(String query) async {
    final requestId = ++_requestSequence;
    setState(() => _loading = true);
    try {
      final res = await ApiClient.getJson(
        '${widget.endpoint}?q=${Uri.encodeComponent(query)}',
      );
      if (requestId == _requestSequence &&
          res['ok'] == true &&
          res['items'] is List) {
        _results = (res['items'] as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (_) {
    } finally {
      if (mounted && requestId == _requestSequence) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              autofocus: true,
              onChanged: _scheduleSearch,
              decoration: InputDecoration(
                hintText: widget.hint,
                prefixIcon: const Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 12),
            if (_loading) const LinearProgressIndicator(),
            Expanded(
              child: _results.isEmpty
                  ? Center(
                      child: Text(
                        _ctrl.text.length < 2
                            ? 'حداقل ۲ حرف وارد کنید'
                            : 'موردی یافت نشد',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final r = _results[i];
                        return ListTile(
                          title: Text(r['text'].toString()),
                          onTap: () => Navigator.pop(context, r),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// جداکننده‌ی هزارگان برای فیلد قیمت
class _ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
      buf.write(digits[i]);
    }
    final formatted = buf.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
