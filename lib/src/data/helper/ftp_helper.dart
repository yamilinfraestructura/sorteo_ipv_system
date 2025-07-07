import 'dart:io';

import 'package:ftpconnect/ftpconnect.dart';

class FtpHelper {
  final String host;
  final String user;
  final String password;
  final int port;
  final bool useSftp;

  FtpHelper({
    required this.host,
    required this.user,
    required this.password,
    this.port = 21,
    this.useSftp = false,
  });

  /// Sube un archivo al FTP en la ruta destino. Devuelve true si fue exitoso.
  Future<bool> subirArchivo({
    required File file,
    required String remoteDir,
    String? remoteFileName,
  }) async {
    late FTPConnect ftp;
    try {
      print('[FTP] Conectando a $host:$port ...');
      ftp = FTPConnect(
        host,
        user: user,
        pass: password,
        port: port,
        securityType: useSftp ? SecurityType.FTPS : SecurityType.FTP,
        timeout: 30,
      );
      await ftp.connect();
      print('[FTP] Conectado. Cambiando a directorio: $remoteDir');
      await ftp.changeDirectory(remoteDir);
      print('[FTP] Subiendo archivo: ${file.path}');
      final ok = await ftp.uploadFile(
        file,
        sRemoteName: remoteFileName ?? file.uri.pathSegments.last,
      );
      print('[FTP] Subida finalizada: $ok');
      await ftp.disconnect();
      return ok;
    } catch (e, stack) {
      print('[FTP] Error: $e');
      print(stack);
      try {
        await ftp.disconnect();
      } catch (_) {}
      return false;
    }
  }

  /// Verifica la conexión y existencia del directorio remoto en el FTP
  Future<bool> verificarConexionYDirectorio({required String remoteDir}) async {
    late FTPConnect ftp;
    try {
      print('[FTP] Verificando conexión a $host:$port ...');
      ftp = FTPConnect(
        host,
        user: user,
        pass: password,
        port: port,
        securityType: useSftp ? SecurityType.FTPS : SecurityType.FTP,
        timeout: 30,
      );
      await ftp.connect();
      print('[FTP] Conectado. Cambiando a directorio: $remoteDir');
      await ftp.changeDirectory(remoteDir);
      print('[FTP] Directorio encontrado y acceso OK.');
      await ftp.disconnect();
      return true;
    } catch (e, stack) {
      print('[FTP] Error de conexión o directorio: $e');
      print(stack);
      try {
        await ftp.disconnect();
      } catch (_) {}
      return false;
    }
  }
}
