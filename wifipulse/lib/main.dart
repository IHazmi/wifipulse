import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:network_speed/network_speed.dart';
import 'dart:async';


void main() {
  runApp(const WiFiPulseApp());
}

class WiFiPulseApp extends StatelessWidget {
  const WiFiPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WiFi Pulse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LocationMapPage(),
    );
  }
}

class LocationMapPage extends StatefulWidget {
  const LocationMapPage({super.key});

  @override
  State<LocationMapPage> createState() => _LocationMapPageState();
}

class _LocationMapPageState extends State<LocationMapPage> {
  LatLng? currentLocation;
  String wifiName = "Unknown";
  String wifiBSSID = "Unknown";
  String wifiIP = "Unknown";
  String speedStatus = "Not tested";
  double downloadSpeed = 0.0;
  double uploadSpeed = 0.0;
  bool isTesting = false;
  String networkType = "Unknown";
  int signalStrength = -1;
  
  // For real-time monitoring
  bool isMonitoring = false;
  StreamSubscription<Map<String, dynamic>>? networkSubscription;

  @override
  void initState() {
    super.initState();
    determinePosition();
    scanWifiInfo();
    getNetworkType();
  }

  @override
  void dispose() {
    networkSubscription?.cancel();
    super.dispose();
  }

  Future<void> determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      currentLocation = LatLng(position.latitude, position.longitude);
    });
  }

  Future<void> scanWifiInfo() async {
    final info = NetworkInfo();
    final ssid = await info.getWifiName();
    final bssid = await info.getWifiBSSID();
    final ip = await info.getWifiIP();

    setState(() {
      wifiName = ssid ?? 'Unavailable';
      wifiBSSID = bssid ?? 'Unavailable';
      wifiIP = ip ?? 'Unavailable';
    });
  }

  Future<void> getNetworkType() async {
    try {
      final type = await NetworkSpeed.getCurrentNetworkType();
      final info = await NetworkSpeed.getCurrentNetworkSpeed();
      
      setState(() {
        networkType = type.toString().split('.').last;
        signalStrength = info['signalStrength'] ?? -1;
      });
    } catch (e) {
      print('Error getting network type: $e');
    }
  }

  Future<void> runSpeedTest() async {
    setState(() {
      isTesting = true;
      downloadSpeed = 0.0;
      uploadSpeed = 0.0;
      speedStatus = "Starting download test...";
    });

    try {
      // Run download test
      downloadSpeed = await NetworkSpeed.runDownloadSpeedTest();
      setState(() {
        speedStatus = "Download complete! Testing upload...";
      });

      // Run upload test
      uploadSpeed = await NetworkSpeed.runUploadSpeedTest();
      setState(() {
        speedStatus = "Test complete!";
      });
    } catch (e) {
      setState(() {
        speedStatus = "Test failed: ${e.toString()}";
      });
    } finally {
      setState(() {
        isTesting = false;
      });
    }
  }

  void toggleRealTimeMonitoring() {
    if (isMonitoring) {
      networkSubscription?.cancel();
      setState(() {
        isMonitoring = false;
        speedStatus = "Monitoring stopped";
      });
    } else {
      setState(() {
        isMonitoring = true;
        speedStatus = "Monitoring started...";
      });
      
      networkSubscription = NetworkSpeed.getNetworkSpeedStream(interval: 1000).listen((data) {
        setState(() {
          downloadSpeed = data['downloadSpeed'] ?? 0.0;
          uploadSpeed = data['uploadSpeed'] ?? 0.0;
          networkType = data['networkType'].toString().split('.').last;
          signalStrength = data['signalStrength'] ?? -1;
          speedStatus = "Monitoring active - ${DateTime.now().toLocal().toString().substring(11, 19)}";
        });
      }, onError: (error) {
        setState(() {
          speedStatus = "Monitoring error: $error";
          isMonitoring = false;
        });
      });
    }
  }

  String getNetworkTypeIcon() {
    switch (networkType) {
      case 'wifi':
        return '📶';
      case 'mobile':
        return '📱';
      default:
        return '❓';
    }
  }

  String getSignalStrengthText() {
    switch (signalStrength) {
      case 4:
        return 'Excellent';
      case 3:
        return 'Good';
      case 2:
        return 'Fair';
      case 1:
        return 'Poor';
      case 0:
        return 'No Signal';
      default:
        return 'N/A';
    }
  }

  Color getSpeedColor(double speed) {
    if (speed <= 0) return Colors.grey;
    if (speed < 1) return Colors.red;
    if (speed < 5) return Colors.orange;
    if (speed < 20) return Colors.yellow.shade800;
    if (speed < 50) return Colors.green;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WiFi Pulse'),
        actions: [
          IconButton(
            icon: Icon(isMonitoring ? Icons.stop : Icons.play_arrow),
            onPressed: toggleRealTimeMonitoring,
            tooltip: isMonitoring ? 'Stop monitoring' : 'Start real-time monitoring',
          ),
        ],
      ),
      body: currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: currentLocation!,
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
                            point: currentLocation!,
                            width: 50,
                            height: 50,
                            child: const Icon(Icons.my_location, color: Colors.red, size: 40),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Network Information
                      Row(
                        children: [
                          Text(getNetworkTypeIcon(), style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("WiFi: $wifiName", style: const TextStyle(fontSize: 16)),
                              Text("IP: $wifiIP", style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                          const Spacer(),
                          if (networkType == 'wifi' && signalStrength != -1)
                            Row(
                              children: [
                                Text(getSignalStrengthText()),
                                const SizedBox(width: 8),
                                ...List.generate(
                                  5,
                                  (i) => Icon(
                                    Icons.signal_cellular_alt,
                                    size: 16,
                                    color: i <= signalStrength
                                        ? Colors.green
                                        : Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Speed Test Results
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              const Text("Download", style: TextStyle(fontSize: 16)),
                              Text("${downloadSpeed.toStringAsFixed(2)} Mbps",
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: getSpeedColor(downloadSpeed),
                                  )),
                            ],
                          ),
                          Column(
                            children: [
                              const Text("Upload", style: TextStyle(fontSize: 16)),
                              Text("${uploadSpeed.toStringAsFixed(2)} Mbps",
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: getSpeedColor(uploadSpeed),
                                  )),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Status and Controls
                      Text("Status: $speedStatus", style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      if (isMonitoring)
                        LinearProgressIndicator(
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        )
                      else if (isTesting)
                        const LinearProgressIndicator(),
                      const SizedBox(height: 16),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              await scanWifiInfo();
                              await getNetworkType();
                            },
                            child: const Text("Refresh Info"),
                          ),
                          ElevatedButton(
                            onPressed: isTesting || isMonitoring ? null : runSpeedTest,
                            child: isTesting
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  )
                                : const Text("Run Speed Test"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}