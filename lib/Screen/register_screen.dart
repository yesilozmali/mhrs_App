import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  String errorMessage = '';
  bool isLoading = false;

  String _sanitizeEmail(String email) {
    return email.replaceAll('@', '_at_').replaceAll('.', '_dot_');
  }

  List<TextInputFormatter> nameInputFormatters = [
    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')), // Sadece harf ve boşluk
  ];

  List<TextInputFormatter> phoneInputFormatters = [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(10), // 10 haneli telefon numarası
  ];

  List<TextInputFormatter> idInputFormatters = [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(11), // 11 haneli kimlik numarası sınırı
  ];

  Future<void> _register() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      if (_idController.text.length != 11) {
        setState(() {
          errorMessage = 'ID number must be 11 digits.';
          isLoading = false;
        });
        return;
      }

      final snapshot = await _database.child('users').get();
      if (snapshot.exists) {
        Map<dynamic, dynamic> usersData = snapshot.value as Map<dynamic, dynamic>;
        for (var userData in usersData.values) {
          if (userData['id'] == _idController.text) {
            setState(() {
              errorMessage = 'This ID number is already in use.';
              isLoading = false;
            });
            return;
          }
        }
      }

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      User? user = userCredential.user;
      if (user != null) {
        String sanitizedEmail = _sanitizeEmail(user.email!);

        await _database.child('users/$sanitizedEmail').set({
          'name': _nameController.text,
          'phone': _phoneController.text,
          'id': _idController.text,
        });

        setState(() {
          isLoading = false;
        });
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        setState(() {
          errorMessage = 'This email is already in use.';
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Registration failed. Please try again.';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Registration failed. Please try again.';
        isLoading = false;
      });
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register Screen'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.lightBlueAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    SizedBox(height: 15),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                    ),
                    SizedBox(height: 15),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      inputFormatters: nameInputFormatters,
                    ),
                    SizedBox(height: 15),
                    TextField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        hintText: '5xx-xxx-xxxx',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      inputFormatters: phoneInputFormatters,
                    ),
                    SizedBox(height: 15),
                    TextField(
                      controller: _idController,
                      decoration: InputDecoration(
                        labelText: 'ID Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: idInputFormatters,
                    ),
                    SizedBox(height: 25),
                    isLoading
                        ? CircularProgressIndicator()
                        : ElevatedButton(
                      onPressed: _register,
                      child: Text(
                        'Register',
                        style: TextStyle(fontSize: 18),

                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent, // Use backgroundColor instead of primary
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 100,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),

                    SizedBox(height: 20),
                    Text(
                      errorMessage,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
