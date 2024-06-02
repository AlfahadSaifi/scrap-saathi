import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart'; // Import intl package for date formatting
import 'package:google_fonts/google_fonts.dart';

class PickupRequest {
  final String key;
  final String address;
  final DateTime date;
  final TimeOfDay time;
  final List<String> items; // Add items field

  PickupRequest({
    required this.key,
    required this.address,
    required this.date,
    required this.time,
    required this.items, // Add items to constructor
  });

  factory PickupRequest.fromMap(String key, Map<String, dynamic> data) {
    DateTime date;
    try {
      date = DateFormat('dd/MM/yyyy')
          .parse(data['date']); // Update this line to match your date format
    } catch (e) {
      // Handle parsing errors by setting the date to a default value
      date = DateTime.now();
      print('Error parsing date: $e');
    }

    TimeOfDay time;
    try {
      time = TimeOfDay(
        hour: int.parse(data['time'].split(":")[0]),
        minute: int.parse(data['time'].split(":")[1]),
      );
    } catch (e) {
      time = TimeOfDay.now();
      print('Error parsing time: $e');
    }

    List<String> items;
    try {
      items = List<String>.from(data['items']); // Update this line
    } catch (e) {
      items = [];
      print('Error parsing items: $e');
    }

    return PickupRequest(
      key: key,
      address: data['address'] ?? '',
      date: date,
      time: time,
      items: items, // Initialize items
    );
  }
}

class PickupListScreen extends StatelessWidget {
  const PickupListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not authenticated')),
      );
    }

    Query pickupRequestsRef = FirebaseDatabase.instance
        .reference()
        .child('pickupRequests')
        .orderByChild('userId')
        .equalTo(user.uid);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightGreen,
        title: Text(
          "Pickup Requests",
          style: GoogleFonts.roboto(
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: pickupRequestsRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("No pickup requests found"));
          }

          Map<dynamic, dynamic> data =
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          List<PickupRequest> requests = data.entries.map((entry) {
            return PickupRequest.fromMap(
                entry.key, Map<String, dynamic>.from(entry.value));
          }).toList();

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Pickup Details'),
                        content: SingleChildScrollView(
                          child: ListBody(
                            children: <Widget>[
                              Text('Address: ${request.address}'),
                              Text(
                                  'Date: ${request.date.day}/${request.date.month}/${request.date.year}'),
                              Text(
                                  'Time: ${request.time.hour}:${request.time.minute}'),
                              Text('Items: ${request.items.join(', ')}'),
                            ],
                          ),
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              // Delete the pickup request
                              FirebaseDatabase.instance
                                  .reference()
                                  .child('pickupRequests')
                                  .child(request.key)
                                  .remove();
                              Navigator.of(context).pop();
                            },
                            child: Text('Delete'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('Close'),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: ListTile(
                    tileColor: Colors.white,
                    title: Text(
                      request.address,
                      style: GoogleFonts.roboto(
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    subtitle: Text(
                      'Date: ${request.date.day}/${request.date.month}/${request.date.year}, '
                      'Time: ${request.time.hour}:${request.time.minute}',
                      style: GoogleFonts.roboto(
                        textStyle: const TextStyle(
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
