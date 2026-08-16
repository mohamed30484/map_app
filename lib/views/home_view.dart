import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_maps/servicse/cubit/location_cubit.dart';
import 'package:google_maps/servicse/route_service.dart';
import 'package:latlong2/latlong.dart';

class Homeview extends StatefulWidget {
  const Homeview({super.key});

  @override
  State<Homeview> createState() => _HomeviewState();
}

class _HomeviewState extends State<Homeview> {
  final _mapController = MapController();
  final _searchController = TextEditingController();
  final _routeService = RouteService();

  LatLng? _currentPoint;
  LatLng? _destinationPoint;
  String? _destinationName;
  List<LatLng> _routePoints = [];
  double? _distanceMeters;
  double? _durationSeconds;
  bool _searching = false;
  bool _routing = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    await context.read<LocationCubit>().getLocation();
  }

  void _handleLocationState(LocationState state) {
    if (state is LocationSuccess) {
      final point = LatLng(state.position.latitude, state.position.longitude);
      setState(() => _currentPoint = point);
      _mapController.move(point, 15);
    }

    if (state is LocationFailure) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.error)));
    }
  }

  Future<void> _searchPlace() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _searching = true);

    try {
      final result = await _routeService.searchPlace(query);
      setState(() {
        _destinationPoint = result.point;
        _destinationName = result.name;
        _routePoints = [];
        _distanceMeters = null;
        _durationSeconds = null;
      });
      _mapController.move(result.point, 13);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _drawRoute() async {
    if (_currentPoint == null) {
      await _getCurrentLocation();
      if (!mounted || _currentPoint == null) return;
    }

    if (_destinationPoint == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ابحث عن الوجهة أولاً')));
      return;
    }

    setState(() => _routing = true);

    try {
      final result = await _routeService.getDrivingRoute(
        start: _currentPoint!,
        destination: _destinationPoint!,
      );

      setState(() {
        _routePoints = result.points;
        _distanceMeters = result.distanceMeters;
        _durationSeconds = result.durationSeconds;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _routing = false);
    }
  }

  void _clearRoute() {
    setState(() {
      _destinationPoint = null;
      _destinationName = null;
      _routePoints = [];
      _distanceMeters = null;
      _durationSeconds = null;
      _searchController.clear();
    });
  }

  String _distanceText() {
    if (_distanceMeters == null) return '--';
    if (_distanceMeters! >= 1000) {
      return '${(_distanceMeters! / 1000).toStringAsFixed(1)} km';
    }
    return '${_distanceMeters!.toStringAsFixed(0)} m';
  }

  String _durationText() {
    if (_durationSeconds == null) return '--';
    return '${(_durationSeconds! / 60).round()} min';
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LocationCubit, LocationState>(
      listener: (_, state) => _handleLocationState(state),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xff016ade),
          centerTitle: true,
          title: const Text(
            'Map Route Planner',
            style: TextStyle(color: Colors.white),
          ),
          leading: const Icon(Icons.menu, color: Colors.white),
          actions: const [
            Icon(Icons.layers_outlined, color: Colors.white),
            SizedBox(width: 12),
          ],
        ),
        body: Stack(
          children: [
            BlocBuilder<LocationCubit, LocationState>(
              builder: (_, state) {
                const fallback = LatLng(30.046750135, 31.196767378);
                final center = _currentPoint ?? fallback;

                return FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(initialCenter: center, initialZoom: 13),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.google_maps',
                    ),
                    if (_routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePoints,
                            strokeWidth: 5,
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        if (_currentPoint != null)
                          Marker(
                            point: _currentPoint!,
                            width: 48,
                            height: 48,
                            child: const Icon(
                              Icons.my_location,
                              color: Colors.blue,
                              size: 36,
                            ),
                          ),
                        if (_destinationPoint != null)
                          Marker(
                            point: _destinationPoint!,
                            width: 48,
                            height: 48,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 42,
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: Material(
                elevation: 5,
                borderRadius: BorderRadius.circular(12),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _searchPlace(),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن مكان...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _searchController.clear(),
                          ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 14,
              bottom: 190,
              child: FloatingActionButton(
                heroTag: 'gps',
                backgroundColor: Colors.white,
                onPressed: _getCurrentLocation,
                child: const Icon(Icons.my_location, color: Colors.blue),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: _InfoCard(
                destinationName: _destinationName,
                distance: _distanceText(),
                duration: _durationText(),
                routing: _routing,
                onRoute: _drawRoute,
                onClear: _clearRoute,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String? destinationName;
  final String distance;
  final String duration;
  final bool routing;
  final VoidCallback onRoute;
  final VoidCallback onClear;

  const _InfoCard({
    required this.destinationName,
    required this.distance,
    required this.duration,
    required this.routing,
    required this.onRoute,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Destination',
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(destinationName ?? 'ابحث عن وجهة لاختيارها'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('المسافة: $distance'), Text('الوقت: $duration')],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: routing ? null : onRoute,
                    child: routing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('ارسم الطريق'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onClear,
                    child: const Text('مسح'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
