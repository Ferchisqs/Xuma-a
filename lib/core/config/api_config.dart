class ApiConfig {
  static const String baseUrl = 'https://api.xuma-a.com';
  static const String apiKey = 'xuma_a_api_key_2024'; 
  
  // Endpoints XUMA'A
  static const String ecoTipsEndpoint = '/api/eco-tips';
  static const String userStatsEndpoint = '/api/user/stats';
  static const String userActivityEndpoint = '/api/user/activity';
  static const String newsEndpoint = '/api/news';
  static const String projectsEndpoint = '/api/projects';
  static const String challengesEndpoint = '/api/challenges';
  
  // Request timeouts
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
  static const int sendTimeout = 30000;
}