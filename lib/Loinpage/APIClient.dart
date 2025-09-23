import 'dart:convert';
import 'package:http/http.dart' as http;

import '../widget/Constants.dart';

class APIClient {

  static Future<Map<String, dynamic>> loginUser(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${Constanst().base_url}login'),
        body: {
          'email': email,
          'password': password,
        },
      );

      // Parse the response body regardless of status code
      final responseBody = json.decode(response.body);

      // Return the parsed response - let the calling code handle success/error
      return responseBody;

    } catch (e) {
      // Return a standardized error format
      return {
        'error': 'Network error: ${e.toString()}'
      };
    }
  }
}



/*

import 'dart:convert';
import 'package:http/http.dart' as http;

import 'Constants.dart';

class APIClient {

  static Future<Map<String, dynamic>> loginUser(String email,
      String password) async {
    final response = await http.post(
      Uri.parse('${Constanst().base_url}login'),
      body: {'email': email,
        'password': password,
      },

    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  }
}*/
