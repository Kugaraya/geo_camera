import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'bloc/geotag_bloc.dart';
import 'bloc/geotag_state.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late MapController _mapController;

  @override
  void initState() {
    _mapController = MapController(
      initMapWithUserPosition: UserTrackingOption(
        enableTracking: true,
        unFollowUser: false
      ),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<GeotagBloc, GeotagState>(
        builder: (context, state) {
          if (state is GeotagLoaded) {
            return Stack(
              children: [
                OSMFlutter(
                  controller: _mapController,
                  mapIsLoading: const Center(child: CircularProgressIndicator()),
                    osmOption: OSMOption(
                      userTrackingOption: const UserTrackingOption(
                      enableTracking: true,
                      unFollowUser: false,
                    ),
                    zoomOption: const ZoomOption(
                      initZoom: 8,
                      minZoomLevel: 3,
                      maxZoomLevel: 19,
                      stepZoom: 1.0,
                    ),
                    userLocationMarker: UserLocationMaker(
                      personMarker: const MarkerIcon(
                        icon: Icon(
                          Icons.location_history_rounded,
                          color: Colors.red,
                          size: 48,
                        ),
                      ),
                      directionArrowMarker: const MarkerIcon(
                        icon: Icon(
                          Icons.double_arrow,
                          size: 48,
                        ),
                      ),
                    ),
                    roadConfiguration: const RoadOption(
                      roadColor: Colors.yellowAccent,
                    ),
                  ),
                  onMapIsReady: (isReady) async {
                    if (isReady) {
                      await _mapController.currentLocation();
                      await _mapController.centerMap;
                    }
                  }, 
                ),
                Positioned(
                  bottom: 24,
                  left: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Lat: ${state.latitude.toStringAsFixed(6)}\nLng: ${state.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            );
          } else if (state is GeotagLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is GeotagError) {
            return Center(
              child: Text(
                'Location Error: ${state.message}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}