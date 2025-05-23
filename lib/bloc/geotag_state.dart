import 'package:equatable/equatable.dart';

abstract class GeotagState extends Equatable {
  @override
  List<Object?> get props => [];
}

class GeotagInitial extends GeotagState {}

class GeotagLoading extends GeotagState {}

class GeotagLoaded extends GeotagState {
  final double latitude;
  final double longitude;
  final double accuracy;

  GeotagLoaded({required this.latitude, required this.longitude, required this.accuracy});

  @override
  List<Object?> get props => [latitude, longitude, accuracy];
}

class GeotagError extends GeotagState {
  final String message;

  GeotagError({required this.message});

  @override
  List<Object?> get props => [message];
}
