import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

import 'core/theme.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/auth_screen.dart';
import 'features/auth/otp_screen.dart';
import 'features/auth/identity_screen.dart';
import 'features/onboarding/company_profile_screen.dart';
import 'features/dashboard/main_screen.dart';
import 'features/loads/create_load_screen.dart';
import 'features/profile/support_screen.dart';
import 'features/profile/ticket_chat_screen.dart';
import 'features/profile/identity_info_screen.dart';

class AmutBarCargoApp extends StatelessWidget {
  const AmutBarCargoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
        GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),
        GoRoute(
          path: '/otp',
          builder: (_, state) {
            final phone = (state.extra is String) ? state.extra as String : '';
            return OtpScreen(phone: phone);
          },
        ),
        // احراز هویت صاحب بار (شاهکار - مثل رانندگان)
        GoRoute(path: '/identity', builder: (_, __) => const IdentityScreen()),
        // تکمیل پروفایل باربری/صاحب بار (جایگزین مرحله‌ی اطلاعات خودرو در اپ راننده)
        GoRoute(
          path: '/company-profile',
          builder: (_, __) => const CompanyProfileScreen(),
        ),
        GoRoute(path: '/dashboard', builder: (_, __) => const MainScreen()),
        GoRoute(
          path: '/create-load',
          builder: (_, __) => const CreateLoadScreen(),
        ),
        GoRoute(path: '/support', builder: (_, __) => const SupportScreen()),
        GoRoute(
          path: '/ticket-chat',
          builder: (_, state) {
            final id = int.tryParse((state.extra ?? '').toString()) ?? 0;
            return TicketChatScreen(ticketId: id);
          },
        ),
        GoRoute(
          path: '/identity-info',
          builder: (_, __) => const IdentityInfoScreen(),
        ),
      ],
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'AmutBar Cargo',
      theme: AppTheme.light(),
      locale: const Locale("fa", "IR"),
      supportedLocales: const [Locale("fa", "IR"), Locale("en", "US")],
      localizationsDelegates: const [
        PersianMaterialLocalizations.delegate,
        PersianCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
    );
  }
}
