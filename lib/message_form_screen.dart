import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
class MessageFormScreen extends StatefulWidget {
  final String sectionName;
  final bool isUnverified;
  const MessageFormScreen({
    super.key,
    required this.sectionName,
    required this.isUnverified,
  });

  @override
  _MessageFormScreenState createState() => _MessageFormScreenState();
}

class _MessageFormScreenState extends State<MessageFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _briefController = TextEditingController();
  final _messageController = TextEditingController();
  LatLng? _selectedLocation;
  String _locationName = 'No location selected';
  bool _isGettingLocation = false;
  bool _isSubmitting = false;

  Future<void> _selectLocation() async {
    setState(() => _isGettingLocation = true);
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are permanently denied')),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);
      
      final address = await _getAddressFromLatLng(latLng);
      
      setState(() {
        _selectedLocation = latLng;
        _locationName = address;
        _isGettingLocation = false;
      });
    } catch (e) {
      setState(() => _isGettingLocation = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: ${e.toString()}')),
      );
    }
  }

  Future<String> _getAddressFromLatLng(LatLng latLng) async {
    try {
      const apiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${latLng.latitude},${latLng.longitude}&key=$apiKey'
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['results'][0]['formatted_address'] ?? 
            'Location (${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)})';
      }
      return 'Location (${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)})';
    } catch (e) {
      return 'Location (${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)})';
    }
  }

  Future<void> _submitMessage() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final messageData = {
        'section': widget.sectionName,
        'brief': _briefController.text,
        'message': _messageController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'isVerified': !widget.isUnverified,
      };

      if (_selectedLocation != null) {
        messageData['location'] = GeoPoint(
          _selectedLocation!.latitude,
          _selectedLocation!.longitude,
        );
        messageData['locationName'] = _locationName;
      }

      await FirebaseFirestore.instance
          .collection(widget.isUnverified ? 'unverifiedMessages' : 'verifiedMessages')
          .add(messageData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Message submitted successfully!")),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to submit message: ${e.toString()}")),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _briefController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Message"),
        actions: [
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _isSubmitting ? null : _submitMessage,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _briefController,
                decoration: const InputDecoration(
                  labelText: 'Brief',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Please enter brief' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) => value?.isEmpty ?? true ? 'Please enter message' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: Text(_locationName),
                subtitle: _selectedLocation != null
                    ? Text('Lat: ${_selectedLocation!.latitude.toStringAsFixed(4)}, '
                        'Lng: ${_selectedLocation!.longitude.toStringAsFixed(4)}')
                    : null,
                trailing: _isGettingLocation
                    ? const CircularProgressIndicator()
                    : IconButton(
                        icon: const Icon(Icons.edit_location),
                        onPressed: _selectLocation,
                      ),
              ),
              if (_selectedLocation != null)
                SizedBox(
                  height: 200,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _selectedLocation!,
                      zoom: 14,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('selectedLocation'),
                        position: _selectedLocation!,
                      ),
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitMessage,
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text('Submit Message'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}