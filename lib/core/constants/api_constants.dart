class ApiConstants {
  ApiConstants._();

  static const String baseUrl =
      'https://destination-vocabulary-api.onrender.com';

  static const String levelsPath = '/api';
  static String levelPath(String level) => '/api/$level';
  static String unitsPath(String level) => '/api/$level/units';
  static String termsPath(String level, String unitName) =>
      '/api/$level/units/$unitName';

  static const String coachExplainPath = '/api/coach/explain';
  static const String coachEvaluatePath = '/api/coach/evaluate';
}
