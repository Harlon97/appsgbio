import 'dart:async';
import 'dart:convert';
import 'dart:io'; // Necesario para Platform.isAndroid / .isIOS
import 'package:appsgbio/api/MotivoModels.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:appsgbio/MarcacionesUsuario.dart';
import 'package:appsgbio/api/Api.dart';
import 'package:appsgbio/api/MarcacionModels.dart';
//import 'package:shared_preferences/shared_preferences.dart';
import 'package:appsgbio/LoginPage.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'package:location/location.dart';

class Principal extends StatefulWidget {
  final String? nombreUsuario;
  final String? dniUsuario;
  final String? usuario;
  final String? token;
  final int? idUsuario;

  // 2. Modifica el constructor para aceptar estos datos
  // Hazlos requeridos si siempre los necesitas, o opcionales si no.
  const Principal({
    Key? key,
    this.nombreUsuario,
    this.dniUsuario,
    this.usuario,
    this.token,
    this.idUsuario,
  }) : super(key: key);

  @override
  _Principal createState() => _Principal();
}

class _Principal extends State<Principal> {
  StreamSubscription<LocationData>? _locationSubscription;
  final _formMarcacionKey = GlobalKey<FormState>();
  final _formUsuarioKey = GlobalKey<FormState>();
  final Completer<GoogleMapController> _googleMapController =
      Completer<GoogleMapController>();

  // --- NUEVAS VARIABLES DE ESTADO ---
  final Location _location = Location();
  LocationData? locationData;
  bool _isLocationReady = false; // Controla si el botón de marcar está activo
  String _errorMessage = ""; // Muestra mensajes de error al usuario
  // --- FIN DE NUEVAS VARIABLES ---

  final List<String> _acciones = ['Ingreso', 'Salida'];
  Future<List<MotivoModels>>? _motivosFuture;
  MotivoModels? _motivoSeleccionado;

  String? _accionSeleccionada;

  LatLng? miposicion;

  String error = "";
  String marcacionesdia = "";
  String _selectedOptionMenu = "";
  List<Widget> widgetsDeHorasMarcacion = [];
  // final Location _location = Location();

  // LocationData? locationData;

  // @override
  // void initState() {
  //   getCurrentLocation();
  //   getMarcacionDia();

  //   // getLocalizacionActual();
  //   super.initState();
  // }

  @override
  void initState() {
    super.initState();
    initializeLocationAndData();
    _motivosFuture = traerMotivos();
  }

  // NUEVA FUNCIÓN: Unifica la carga inicial
  Future<void> initializeLocationAndData() async {
    await _validateLocation(); // Valida y actualiza el estado de la ubicación
    if (_isLocationReady) {
      getMarcacionDia();
      _listenForLocationChanges();
    }
  }

  // NUEVA FUNCIÓN DE VALIDACIÓN ⚙️
  // Revisa el servicio y los permisos, y actualiza el estado de la UI.
  Future<bool> _validateLocation() async {
    // 1. Revisa si el servicio GPS está activo
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        setState(() {
          _isLocationReady = false;
          _errorMessage = "El servicio de ubicación (GPS) está desactivado.";
        });
        return false;
      }
    }

    // 2. Revisa si la app tiene permisos
    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        setState(() {
          _isLocationReady = false;
          _errorMessage =
              "El permiso de ubicación es necesario para marcar asistencia.";
        });
        return false;
      }
    }

    // Si todo está bien...
    setState(() {
      _isLocationReady = true;
      _errorMessage = ""; // Limpia errores previos
    });

    // Actualiza la ubicación actual una vez que todo está validado
    try {
      locationData = await _location.getLocation();
      // Mueve la cámara a la posición inicial
      final GoogleMapController controller = await _googleMapController.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(locationData!.latitude!, locationData!.longitude!),
            zoom: 14.5,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isLocationReady = false;
        _errorMessage = "No se pudo obtener la ubicación actual.";
      });
      return false;
    }

    return true;
  }

  // MODIFICADO: Extraemos el listener para mayor claridad
  void _listenForLocationChanges() {
    if (_locationSubscription != null) {
      _locationSubscription
          ?.cancel(); // Cancela la suscripción anterior si existe
    }
    _locationSubscription = _location.onLocationChanged.listen((
      LocationData newLocation,
    ) async {
      // Solo actualiza si los permisos siguen activos
      if (!_isLocationReady) return;

      setState(() {
        locationData = newLocation;
      });

      final GoogleMapController controller = await _googleMapController.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(newLocation.latitude!, newLocation.longitude!),
            zoom: 14.5,
          ),
        ),
      );
    });
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

  Future<List<MotivoModels>> traerMotivos() async {
    try {
      var respuesta = await Api().MotivoObtener("/Motivo", widget.token!);
      var contenidoMotivo = json.decode(respuesta.body);

      if (contenidoMotivo["success"]) {
        final List<dynamic> motivosJson = contenidoMotivo["listaMotivo"];
        return motivosJson.map((json) => MotivoModels.fromJson(json)).toList();
      } else {
        throw Exception(contenidoMotivo["message"]);
      }
    } catch (e) {
      print("Error al obtener motivos: $e");
      // Puedes manejar el error o devolver una lista vacía
      return [];
    }
  }

  @override
  void dispose() {
    // Si la suscripción no es nula, la cancelamos.
    _locationSubscription?.cancel();
    super.dispose();
  }

  // void getCurrentLocation() async {
  //   try {
  //     //Obtenemos la posicion actual
  //     LocationData currentLoc = await _location.getLocation();
  //     //Seteamos la variable que guardara la posicion
  //     setState(() {
  //       locationData = currentLoc;
  //     });

  //     //mover la camara del mapa
  //     final GoogleMapController controller = await _googleMapController.future;
  //     await controller.animateCamera(
  //       CameraUpdate.newCameraPosition(
  //         CameraPosition(
  //           target: LatLng(currentLoc.latitude!, currentLoc.longitude!),
  //           zoom: 14.5,
  //         ),
  //       ),
  //     );

  //     _locationSubscription = _location.onLocationChanged.listen((
  //       LocationData newLocation,
  //     ) async {
  //       //para actualizar conforme se va moviendo
  //       await controller.animateCamera(
  //         CameraUpdate.newCameraPosition(
  //           CameraPosition(
  //             target: LatLng(newLocation.latitude!, newLocation.longitude!),
  //             zoom: 14.5,
  //           ),
  //         ),
  //       );
  //       setState(() {
  //         locationData = newLocation;
  //       });
  //     });
  //   } catch (e) {}
  // }

  //-8.100810904027863, -79.03621590722578
  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(-8.100810904027863, -79.03621590722578),
    zoom: 14.5,
  );

  List<Marker> marcadores = [];

  _marcaposicion(LatLng posicion) {
    marcadores = [];
    setState(() {
      marcadores.add(
        Marker(markerId: MarkerId(posicion.toString()), position: posicion),
      );
    });
  }

  void getMarcacionDia() async {
    try {
      String dia = DateFormat('dd/MM/yyyy').format(DateTime.now());
      var datosmarcacion = {
        "dni": widget.dniUsuario,
        "fechainicio": dia,
        "fechafin": dia,
      };

      var respuesta = await Api().MarcacionObtener(
        datosmarcacion,
        "/Marcacion",
        widget.token!, //registrosesion.getString("token")!,
      );
      var contenidomarcacion = json.decode(respuesta.body);
      if (contenidomarcacion["success"]) {
        final List<dynamic> marcaciones =
            contenidomarcacion["listaMarcaciones"];
        final List<MarcacionModels> listaMarcaciones = marcaciones
            .map((e) => MarcacionModels.fromJson(e))
            .toList();

        List<Widget> widgetsDeHoras = [];
        int fila = 0;

        if (listaMarcaciones.length > 0) {
          for (MarcacionModels asistencia in listaMarcaciones) {
            fila = fila + 1;
            String horaFormateada =
                "${fila}°: ${asistencia.fecha_hora.hour.toString().padLeft(2, "0")}:${asistencia.fecha_hora.minute.toString().padLeft(2, "0")}";
            widgetsDeHoras.add(
              Container(
                // La decoración es donde defines el borde, color de fondo, radio, etc.
                decoration: BoxDecoration(
                  color: Colors.white, // Color de fondo del borde (opcional)
                  borderRadius: BorderRadius.circular(
                    5,
                  ), // Radio para esquinas redondeadas
                  border: Border.all(
                    color: Colors.black, // Color del borde
                    width: 1.5, // Ancho del borde
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 2,
                  vertical: 1.5,
                ), // Relleno interno
                child: Text(
                  horaFormateada,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color.fromARGB(255, 35, 35, 35),
                  ),
                ),
              ),
            );
          }
        }

        setState(() {
          widgetsDeHorasMarcacion = widgetsDeHoras;
        });
      }
    } catch (e) {
      debugPrint("Error en traer marcacion");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
          "¡Bienvenido!\n${widget.nombreUsuario}",
          style: const TextStyle(
            fontSize: 14, // Tamaño de la fuente
            fontWeight: FontWeight.bold, // Opcional: para que sea negrita
            // Puedes añadir más propiedades aquí, como 'color'
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String result) {
              setState(() {
                _selectedOptionMenu = result;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Seleccionaste: $result')),
                );
              });
              if (result == "MARCACION") {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Principal(
                      idUsuario: widget.idUsuario,
                      nombreUsuario: widget.nombreUsuario,
                      dniUsuario: widget.dniUsuario,
                      usuario: widget.usuario,
                      token: widget.token,
                    ),
                  ),
                  (Route<dynamic> route) => false,
                );
              } else if (result == "REPORTEMARCACIONES") {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MarcacionesUsuario(
                      idUsuario: widget.idUsuario,
                      nombreUsuario: widget.nombreUsuario,
                      dniUsuario: widget.dniUsuario,
                      usuario: widget.usuario,
                      token: widget.token,
                    ),
                  ),
                  (Route<dynamic> route) => false,
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: "MARCACION",
                child: Text("MARCACIÓN"),
              ),
              const PopupMenuItem<String>(
                value: "REPORTEMARCACIONES",
                child: Text("MIS MARCACIONES"),
              ),
            ],
          ),

          InkWell(
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
                (Route route) => false,
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Icon(Icons.exit_to_app),
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: Column(
          //mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 7.0),
            formularioUsuario(),
            Expanded(
              child: Container(
                margin: EdgeInsets.only(top: 1.0),
                padding: EdgeInsets.all(2),
                width: double.infinity,
                height: 650,
                decoration: const BoxDecoration(color: Colors.white),
                child: GoogleMap(
                  initialCameraPosition: _kGooglePlex,
                  onMapCreated: (controller) {
                    _googleMapController.complete(controller);
                  },
                  markers: {
                    if (locationData != null && _isLocationReady)
                      Marker(
                        markerId: MarkerId("currentLocation"),
                        position: LatLng(
                          locationData!.latitude!,
                          locationData!.longitude!,
                        ),
                      ),
                  },
                ),
              ),
            ),
            // NUEVO: Widget para mostrar el mensaje de error
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 16.0,
                ),
                child: Text(
                  _errorMessage,
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            botonRegistraAsistencia(),
            formularioMarcacion(),
          ],
        ),
      ),
      backgroundColor: Colors.grey[300],
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {},
      //   child: Icon(Icons.add),
      // ),
    );
  }

  Widget formularioUsuario() {
    //String dia = DateFormat.yMMMMEEEEd('es_ES').format(DateTime.now());
    //String dia = DateFormat('dd/MM/yyyy').format(DateTime.now());

    return Form(
      key: _formUsuarioKey,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: FutureBuilder<List<MotivoModels>>(
              future: _motivosFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No se pudo cargar los motivos.'),
                  );
                } else {
                  // Si los datos están listos, muestra el Dropdown
                  final List<MotivoModels> motivos = snapshot.data!;
                  return DropdownButtonFormField<MotivoModels>(
                    // Decoración para que se vea como un campo de texto normal
                    decoration: InputDecoration(
                      labelText: 'Selecciona un Motivo',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),

                    // El valor actualmente seleccionado. Debe coincidir con uno de los valores de los items.
                    value: _motivoSeleccionado,

                    // Texto que aparece cuando no hay nada seleccionado
                    hint: const Text('Elige...'),

                    // La lista de items que se mostrarán en el desplegable.
                    // Usamos .map() para convertir nuestra lista de Strings en una lista de DropdownMenuItem.
                    items: motivos.map<DropdownMenuItem<MotivoModels>>((
                      MotivoModels motivo,
                    ) {
                      return DropdownMenuItem<MotivoModels>(
                        value: motivo,
                        child: Text(
                          motivo.descripcion,
                        ), // Aquí usamos el campo 'descripcion' de MotivoModels
                      );
                    }).toList(),

                    // La función que se ejecuta cuando el usuario selecciona una nueva opción.
                    onChanged: (MotivoModels? nuevoValor) {
                      // Usamos setState para actualizar la UI con la nueva selección.
                      setState(() {
                        _motivoSeleccionado = nuevoValor;
                      });
                    },

                    // (Opcional) Validador para formularios
                    validator: (value) {
                      if (value == null) {
                        return 'Por favor, selecciona un Motivo.';
                      }
                      return null;
                    },
                  );
                }
              },
            ),
          ),
          Expanded(
            child: DropdownButtonFormField<String>(
              // Decoración para que se vea como un campo de texto normal
              decoration: InputDecoration(
                labelText: 'Selecciona una Accion',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                filled: true,
                fillColor: Colors.white,
              ),

              // El valor actualmente seleccionado. Debe coincidir con uno de los valores de los items.
              value: _accionSeleccionada,

              // Texto que aparece cuando no hay nada seleccionado
              hint: const Text('Elige...'),

              // La lista de items que se mostrarán en el desplegable.
              // Usamos .map() para convertir nuestra lista de Strings en una lista de DropdownMenuItem.
              items: _acciones.map((String valor) {
                return DropdownMenuItem<String>(
                  value: valor,
                  child: Text(valor),
                );
              }).toList(),

              // La función que se ejecuta cuando el usuario selecciona una nueva opción.
              onChanged: (String? nuevoValor) {
                // Usamos setState para actualizar la UI con la nueva selección.
                setState(() {
                  _accionSeleccionada = nuevoValor;
                });
              },

              // (Opcional) Validador para formularios
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, selecciona una Accion.';
                }
                return null;
              },
            ),
          ),

          // Text(
          //   "Marcaciones\n" + dia,
          //   style: TextStyle(
          //     fontWeight: FontWeight.bold,
          //     fontSize: 12,
          //     color: Color.fromARGB(255, 35, 35, 35),
          //   ),
          // ),
          // const Padding(padding: EdgeInsets.only(left: 20)),
          // Flexible(
          //   child: Wrap(
          //     spacing: 3.0, // Espacio horizontal entre widgets
          //     runSpacing: 0.5, // Espacio vertical entre líneas
          //     children: widgetsDeHorasMarcacion,
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget botonRegistraAsistencia() {
    return FractionallySizedBox(
      widthFactor: 0.6,
      child: ElevatedButton(
        onPressed: _isLocationReady
            ? () async {
                // if (_formKey.currentState!.validate()) {
                //   _formKey.currentState!.save();
                // SharedPreferences registrosesion =
                //     await SharedPreferences.getInstance();

                // 1. Re-validar justo antes de marcar 🚨
                final bool isStillReady = await _validateLocation();
                if (!isStillReady) {
                  // Si la validación falla, muestra el SnackBar y no continúa.
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_errorMessage),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // 2. Seguridad extra: Asegurarse que locationData no es nulo
                if (locationData == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "No se pudo obtener la ubicación para marcar.",
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                if (_motivoSeleccionado == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Seleccione un motivo."),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                if (_accionSeleccionada == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Seleccione una acción."),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Map<String, dynamic> deviceData = await _getDeviceData();

                // 3. Si todo está OK, procede con el registro
                //var datos = {"User": usuario, "Password": password};
                MarcacionModels marcacionactual = MarcacionModels(
                  dni: widget.dniUsuario!,
                  fecha_hora: DateTime.now(),
                  idbio: 9,
                  fecha_hora_real: DateTime.now(),
                  tipo_marcado: 1,
                  latitud: locationData!.latitude!,
                  longitud: locationData!.longitude!,
                  dispositivoId: deviceData['dispositivoId'],
                  dispositivoMarca: deviceData['dispositivoMarca'],
                  dispositivoModelo: deviceData['dispositivoModelo'],
                  dispositivoSerie: deviceData['dispositivoSerie'],
                  dispositivoNombre: deviceData['dispositivoNombre'],
                  idmotivo: _motivoSeleccionado!.id,
                  tipo: _accionSeleccionada!,
                );

                var respuesta = await Api().MarcacionRegistrar(
                  marcacionactual.toJsonPost(),
                  "/Marcacion",
                  widget.token!, //registrosesion.getString("token")!,
                );
                var contenido = json.decode(respuesta.body);
                if (contenido["success"]) {
                  getMarcacionDia();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("¡Marcación registrada con éxito!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  setState(() {
                    error = contenido["message"];
                    // Si la API da un error, muéstralo
                    _errorMessage = contenido["message"];
                  });
                }
                //}
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isLocationReady
              ? Theme.of(context).primaryColor
              : Colors.grey,
          foregroundColor: Colors.white,
        ),
        child: Text("Marcar Asistencia"),
      ),
    );

    //return ElevatedButton(onPressed: () {}, child: Text("Iniciar Sesión"));
  }

  Widget formularioMarcacion() {
    //String dia = DateFormat.yMMMMEEEEd('es_ES').format(DateTime.now());
    String dia = DateFormat('dd/MM/yyyy').format(DateTime.now());
    return Form(
      key: _formMarcacionKey,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Marcaciones\n" + dia,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Color.fromARGB(255, 35, 35, 35),
            ),
          ),
          const Padding(padding: EdgeInsets.only(left: 20)),
          Flexible(
            child: Wrap(
              spacing: 3.0, // Espacio horizontal entre widgets
              runSpacing: 0.5, // Espacio vertical entre líneas
              children: widgetsDeHorasMarcacion,
            ),
          ),
        ],
      ),
    );
  }
}
