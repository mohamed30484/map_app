import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps/servicse/cubit/location_cubit.dart';
import 'package:latlong2/latlong.dart';

class Homeview extends StatelessWidget {
  const Homeview({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xff016ade),
        centerTitle: true,
        title: const Text(
          'Maps Route Planner',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          onPressed: () {},
          icon: Icon(Icons.menu),
          color: Colors.white,
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.layers_outlined),
            color: Colors.white,
            iconSize: 24,
          ),
        ],
      ),
      body: BlocBuilder<LocationCubit, LocationState>(
        builder: (context, state) {
          Position? position;

          if (state is LocationSuccess) {
            position = state.position;
          }
          return FlutterMap(
            mapController: MapController(),
            options: MapOptions(
              initialCenter: position == null
                  ? LatLng(30.046750135036035, 31.196767378508515)
                  : LatLng(position.latitude, position.longitude),

              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://api.thunderforest.com/cycle/{z}/{x}/{y}.png?apikey=8ea47ba878414ef4bb25e6af10cc751a',
                userAgentPackageName: 'com.example.maps_app',
                subdomains: ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: [
                  if (position != null)
                    Marker(
                      point: LatLng(position.latitude, position.longitude),
                      child: Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  Marker(
                    point: LatLng(30.046750135036035, 31.196767378508515),
                    child: Icon(Icons.location_on),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
