import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import 'package:neopay_ai/core/models/agent_model.dart';
import 'package:neopay_ai/core/services/location_service.dart';

class LocatorScreen extends StatefulWidget {
  @override
  _LocatorScreenState createState() => _LocatorScreenState();
}

class _LocatorScreenState extends State<LocatorScreen> {
  late LocationService _locationService;
  double _userLat = 0.0;
  double _userLon = 0.0;
  bool _locationFetched = false;

  @override
  void initState() {
    super.initState();
    _locationService = LocationService();
    _initializeService();
  }

  Future<void> _initializeService() async {
    await _locationService.seedGlobalAgentsIfEmpty();
    await _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _locationFetched = true);
        return;
      }

      final currentLocation = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _userLat = currentLocation.latitude;
        _userLon = currentLocation.longitude;
        _locationFetched = true;
      });
    } catch (e) {
      setState(() => _locationFetched = true);
      print('Error getting user location: $e');
    }
  }

  double radians(double degrees) {
    return degrees * (math.pi / 180);
  }

  double calculateHaversineDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = radians(lat2 - lat1);
    final dLon = radians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(radians(lat1)) *
            math.cos(radians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text('Nearby Agents'),
            floating: true,
            snap: true,
            backgroundColor: Theme.of(context).primaryColor,
          ),
          if (!_locationFetched)
            SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            StreamBuilder<List<AgentModel>>(
              stream: _locationService.getAgentsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Text('Error loading agents: ${snapshot.error}'),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(child: Text('No agents available')),
                  );
                }

                final agents = snapshot.data!;
                final agentsWithDistance = agents.map((agent) {
                  final distance = calculateHaversineDistance(
                    _userLat,
                    _userLon,
                    agent.latitude,
                    agent.longitude,
                  );
                  return {
                    'agent': agent,
                    'distance': distance,
                  };
                }).toList();

                agentsWithDistance.sort((a, b) =>
                    (a['distance'] as double)
                        .compareTo(b['distance'] as double));

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final item = agentsWithDistance[i];
                      final agent = item['agent'] as AgentModel;
                      final distance =
                          (item['distance'] as double).toStringAsFixed(1);
                      return ListTile(
                        title: Text('${agent.name} - $distance km'),
                        subtitle: Text(agent.city),
                        trailing: Icon(Icons.location_pin),
                      );
                    },
                    childCount: agentsWithDistance.length,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}