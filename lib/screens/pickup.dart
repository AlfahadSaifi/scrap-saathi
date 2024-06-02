import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:google_fonts/google_fonts.dart';

class Pickup extends StatefulWidget {
  const Pickup({Key? key}) : super(key: key);

  @override
  State<Pickup> createState() => _PickupState();
}

class _PickupState extends State<Pickup> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  List<PickupRequest> _pickupRequests = [];

  final DatabaseReference _database = FirebaseDatabase.instance.reference();

  final List<String> items = [
    'Newspaper',
    'Books',
    'Cardboard',
    'Plastic',
    'Iron',
    'Steel',
    'Aluminium',
    'Brass',
    'Copper',
    'GlassWare',
    'Tyres',
  ];
  Future<void> _sendEmail(String address, String date, String time) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      print('Error: User is not authenticated or email is null.');
      return;
    }

    final Email email = Email(
      body:
          'Your pickup request for $address on $date at $time has been received.',
      subject: 'Pickup Request Confirmation',
      recipients: [user.email!], // Use the user's email as the recipient
      isHTML: false,
    );

    try {
      await FlutterEmailSender.send(email);
      print('Message sent');
    } catch (e) {
      print('Error sending email: $e');
    }
  }

  Future<List<String>> _showMultiSelect(BuildContext context) async {
    final List<String> selectedItems = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return MultiSelectDialog(items: items);
      },
    );

    return selectedItems ?? [];
  }

  Future<void> _schedulePickup() async {
    if (_formKey.currentState!.validate()) {
      String address = _addressController.text;
      String selectedDate = _dateController.text;
      String selectedTime = _timeController.text;

      final selectedItems = await _showMultiSelect(context);
      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        return; // Handle unauthenticated user case
      }

      if (selectedItems.isNotEmpty) {
        // Add the pickup request to the list
        setState(() {
          _pickupRequests.add(
            PickupRequest(
              address: address,
              date: _selectedDate!,
              time: _selectedTime!,
              items: selectedItems,
            ),
          );
        });

        // Save to Firebase
        _database.child('pickupRequests').push().set({
          'userId': user.uid,
          'address': address,
          'date': selectedDate,
          'time': selectedTime,
          'items': selectedItems
              .asMap()
              .map((index, item) => MapEntry(index.toString(), item)),
        });

        // Send an email confirmation
        _sendEmail(address, selectedDate, selectedTime);

        print('Address: $address');
        print('Selected Date: $selectedDate');
        print('Selected Time: $selectedTime');
        print('Selected Items: $selectedItems');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Pickup",
          style: GoogleFonts.roboto(
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Select Address',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _dateController,
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(DateTime.now().year + 1),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _selectedDate = pickedDate;
                      _dateController.text =
                          '${pickedDate.day}/${pickedDate.month}/${pickedDate.year}';
                    });
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Select Date',
                ),
                readOnly: true,
                validator: (value) {
                  if (_selectedDate == null) {
                    return 'Please select a date';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _timeController,
                onTap: () async {
                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime ?? TimeOfDay.now(),
                  );
                  if (pickedTime != null) {
                    setState(() {
                      _selectedTime = pickedTime;
                      _timeController.text =
                          '${pickedTime.hour}:${pickedTime.minute}';
                    });
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Select Time',
                ),
                readOnly: true,
                validator: (value) {
                  if (_selectedTime == null) {
                    return 'Please select a time';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _schedulePickup,
                    child: Text(
                      'Schedule Pickup',
                      style: GoogleFonts.roboto(
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              Expanded(
                child: ListView.builder(
                  itemCount: _pickupRequests.length,
                  itemBuilder: (context, index) {
                    final request = _pickupRequests[index];
                    return ListTile(
                      title: Text(request.address),
                      subtitle: Text(
                        'Date: ${request.date.day}/${request.date.month}/${request.date.year}, Time: ${request.time.hour}:${request.time.minute}\nItems: ${request.items.join(', ')}',
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PickupRequest {
  final String address;
  final DateTime date;
  final TimeOfDay time;
  final List<String> items;

  PickupRequest({
    required this.address,
    required this.date,
    required this.time,
    required this.items,
  });

  factory PickupRequest.fromMap(Map<String, dynamic> data) {
    DateTime date = DateTime.parse(data['date']);
    List<String> items = List<String>.from(data['items'].values);
    TimeOfDay time = TimeOfDay(
      hour: int.parse(data['time'].split(":")[0]),
      minute: int.parse(data['time'].split(":")[1]),
    );
    return PickupRequest(
      address: data['address'],
      date: date,
      time: time,
      items: items,
    );
  }
}

class MultiSelectDialog extends StatefulWidget {
  final List<String> items;

  const MultiSelectDialog({Key? key, required this.items}) : super(key: key);

  @override
  _MultiSelectDialogState createState() => _MultiSelectDialogState();
}

class _MultiSelectDialogState extends State<MultiSelectDialog> {
  final List<String> _selectedItems = [];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select Items'),
      content: SingleChildScrollView(
        child: ListBody(
          children: widget.items.map((item) {
            return CheckboxListTile(
              value: _selectedItems.contains(item),
              title: Text(item),
              onChanged: (bool? selected) {
                setState(() {
                  if (selected == true) {
                    _selectedItems.add(item);
                  } else {
                    _selectedItems.remove(item);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          child: Text('Cancel'),
          onPressed: () {
            Navigator.pop(context, []);
          },
        ),
        TextButton(
          child: Text('OK'),
          onPressed: () {
            Navigator.pop(context, _selectedItems);
          },
        ),
      ],
    );
  }
}
