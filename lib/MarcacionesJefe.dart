import 'package:appsgbio/principal.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:appsgbio/api/Api.dart';
import 'package:appsgbio/api/MarcacionModels.dart';
import 'package:appsgbio/LoginPage.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'package:location/location.dart';

class MarcacionesUsuario extends StatefulWidget {
  final String? nombreUsuario;
  final String? dniUsuario;
  final String? usuario;
  final String? token;
  final int? idUsuario;

  // 2. Modifica el constructor para aceptar estos datos
  // Hazlos requeridos si siempre los necesitas, o opcionales si no.
  const MarcacionesUsuario({
    Key? key,
    this.nombreUsuario,
    this.dniUsuario,
    this.usuario,
    this.token,
    this.idUsuario,
  }) : super(key: key);

  @override
  _MarcacionesUsuario createState() => _MarcacionesUsuario();
}

class _MarcacionesUsuario extends State<MarcacionesUsuario> {
  StreamSubscription<LocationData>? _locationSubscription;
  final _formMarcacionKey = GlobalKey<FormState>();
  final Completer<GoogleMapController> _googleMapController =
      Completer<GoogleMapController>();
  LatLng? miposicion;

  String error = "";
  String marcacionesdia = "";
  String _selectedOptionMenu = "";
  Set<Marker> misPosiciones = {};
  List<Widget> widgetsDeHorasMarcacion = [];
  final Location _location = Location();

  LocationData? locationData;
  DateTime _selectedDate = DateTime.now(); // La fecha seleccionada por defecto
  String _message = 'Selecciona una fecha'; // Mensaje para la interfaz

  // Función que se ejecutará como "evento" al seleccionar una fecha
  void _handleDateSelected(DateTime newDate) {
    // Aquí puedes añadir cualquier lógica que necesites
    // Por ejemplo, guardar en una variable, llamar a una API, etc.
    print('Fecha seleccionada por el usuario: $newDate');
    setState(() {
      _selectedDate = newDate;
      _message = '¡Fecha seleccionada!';
    });
    getMarcacionDia();
  }

  Future<void> _selectDate(BuildContext context) async {
    // Muestra el diálogo de selección de fecha
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate, // Fecha inicial del selector
      firstDate: DateTime(2025, 08, 01), // La primera fecha disponible
      lastDate: DateTime(2101), // La última fecha disponible
    );
    // Si el usuario seleccionó una fecha y no es nula, activa el evento
    if (picked != null && picked != _selectedDate) {
      _handleDateSelected(picked);
    }
  }

  void getCurrentLocation() async {
    try {
      //Obtenemos la posicion actual
      LocationData currentLoc = await _location.getLocation();
      //Seteamos la variable que guardara la posicion
      setState(() {
        locationData = currentLoc;
      });

      //mover la camara del mapa
      final GoogleMapController controller = await _googleMapController.future;
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(currentLoc.latitude!, currentLoc.longitude!),
            zoom: 14.5,
          ),
        ),
      );

      _locationSubscription = _location.onLocationChanged.listen((
        LocationData newLocation,
      ) async {
        //para actualizar conforme se va moviendo
        await controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(newLocation.latitude!, newLocation.longitude!),
              zoom: 14.5,
            ),
          ),
        );
        setState(() {
          locationData = newLocation;
        });
      });
    } catch (e) {}
  }

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
      //String dia = DateFormat('dd/MM/yyyy').format(DateTime.now());
      String dia = DateFormat('dd/MM/yyyy').format(_selectedDate);
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

        Set<Marker> myMarkers = {};
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

            myMarkers.add(
              Marker(
                markerId: MarkerId("Marcacion_${fila}"),
                position: LatLng(
                  asistencia.latitud,
                  asistencia.longitud,
                ), // Ejemplo de latitud y longitud
                infoWindow: InfoWindow(title: "Marcación ${fila}"),
              ),
            );
            if (fila == 1) {
              final GoogleMapController controller =
                  await _googleMapController.future;
              await controller.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: LatLng(asistencia.latitud, asistencia.longitud),
                    zoom: 14.5,
                  ),
                ),
              );
            }
          }
        }

        setState(() {
          widgetsDeHorasMarcacion = widgetsDeHoras;
        });
        setState(() {
          misPosiciones = myMarkers;
        });
      }
    } catch (e) {
      debugPrint("Error en traer marcacion");
    }
  }

  @override
  void initState() {
    //getCurrentLocation();
    getMarcacionDia();

    // getLocalizacionActual();
    super.initState();
  }

  @override
  void dispose() {
    // Si la suscripción no es nula, la cancelamos.
    _locationSubscription?.cancel();
    super.dispose();
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
      body: Column(
        //mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ElevatedButton(
            onPressed: () => _selectDate(context),
            child: const Text('Seleccionar Fecha'),
          ),
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
                markers: misPosiciones,
              ),
            ),
          ),
          // botonRegistraAsistencia(),
          // formularioMarcacion(),
        ],
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

  Widget botonRegistraAsistencia() {
    return FractionallySizedBox(
      widthFactor: 0.6,
      child: ElevatedButton(
        onPressed: () async {
          // if (_formKey.currentState!.validate()) {
          //   _formKey.currentState!.save();
          // SharedPreferences registrosesion =
          //     await SharedPreferences.getInstance();

          //var datos = {"User": usuario, "Password": password};
          MarcacionModels marcacionactual = MarcacionModels(
            dni: widget.dniUsuario!,
            fecha_hora: DateTime.now(),
            idbio: 9,
            fecha_hora_real: DateTime.now(),
            tipo_marcado: 1,
            latitud: locationData!.latitude!,
            longitud: locationData!.longitude!,
          );

          var respuesta = await Api().MarcacionRegistrar(
            marcacionactual.toJsonPost(),
            "/Marcacion",
            widget.token!, //registrosesion.getString("token")!,
          );
          var contenido = json.decode(respuesta.body);
          if (contenido["success"]) {
            getMarcacionDia();
            // //error = "";
            // //getLocalizacionActual();
            // //if (permitir) {
            // Navigator.pushAndRemoveUntil(
            //   context,
            //   MaterialPageRoute(builder: (context) => Principal()),
            //   (Route<dynamic> route) => false,
            // );
            // // }
            // // else {
            // //   setState(() {
            // //     error = "No dio los permisos de ubicación";
            // //   });
            // // }

            // // SharedPreferences registrosesion =
            // //     await SharedPreferences.getInstance();

            // // registrosesion.setString("token", contenido["accessToken"]);

            // //print(contenido["accessToken"]);
          } else {
            setState(() {
              error = contenido["message"];
            });
          }
          //}
        },
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
