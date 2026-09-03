class ApiResponse<T> {
  final int statusCode;
  final bool success;
  final T? data;
  final dynamic message;
  final String timestamp;

  ApiResponse({
    required this.statusCode,
    required this.success,
    this.data,
    this.message,
    required this.timestamp,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromJsonT,
  ) {
    return ApiResponse<T>(
      statusCode: json['statusCode'] ?? 200,
      success: json['success'] ?? false,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      message: json['message'],
      timestamp: json['timestamp'] ?? DateTime.now().toIso8601String(),
    );
  }

  String get errorMessage {
    if (message is List) {
      return (message as List).join('\n');
    }
    return message?.toString() ?? 'Đã xảy ra lỗi, vui lòng thử lại';
  }
}
