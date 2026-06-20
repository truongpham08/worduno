class SearchUtils {
  SearchUtils._();

  static bool matches(String query, String value) {
    if (query.trim().isEmpty) {
      return true;
    }
    return value.toLowerCase().contains(query.toLowerCase());
  }
}
