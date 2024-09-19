import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExistingAppointmentsScreen extends StatefulWidget {
  @override
  _MyAppointmentsScreenState createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<ExistingAppointmentsScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _userId;
  List<Map<String, dynamic>> _appointments = [];

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    User? user = _auth.currentUser;
    if (user != null) {
      String sanitizedEmail = user.email!.replaceAll('@', '_at_').replaceAll('.', '_dot_');
      final snapshot = await _database.child('users/$sanitizedEmail/id').get();
      if (snapshot.exists) {
        setState(() {
          _userId = snapshot.value.toString();
        });
        _loadAppointments();
      } else {
        print('User ID not found.');
      }
    }
  }

  Future<void> _loadAppointments() async {
    List<Map<String, dynamic>> appointments = [];

    try {
      final snapshot = await _database.child('cities/Izmir/hospitals').get();
      if (snapshot.exists) {
        Map<dynamic, dynamic> hospitalsData = snapshot.value as Map<dynamic, dynamic>;

        for (var hospitalEntry in hospitalsData.entries) {
          var hospitalId = hospitalEntry.key;
          var hospitalData = hospitalEntry.value;

          if (hospitalData['departments'] == null) continue;

          Map<dynamic, dynamic> departmentsData = hospitalData['departments'];
          for (var departmentEntry in departmentsData.entries) {
            var departmentId = departmentEntry.key;
            var departmentData = departmentEntry.value;

            if (departmentData['doctors'] == null) continue;

            Map<dynamic, dynamic> doctorsData = departmentData['doctors'];
            for (var doctorEntry in doctorsData.entries) {
              var doctorId = doctorEntry.key;
              var doctorData = doctorEntry.value;

              if (doctorData['appointments'] == null) continue;

              Map<dynamic, dynamic> appointmentsData = doctorData['appointments'];
              for (var appointmentEntry in appointmentsData.entries) {
                var date = appointmentEntry.key;
                var timesData = appointmentEntry.value;

                if (timesData == null) continue;

                for (var timeEntry in timesData.entries) {
                  var time = timeEntry.key;
                  var userId = timeEntry.value;

                  if (userId == _userId) {
                    appointments.add({
                      'hospitalId': hospitalId,
                      'departmentId': departmentId,
                      'doctorId': doctorId,
                      'hospital': hospitalData['name'],
                      'department': departmentData['name'],
                      'doctor': doctorData['name'], // Doktor adını buraya ekliyoruz
                      'date': date,
                      'time': time,
                    });
                  }
                }
              }
            }
          }
        }

        setState(() {
          _appointments = appointments;
        });
      } else {
        print('No data found in the database.');
        setState(() {
          _appointments = [];
        });
      }
    } catch (e) {
      print('Error loading appointments: $e');
    }
  }

  Future<void> _cancelAppointment(int index) async {
    var appointment = _appointments[index];
    try {
      await _database
          .child('cities/Izmir/hospitals/${appointment['hospitalId']}/departments/${appointment['departmentId']}/doctors/${appointment['doctorId']}/appointments/${appointment['date']}/${appointment['time']}')
          .remove();

      setState(() {
        _appointments.removeAt(index); // Listeden de kaldırıyoruz
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment canceled successfully.')),
      );
    } catch (e) {
      print('Error cancelling appointment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment could not be canceled.')),
      );
    }
  }

  Future<void> _showCancelConfirmationDialog(int index) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Appointment Cancellation'),
          content: Text('Are you sure you want to cancel this appointment?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Onaylanmadı
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Onaylandı
                _cancelAppointment(index); // Randevuyu iptal et
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Current Appointments'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _appointments.isEmpty
            ? Center(
          child: Text(
            "You don't have an appointment yet",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        )
            : ListView.builder(
          itemCount: _appointments.length,
          itemBuilder: (context, index) {
            final appointment = _appointments[index];
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              elevation: 5,
              child: ListTile(
                title: Text(
                  '${appointment['hospital']} - ${appointment['department']}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Doctor: ${appointment['doctor']}\nDate: ${appointment['date']} - Hour: ${appointment['time']}',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.cancel, color: Colors.red),
                  onPressed: () {
                    _showCancelConfirmationDialog(index); // İptal onayı için dialog
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
