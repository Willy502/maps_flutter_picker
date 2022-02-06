import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_place/google_place.dart';

class PickerDetail {

  final LatLng location;
  final String formatedAddress;
  late final DetailsResponse? pickedInformation;

  PickerDetail({
    required this.location,
    required this.formatedAddress,
    this.pickedInformation
  });

}