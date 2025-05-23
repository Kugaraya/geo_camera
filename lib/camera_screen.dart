import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../bloc/geotag_bloc.dart';
import '../bloc/geotag_event.dart';
import '../bloc/geotag_state.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
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
  }

  Future<void> _initCamera() async {
    await Permission.camera.request();
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      final CameraDescription camera = _cameras![0];
      // The camera plugin does not expose FPS selection directly, but we use the highest available resolution
      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _controller!.initialize();
      setState(() {
        _isCameraInitialized = true;
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

  Future<void> _onCapturePressed() async {
    if (_controller != null && _controller!.value.isInitialized) {
      final image = await _controller!.takePicture();
      final now = DateTime.now();
      final dateFolder = DateFormat('yyyy-MM-dd').format(now);
      final Directory extDir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      final Directory miadpDir = Directory('${extDir.path}/MIADP/$dateFolder');
      if (!await miadpDir.exists()) {
        await miadpDir.create(recursive: true);
      }
      final String filePath = '${miadpDir.path}/IMG_${DateFormat('HHmmss').format(now)}.jpg';
      await image.saveTo(filePath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image saved to $filePath')),
        );
      }
      // Optionally, you can show a dialog or navigate to a preview screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.black,
        body: _isCameraInitialized
            ? Stack(
                children: [
                  Positioned.fill(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _controller!.value.previewSize?.height ?? 1,
                        height: _controller!.value.previewSize?.width ?? 1,
                        child: CameraPreview(_controller!),
                      ),
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
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
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
                      padding: const EdgeInsets.only(right: 32, bottom: 0, top: 0),
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
                              child: _lastImagePath != null
                                  ? ClipOval(
                                      child: Image.file(
                                        File(_lastImagePath!),
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(Icons.photo, color: Colors.white, size: 32),
                            ),
                          ),
                          // Shutter button
                          Container(
                            width: 80,
                            height: 80,
                            margin: const EdgeInsets.only(bottom: 32),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 6),
                              color: Colors.white.withOpacity(0.2),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.camera, size: 40, color: Colors.white),
                              onPressed: _onCapturePressed,
                            ),
                          ),
                          // Spacer for future controls
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : const Center(child: CircularProgressIndicator()),
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
    final dateFolder = DateFormat('yyyy-MM-dd').format(now);
    final Directory extDir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    final Directory miadpDir = Directory('${extDir.path}/MIADP/$dateFolder');
    if (await miadpDir.exists()) {
      final files = miadpDir
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

  void _onPreviewPressed() {
    if (_lastImagePath != null) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(File(_lastImagePath!), fit: BoxFit.contain),
          ),
        ),
      );
    }
  }
}
