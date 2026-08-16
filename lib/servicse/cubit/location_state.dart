part of 'location_cubit.dart';

abstract class LocationState {}

class LocationInitial extends LocationState {}

class LocationLoading extends LocationState {}

class LocationSuccess extends LocationState {
  final Position position;

  LocationSuccess(this.position);
}

class LocationFailure extends LocationState {
  final String error;

  LocationFailure(this.error);
}
