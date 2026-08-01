import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';

/// لیست بارهای اعلام‌شده‌ی همین باربری + امکان بستن بار
class MyLoadsScreen extends StatefulWidget {
  const MyLoadsScreen({super.key});

  @override
  State<MyLoadsScreen> createState() => MyLoadsScreenState();
}

class MyLoadsScreenState extends State<MyLoadsScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    fetch();
  }

  Future<void> fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiClient.getJson(AppConstants.companyLoadsEndpoint);
      if (res['ok'] == true && res['items'] is List) {
        _items = (res['items'] as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      } else {
        _error = res['message']?.toString() ?? 'خطا در دریافت بارها';
      }
    } catch (e) {
      _error = e is ApiException ? e.message : 'خطا در ارتباط با سرور';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _closeLoad(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('بستن بار'),
        content: const Text(
          'آیا این بار بسته شود؟ پس از بستن، دیگر به رانندگان نمایش داده نمی‌شود.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('بستن بار'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final res = await ApiClient.postJson(
        '${AppConstants.companyLoadsEndpoint}/$id/close',
        {},
      );
      if (res['ok'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('بار بسته شد'),
              backgroundColor: Colors.green,
            ),
          );
        }
        fetch();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is ApiException ? e.message : 'خطا در بستن بار',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('بارهای من'),
        actions: [
          IconButton(
            onPressed: fetch,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetch,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _Centered(
        icon: Icons.error_outline_rounded,
        text: _error!,
        action: 'تلاش مجدد',
        onAction: fetch,
      );
    }
    if (_items.isEmpty) {
      return _Centered(
        icon: Icons.inbox_outlined,
        text: 'هنوز باری اعلام نکرده‌اید.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _items.length,
      itemBuilder: (_, i) => _LoadCard(
        data: _items[i],
        onClose: () => _closeLoad(_items[i]['id'] as int),
      ),
    );
  }
}

class _LoadCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onClose;

  const _LoadCard({required this.data, required this.onClose});

  Color _statusColor(int s) {
    switch (s) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.grey;
      case 4:
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusId =
        int.tryParse(data['status_id']?.toString() ?? '0') ?? 0;
    final isActive = data['is_active'] == true;
    final color = _statusColor(statusId);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    data['status_text']?.toString() ?? '',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'کد: ${data['public_code'] ?? '-'}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.my_location_rounded,
                    size: 18, color: AppTheme.primary),
                const SizedBox(width: 6),
                Expanded(child: Text(data['origin']?.toString() ?? '')),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(right: 8, top: 2, bottom: 2),
              child: Icon(Icons.more_vert, size: 16, color: Colors.grey),
            ),
            Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    size: 18, color: Colors.orange),
                const SizedBox(width: 6),
                Expanded(child: Text(data['destination']?.toString() ?? '')),
              ],
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _info(Icons.inventory_2_outlined, data['cargo_title']),
                _info(Icons.local_shipping_outlined, data['vehicle_title']),
                _info(Icons.scale_outlined, data['weight_text']),
                if (data['price'] != null)
                  _info(Icons.payments_outlined, '${data['price']} تومان'),
              ],
            ),
            if (isActive) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onClose,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('بستن بار (تکمیل شد)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _info(IconData icon, dynamic text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          text?.toString() ?? '-',
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }
}

class _Centered extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? action;
  final VoidCallback? onAction;

  const _Centered({
    required this.icon,
    required this.text,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        Icon(icon, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Center(
          child: Text(text, style: TextStyle(color: Colors.grey.shade600)),
        ),
        if (action != null) ...[
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton(onPressed: onAction, child: Text(action!)),
          ),
        ],
      ],
    );
  }
}
