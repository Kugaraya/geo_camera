import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocam/camera_screen.dart';
import 'bloc/geotag_state.dart';
import 'bloc/geotag_bloc.dart';
import 'bloc/geotag_event.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GeotagBloc(),
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: const CameraScreen(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: BlocBuilder<GeotagBloc, GeotagState>(
                builder: (context, state) {
                  if (state is GeotagLoading) {
                    return const CircularProgressIndicator();
                  } else if (state is GeotagLoaded) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Latitude:  ${state.latitude}'),
                        Text('Longitude: ${state.longitude}'),
                        Text('Accuracy: ±${state.accuracy.toStringAsFixed(1)} m'),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            context.read<GeotagBloc>().add(GetLocationEvent());
                          },
                          child: const Text('Get Location'),
                        ),
                      ],
                    );
                  } else if (state is GeotagError) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: ${state.message}', style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            context.read<GeotagBloc>().add(GetLocationEvent());
                          },
                          child: const Text('Try Again'),
                        ),
                      ],
                    );
                  }
                  // Initial state
                  return ElevatedButton(
                    onPressed: () {
                      context.read<GeotagBloc>().add(GetLocationEvent());
                    },
                    child: const Text('Get Location'),
                  );
                },
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Open Camera'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CameraScreen()),
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
