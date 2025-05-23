import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'geotag_event.dart';
import 'geotag_state.dart';

class GeotagBloc extends Bloc<GeotagEvent, GeotagState> {
  GeotagBloc() : super(GeotagInitial()) {
    on<GetLocationEvent>((event, emit) async {
      emit(GeotagLoading());
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          emit(GeotagError(message: 'Location services are disabled.'));
          return;
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            emit(GeotagError(message: 'Location permissions are denied.'));
            return;
          }
        }

        if (permission == LocationPermission.deniedForever) {
          emit(GeotagError(message: 'Location permissions are permanently denied.'));
          return;
        }

        Position position = await Geolocator.getCurrentPosition();
        emit(GeotagLoaded(latitude: position.latitude, longitude: position.longitude, accuracy: position.accuracy));
      } catch (e) {
        emit(GeotagError(message: e.toString()));
      }
    });
  }
}
