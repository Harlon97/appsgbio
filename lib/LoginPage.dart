import 'package:appsgbio/api/UsuarioModels.dart';
import 'package:flutter/material.dart';
//import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:convert';
import 'package:appsgbio/api/Api.dart';
import 'package:appsgbio/principal.dart';
import 'package:geolocator/geolocator.dart';

class LoginPage extends StatefulWidget {
  @override
  State createState() {
    return _LoginState();
  }
}

class _LoginState extends State<LoginPage> {
  late String usuario, password;
  final _formKey = GlobalKey<FormState>();
  String error = "";
  bool permitirLogin = false; // Estado inicial del botón: deshabilitado

  @override
  void initState() {
    super.initState();
    // Llamamos a la función para verificar permisos cuando la página se inicializa
    _checkLocationStatus();
  }

  /// Función mejorada que verifica PERMISOS y si el SERVICIO GPS está activado.
  Future<void> _checkLocationStatus() async {
    // 1. Verificar si el servicio de ubicación (GPS) está activado en el dispositivo
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Si el servicio está desactivado, no podemos continuar.
      // Mostramos un mensaje y mantenemos el botón deshabilitado.
      setState(() {
        permitirLogin = false;
        error =
            "Por favor, active el servicio de ubicación (GPS) de su dispositivo y abra la aplicacion nuevamente.";
      });
      // Opcional: puedes abrir la configuración de ubicación para que el usuario lo active.
      // await Geolocator.openLocationSettings();
      return;
    }

    // 2. Si el servicio está activo, ahora verificamos los permisos de la app
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // El usuario negó el permiso
        setState(() {
          permitirLogin = false;
          error =
              "El permiso de ubicación fue denegado. Es necesario para continuar.";
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // El usuario negó el permiso permanentemente
      setState(() {
        permitirLogin = false;
        error =
            "El permiso de ubicación fue denegado permanentemente. Habilítelo desde la configuración.";
      });
      return;
    }

    // 3. Si llegamos aquí, el servicio está activo y tenemos permisos.
    setState(() {
      permitirLogin = true;
      error = ""; // Limpiamos cualquier error anterior
    });
  }

  Future<bool?> _mostrarDialogoConfirmacion(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // El usuario debe elegir una opción
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Acción'),
          content: const Text(
            'Se registrará un idenficador de su celular desde el cual realizará su marcación, no podrá hacerlo desde otro dispositivo ¿Desea continuar de todas formas?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop(false); // Devuelve false
              },
            ),
            TextButton(
              child: const Text('Sí, continuar'),
              onPressed: () {
                Navigator.of(context).pop(true); // Devuelve true
              },
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getDeviceData() async {
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    Map<String, dynamic> deviceData = <String, dynamic>{};

    try {
      if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo =
            await deviceInfoPlugin.androidInfo;
        deviceData = {
          'dispositivoId': androidInfo.id, // ID único del dispositivo Android
          'dispositivoMarca': androidInfo.manufacturer, // Ejemplo: "Google"
          'dispositivoModelo': androidInfo.model, // Ejemplo: "Pixel 6"
          'osVersion': androidInfo.version.release, // Ejemplo: "12"
          'esDispositivoFisico': androidInfo.isPhysicalDevice,
          'dispositivoSerie': androidInfo.serialNumber,
          'dispositivoNombre': androidInfo.name,
        };
      } else if (Platform.isIOS) {
        final IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
        deviceData = {
          'dispositivoId': iosInfo
              .identifierForVendor, // ID único para el vendedor de la app en este dispositivo
          'dispositivoMarca': 'Apple',
          'dispositivoModelo': iosInfo.model, // Ejemplo: "iPhone 13 Pro"
          'osVersion': iosInfo.systemVersion, // Ejemplo: "15.1"
          'esDispositivoFisico': iosInfo.isPhysicalDevice,
          'dispositivoSerie': '',
          'dispositivoNombre': iosInfo.name,
        };
      }
    } catch (e) {
      // Si hay un error, devolvemos un mapa con valores por defecto o de error
      deviceData = {
        'error': 'No se pudo obtener la información del dispositivo.',
        'dispositivoId': 'desconocido',
        'dispositivoMarca': 'desconocido',
        'dispositivoModelo': 'desconocido',
      };
    }
    return deviceData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/fingerprint5.png', // Ruta a tu imagen local
            width: 50, // Ancho opcional
            height: 65, // Alto opcional
            fit: BoxFit.fill, // Cómo la imagen debe llenar su espacio
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "SGBIO",
              style: TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Offstage(
            offstage: error == "",
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                error,
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.all(8), child: formulario()),
          botonlogin(),
        ],
      ),
    );
  }

  Widget formulario() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          buildUsuario(),
          const Padding(padding: EdgeInsets.only(top: 12)),
          buildPassword(),
        ],
      ),
    );
  }

  Widget buildUsuario() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: "Usuario",
        border: OutlineInputBorder(
          borderRadius: new BorderRadius.circular(8),
          borderSide: new BorderSide(color: Colors.black),
        ),
      ),
      onSaved: (String? value) {
        usuario = value!;
      },
      validator: (value) {
        if (value!.isEmpty) {
          return "Este campo es obligatorio";
        }
        return null;
      },
    );
  }

  Widget buildPassword() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: "Password",
        border: OutlineInputBorder(
          borderRadius: new BorderRadius.circular(8),
          borderSide: new BorderSide(color: Colors.black),
        ),
      ),
      obscureText: true,
      validator: (value) {
        if (value!.isEmpty) {
          return "Este campo es obligatorio";
        }
        return null;
      },
      onSaved: (String? value) {
        password = value!;
      },
    );
  }

  Widget botonlogin() {
    return FractionallySizedBox(
      widthFactor: 0.6,
      child: ElevatedButton(
        onPressed: permitirLogin
            ? () async {
                // Es buena práctica volver a verificar justo antes de la acción
                await _checkLocationStatus();
                if (!permitirLogin) {
                  // Si después de la verificación el estado cambió a no permitido, detenemos la ejecución
                  return;
                }

                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();

                  var datos = {"User": usuario, "Password": password};

                  var respuesta = await Api().login(datos, "/Autenticacion");
                  var contenido = json.decode(respuesta.body);
                  if (contenido["success"]) {
                    //error = "";
                    //getLocalizacionActual();
                    //if (permitir) {

                    var datosusuario = {"usuario": usuario};
                    var respuestausuario = await Api().UsuarioObtener(
                      datosusuario,
                      "/Usuario",
                      contenido["accessToken"].toString(),
                    );
                    //var contenidousuario = json.decode(respuestausuario.body);
                    var contenidousuario = jsonDecode(respuestausuario.body);
                    if (contenidousuario["success"]) {
                      // SharedPreferences registrosesion =
                      //     await SharedPreferences.getInstance();

                      // registrosesion.setString("User", usuario);
                      // registrosesion.setString("token", contenido["accessToken"]);
                      String dispositivoSerie = "";
                      Map<String, dynamic> deviceData = await _getDeviceData();
                      if (Platform.isAndroid) {
                        dispositivoSerie = deviceData['dispositivoId'];
                      } else if (Platform.isIOS) {
                        dispositivoSerie = deviceData['dispositivoId'];
                      }

                      final List<dynamic> usuarios =
                          contenidousuario["listaUsuarios"];
                      final List<UsuarioModels> listaUsuarios = usuarios
                          .map((e) => UsuarioModels.fromJson(e))
                          .toList();

                      if (listaUsuarios.length > 0) {
                        if (listaUsuarios[0].nombres != "") {
                          if (listaUsuarios[0].dni != "") {
                            if (listaUsuarios[0].serieidcel == "") {
                              // **AQUÍ ESTÁ LA IMPLEMENTACIÓN**
                              // Llamamos a la función del diálogo y esperamos la respuesta.
                              final bool? confirmacion =
                                  await _mostrarDialogoConfirmacion(context);

                              // Si el usuario presiona "Sí" (true), continuamos con la navegación.
                              if (confirmacion == true) {
                                // Si el usuario confirma, navega a la siguiente pantalla.
                                if (!mounted)
                                  return; // Buena práctica: verificar contexto antes de navegar.

                                UsuarioModels usuarioeditar = UsuarioModels(
                                  dni: listaUsuarios[0].dni,
                                  user: listaUsuarios[0].user,
                                  serieidcel: dispositivoSerie,
                                );

                                var respuestaedicion = await Api()
                                    .UsuarioEditarInfoCel(
                                      usuarioeditar.toJson(),
                                      "/Usuario/" +
                                          listaUsuarios[0].id.toString(),
                                      contenido["accessToken"].toString(),
                                    );
                                var contenidoedicion = json.decode(
                                  respuestaedicion.body,
                                );

                                if (contenidoedicion["success"]) {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Principal(
                                        idUsuario: listaUsuarios[0].id,
                                        nombreUsuario: listaUsuarios[0].nombres,
                                        dniUsuario: listaUsuarios[0].dni,
                                        usuario: usuario,
                                        token: contenido["accessToken"]
                                            .toString(),
                                      ),
                                    ),
                                    (Route<dynamic> route) => false,
                                  );
                                } else {
                                  setState(() {
                                    error = contenido["message"];
                                  });
                                }
                              } else {
                                // Si el usuario presiona "No", simplemente no hacemos nada
                                // y el usuario se queda en la pantalla de login.
                                return;
                              }
                            } else {
                              // Si SÍ tiene serieidcel, navega directamente.
                              if (!mounted) return;

                              if (listaUsuarios[0].serieidcel ==
                                  dispositivoSerie) {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Principal(
                                      idUsuario: listaUsuarios[0].id,
                                      nombreUsuario: listaUsuarios[0].nombres,
                                      dniUsuario: listaUsuarios[0].dni,
                                      usuario: usuario,
                                      token: contenido["accessToken"]
                                          .toString(),
                                    ),
                                  ),
                                  (Route<dynamic> route) => false,
                                );
                              } else {
                                setState(() {
                                  error =
                                      "Este dispositivo no está autorizado para la marcación";
                                });
                                return;
                              }
                            }
                          } else {
                            setState(() {
                              error = "El usuario no tiene dni asignado";
                            });
                          }
                        } else {
                          setState(() {
                            error = "El usuario no tiene nombre asignado";
                          });
                        }
                      } else {
                        setState(() {
                          error =
                              "No existe el usuario o la persona con el dni asignado";
                        });
                      }
                    } else {
                      setState(() {
                        error = contenido["message"];
                      });
                    }

                    // }
                    // else {
                    //   setState(() {
                    //     error = "No dio los permisos de ubicación";
                    //   });
                    // }

                    //print(contenido["accessToken"]);
                  } else {
                    setState(() {
                      error = contenido["message"];
                    });
                  }
                }
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: permitirLogin
              ? Colors.green
              : Colors.grey, // verde habilitado, gris deshabilitado
          foregroundColor: Colors.white, // Texto blanco
        ),
        child: Text("Iniciar Sesión"),
      ),
    );

    //return ElevatedButton(onPressed: () {}, child: Text("Iniciar Sesión"));
  }
}
