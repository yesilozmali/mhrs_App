import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ExistingAppointmentsScreen extends StatefulWidget {
  @override
  _ExistingAppointmentsScreenState createState() => _ExistingAppointmentsScreenState();
}

class _ExistingAppointmentsScreenState extends State<ExistingAppointmentsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  List<Map<dynamic, dynamic>> _appointments = [];
  bool _loading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  String _sanitizeEmail(String email) {
    return email.replaceAll('@', '_at_').replaceAll('.', '_dot_');
  }

  Future<void> _fetchAppointments() async {
    User? user = _auth.currentUser;
    if (user != null) {
      String sanitizedEmail = _sanitizeEmail(user.email!);

      try {
        final snapshot = await _database.child('appointments').get();
        if (snapshot.exists) {
          List<Map<dynamic, dynamic>> loadedAppointments = [];
          Map<dynamic, dynamic> appointmentsData = snapshot.value as Map<dynamic, dynamic>;

          appointmentsData.forEach((key, value) {
            if (value['email'] == sanitizedEmail) {
              loadedAppointments.add(value);
            }
          });

          setState(() {
            _appointments = loadedAppointments;
            _loading = false;
          });
        } else {
          setState(() {
            errorMessage = 'No appointments found.';
            _loading = false;
          });
        }
      } catch (e) {
        setState(() {
          errorMessage = 'Failed to fetch appointments.';
          _loading = false;
        });
        print(e.toString());
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Appointments'),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _appointments.isEmpty
          ? Center(child: Text('No appointments found.'))
          : ListView.builder(
        itemCount: _appointments.length,
        itemBuilder: (context, index) {
          final appointment = _appointments[index];
          return ListTile(
            title: Text('Date: ${appointment['date_time']}'),
            subtitle: Text('Email: ${appointment['email']}'),
          );
        },
      ),
    );
  }
}
