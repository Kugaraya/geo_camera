import 'dart:io';
import 'package:exif/exif.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../bloc/geotag_bloc.dart';
import '../bloc/geotag_event.dart';
import '../bloc/geotag_state.dart';
import 'package:image/image.dart' as img; // Add this import
import 'package:intl/intl.dart'; // Add this for date formatting

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  List<String> _folders = [];
  Timer? _locationTimer;
  String? _lastImagePath;

  @override
  void initState() {
    super.initState();
    // Force landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _initCamera();
    _startLocationUpdates();
    _loadFolders();
  }

  Future<void> _initCamera() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Permission.camera.request();
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      final CameraDescription camera = _cameras![0];
      _controller = CameraController(
        camera,
        fps: 60,
        ResolutionPreset.max,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _controller!.initialize();
      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _startLocationUpdates() {
    // Request location updates as fast as possible (every 1 second)
    _locationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        context.read<GeotagBloc>().add(GetLocationEvent());
      }
    });
  }

  Future<void> _loadFolders() async {
    String basePath = '/storage/emulated/0/DCIM/MIADP_GeoCamera';
    Directory baseDir = Directory(basePath);
    if (!(await baseDir.exists())) {
      await baseDir.create(recursive: true);
    }
    List<String> folders = [];
    await for (var entity in baseDir.list()) {
      if (entity is Directory) {
        folders.add(entity.path.split('/').last);
      }
    }
    setState(() {
      _folders = folders;
    });
  }

  Future<void> _capturePhoto() async {
    if (!_controller!.value.isInitialized) return;
    final image = await _controller!.takePicture();

    // Format date as "Mon DD, YYYY"
    final now = DateTime.now();
    final folderName = DateFormat('MMM dd, yyyy').format(now);

    String basePath = '/storage/emulated/0/DCIM/MIADP_GeoCamera';
    String saveDirPath = '$basePath/$folderName';
    Directory saveDir = Directory(saveDirPath);
    if (!(await saveDir.exists())) {
      await saveDir.create(recursive: true);
    }
    String filePath = '${saveDir.path}/_IMG_${DateFormat('ddmmyyyy').format(DateTime.now())}_${DateFormat('HHMMSS').format(DateTime.now())}.jpg';

    // Save the image first
    await image.saveTo(filePath);

    // Get geolocation from Bloc
    final state = context.read<GeotagBloc>().state;
    double? latitude, longitude;
    if (state is GeotagLoaded) {
      latitude = state.latitude;
      longitude = state.longitude;
    }

    _savingPhoto(filePath);
    _loadFolders();
    _loadLastImage();
  }

  _savingPhoto(filePath) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved to $filePath')),
    );
  }

  @override
  void dispose() {
    // Restore orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _controller?.dispose();
    _locationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    final aspectRatio = _controller!.value.aspectRatio;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: CameraPreview(_controller!),
            ),
          ),
          BlocBuilder<GeotagBloc, GeotagState>(
            builder: (context, state) {
              if (state is GeotagLoaded) {
                return Positioned(
                  left: 16,
                  top: 32,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Lat: ${state.latitude.toStringAsFixed(6)}, Lng: ${state.longitude.toStringAsFixed(6)}, ±${state.accuracy.toStringAsFixed(1)} m',
                      style: TextStyle(color: state.accuracy >= 15.0 ? Colors.red : Colors.green, fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                );
              } else if (state is GeotagLoading) {
                return const Positioned(
                  left: 16,
                  top: 32,
                  child: CircularProgressIndicator(),
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
          // Google Camera style controls on the right
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Preview button
                  GestureDetector(
                    onTap: _onPreviewPressed,
                    child: Container(
                      width: 56,
                      height: 56,
                      margin: const EdgeInsets.only(bottom: 32),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        color: Colors.white.withOpacity(0.2),
                      ),
                      child: const Icon(Icons.grid_view, color: Colors.white, size: 32),
                    ),
                  ),
                  // Shutter button (white circle)
                  GestureDetector(
                    onTap: _capturePhoto,
                    child: Container(
                      width: 70,
                      height: 70,
                      margin: const EdgeInsets.only(bottom: 32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300, width: 4),
                      ),
                    ),
                  ),
                  // Spacer for future controls
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadLastImage();
  }

  Future<void> _loadLastImage() async {
    final now = DateTime.now();
    final folderName = DateFormat('MMM dd, yyyy').format(now);
    String saveDirPath = '/storage/emulated/0/DCIM/MIADP_GeoCamera/$folderName';
    final Directory saveDir = Directory(saveDirPath);
    if (await saveDir.exists()) {
      final files = saveDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.jpg'))
          .toList();
      files.sort((a, b) => b.path.compareTo(a.path));
      if (files.isNotEmpty) {
        setState(() {
          _lastImagePath = files.first.path;
        });
      }
    }
  }

  void _onPreviewPressed() async {
    String basePath = '/storage/emulated/0/DCIM/MIADP_GeoCamera';
    Directory baseDir = Directory(basePath);
    List<String> folders = [];
    await for (var entity in baseDir.list()) {
      if (entity is Directory) {
        folders.add(entity.path.split('/').last);
      }
    }
    folders.sort((a, b) => b.compareTo(a)); // newest first

    showDialog(
      context: context,
      builder: (context) {
        return DefaultTabController(
          length: folders.length,
          child: Dialog(
            backgroundColor: Colors.black87,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TabBar(
                  isScrollable: true,
                  tabs: folders.map((f) => Tab(text: f)).toList(),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.675,
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: TabBarView(
                    children: folders.map((folder) {
                      final dir = Directory('$basePath/$folder');
                      final images = dir
                          .listSync()
                          .whereType<File>()
                          .where((f) => f.path.endsWith('.jpg'))
                          .toList()
                        ..sort((a, b) => b.path.compareTo(a.path));
                      if (images.isEmpty) {
                        return const Center(child: Text('No images', style: TextStyle(color: Colors.white)));
                      }
                      return GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 8,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: images.length,
                        itemBuilder: (context, idx) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                              showDialog(
                                context: context,
                                builder: (_) => Dialog(
                                  backgroundColor: Colors.transparent,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.file(images[idx], fit: BoxFit.contain),
                                  ),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(images[idx], fit: BoxFit.cover),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  
}
