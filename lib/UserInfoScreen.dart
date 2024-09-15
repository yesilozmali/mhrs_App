import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class UserInfoScreen extends StatefulWidget {
  @override
  _UserInfoScreenState createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  String _email = '';
  bool _isEditing = false;  // Düzenleme modunu tutuyor
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();  // Ekran açıldığında kullanıcı verilerini yükle
  }

  // Email'i Firebase'e uygun hale getirme
  String _sanitizeEmail(String email) {
    return email.replaceAll('@', '_at_').replaceAll('.', '_dot_');
  }

  // Firebase'den kullanıcı verilerini çekme
  Future<void> _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _email = user.email!;
      });

      String sanitizedEmail = _sanitizeEmail(_email);

      try {
        final snapshot = await _database.child('users/$sanitizedEmail').get();
        if (snapshot.exists) {
          Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
          // Verileri controller'lara set et
          setState(() {
            _nameController.text = data['name'] ?? '';
            _phoneController.text = data['phone'] ?? '';
            _idController.text = data['id'] ?? '';
          });
        } else {
          setState(() {
            errorMessage = 'User data does not exist.';
          });
        }
      } catch (error) {
        setState(() {
          errorMessage = 'Failed to load user data.';
        });
        print(error.toString());
      }
    }
  }

  // Firebase'e kullanıcı verilerini kaydetme
  Future<void> _saveUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      String sanitizedEmail = _sanitizeEmail(user.email!);

      try {
        await _database.child('users/$sanitizedEmail').set({
          'name': _nameController.text,
          'phone': _phoneController.text,
          'id': _idController.text,
        });
        setState(() {
          _isEditing = false;  // Kaydettikten sonra düzenleme modunu kapat
        });
        print('User data updated successfully');
      } catch (e) {
        setState(() {
          errorMessage = 'Failed to update user data.';
        });
        print(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Information'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: $_email'),  // Kullanıcının email adresini göster
            SizedBox(height: 10),

            // Düzenleme modunda mı değil mi kontrol et
            _isEditing
                ? Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(labelText: 'Phone Number'),
                ),
                TextField(
                  controller: _idController,
                  decoration: InputDecoration(labelText: 'ID Number'),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _saveUserData,
                  child: Text('Save Changes'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;  // Düzenleme modunu iptal et
                    });
                  },
                  child: Text('Cancel'),
                ),
              ],
            )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${_nameController.text}'),
                Text('Phone: ${_phoneController.text}'),
                Text('ID Number: ${_idController.text}'),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = true;  // Düzenleme moduna geç
                    });
                  },
                  child: Text('Edit'),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              errorMessage,
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
