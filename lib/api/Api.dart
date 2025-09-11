import 'dart:convert';

import 'package:http/http.dart' as http;

class Api {
  final String _dominioAutenticacion = "200.48.198.74:7091";
  final String _dominioUsuario = "200.48.198.74:7093";
  final String _dominioMarcacion = "200.48.198.74:7092";
  final String _dominioMotivo = "200.48.198.74:7094";

  //final String _dominioUsuario = "192.168.50.111:7093";
  //final String _dominioMarcacion = "192.168.50.111:7092";
  //final String _dominioMotivo = "192.168.50.111:7094";
  final String _url1 = "/api";

  //"Autenticacion/"
  login(_data, String _url2) async {
    var ruta = _url1 + _url2;
    return await http.post(
      Uri.http(_dominioAutenticacion, ruta),
      body: json.encode(_data),
      headers: {
        'Content-type': 'application/json',
        'Aceppt': 'application/json',
      },
    );
  }

  UsuarioObtener(
    Map<String, dynamic> _data,
    String _url2,
    String jwtToken,
  ) async {
    var ruta = _url1 + _url2;

    final Map<String, String> queryParameters = _data.map(
      (key, value) => MapEntry(key, value.toString()),
    );

    final Uri uri = Uri.http(_dominioUsuario, ruta, queryParameters);

    return await http.get(
      uri,
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $jwtToken',
      },
    );
  }

  UsuarioEditarInfoCel(
    Map<String, dynamic> _data,
    String _url2,
    String jwtToken,
  ) async {
    var ruta = _url1 + _url2;

    //final Map<String, String> queryParameters = _data.map((key, value) => MapEntry(key, value.toString()));

    final Uri uri = Uri.http(_dominioUsuario, ruta);

    return await http.put(
      uri,
      body: json.encode(_data),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $jwtToken',
      },
    );
  }

  MarcacionObtener(
    Map<String, dynamic> _data,
    String _url2,
    String jwtToken,
  ) async {
    var ruta = _url1 + _url2;

    final Map<String, String> queryParameters = _data.map(
      (key, value) => MapEntry(key, value.toString()),
    );

    final Uri uri = Uri.http(_dominioMarcacion, ruta, queryParameters);

    return await http.get(
      uri,
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $jwtToken',
      },
    );
  }

  MarcacionRegistrar(
    Map<String, dynamic> _data,
    String _url2,
    String jwtToken,
  ) async {
    var ruta = _url1 + _url2;

    //final Map<String, String> queryParameters = _data.map((key, value) => MapEntry(key, value.toString()));

    final Uri uri = Uri.http(_dominioMarcacion, ruta);

    return await http.post(
      uri,
      body: json.encode(_data),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $jwtToken',
      },
    );
  }

  MotivoObtener(String _url2, String jwtToken) async {
    var ruta = _url1 + _url2;

    // final Map<String, String> queryParameters = _data.map(
    //   (key, value) => MapEntry(key, value.toString()),
    // );

    final Uri uri = Uri.http(_dominioMotivo, ruta);

    return await http.get(
      uri,
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $jwtToken',
      },
    );
  }
}
