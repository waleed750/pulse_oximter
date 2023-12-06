import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';



import '../errors/exceptions.dart';
import 'api_consumer.dart';
import 'end_points.dart';
import 'status_code.dart';

class DioConsumer implements ApiConsumer {
  final Dio client;

  DioConsumer({required this.client}) {
    (client.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
        (HttpClient client) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };

    client.options
      ..baseUrl = EndPoints.baseUrl
      ..responseType = ResponseType.plain
      ..followRedirects = false
      ..receiveDataWhenStatusError = true
      ..connectTimeout = const Duration(seconds: 5)
      // ..receiveTimeout = const Duration(seconds: 5)
      ..validateStatus = (status) {
        return status! < StatusCode.internalServerError;
      };
    // client.interceptors.add(di.sl<AppIntercepters>());
    if (kDebugMode) {
      // client.interceptors.add(di.sl<LogInterceptor>());
    }
  }

  @override
  Future get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      
      final response = await client.get(path, queryParameters: queryParameters);
      return _handleResponseAsJson(response);

    } on DioException catch (error) {
      _handleDioError(error);
    }
  }

  @override
  Future post(String path,
      {String? body,
      bool formDataIsEnabled = false,
      Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await (client.post(path,
          queryParameters: queryParameters,
          data: body , 
          ));
        //  if(response.data == null){
        //   throw DioException.connectionTimeout(timeout: Duration.zero,
        //    requestOptions: RequestOptions());
        //  }
          // data: formDataIsEnabled ? FormData.fromMap(body!) : body);
      return _handleResponseAsJson(response);
    } on DioException catch (error) {
      debugPrint("DioException : ${error.message}");
      _handleDioError(error);
    } on Exception  catch(e){
        debugPrint("Exception : ${e.toString()} on Endpoint : ${path}");
    }
  }

  @override
  Future put(String path,
      {Map<String, dynamic>? body,
      Map<String, dynamic>? queryParameters}) async {
    try {
      
      final response =
          await client.put(path, queryParameters: queryParameters, data: body);
      return _handleResponseAsJson(response);
    } on DioException catch (error) {
      _handleDioError(error);
    }
  }

  dynamic _handleResponseAsJson(Response<dynamic> response) {
    final responseJson = jsonDecode(response.data.toString());
    return responseJson;
  }
  Future<bool> _isServerDown(String serverUrl) async {
  try {
    final response = await get(serverUrl).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      return false; // Server is responsive
    }
  } catch (e) {
    // Handle network-related exceptions here
    print("Exception: $e");
  }

  return true; // Server may be down or unresponsive
}

  dynamic _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        throw const FetchDataException();
      case DioExceptionType.badResponse:
        switch (error.response?.statusCode) {
          case StatusCode.badRequest:
            throw const BadRequestException();
          case StatusCode.unauthorized:
          case StatusCode.forbidden:
            throw const UnauthorizedException();
          case StatusCode.notFound:
            throw const NotFoundException();
          case StatusCode.confilct:
            throw const ConflictException();

          case StatusCode.internalServerError:
            throw const InternalServerErrorException();
        }
        break;
      case DioExceptionType.cancel:
        break;
      case DioExceptionType.unknown:
        throw const NoInternetConnectionException();
      default:
        throw const NoInternetConnectionException();

    }
  }
}
