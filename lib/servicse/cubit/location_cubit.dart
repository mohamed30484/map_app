import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps/servicse/location_service.dart';

part 'location_state.dart';

class LocationCubit extends Cubit<LocationState> {
  LocationCubit() : super(LocationInitial());

  final LocationService _locationService = LocationService();

  Future<void> getLocation() async {
    emit(LocationLoading());

    try {
      Position position = await _locationService.getCurrentLocation();

      emit(LocationSuccess(position));
    } catch (e) {
      emit(LocationFailure(e.toString()));
    }
  }
}
