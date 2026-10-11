class ApiResponse<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  const ApiResponse._({
    this.data,
    this.error,
    required this.isSuccess,
  });

  factory ApiResponse.success(T data) =>
      ApiResponse._(data: data, isSuccess: true);

  factory ApiResponse.error(String message) =>
      ApiResponse._(error: message, isSuccess: false);
}
