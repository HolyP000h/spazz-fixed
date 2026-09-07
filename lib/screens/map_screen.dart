import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart';
import 'subscription_screen.dart';
import '../widgets/ping_system.dart';
import '../widgets/spazz_radar.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'hunt_state_screens.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Position? _myPosition;
  double _heading = 0.0;
  bool _loading = false;
  bool _isPremium = false;
  String _token = ''; 
  String _userId = '';
  String _username = '';

  Set<Marker> _markers = {};
  Set<Circle> _hotspotCircles = {};
  final Set<Circle> _pingWaves = {};

  List<dynamic> _nearbyUsers = [];
  List<dynamic> _wisps = [];
  List<dynamic> _hotspots = [];

  // Spazz Match State
  Map<String, dynamic>? _activeMatch;
  double? _lastDistance;
  bool _isHunting = false;
  Map<String, dynamic> _myPrefs = {};
  bool _showSpazzFlash = false;
  double _intensity = 0.0;

  // Ping state
  List<String> _ownedPings = [];
  String _activePingId = 'ping_default';
  final List<PingData> _incomingPings = [];
  Timer? _pingPollTimer;

  Timer? _locationTimer;
  Timer? _fetchTimer;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _fetchTimer?.cancel();
    _pingPollTimer?.cancel();
    _positionStream?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    
    final prefs = await SharedPreferences.getInstance();
    _myPrefs = await AuthService.getPreferences();
    
    _token = prefs.getString('token') ?? '';
    _userId = prefs.getString('user_id') ?? '';
    _username = prefs.getString('username') ?? 'Hunter';
    _activePingId = prefs.getString('active_ping') ?? 'ping_default';

    try {
      final res = await ApiService.get('/api/user/$_userId');
      if (res != null) {
        setState(() {
          _isPremium = res['is_premium'] ?? false;
          _ownedPings = List<String>.from(res['inventory'] ?? [])
              .where((id) => id.startsWith('ping_'))
              .toList();
        });
      }
    } catch (_) {}

    await _getLocation();

    // Smooth position updates
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2,
      ),
    ).listen((Position pos) {
      if (mounted) {
        setState(() {
          _myPosition = pos;
          _heading = pos.heading;
        });
        _updateCamera();
        if (_isHunting) _updateHuntStatus();
      }
    });

    _locationTimer = Timer.periodic(const Duration(seconds: 10), (_) => _pingLocation());
    _fetchTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchNearby());
    _pingPollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _pollPings());

    await _fetchNearby();
    setState(() => _loading = false);
  }

  Future<void> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() {
        _myPosition = pos;
        _heading = pos.heading;
      });
      await _pingLocation();
      _updateCamera();
      if (_isHunting) _updateHuntStatus();
    } catch (_) {}
  }

  void _updateCamera() {
    if (_mapController == null || _myPosition == null) return;
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(_myPosition!.latitude, _myPosition!.longitude),
          zoom: 18.0,
          tilt: 65.0, // 1st person tilt
          bearing: _heading, // Follow heading
        ),
      ),
    );
  }

  Future<void> _pingLocation() async {
    if (_myPosition == null) return;
    try {
      await ApiService.post('/api/location/update', {
        'user_id': _userId,
        'lat': _myPosition!.latitude,
        'lng': _myPosition!.longitude,
      });
    } catch (_) {}
  }

  Future<void> _fetchNearby() async {
    if (_myPosition == null) return;

    if (!(_myPrefs['is_broadcasting'] ?? false)) {
      _buildMockMarkers();
      return;
    }

    try {
      final res = await ApiService.get(
        '/api/nearby?lat=${_myPosition!.latitude}&lng=${_myPosition!.longitude}&user_id=$_userId'
      );
      
      if (res != null) {
        final users = (res['users'] as List?) ?? [];
        
        // Offset mock users so they aren't exactly on top of us if 0.0
        final processedUsers = users.map((u) {
          if (u['lat'] == 0.0) {
            u['lat'] = _myPosition!.latitude + 0.0003;
            u['lng'] = _myPosition!.longitude + 0.0003;
          }
          return u;
        }).toList();

        setState(() {
          _nearbyUsers = processedUsers;
          _wisps = res['wisps'] ?? [];
          _hotspots = res['hotspots'] ?? [];
        });
        
        _buildMarkers();
        _checkForMatches();
      }
    } catch (_) {
      _buildMockMarkers();
    }
  }

  void _checkForMatches() async {
    if (_isHunting || _myPosition == null) return;

    for (var user in _nearbyUsers) {
      final genderMatch = _myPrefs['interested_in'] == 'Both' || user['gender'] == _myPrefs['interested_in'];
      final ageMatch = user['age'] >= (_myPrefs['min_age'] ?? 18) && user['age'] <= (_myPrefs['max_age'] ?? 99);
      
      if (genderMatch && ageMatch && user['is_broadcasting'] == true) {
        double dist = Geolocator.distanceBetween(
          _myPosition!.latitude, _myPosition!.longitude, 
          user['lat'], user['lng']
        );

        if (dist < 50) {
          _triggerSpazzAlert(user);
          break;
        }
      }
    }
  }

  void _triggerSpazzAlert(Map<String, dynamic> user) async {
    setState(() => _showSpazzFlash = true);
    for (int i = 0; i < 4; i++) {
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
    }
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => _showSpazzFlash = false);

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => HuntDetectedScreen(
          detectedUsername: user['username'], 
          isPremium: user['is_premium'] ?? false
        ),
      ).then((_) => _startHunt(user));
    }
  }

  void _startHunt(Map<String, dynamic> user) {
    setState(() {
      _activeMatch = user;
      _isHunting = true;
    });
    _updateHuntStatus();
  }

  void _updateHuntStatus() {
    if (!_isHunting || _activeMatch == null || _myPosition == null) return;

    double dist = Geolocator.distanceBetween(
      _myPosition!.latitude, _myPosition!.longitude, 
      _activeMatch!['lat'], _activeMatch!['lng']
    );

    setState(() {
      _intensity = (1.0 - (dist / 100)).clamp(0.0, 1.0);
    });

    bool isCloser = _lastDistance == null || dist < _lastDistance!;
    _lastDistance = dist;

    // Trigger directional haptics
    if (isCloser) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }

    if (dist < 5) {
      _completeEncounter();
    } else {
      // Show hot/cold overlay
      _showHuntOverlay(dist, isCloser);
    }
  }

  void _showHuntOverlay(double dist, bool isCloser) {
    // In a real app, this might be a persistent overlay. 
    // For this prototype, we'll use a snackbar or a temporary dialog if not already shown.
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isCloser ? '🔥 GETTING WARMER: ${dist.toInt()}m' : '❄️ GETTING COLDER: ${dist.toInt()}m',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isCloser ? Colors.orange : Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _completeEncounter() async {
    setState(() {
      _isHunting = false;
      _intensity = 0.0;
    });
    
    // BAM - Face to face intense haptics
    for (int i = 0; i < 8; i++) {
      HapticFeedback.vibrate();
      await Future.delayed(const Duration(milliseconds: 50));
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => HuntConnectionScreen(
          connectedUsername: _activeMatch!['username'], 
          isPremium: _activeMatch!['is_premium'] ?? false
        ),
      );
    }
    
    await ApiService.post('/api/encounter/success', {'target_id': _activeMatch!['id']});
    _activeMatch = null;
    _lastDistance = null;
  }

  Future<void> _pollPings() async {
    if (_myPosition == null) return;
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/api/ping/nearby?lat=${_myPosition!.latitude}&lng=${_myPosition!.longitude}'),
        headers: {'Authorization': 'Bearer $_token'},
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final pings = (data['pings'] as List?) ?? [];
        for (final p in pings) {
          final ping = PingData.fromJson(p);
          // Only show if we haven't shown it already
          final alreadyShown = _incomingPings.any((ip) => ip.id == ping.id);
          if (!alreadyShown) {
            _showIncomingPing(ping);
          }
        }
      }
    } catch (_) {}
  }

  void _showIncomingPing(PingData ping) {
    setState(() => _incomingPings.add(ping));
    // Animate a ripple wave on the map at the ping origin
    _addPingWave(ping);
  }

  void _addPingWave(PingData ping) {
    final pingDef = PingDefinitions.getById(ping.pingId);
    final priority = pingDef?['priority'] as int? ?? 1;
    final color = _priorityColor(priority);

    final waveId = 'wave_${ping.id}';
    setState(() {
      _pingWaves.add(Circle(
        circleId: CircleId(waveId),
        center: LatLng(ping.lat, ping.lng),
        radius: 80 + (priority * 40).toDouble(),
        fillColor: color.withValues(alpha: 0.15),
        strokeColor: color.withValues(alpha: 0.6),
        strokeWidth: 2,
      ));
    });

    // Fade wave out after 4s
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _pingWaves.removeWhere((c) => c.circleId.value == waveId));
      }
    });
  }

  Color _priorityColor(int priority) {
    switch (priority) {
      case 5: return const Color(0xFFFFD700);
      case 4: return const Color(0xFFFF4500);
      case 3: return const Color(0xFF7C3AED);
      case 2: return const Color(0xFF00BFFF);
      default: return const Color(0xFF444460);
    }
  }

  void _buildMarkers() {
    final markers = <Marker>{};
    final circles = <Circle>{};

    if (_myPosition != null) {
      markers.add(Marker(
        markerId: const MarkerId('me'),
        position: LatLng(_myPosition!.latitude, _myPosition!.longitude),
        infoWindow: InfoWindow(title: 'You ($_username)'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
      ));
    }

    for (final user in _nearbyUsers) {
      // Boss users get a golden hue
      final isBoss = user['is_premium'] ?? false;
      markers.add(Marker(
        markerId: MarkerId('user_${user['id']}'),
        position: LatLng(user['lat'], user['lng']),
        infoWindow: InfoWindow(title: '${isBoss ? '👑 ' : ''}${user['username'] ?? 'Hunter'}'),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isBoss ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueBlue,
        ),
      ));
    }

    for (final wisp in _wisps) {
      markers.add(Marker(
        markerId: MarkerId('wisp_${wisp['id']}'),
        position: LatLng(wisp['lat'], wisp['lng']),
        infoWindow: InfoWindow(title: '✨ Wisp', snippet: '+${wisp['xp'] ?? 10} XP'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        onTap: () => _collectWisp(wisp),
      ));
    }

    if (_isPremium) {
      for (final hotspot in _hotspots) {
        final intensity = (hotspot['visit_count'] ?? 1).toDouble();
        circles.add(Circle(
          circleId: CircleId('hotspot_${hotspot['id']}'),
          center: LatLng(hotspot['lat'], hotspot['lng']),
          radius: (50 + (intensity * 10).clamp(0, 200)).toDouble(),
          fillColor: Color.fromRGBO(255, (50 - intensity * 5).clamp(0, 50).toInt(), 0,
              (0.1 + intensity * 0.05).clamp(0.1, 0.5)),
          strokeColor: Colors.transparent,
          strokeWidth: 0,
        ));
      }
    }

    setState(() {
      _markers = markers;
      _hotspotCircles = circles;
    });
  }

  void _buildMockMarkers() {
    if (_myPosition == null) return;
    final rand = Random();
    final markers = <Marker>{};
    final circles = <Circle>{};

    markers.add(Marker(
      markerId: const MarkerId('me'),
      position: LatLng(_myPosition!.latitude, _myPosition!.longitude),
      infoWindow: const InfoWindow(title: 'You'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
    ));

    for (int i = 0; i < 3; i++) {
      final lat = _myPosition!.latitude + (rand.nextDouble() - 0.5) * 0.01;
      final lng = _myPosition!.longitude + (rand.nextDouble() - 0.5) * 0.01;
      markers.add(Marker(
        markerId: MarkerId('mock_user_$i'),
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(title: 'Hunter ${i + 1}'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ));
    }

    for (int i = 0; i < 5; i++) {
      final lat = _myPosition!.latitude + (rand.nextDouble() - 0.5) * 0.008;
      final lng = _myPosition!.longitude + (rand.nextDouble() - 0.5) * 0.008;
      markers.add(Marker(
        markerId: MarkerId('mock_wisp_$i'),
        position: LatLng(lat, lng),
        infoWindow: const InfoWindow(title: '✨ Wisp', snippet: '+10 XP'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
      ));
    }

    if (_isPremium) {
      for (int i = 0; i < 3; i++) {
        final lat = _myPosition!.latitude + (rand.nextDouble() - 0.5) * 0.015;
        final lng = _myPosition!.longitude + (rand.nextDouble() - 0.5) * 0.015;
        circles.add(Circle(
          circleId: CircleId('mock_hotspot_$i'),
          center: LatLng(lat, lng),
          radius: 80 + rand.nextDouble() * 120,
          fillColor: const Color.fromRGBO(255, 50, 0, 0.25),
          strokeColor: Colors.transparent,
          strokeWidth: 0,
        ));
      }
    }

    setState(() {
      _markers = markers;
      _hotspotCircles = circles;
    });
  }

  Future<void> _collectWisp(Map<String, dynamic> wisp) async {
    try {
      await ApiService.post('/api/wisp/collect', {'wisp_id': wisp['id'], 'user_id': _userId});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✨ Wisp collected! +${wisp['credits'] ?? 5} Spazz Coins'),
            backgroundColor: const Color(0xFF7C3AED),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      _fetchNearby();
    } catch (_) {}
  }

  void _onPingSent(PingData ping) {
    // Animate ripple from MY position on the map
    _addPingWave(ping);
    // Center map briefly on self
    if (_myPosition != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_myPosition!.latitude, _myPosition!.longitude),
          15.5,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allCircles = {..._hotspotCircles, ..._pingWaves};

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          // ── MAP ──────────────────────────────────────────────────
          (_myPosition == null || _loading)
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF7C3AED)),
                      const SizedBox(height: 16),
                      Text(
                        _loading ? 'Loading nearby players...' : 'Getting your location...',
                        style: const TextStyle(color: Color(0xFF888899)),
                      ),
                    ],
                  ),
                )
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(_myPosition!.latitude, _myPosition!.longitude),
                    zoom: 18.0,
                    tilt: 65.0,
                    bearing: _heading,
                  ),
                  onMapCreated: (c) => _mapController = c,
                  markers: _markers,
                  circles: allCircles,
                  myLocationEnabled: false, // Use custom radar arrow
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapType: MapType.normal,
                  style: _darkMapStyle,
                ),

          // ── SPAZZ RADAR OVERLAY ──────────────────────────────────
          if (_myPosition != null)
            IgnorePointer(
              child: Center(
                child: SpazzRadar(
                  intensity: _isHunting ? _intensity : 0.1,
                  showLightning: _isHunting && _intensity > 0.7,
                  heading: _heading,
                ),
              ),
            ),

          // ── TOP BAR ──────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Live users count
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xCC13131A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(
                              color: Color(0xFF22C55E), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text('${_nearbyUsers.length} nearby',
                            style: const TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Heatmap toggle
                  GestureDetector(
                    onTap: () {
                      if (!_isPremium) {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _isPremium ? const Color(0xCC7C3AED) : const Color(0xCC13131A),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isPremium ? const Color(0xFF7C3AED) : const Color(0xFF444460),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text(
                            _isPremium ? 'Heatmap ON' : 'Heatmap 👑',
                            style: TextStyle(
                              color: _isPremium ? Colors.white : const Color(0xFF888899),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── INCOMING PING OVERLAYS ────────────────────────────────
          if (_incomingPings.isNotEmpty)
            Positioned(
              top: 90,
              left: 0,
              right: 0,
              child: Column(
                children: _incomingPings.map((ping) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: IncomingPingOverlay(
                      ping: ping,
                      onDismiss: () => setState(() => _incomingPings.remove(ping)),
                    ),
                  );
                }).toList(),
              ),
            ),

          // ── PING BUTTON (bottom right) ────────────────────────────
          if (_myPosition != null)
            Positioned(
              bottom: 90,
              right: 20,
              child: PingButton(
                lat: _myPosition!.latitude,
                lng: _myPosition!.longitude,
                ownedPings: _ownedPings,
                activePingId: _activePingId,
                onPingSent: _onPingSent,
              ),
            ),

          // ── RECENTER BUTTON ───────────────────────────────────────
          if (_myPosition != null)
            Positioned(
              bottom: 90,
              left: 20,
              child: GestureDetector(
                onTap: () => _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(_myPosition!.latitude, _myPosition!.longitude),
                    15.5,
                  ),
                ),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xCC13131A),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF1E1E2E)),
                  ),
                  child: const Icon(Icons.my_location, color: Colors.white, size: 20),
                ),
              ),
            ),

          // ── BOTTOM LEGEND ─────────────────────────────────────────
          Positioned(
            bottom: 20,
            left: 70,
            right: 70,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xCC13131A),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _LegendItem(color: const Color(0xFF7C3AED), label: 'You'),
                  _LegendItem(color: Colors.orange, label: 'Boss'),
                  _LegendItem(color: Colors.blue, label: 'Hunter'),
                  _LegendItem(color: Colors.yellow, label: 'Wisp'),
                  if (_isPremium)
                    _LegendItem(color: Colors.deepOrange, label: 'Hot'),
                ],
              ),
            ),
          ),

          // ── SPAZZ FLASH OVERLAY ──────────────────────────────────
          if (_showSpazzFlash)
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: _showSpazzFlash ? 0.8 : 0.0,
                duration: const Duration(milliseconds: 100),
                child: Container(
                  color: Colors.white,
                  child: const Center(
                    child: Text('MATCH NEARBY!', 
                      style: TextStyle(color: Colors.black, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2)
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
      ],
    );
  }
}

const _darkMapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#0A0A0F"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#746855"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#242f3e"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#1E1E2E"}]},
  {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#212a37"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#2a2a3a"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#0d1b2a"}]},
  {"featureType": "poi", "elementType": "geometry", "stylers": [{"color": "#13131A"}]},
  {"featureType": "transit", "elementType": "geometry", "stylers": [{"color": "#2f3948"}]}
]
''';
