import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SearchMethod {
  // Function to save the search log along with the place ID
  static Future<void> save_search_log(String log, String placeId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Retrieve existing search logs
    Map<String, String>? searchLogs = prefs.getString('search_logs') != null
        ? Map<String, String>.from(json.decode(prefs.getString('search_logs')!))
        : {};

    // Add the new log with place ID
    searchLogs[log] = placeId;
    print("search log $searchLogs");

    // Save the updated search logs back to SharedPreferences
    await prefs.setString('search_logs', json.encode(searchLogs));
  }

  // Function to retrieve the saved search logs
  static Future<Map<String, String>> getSearchLogs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Retrieve existing search logs
    Map<String, dynamic>? searchLogsJson =
        prefs.getString('search_logs') != null
            ? json.decode(prefs.getString('search_logs')!)
            : null;

    // Convert the dynamic map to a map of strings
    Map<String, String> searchLogs = {};
    if (searchLogsJson != null) {
      searchLogsJson.forEach((key, value) {
        searchLogs[key] = value.toString();
      });
    }

    // Reverse the order of the map entries
    Map<String, String> reversedSearchLogs =
        Map.fromEntries(searchLogs.entries.toList().reversed);

    return reversedSearchLogs;
  }
}
