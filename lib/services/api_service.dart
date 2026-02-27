import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl =
      "https://superbett-api-production.up.railway.app/api";

  static Future<Map<String, dynamic>> request(
      String path, String method,
      {Map<String, dynamic>? body}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final response = await http.Request(method, Uri.parse("$baseUrl$path"))
      ..headers.addAll({
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token"
      })
      ..body = body != null ? jsonEncode(body) : "";

    final streamed = await response.send();
    final res = await http.Response.fromStream(streamed);

    final data = jsonDecode(res.body);

    if (res.statusCode >= 400) {
      throw Exception(data["error"] ?? "Error servidor");
    }

    return data;
  }
}