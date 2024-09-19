import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mhrs_app/Screen/login_screen.dart';
import 'appointment_screen.dart';
import 'existing_appointment_screen.dart';
import 'user_ınfo_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  String _email = '';
  String _name = '';  // Kullanıcı adı için yeni değişken
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  String _sanitizeEmail(String email) {
    return email.replaceAll('@', '_at_').replaceAll('.', '_dot_');
  }

  Future<void> _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _email = user.email!;
      });
      String sanitizedEmail = _sanitizeEmail(_email);

      // Firebase'den kullanıcı ismini çekiyoruz
      final snapshot = await _database.child('users/$sanitizedEmail').get();
      if (snapshot.exists && snapshot.value != null) {
        Map<dynamic, dynamic> userData = snapshot.value as Map<dynamic, dynamic>; // snapshot.value'yi Map olarak alıyoruz
        setState(() {
          _name = userData['name'] ?? '';  // 'name' alanına güvenle erişiyoruz
        });
      }
    }
  }

  Future<void> _signOut(BuildContext context) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Are you sure you want to quit?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Hayır
            child: Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // Evet
            child: Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _auth.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()), // LoginPage'i kendi sayfanızla değiştirin
            (route) => false, // Tüm önceki sayfaları temizle
      );
    }
  }



  Future<bool> _onWillPop() async {
    return (await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Are you sure you want to quit?Are you sure you want to quit?'),
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
    )) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop, // Geri tuşuna basılınca onay diyaloğunu göster
      child: Scaffold(
        appBar: AppBar(
          title: Text('Home Page'),
          backgroundColor: Colors.deepPurple,  // Estetik için renk ayarı
          foregroundColor: Colors.white,

        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kullanıcının ismini gösteriyoruz
              Text(
                'Welcome, $_name',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,  // Estetik için metin rengi
                ),
              ),
              SizedBox(height: 20),

              // Kullanıcı Bilgilerini Düzenleme Butonu
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserInfoScreen(),
                    ),
                  );
                },
                icon: Icon(Icons.person, color: Colors.white),
                label: Text('User Information'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,  // Estetik için buton rengi
                  foregroundColor: Colors.white,

                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  textStyle: TextStyle(fontSize: 16),
                ),
              ),

              SizedBox(height: 10),

              // Randevu Alma Ekranına Yönlendirme Butonu
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AppointmentScreen(),
                    ),
                  );
                },
                icon: Icon(Icons.calendar_today, color: Colors.white),
                label: Text('Make an Appointment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,

                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  textStyle: TextStyle(fontSize: 16),
                ),
              ),

              SizedBox(height: 10),

              // Mevcut Randevuları Gösterme Ekranına Yönlendirme Butonu
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExistingAppointmentsScreen(),
                    ),
                  );
                },
                icon: Icon(Icons.list, color: Colors.white),
                label: Text('Current Appointment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  textStyle: TextStyle(fontSize: 16),
                ),
              ),

              SizedBox(height: 30),

              // Çıkış Yap Butonu
              Center(
                child: ElevatedButton.icon(
                  onPressed: () => _signOut(context),
                  icon: Icon(Icons.logout, color: Colors.white),
                  label: Text('Sign Out',),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,

                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                    textStyle: TextStyle(fontSize: 16),
                  ),
                ),
              ),

              SizedBox(height: 20),
              Text(
                errorMessage,
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
