import 'package:equatable/equatable.dart';

abstract class GeotagEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class GetLocationEvent extends GeotagEvent {}
