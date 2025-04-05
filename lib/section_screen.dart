import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:navobs/message_form_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
class SectionScreen extends StatefulWidget {
  final int sectionIndex;
  final List<String> itemsInMenu;
  final bool isUnverified;
  final bool canEdit;
  
  const SectionScreen({
    super.key,
    required this.sectionIndex,
    required this.itemsInMenu,
    required this.isUnverified,
    required this.canEdit,
  });

  @override
  _SectionScreenState createState() => _SectionScreenState();
}

class _SectionScreenState extends State<SectionScreen> {
  late final Stream<QuerySnapshot> _messagesStream;

  @override
  void initState() {
    super.initState();
    _messagesStream = FirebaseFirestore.instance
        .collection(widget.isUnverified ? 'unverifiedMessages' : 'verifiedMessages')
        .where('section', isEqualTo: widget.itemsInMenu[widget.sectionIndex])
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  void _openMessageForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessageFormScreen(
          sectionName: widget.itemsInMenu[widget.sectionIndex],
          isUnverified: widget.isUnverified,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.itemsInMenu[widget.sectionIndex]),
      ),
      floatingActionButton: widget.canEdit
          ? FloatingActionButton(
              onPressed: _openMessageForm,
              child: const Icon(Icons.add),
            )
          : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: _messagesStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final messages = snapshot.data?.docs ?? [];
          if (messages.isEmpty) {
            return const Center(child: Text("No messages found"));
          }

          return ListView.builder(
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              final timestamp = message['timestamp'] as Timestamp?;
              final formattedTime = timestamp != null 
                  ? DateFormat('MMM dd, hh:mm a').format(timestamp.toDate())
                  : 'No timestamp';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(message['brief']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message['message'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (message['locationName'] != null)
                        Text(
                          'Location: ${message['locationName']}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      Text(
                        'Sent: $formattedTime',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    _showMessageDetails(context, message, formattedTime);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showMessageDetails(BuildContext context, QueryDocumentSnapshot message, String formattedTime) {
    final location = message['location'] as GeoPoint?;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message['brief']),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message['message']),
              const SizedBox(height: 16),
              if (location != null) ...[
                const Text(
                  'Location:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(message['locationName'] ?? 
                    '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(location.latitude, location.longitude),
                      zoom: 14,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('messageLocation'),
                        position: LatLng(location.latitude, location.longitude),
                      ),
                    },
                    myLocationEnabled: true,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                'Sent: $formattedTime',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (widget.canEdit)
            TextButton(
              onPressed: () async {
                await message.reference.delete();
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }
}