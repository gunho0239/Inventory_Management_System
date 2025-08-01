import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String baseUrl = "http://localhost:8080/";

  
  static Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      Uri.parse(baseUrl + endpoint),
      headers: {
        'Content-Type': 'application/json',
        // 필요시 인증 헤더 등 추가
      },
    );
    return _processResponse(response);
  }

  /// 응답 처리 공통 함수
  static dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      throw Exception('API Error: ${response.statusCode}, ${response.body}');
    }
  }


  static Future<dynamic> post(String endpoint, dynamic body) async {
    final response = await http.post(
      Uri.parse(baseUrl + endpoint),
      headers: {
        'Content-Type': 'application/json',
        // 필요시 인증 헤더 등 추가
      },
      body: jsonEncode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } 
    else {
      throw Exception('Failed to post data');
    }
  }


  static Future<DeleteResult> delete(String endpoint, dynamic body) async {
    final response = await http.delete(
      Uri.parse(baseUrl + endpoint),
      headers: {
        'Content-Type': 'application/json',
        // 필요시 인증 헤더 등 추가
      },
      body: body != null ? jsonEncode(body) : null,
    );
    Map<String, dynamic> responseBody = jsonDecode(response.body);

    return DeleteResult(successCount: responseBody["successCount"], failedCount: responseBody["failedCount"]);
  }

}

enum ResponseStatus {
  success,
  failure,
}

class DeleteResult {
  int successCount;
  int failedCount;

  DeleteResult({required this.successCount, required this.failedCount});
}