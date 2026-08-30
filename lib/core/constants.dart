class AppConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://amutapp.com/amutadmin',
  );

  // عمومی / متا
  static const String appInfoEndpoint =
      '/api/v1/meta/app-config?target_app_id=2';
  static const String provincesEndpoint = '/api/v1/meta/provinces';
  static const String citiesEndpoint = '/api/v1/meta/cities';
  static const String citiesSearchEndpoint = '/api/v1/meta/cities/search';
  static const String cargosSearchEndpoint = '/api/v1/meta/cargos/search';
  static const String vehicleTypesEndpoint = '/api/v1/meta/vehicle-types';

  // احراز هویت
  static const String sendOtpEndpoint = '/api/v1/auth/request-otp';
  static const String verifyOtpEndpoint = '/api/v1/auth/verify-otp';
  static const String refreshTokenEndpoint = '/api/v1/auth/refresh';
  static const String logoutEndpoint = '/api/v1/auth/logout';
  static const String meEndpoint = '/api/v1/me';

  // مخصوص باربری / اعلام بار
  static const String companyVerifyIdentityEndpoint =
      '/api/v1/company/verify-identity';
  static const String companyProfileEndpoint = '/api/v1/company/profile';
  static const String companyMeEndpoint = '/api/v1/company/me';
  static const String companyDocsEndpoint = '/api/v1/company/docs';
  static const String companyLoadsEndpoint = '/api/v1/company/loads';
  // بستن بار: '$companyLoadsEndpoint/{id}/close'

  // سایر
  static const String bannersEndpoint = '/api/v1/banners';
  static const String faqsEndpoint = '/api/v1/faqs?target_app_id=2';
  static const String ticketsEndpoint = '/api/v1/support/tickets';
  static const String unreadNotifsCountEndpoint =
      '/api/v1/me/notifications/unread-count';
  static const String notificationsEndpoint = '/api/v1/me/notifications';

  // نقش این اپلیکیشن: 2 = باربری / صاحب بار
  static const int userType = 2;

  // شناسه‌ی اپ برای بنرها (در پنل می‌توانید بنر مخصوص اعلام بار با این شناسه بسازید)
  static const int targetAppId = 2;

  static String fixUrl(String? url) {
    final raw = url?.trim() ?? '';
    if (raw.isEmpty) return '';
    for (final localBase in const [
      'http://amutbar-admin.test',
      'https://amutbar-admin.test',
      'http://10.0.2.2/amutbar-admin',
      'https://10.0.2.2/amutbar-admin',
    ]) {
      if (raw.startsWith(localBase)) {
        return '$baseUrl${raw.substring(localBase.length)}';
      }
    }
    final uri = Uri.tryParse(raw);
    if (uri != null && uri.hasScheme && uri.host.isNotEmpty) return raw;
    if (raw.startsWith('//')) return 'https:$raw';
    return '$baseUrl/${raw.replaceFirst(RegExp(r'^/+'), '')}';
  }
}
