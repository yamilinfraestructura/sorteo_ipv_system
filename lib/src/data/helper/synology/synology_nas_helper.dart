import 'package:dio/dio.dart';
import 'dart:io';
import 'dart:convert';

class SynologyNasHelper {
  final String nasHost;
  final String user;
  final String password;

  SynologyNasHelper({
    required this.nasHost,
    required this.user,
    required this.password,
  });

  Dio get _dio => Dio();

  /// Login y devuelve el SID (Session ID) o null si falla
  Future<String?> login() async {
    try {
      final response = await _dio.get(
        '$nasHost/webapi/auth.cgi',
        queryParameters: {
          'api': 'SYNO.API.Auth',
          'version': 3,
          'method': 'login',
          'account': user,
          'passwd': password,
          'session': 'FileStation',
          'format': 'sid',
        },
      );
      print('[NAS LOGIN] Respuesta:');
      print(response.data);
      if (response.data['success'] == true) {
        return response.data['data']['sid'];
      }
      return null;
    } catch (e) {
      print('[NAS LOGIN] Error: $e');
      return null;
    }
  }

  /// Sube un archivo al NAS. Devuelve true si fue exitoso.
  Future<bool> uploadFile({
    required String sid,
    required String pathDestino,
    required File file,
    String? fileName,
  }) async {
    try {
      final uploadUrl = '$nasHost/webapi/entry.cgi';
      final formData = FormData.fromMap({
        'api': 'SYNO.FileStation.Upload',
        'version': 2,
        'method': 'upload',
        'path': pathDestino,
        'create_parents': 'true',
        'overwrite': 'true',
        '_sid': sid,
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName ?? file.uri.pathSegments.last,
        ),
      });
      print('[NAS UPLOAD] FormData:');
      print('api: SYNO.FileStation.Upload');
      print('version: 2');
      print('method: upload');
      print('path: $pathDestino');
      print('create_parents: true');
      print('overwrite: true');
      print('_sid: $sid');
      print('file: ${file.path}');
      final response = await _dio.post(uploadUrl, data: formData);
      dynamic data = response.data;
      // Forzar parseo si es String
      if (data is String) {
        try {
          data = data.isNotEmpty ? jsonDecode(data) : {};
        } catch (e) {
          print('[NAS UPLOAD] Respuesta no es JSON, contenido crudo:');
          print(data);
          return false;
        }
      }
      print('[NAS UPLOAD] Respuesta:');
      print(data);
      if (data is Map && data['success'] == true) {
        return true;
      } else {
        final error = data is Map ? data['error'] : null;
        if (error != null) {
          print('[NAS UPLOAD] Código de error: ${error['code']}');
        }
        return false;
      }
    } catch (e, stack) {
      print('[NAS UPLOAD] Error: $e');
      print(stack);
      return false;
    }
  }

  /// Logout de la sesión
  Future<void> logout(String sid) async {
    try {
      await _dio.get(
        '$nasHost/webapi/auth.cgi',
        queryParameters: {
          'api': 'SYNO.API.Auth',
          'version': 1,
          'method': 'logout',
          'session': 'FileStation',
          '_sid': sid,
        },
      );
    } catch (e) {
      // Ignorar errores de logout
    }
  }

  /// Verifica si la carpeta destino existe en el NAS
  Future<bool> existeCarpetaDestino({
    required String sid,
    required String pathDestino,
  }) async {
    try {
      final response = await _dio.get(
        '$nasHost/webapi/entry.cgi',
        queryParameters: {
          'api': 'SYNO.FileStation.List',
          'version': 2,
          'method': 'list',
          'folder_path': pathDestino,
          '_sid': sid,
        },
      );
      print('[NAS CHECK FOLDER] Respuesta:');
      print(response.data);
      // Si success es true y hay datos, la carpeta existe
      return response.data['success'] == true;
    } catch (e) {
      print('[NAS CHECK FOLDER] Error: $e');
      return false;
    }
  }
}
