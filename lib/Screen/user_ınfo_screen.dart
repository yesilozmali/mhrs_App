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
  bool _isEditing = false;
  String errorMessage = '';

  final _formKey = GlobalKey<FormState>();

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

      try {
        final snapshot = await _database.child('users/$sanitizedEmail').get();
        if (snapshot.exists) {
          Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
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
      }
    }
  }

  Future<void> _saveUserData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    User? user = _auth.currentUser;
    if (user != null) {
      String sanitizedEmail = _sanitizeEmail(user.email!);
      String newId = _idController.text;

      try {
        final usersSnapshot = await _database.child('users').get();
        if (usersSnapshot.exists) {
          Map<dynamic, dynamic> usersData = usersSnapshot.value as Map<dynamic, dynamic>;

          for (var userData in usersData.entries) {
            String emailKey = userData.key;
            Map<dynamic, dynamic> userInfo = userData.value;

            if (emailKey != sanitizedEmail && userInfo['id'] == newId) {
              setState(() {
                errorMessage = 'This ID is already in use by another user.';
                // Yeni ID'yi boşalt
                _idController.clear();
              });
              return;
            }
          }
        }

        // Eğer ID kullanılmıyorsa güncelle
        await _database.child('users/$sanitizedEmail').set({
          'name': _nameController.text,
          'phone': _phoneController.text,
          'id': _idController.text,
        });

        // Verileri tekrar yükle
        await _loadUserData();

        setState(() {
          _isEditing = false;
          errorMessage = '';
        });

      } catch (e) {
        setState(() {
          errorMessage = 'Failed to update user data.';
        });
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Information'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserInfoCard(),
                SizedBox(height: 20),
                _isEditing ? _buildEditMode() : _buildViewMode(),
                SizedBox(height: 20),
                Text(
                  errorMessage,
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(Icons.email, 'Email', _email),
            SizedBox(height: 10),
            _buildInfoRow(Icons.person, 'Name', _nameController.text),
            SizedBox(height: 10),
            _buildInfoRow(Icons.phone, 'Phone', _phoneController.text),
            SizedBox(height: 10),
            _buildInfoRow(Icons.badge, 'ID Number', _idController.text),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.deepPurple),
        SizedBox(width: 10),
        Text(
          '$label: ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? 'Not provided' : value,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildEditMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(_nameController, 'Name'),
        SizedBox(height: 10),
        _buildPhoneTextField(),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: _saveUserData,
              child: Text('Save Changes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  errorMessage = '';
                });
              },
              child: Text('Cancel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildViewMode() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _isEditing = true;
          });
        },
        child: Text('Edit Information',),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 30),
          foregroundColor: Colors.white
        ),
      ),
    );
  }

  Widget _buildPhoneTextField() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      maxLength: 10,
      decoration: InputDecoration(
        labelText: 'Phone Number',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a phone number';
        } else if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
          return 'Phone number must be 10 digits';
        }
        return null;
      },
    );
  }



  Widget _buildTextField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
