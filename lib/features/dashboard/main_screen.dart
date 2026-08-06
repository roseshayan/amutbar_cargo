import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import 'dashboard_screen.dart';
import '../profile/profile_screen.dart';
import '../loads/create_load_screen.dart';
import '../loads/my_loads_screen.dart';
import '../../core/app_logger.dart';

final ValueNotifier<int> unreadNotificationsCount = ValueNotifier<int>(0);
final ValueNotifier<Map<String, dynamic>?> latestNotificationRoute =
    ValueNotifier(null);

void handleNotificationRouting(BuildContext context) {
  final notif = latestNotificationRoute.value;
  if (notif == null) return;

  final String? type = notif['type'];
  final Map<String, dynamic>? data = notif['data'];

  ApiClient.getJson(AppConstants.notificationsEndpoint).catchError((_) {});

  if (type == 'ticket_reply' && data != null && data['ticket_id'] != null) {
    final ticketId = int.tryParse(data['ticket_id'].toString());
    if (ticketId != null) {
      unreadNotificationsCount.value = 0;
      latestNotificationRoute.value = null;
      GoRouter.of(context).push('/ticket-chat', extra: ticketId);
    }
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  Timer? _notifTimer;
  int _lastNotifiedCount = 0;

  final GlobalKey<MyLoadsScreenState> _myLoadsKey =
      GlobalKey<MyLoadsScreenState>();

  @override
  void initState() {
    super.initState();
    _checkUnreadNotifs();
    _notifTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _checkUnreadNotifs(),
    );
  }

  @override
  void dispose() {
    _notifTimer?.cancel();
    super.dispose();
  }

  void _changeTab(int index) {
    setState(() => _currentIndex = index);
    if (index == 2) {
      _myLoadsKey.currentState?.fetch();
    }
  }

  Future<void> _checkUnreadNotifs() async {
    try {
      final res = await ApiClient.getJson(
        AppConstants.unreadNotifsCountEndpoint,
      );
      if (res['ok'] == true && mounted) {
        final newCount = res['unread_count'] as int;
        if (newCount > _lastNotifiedCount && newCount > 0) {
          latestNotificationRoute.value = {
            'type': res['latest_type'],
            'data': res['latest_data'],
          };
          _showInAppNotificationAlert();
          _lastNotifiedCount = newCount;
        } else if (newCount == 0) {
          _lastNotifiedCount = 0;
        }
        unreadNotificationsCount.value = newCount;
      }
    } catch (e, st) {
      AppLogger.error('Fetch support tickets', e, st);
    }
  }

  void _showInAppNotificationAlert() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.chat_bubble_rounded, color: Colors.white),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'پاسخ جدیدی از پشتیبانی دریافت شد.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Vazir',
                  fontSize: 13,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.close_rounded,
                color: Colors.white70,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () =>
                  ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            ),
          ],
        ),
        backgroundColor: AppTheme.secondary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'مشاهده',
          textColor: Colors.amber,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            handleNotificationRouting(context);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DashboardScreen(onChangeTab: _changeTab),
          // تب اعلام بار (embedded). بعد از ثبت، به تب بارهای من می‌رود.
          Scaffold(
            appBar: AppBar(title: const Text('اعلام بار جدید')),
            body: SafeArea(
              child: CreateLoadScreen(
                embedded: true,
                onSubmitted: () => _changeTab(2),
              ),
            ),
          ),
          MyLoadsScreen(key: _myLoadsKey),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _changeTab,
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.primary.withOpacity(0.15),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppTheme.primary),
            label: 'داشبورد',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_box_outlined),
            selectedIcon: Icon(Icons.add_box_rounded, color: AppTheme.primary),
            label: 'اعلام بار',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(
              Icons.local_shipping_rounded,
              color: AppTheme.primary,
            ),
            label: 'بارهای من',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: AppTheme.primary),
            label: 'پروفایل',
          ),
        ],
      ),
    );
  }
}
