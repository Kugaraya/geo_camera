import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'bloc/geotag_bloc.dart';
import 'bloc/geotag_state.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  MapType _mapType = MapType.normal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Location'),
        actions: [
          PopupMenuButton<MapType>(
            icon: const Icon(Icons.layers),
            onSelected: (type) => setState(() => _mapType = type),
            itemBuilder: (context) => [
              const PopupMenuItem(value: MapType.normal, child: Text('Normal')),
              const PopupMenuItem(value: MapType.satellite, child: Text('Satellite')),
              const PopupMenuItem(value: MapType.terrain, child: Text('Terrain')),
              const PopupMenuItem(value: MapType.hybrid, child: Text('Hybrid')),
            ],
          ),
        ],
      ),
      body: BlocBuilder<GeotagBloc, GeotagState>(
        builder: (context, state) {
          if (state is GeotagLoaded) {
            final latLng = LatLng(state.latitude, state.longitude);
            return Stack(
              children: [
                GoogleMap(
                  mapType: _mapType,
                  initialCameraPosition: CameraPosition(target: latLng, zoom: 17),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  markers: {
                    Marker(
                      markerId: const MarkerId('current_location'),
                      position: latLng,
                      infoWindow: InfoWindow(
                        title: 'You are here',
                        snippet: 'Lat: ${latLng.latitude.toStringAsFixed(6)}, Lng: ${latLng.longitude.toStringAsFixed(6)}',
                      ),
                    ),
                  },
                  onMapCreated: (controller) {
                    _mapController = controller;
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
                      'Lat: ${latLng.latitude.toStringAsFixed(6)}\nLng: ${latLng.longitude.toStringAsFixed(6)}',
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
          // Initial or unknown state
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}