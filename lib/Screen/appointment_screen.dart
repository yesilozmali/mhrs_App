import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import 'home_screen.dart';

// Hastane bilgilerini tutmak için bir model
class Hospital {
  final String id;
  final String name;

  Hospital(this.id, this.name);
}

// Departman bilgilerini tutmak için bir model
class Department {
  final String id;
  final String name;

  Department(this.id, this.name);
}

class AppointmentScreen extends StatefulWidget {
  @override
  _AppointmentScreenState createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;  // FirebaseAuth instance
  String? _userId;  // Kullanıcı ID'sini saklamak için değişken

  String? _selectedHospitalId;
  String? _selectedDepartmentId;
  String? _selectedDoctor;
  String? _selectedDate;
  String? _selectedTime;
  List<Hospital> _hospitals = [];
  List<Department> _departments = [];
  Map<String, String> _doctors = {};
  List<String> _dates = [];
  Map<String, bool> _availableTimes = {};
  final List<String> _allPossibleTimes = [
    '09:00', '09:30', '10:00', '10:30', '11:00', '11:30', '13:00',
    '13:30', '14:00', '14:30', '15:00', '15:30', '16:00', '16:30'
  ];

  @override
  void initState() {
    super.initState();
    _loadHospitals();
    _loadUserId();  // Kullanıcı ID'sini yükleme fonksiyonunu çağır

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
      } else {
        print('User ID not found.');
      }
    }
  }
  // Hastaneleri yüklemek için fonksiyon
  Future<void> _loadHospitals() async {
    try {
      final snapshot = await _database.child('cities/Izmir/hospitals').get();
      if (snapshot.exists) {
        Map<dynamic, dynamic> hospitalsData = snapshot.value as Map<dynamic, dynamic>;
        List<Hospital> hospitals = [];
        hospitalsData.forEach((key, value) {
          hospitals.add(Hospital(key, value['name']));
        });
        setState(() {
          _hospitals = hospitals;
        });
      } else {
        print('No hospitals found.');
      }
    } catch (e) {
      print('Error loading hospitals: $e');
    }
  }

  // Departmanları yüklemek için fonksiyon
  Future<void> _loadDepartments() async {
    if (_selectedHospitalId == null) return;

    try {
      final snapshot = await _database
          .child('cities/Izmir/hospitals/$_selectedHospitalId/departments')
          .get();

      if (snapshot.exists) {
        Map<dynamic, dynamic> departmentsData = snapshot.value as Map<dynamic, dynamic>;
        List<Department> departments = [];

        departmentsData.forEach((key, value) {
          departments.add(Department(key, value['name']));
        });

        setState(() {
          _departments = departments;
          _selectedDepartmentId = null;
          _selectedDoctor = null;
          _selectedDate = null;
          _availableTimes.clear();
        });
      } else {
        print('No departments found for this hospital.');
      }
    } catch (e) {
      print('Error loading departments: $e');
    }
  }

  // Doktorları yüklemek için fonksiyon
  Future<void> _loadDoctors() async {
    if (_selectedHospitalId == null || _selectedDepartmentId == null) return;

    try {
      final snapshot = await _database
          .child('cities/Izmir/hospitals/$_selectedHospitalId/departments/$_selectedDepartmentId/doctors')
          .get();

      if (snapshot.exists) {
        Map<dynamic, dynamic> doctorsData = snapshot.value as Map<dynamic, dynamic>;
        Map<String, String> doctors = {};

        doctorsData.forEach((key, value) {
          doctors[key] = value['name'];
        });

        setState(() {
          _doctors = doctors;
        });
      } else {
        print('No doctors found for this department.');
      }
    } catch (e) {
      print('Error loading doctors: $e');
    }
  }
// Tarihleri yüklemek için fonksiyon (Eğer tüm saatler doluysa tarihi listeden çıkar)
  Future<void> _loadDates() async {
    if (_selectedHospitalId == null || _selectedDepartmentId == null || _selectedDoctor == null) return;

    try {
      // Firebase'deki randevu bilgilerini kontrol et
      final snapshot = await _database
          .child('cities/Izmir/hospitals/$_selectedHospitalId/departments/$_selectedDepartmentId/doctors/$_selectedDoctor')
          .get();

      if (snapshot.exists) {
        Map<dynamic, dynamic> appointmentsData = snapshot.value as Map<dynamic, dynamic>;
        List<String> dates = [];

        // Şu andan itibaren 10 hafta (70 gün) hesapla
        DateTime today = DateTime.now();
        DateTime endDate = today.add(Duration(days: 14)); // 10 hafta

        DateTime currentDate = today;

        while (currentDate.isBefore(endDate)) {
          // Sadece hafta içi günleri kontrol et
          if (currentDate.weekday < 6) {
            String formattedDate = "${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}";

            if (appointmentsData.containsKey(formattedDate)) {
              Map<dynamic, dynamic> timesData = appointmentsData[formattedDate] as Map<dynamic, dynamic>;
              bool allTimesFull = true;

              // Tüm saatlerin dolu olup olmadığını kontrol et
              for (var time in _allPossibleTimes) {
                if (!timesData.containsKey(time) || timesData[time] == true) {
                  allTimesFull = false; // Eğer en az bir saat boşsa
                  break;
                }
              }

              // Eğer tüm saatler dolu değilse tarihi ekle
              if (!allTimesFull) {
                dates.add(formattedDate);
              }
            } else {
              // Eğer tarihte hiç randevu yoksa, tarihi ekle
              dates.add(formattedDate);
            }
          }
          currentDate = currentDate.add(Duration(days: 1));
        }

        setState(() {
          _dates = dates;
          _selectedDate = null;
          _availableTimes.clear();
        });
      } else {
        print('No dates available for the selected doctor.');
        setState(() {
          _dates = [];
          _selectedDate = null;
          _availableTimes.clear();
        });
      }
    } catch (e) {
      print('Error loading dates: $e');
    }
  }


// Uygun saatleri yüklemek için fonksiyon (Seçilen tarih için dolu olan saatleri kontrol eder)
  Future<void> _loadAvailableTimes() async {
    if (_selectedHospitalId == null || _selectedDepartmentId == null || _selectedDoctor == null || _selectedDate == null) return;

    try {
      final snapshot = await _database
          .child('cities/Izmir/hospitals/$_selectedHospitalId/departments/$_selectedDepartmentId/doctors/$_selectedDoctor/appointments/$_selectedDate')
          .get();

      if (snapshot.exists) {
        Map<dynamic, dynamic> timesData = snapshot.value as Map<dynamic, dynamic>;
        Map<String, bool> availableTimes = {};

        // Varsayılan olarak tüm saatleri boş kabul et
        _allPossibleTimes.forEach((time) {
          availableTimes[time] = true;
        });

        // Firebase'den dolu olan saatleri güncelle
        timesData.forEach((key, value) {
          availableTimes[key] = false;
        });

        setState(() {
          _availableTimes = availableTimes;
        });
      } else {
        // Eğer o gün için hiçbir randevu yoksa, tüm saatler boş kabul edilir
        Map<String, bool> availableTimes = {};
        _allPossibleTimes.forEach((time) {
          availableTimes[time] = true;
        });

        setState(() {
          _availableTimes = availableTimes;
        });
      }
    } catch (e) {
      print('Error loading available times: $e');
    }
  }

  Future<void> _bookAppointment() async {
    if (_selectedTime != null && _availableTimes[_selectedTime!] == true && _userId != null) {
      try {
        await _database
            .child('cities/Izmir/hospitals/$_selectedHospitalId/departments/$_selectedDepartmentId/doctors/$_selectedDoctor/appointments/$_selectedDate')
            .update({_selectedTime!: _userId});  // Kullanıcının ID'si randevuya ekleniyor

        // Başarılı bir şekilde randevu oluşturulduktan sonra ana ekrana yönlendir
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Randevu başarıyla alındı!')),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()), // Ana ekrana yönlendirme
          );
        }
      } catch (e) {
        print('Error booking appointment: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Randevu alırken bir hata oluştu!')),
        );
      }
    } else {
      print('Time slot not available or User ID is null');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Seçilen saat dolu veya kullanıcı ID bulunamadı.')),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Make an Appointment', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,color: Colors.white)),
        backgroundColor: Colors.teal,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDropdownCard(
                title: 'Choose Hospital',
                value: _selectedHospitalId,
                onChanged: (value) {
                  setState(() {
                    _selectedHospitalId = value;
                    _loadDepartments();
                  });
                },
                items: _hospitals.map((hospital) {
                  return DropdownMenuItem<String>(
                    value: hospital.id,
                    child: Text(hospital.name),
                  );
                }).toList(),
              ),
              if (_selectedHospitalId != null)
                _buildDropdownCard(
                  title: 'Select Department',
                  value: _selectedDepartmentId,
                  onChanged: (value) {
                    setState(() {
                      _selectedDepartmentId = value;
                      _loadDoctors();
                    });
                  },
                  items: _departments.map((department) {
                    return DropdownMenuItem<String>(
                      value: department.id,
                      child: Text(department.name),
                    );
                  }).toList(),
                ),
              if (_selectedDepartmentId != null)
                _buildDropdownCard(
                  title: 'Choose a Doctor',
                  value: _selectedDoctor,
                  onChanged: (value) {
                    setState(() {
                      _selectedDoctor = value;
                      _loadDates();
                    });
                  },
                  items: _doctors.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                ),
              if (_dates.isNotEmpty)
                _buildDropdownCard(
                  title: 'Select Date',
                  value: _selectedDate,
                  onChanged: (value) {
                    setState(() {
                      _selectedDate = value;
                      _loadAvailableTimes();
                    });
                  },
                  items: _dates.map((date) {
                    return DropdownMenuItem<String>(
                      value: date,
                      child: Text(date),
                    );
                  }).toList(),
                ),
              if (_availableTimes.isNotEmpty)
                _buildDropdownCard(
                  title: 'Select Time',
                  value: _selectedTime,
                  onChanged: (value) {
                    setState(() {
                      _selectedTime = value;
                    });
                  },
                  items: _availableTimes.keys.where((time) => _availableTimes[time] == true).map((time) {
                    return DropdownMenuItem<String>(
                      value: time,
                      child: Text(time),
                    );
                  }).toList(),
                ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _selectedTime != null && _availableTimes[_selectedTime!] == true ? _bookAppointment : null,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    backgroundColor: Colors.teal,
                  ),
                  child: Text(
                    'Make an Appointment',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Function to build styled dropdown cards
  Widget _buildDropdownCard({required String title, String? value, required Function(String?) onChanged, required List<DropdownMenuItem<String>> items}) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            DropdownButton<String>(
              isExpanded: true,
              value: value,
              onChanged: onChanged,
              underline: SizedBox(),
              items: items,
              icon: Icon(Icons.arrow_drop_down, color: Colors.teal),
            ),
          ],
        ),
      ),
    );
  }
}