import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  // Firebase'den randevuları yükleyen fonksiyon
  Future<void> _loadAppointments() async {
    try {
      final snapshot = await _database.child('cities/Izmir/hospitals').get();
      if (snapshot.exists) {
        Map<dynamic, dynamic> hospitalsData = snapshot.value as Map<dynamic, dynamic>;
        List<Map<String, dynamic>> appointments = [];

        hospitalsData.forEach((hospitalId, hospitalData) {
          if (hospitalData['departments'] == null) return;

          Map<dynamic, dynamic> departmentsData = hospitalData['departments'] as Map<dynamic, dynamic>;

          departmentsData.forEach((departmentId, departmentData) {
            if (departmentData['doctors'] == null) return;

            Map<dynamic, dynamic> doctorsData = departmentData['doctors'] as Map<dynamic, dynamic>;

            doctorsData.forEach((doctorId, doctorData) {
              if (doctorData['appointments'] == null) return;

              Map<dynamic, dynamic> appointmentsData = doctorData['appointments'] as Map<dynamic, dynamic>;

              appointmentsData.forEach((date, timesData) {
                if (timesData == null) return;

                timesData.forEach((time, isBooked) {
                  if (isBooked != null) {
                    appointments.add({
                      'hospital': hospitalData['name'],
                      'department': departmentData['name'],
                      'doctor': doctorData['name'],
                      'date': date,
                      'time': time,
                      'userId': isBooked,

                    });
                  } // Sadece alınmış randevuları gösteriyoruz
                });
              });
            });
          });
        });

        setState(() {
          _appointments = appointments;
          _isLoading = false;
        });
      } else {
        print('No appointments found.');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading appointments: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Are you sure you want to quit?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Hayır derse çıkış iptal edilir
            child: Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // Evet derse çıkış yapılır
            child: Text('Yes'),
          ),
        ],
      ),
    )) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop, // Geri tuşuna basıldığında onay diyaloğunu göster
      child: Scaffold(
        backgroundColor: Colors.cyan,
        appBar: AppBar(
          title: Text('Admin Panel - Appointments'),

        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : _appointments.isEmpty
              ? Center(child: Text('Appointment not found.'))
              : ListView.builder(
            itemCount: _appointments.length,
            itemBuilder: (context, index) {
              final appointment = _appointments[index];
              return Card(

                elevation: 4,
                margin: EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text(
                    'Hospital: ${appointment['hospital']}, Department: ${appointment['department']}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Doctor: ${appointment['doctor']}\nDate: ${appointment['date']} Saat: ${appointment['time']}\nUser ID: ${appointment['userId']}',
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
