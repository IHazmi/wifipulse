import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WiFi Pulse',
      home: WiFiHeatmapMainPage(),
    );
  }
}

class WiFiHeatmapMainPage extends StatelessWidget {
  // Mock current location (IIUM Gombak coordinates)
  final LatLng mockCurrentLocation = LatLng(6.278901, 100.413792);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WiFi Pulse (OSM)'),
        backgroundColor: Colors.blueAccent,
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: mockCurrentLocation, // Center the map on the mock location
          initialZoom: 16.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: mockCurrentLocation, // Pinpoint the mock location
                width: 40,
                height: 40,
                child: Icon(
                  Icons.location_pin, // Use a location pin icon
                  color: Colors.red,
                  size: 40,
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // You can add WiFi speed test logic here later
        },
        label: Text('Test My Spot'),
        icon: Icon(Icons.wifi_tethering),
      ),
    );
  }
}