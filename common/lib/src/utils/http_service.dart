import 'package:common/common.dart';
import 'package:flutter/foundation.dart';

const withTokenKey = 'withToken';

class HttpService {
  factory HttpService() {
    _instance ??= HttpService._internal();
    return _instance!;
  }

  HttpService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: dotenv.get('BASE_URL'),
        connectTimeout: Duration(
          milliseconds: int.parse(
            dotenv.get('CONNECT_TIMEOUT', fallback: '10000'),
          ),
        ),
        receiveTimeout: Duration(
          milliseconds: int.parse(
            dotenv.get('RECEIVE_TIMEOUT', fallback: '10000'),
          ),
        ),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          if (kDebugMode) {
            print(
              '👶👶👶----请求方式:${options.method} ${options.baseUrl}  ${options.path}',
            );
            print('👧👧👧请求头: ${options.headers}');
            if (options.data != null) {
              print('👩👩👩请求参数: ${options.data}');
            }
            print('👨👨👨查询参数: ${options.queryParameters}');
            print('🔥🔥🔥额外数据: ${options.extra}');
          }
          return handler.next(options);
        },

        onResponse: (Response response, ResponseInterceptorHandler handler) {
          if (kDebugMode) {
            recordResponse.saveResponse(
              requestPath: response.requestOptions.path,
              responseData: response.data,
              method: response.requestOptions.method,
              queryParams: response.requestOptions.queryParameters,
            );
          }
          return handler.next(response);
        },

        onError: (DioException error, ErrorInterceptorHandler handler) {
          return handler.next(error);
        },
      ),
    );
  }

  static HttpService? _instance;
  late Dio _dio;

  /// 全局配置：是否自动显示错误Toast提示
  bool autoShowErrorToast = true;

  // 处理错误
  void _handleError(DioException error, {bool? showErrorToast}) {
    String? errorMessage = error.response?.data?['message'];

    if (errorMessage == null) {
      switch (error.type) {
        case .connectionTimeout:
          errorMessage = '连接超时';
        case .sendTimeout:
          errorMessage = '请求超时';
        case .receiveTimeout:
          errorMessage = '响应超时';
        case .badResponse:
          // 服务器错误
          errorMessage = '服务器错误：${error.response?.statusCode}';
        case .cancel:
          errorMessage = '请求取消';
        case .unknown:
          errorMessage = '网络错误，请检查网络连接';
        default:
          errorMessage = '发生错误: ${error.message}';
      }
    }

    // 显示错误信息
    if (kDebugMode) {
      print('😩😩😩网络请求发生错误: ${error.message}');
    }

    final shouldShowToast = showErrorToast ?? autoShowErrorToast;
    if (shouldShowToast) {
      showToast(errorMessage);
    }
  }

  Future<BaseModel<T>> request<T>(
    String path, {
    dynamic data,
    Options? options,

    /// 处理后台直接返回data这种裸数据的情况
    bool isNake = false,
    bool? showErrorToast,
    String method = 'GET',
    bool withToken = true,
    CancelToken? cancelToken,
    Map<String, dynamic>? query,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    T Function(Map<String, dynamic>)? converter,
    bool useBaseUrl = true,
  }) async {
    try {
      final Options finalOptions =
          (options ?? Options(contentType: 'application/json'))
            ..method = method
            ..extra ??= {}
            ..extra?[withTokenKey] = withToken;

      Response response;

      if (useBaseUrl) {
        // 走「baseUrl + path」
        response = await _dio.request(
          path,
          data: data,
          queryParameters: query,
          options: finalOptions,
          cancelToken: cancelToken,
          onSendProgress: onSendProgress,
          onReceiveProgress: onReceiveProgress,
        );
      } else {
        // 完全使用外部传入的 URL，忽略 baseUrl
        response = await _dio.requestUri(
          Uri.parse(path),
          data: data,
          options: finalOptions,
          cancelToken: cancelToken,
          onSendProgress: onSendProgress,
          onReceiveProgress: onReceiveProgress,
        );
      }

      if (isNake) {
        return BaseModel.fromJson(
          {'code': 200, 'message': 'Success!', 'data': response.data},
          converter ?? (j) => j as T,
          showErrorToast ?? autoShowErrorToast,
        );
      }
      return BaseModel.fromJson(
        response.data,
        converter ?? (j) => j as T,
        showErrorToast ?? autoShowErrorToast,
      );
    } on DioException catch (e) {
      _handleError(e, showErrorToast: showErrorToast);
      rethrow;
    }
  }

  Future<BaseModel<T>> get<T>(
    String path, {
    Options? options,
    bool isNake = false,
    bool showErrorToast = false,
    bool withToken = true,
    CancelToken? cancelToken,
    Map<String, dynamic>? query,
    ProgressCallback? onReceiveProgress,
    T Function(Map<String, dynamic>)? converter,
  }) => request<T>(
    path,
    query: query,
    isNake: isNake,
    options: options,
    converter: converter,
    withToken: withToken,
    cancelToken: cancelToken,
    showErrorToast: showErrorToast,
    onReceiveProgress: onReceiveProgress,
  );

  Future<BaseModel<T>> post<T>(
    String path, {
    dynamic data,
    Options? options,
    bool isNake = false,
    bool showErrorToast = false,
    bool withToken = true,
    CancelToken? cancelToken,
    Map<String, dynamic>? query,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    T Function(Map<String, dynamic>)? converter,
  }) => request<T>(
    path,
    data: data,
    query: query,
    method: 'POST',
    isNake: isNake,
    options: options,
    withToken: withToken,
    converter: converter,
    cancelToken: cancelToken,
    showErrorToast: showErrorToast,
    onSendProgress: onSendProgress,
    onReceiveProgress: onReceiveProgress,
  );

  Future<BaseModel<T>> put<T>(
    String path, {
    dynamic data,
    Options? options,
    bool isNake = false,
    bool? showErrorToast,
    bool withToken = true,
    CancelToken? cancelToken,
    Map<String, dynamic>? query,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    T Function(Map<String, dynamic>)? converter,
    bool useBaseUrl = true,
  }) => request<T>(
    path,
    data: data,
    query: query,
    method: 'PUT',
    isNake: isNake,
    options: options,
    withToken: withToken,
    converter: converter,
    cancelToken: cancelToken,
    showErrorToast: showErrorToast,
    onSendProgress: onSendProgress,
    onReceiveProgress: onReceiveProgress,
  );

  Future<BaseModel<T>> delete<T>(
    String path, {
    T Function(Map<String, dynamic>)? converter,
    dynamic data,
    Options? options,
    bool isNake = false,
    bool? showErrorToast,
    bool withToken = true,
    CancelToken? cancelToken,
    Map<String, dynamic>? query,
  }) => request<T>(
    path,
    data: data,
    query: query,
    isNake: isNake,
    method: 'DELETE',
    options: options,
    withToken: withToken,
    converter: converter,
    cancelToken: cancelToken,
    showErrorToast: showErrorToast,
  );

  Future<BaseModel<T>> patch<T>(
    String path, {
    dynamic data,
    Options? options,
    bool isNake = false,
    bool? showErrorToast,
    bool withToken = true,
    CancelToken? cancelToken,
    Map<String, dynamic>? query,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    T Function(Map<String, dynamic>)? converter,
  }) => request<T>(
    path,
    data: data,
    query: query,
    isNake: isNake,
    method: 'PATCH',
    options: options,
    converter: converter,
    withToken: withToken,
    cancelToken: cancelToken,
    showErrorToast: showErrorToast,
    onSendProgress: onSendProgress,
    onReceiveProgress: onReceiveProgress,
  );

  Future<BaseModel<T>> uploadFile<T>(
    String path, {
    required FormData formData,
    T Function(Map<String, dynamic>)? converter,
    Map<String, dynamic>? query,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    bool? showErrorToast,
    bool withToken = true,
  }) => request<T>(
    path,
    converter: converter,
    method: 'POST',
    data: formData,
    query: query,
    options: options?.copyWith(contentType: 'multipart/form-data'),
    cancelToken: cancelToken,
    onSendProgress: onSendProgress,
    showErrorToast: showErrorToast,
    withToken: withToken,
  );

  Future<Response> downloadFile(
    String url, {
    required String savePath,
    Map<String, dynamic>? query,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
    bool? showErrorToast,
    bool withToken = true,
  }) async {
    try {
      return await _dio.download(
        url,
        savePath,
        queryParameters: query,
        options:
            (options?.copyWith(responseType: ResponseType.bytes) ??
                    Options(responseType: ResponseType.bytes))
                .copyWith(extra: {withTokenKey: withToken}),
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      _handleError(e, showErrorToast: showErrorToast);
      rethrow;
    }
  }

  FormData createFormData(Map<String, dynamic> data) {
    return FormData.fromMap(data);
  }

  Future<FormData> addFileToFormData(
    FormData formData, {
    required String key,
    required String filePath,
    String? fileName,
  }) async {
    final file = await MultipartFile.fromFile(filePath, filename: fileName);
    formData.files.add(MapEntry(key, file));
    return formData;
  }

  Future<FormData> addBytesToFormData(
    FormData formData, {
    required String key,
    required List<int> bytes,
    String? fileName,
  }) async {
    final file = MultipartFile.fromBytes(bytes, filename: fileName);
    formData.files.add(MapEntry(key, file));
    return formData;
  }

  void cancelRequest(CancelToken cancelToken) {
    if (!cancelToken.isCancelled) {
      cancelToken.cancel('请求已取消');
    }
  }

  void setHeaders(Map<String, dynamic> headers) {
    _dio.options.headers.addAll(headers);
  }

  void clearHeaders() {
    _dio.options.headers.clear();
  }

  void setTimeout(Duration timeout) {
    _dio.options.connectTimeout = timeout;
    _dio.options.receiveTimeout = timeout;
    _dio.options.sendTimeout = timeout;
  }

  set setBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
  }

  void addInterceptor(Interceptor interceptor) {
    _dio.interceptors.insert(0, interceptor);
  }

  void removeInterceptor(Interceptor interceptor) {
    _dio.interceptors.remove(interceptor);
  }
}

final http = HttpService();
