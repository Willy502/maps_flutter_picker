library maps_flutter_picker;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_geocoding/google_geocoding.dart' hide Location;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_place/google_place.dart' hide LatLon;
import 'package:maps_flutter_picker/loader_widget.dart';
import 'package:maps_flutter_picker/models/picker_detail.dart';
import 'package:permission_handler/permission_handler.dart';

class MapsPicker extends StatefulWidget {

  final bool currentLocation;
  final double lat;
  final double lan;
  final ArgumentCallback<PickerDetail> onLocationPicked;
  final Color color;
  final String apiKey;

  const MapsPicker({
    required this.currentLocation,
    required this.lat,
    required this.lan,
    required this.onLocationPicked,
    required this.color,
    required this.apiKey
  });

  @override
  State<MapsPicker> createState() => _MapsPickerState();
}

class _MapsPickerState extends State<MapsPicker> {

  late final bool currentLocation;
  late final double lat;
  late final double lan;
  late final Color color;
  late final ArgumentCallback<PickerDetail> onLocationPicked;
  late Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  late final String apiKey;
  final MarkerId markerId = const MarkerId("1");
  late GoogleGeocoding _googleGeocoding;
  late GooglePlace _googlePlace;
  List<dynamic> _placeList = [];
  final TextEditingController _autocompleteController = TextEditingController();

  _MapsPickerState() {
    currentLocation = widget.currentLocation;
    lat = widget.lat;
    lan = widget.lan;
    onLocationPicked = widget.onLocationPicked;
    color = widget.color;
    apiKey = widget.apiKey;
    _googleGeocoding = GoogleGeocoding(apiKey);
    _googlePlace = GooglePlace(apiKey);
  }

  CameraPosition? location;
  GoogleMapController? mapController;
  Map<String, String?>? searchSelected;

  @override
  void initState() {
    _autocompleteController.addListener(() {
      _onChanged();
    });
    _locationInit();
    super.initState();
  }

  void _locationInit() async {
    
    if (await Permission.location.isGranted) {
      LatLng current = LatLng(lat, lan);
      final Marker marker = Marker(
        markerId: markerId,
        position: current
      );
      setState(() {
        markers[markerId] = marker;
      });

      if (currentLocation) _getCurrentPosition();
    } else {

      Map<Permission, PermissionStatus> statuses = await [
        Permission.location,
        Permission.locationWhenInUse
      ].request();
      
      if (statuses[Permission.location] == PermissionStatus.granted) {
        _locationInit();
      } else if (statuses[Permission.location] == PermissionStatus.denied) {

        bool answer = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Advertencia"),
              content: const Text("Para seleccionar una ubicación es necesario aceptar el permiso solicitado."),
              actions: <Widget>[
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red[300],
                    primary: Colors.white
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("Continuar")
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("Solicitar permiso"),
                ),
              ],
            );
          }
        );

        if (answer) {
          _locationInit();
        } else {
          Navigator.of(context).pop();
        }
        
      } else if (statuses[Permission.location] == PermissionStatus.permanentlyDenied) {

        bool answer = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Permiso no aceptado"),
              content: const Text("No hemos podido acceder a la ubicación, deberás aceptar los permisos manualmente."),
              actions: <Widget>[
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red[300],
                    primary: Colors.white
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("Cancelar")
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("Abrir configuración"),
                ),
              ],
            );
          }
        );

        if (answer) {
          openAppSettings().then((value) => Navigator.of(context).pop());
        } else {
          Navigator.of(context).pop();
        }

      }
    }
  }

  @override
  Widget build(BuildContext context) {

    location = CameraPosition(
      target: LatLng(lat, lan),
      zoom: 14.4746,
    );

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        iconTheme: IconThemeData(
          color: color
        ),
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        title: _searchBar(),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: location!,
            myLocationEnabled: false,
            mapType: MapType.normal,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            onTap: (position) {
              _moveToPosition(position);
              //onLocationPicked(position); To execute the callback
            },
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
            },
            markers: Set<Marker>.of(markers.values),
          ),
          SafeArea(
            child: Container(
              color: Colors.white,
              child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _placeList.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_placeList[index]["description"]),
                    onTap: () {
                      if (_placeList[index]["placeId"] != null) {
                        searchSelected = _placeList[index];
                        _moveToPositionWithAddress(searchSelected!["placeId"]!);
                      } else {
                        _showError();
                      }
                      _autocompleteController.text = "";
                      _placeList.clear();
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                  );
                },
              ),
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: color,
        child: const Icon(Icons.location_searching_sharp),
        onPressed: _getCurrentPosition
      ),
    );
  }

  void _showError() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Ahx ocurrido un error"),
          content: const Text("No pudimos ubicar este lugar en el mapa.\nPor favor coloca la ubicación manualmente"),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.green[300],
                primary: Colors.white
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Aceptar")
            ),
          ],
        );
      },
    );
  }

  void _moveToPositionWithAddress(String placeId) async {
    showLoader(context, color: color);
    DetailsResponse? placeDetail = await _googlePlace.details.get(placeId);
    Location? location = placeDetail!.result!.geometry!.location;
    LatLng position = LatLng(location!.lat!, location.lng!);
    CameraUpdate cameraUpdate = CameraUpdate.newLatLng(position);
    mapController?.animateCamera(cameraUpdate);
    final Marker marker = Marker(
      markerId: markerId,
      position: position
    );
    setState(() {
      markers[markerId] = marker;
    });
    hideLoader(context);
    _showPickerDialog(position, detailsResponse: placeDetail);
  }

  void _moveToPosition(LatLng position) async {
    showLoader(context, color: color);
    GeocodingResponse? geocodingInformation = await _googleGeocoding.geocoding.getReverse(LatLon(position.latitude, position.longitude));
    CameraUpdate cameraUpdate = CameraUpdate.newLatLng(position);
    mapController?.animateCamera(cameraUpdate);
    final Marker marker = Marker(
      markerId: markerId,
      position: position
    );
    setState(() {
      markers[markerId] = marker;
    });
    hideLoader(context);
    _showPickerDialog(position, locationGeocoding: geocodingInformation);
  }

  void _getCurrentPosition() async {

    showLoader(context, color: color);
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    LatLng current = LatLng(position.latitude, position.longitude);
    GeocodingResponse? geocodingInformation = await _googleGeocoding.geocoding.getReverse(LatLon(position.latitude, position.longitude));
    CameraUpdate cameraUpdate = CameraUpdate.newLatLng(current);
    mapController?.animateCamera(cameraUpdate);
    final Marker marker = Marker(
      markerId: markerId,
      position: current
    );

    setState(() {
      markers[markerId] = marker;
    });
    hideLoader(context);
    _showPickerDialog(current, locationGeocoding: geocodingInformation);
  }

  Widget _searchBar() {

    TextField searchField = TextField(
      controller: _autocompleteController,
      textCapitalization: TextCapitalization.sentences,
      maxLines: 1,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.done,
      decoration: decorator(hint: "Búsqueda"),
    );

    return searchField;
  }

  InputDecoration decorator({required String hint}) {
    return InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20.0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(100.0)),
        prefixIcon: const Icon(Icons.search),
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100.0),
            borderSide: BorderSide(color: color)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(100.0),
            borderSide: BorderSide(color: color))
    );
  }

  void _showPickerDialog(LatLng position, {GeocodingResponse? locationGeocoding, DetailsResponse? detailsResponse}) {
    String? location = "Unnamed Road";

    try {
      if (locationGeocoding != null) location = locationGeocoding.results!.first.formattedAddress;
      if (detailsResponse != null) location = detailsResponse.result!.formattedAddress;
    } on Exception catch(_) {
      location = "Unnamed Road";
    }
    
    showModalBottomSheet(
      isDismissible: false,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (buildcontext) {
        return Wrap(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(20.0))
              ),
              margin: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  ListTile(
                    isThreeLine: true,
                    title: const Center(
                      child: Text("Seleccionar ubicación")
                    ),
                    subtitle: Center(
                      child: Text(location!),
                    ),
                  ),
                  ListTile(
                    title: Wrap(
                      children: [
                        Center(
                          child: ElevatedButton(
                            onPressed: () {
                              PickerDetail pickerDetail = PickerDetail(
                                location: position,
                                formatedAddress: location!,
                                pickedInformation: detailsResponse
                              );
                              Navigator.pop(context);
                              onLocationPicked(pickerDetail);
                            },
                            child: const Text('Seleccionar',
                              style: TextStyle(
                                fontSize: 16.0
                              )
                            ),
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all(color)
                            )
                          ),
                        )
                      ],
                    ),
                    subtitle: Wrap(
                      children: [
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar',
                              style: TextStyle(
                                fontSize: 16.0
                              )
                            )
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            )
          ]
        );
      }
    );
  }

  _onChanged() {
      getSuggestion(_autocompleteController.text);
    }

  void getSuggestion(String input) async {

    _placeList.clear();
    if (input != "") {
      
      AutocompleteResponse? result = await _googlePlace.autocomplete.get(input);
      for (var element in result!.predictions!) {
        _placeList.add({
          'description' : element.description,
          'placeId' : element.placeId
        });
      }
    }

    if (_autocompleteController.text == "") _placeList = [];
    setState(() {});
  }
}
