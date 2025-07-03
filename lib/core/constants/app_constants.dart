class AppConstants {
  // App Info XUMA'A
  static const String appName = 'XUMA\'A';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Protector del medio ambiente con Xico';
  
  // Cache Keys
  static const String dailyTipCacheKey = 'daily_tip_cache';
  static const String userStatsCacheKey = 'user_stats_cache';
  static const String newsCacheKey = 'news_cache';
  static const String projectsCacheKey = 'projects_cache';
  
  // Cache Duration (in hours)
  static const int defaultCacheDuration = 24;
  static const int shortCacheDuration = 1;
  static const int longCacheDuration = 168; // 1 week
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Navigation Items
  static const List<String> navigationItems = [
    'Inicio',
    'Noticias',
    'Aprendamos',
    'Proyectos',
    'Desafíos',
    'Comunidad',
    'Contacto'
  ];

  // Eco Tips Categories
  static const List<String> ecoTipCategories = [
    'energia',
    'agua',
    'reciclaje',
    'transporte',
    'alimentacion',
    'consumo',
    'biodiversidad'
  ];

  // Achievement Types
  static const Map<String, String> achievementTypes = {
    'first_week': 'Primera Semana',
    'recycler_pro': 'Reciclador Pro',
    'energy_saver': 'Ahorrador de Energía',
    'water_guardian': 'Guardián del Agua',
    'eco_warrior': 'Eco Guerrero',
    'nature_lover': 'Amante de la Naturaleza',
  };

  // User Levels
  static const List<String> userLevels = [
    'Eco Principiante',
    'Protector Verde',
    'Guardián Ambiental',
    'Eco Héroe',
    'Maestro de la Naturaleza'
  ];

  // Error Messages
  static const String networkError = 'Error de conexión. Verifica tu internet.';
  static const String serverError = 'Error del servidor. Intenta más tarde.';
  static const String cacheError = 'Error al acceder a datos guardados.';
  static const String generalError = 'Algo salió mal. Intenta nuevamente.';

  // Success Messages  
  static const String dataLoaded = 'Datos cargados exitosamente';
  static const String dataRefreshed = 'Datos actualizados';
  static const String offlineMode = 'Modo offline activado';
  static const String activityUpdated = 'Actividad registrada';
}