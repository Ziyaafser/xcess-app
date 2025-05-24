import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _agreeTerms = false;

  String _selectedRole = 'customer';
  final List<String> _roles = ['customer', 'vendor', 'admin'];

  bool _obscurePassword = true;

  void _submitForm() async {
    if (!_agreeTerms) {
      Fluttertoast.showToast(msg: "Please accept terms and conditions");
      return;
    }

    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'userID': userCredential.user!.uid,
          'userName': name,
          'userEmail': email,
          'role': _selectedRole,
        });

        if (context.mounted) {
          Fluttertoast.showToast(msg: 'Registration successful ✅');
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
        }
      } on FirebaseAuthException catch (e) {
        Fluttertoast.showToast(msg: 'Error: ${e.message}');
      } catch (e) {
        print('🔥 Error: $e');
        Fluttertoast.showToast(msg: 'Something went wrong.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 50),
                const Text("Create your new account", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                const Text("Create an account to start looking for the food you like", style: TextStyle(color: Colors.grey)),

                const SizedBox(height: 30),
              TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "Email Address",
                labelStyle: TextStyle(color: Colors.black),
                hintText:"Enter Email Address",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
                focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(5),
                )
              ),
              validator: (value) => value!.isEmpty ? "Enter email" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Full Name",
                  labelStyle: TextStyle(color: Colors.black),
                  hintText: "Enter Full Name",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
                  focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(5),
                )
                ),
                validator: (value) => value!.isEmpty ? "Enter name" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: "Password",
                  labelStyle: TextStyle(color: Colors.black),
                  hintText: "Enter Password",
                  border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide(color: Colors.black),
                  ),
                  focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide(color: Colors.black, width: 2), // <-- thick black border
                  ),
                  
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    
                  ),
                ),
                validator: (value) => value!.length < 6 ? "Minimum 6 characters" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Confirm Password",
                  labelStyle: TextStyle(color: Colors.black),
                  hintText: "Confirm Password",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
                  focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(5),
                )
                ),
                validator: (value) =>
                    value != _passwordController.text ? "Passwords do not match" : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: InputDecoration(
                  labelText: "Select Role",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
                  focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(5),
                )
                ),
                items: _roles.map((role) {
                  return DropdownMenuItem(value: role, child: Text(role));
                }).toList(),
                onChanged: (value) => setState(() => _selectedRole = value!),
              ),

                const SizedBox(height: 10),
                Row(
                  children: [
                    Checkbox(
                      value: _agreeTerms,
                      onChanged: (value) => setState(() => _agreeTerms = value!),
                    ),
                    const Text("I Agree with "),
                    GestureDetector(
                      onTap: () {},
                      child: const Text("Terms of Service", style: TextStyle(color: Colors.orange)),
                    ),
                    const Text(" and "),
                    GestureDetector(
                      onTap: () {},
                      child: const Text("Privacy Policy", style: TextStyle(color: Colors.orange)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _submitForm,
                  child: const Text("Register", style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
                const SizedBox(height: 30),
                const Divider(),
                const SizedBox(height: 10),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.g_mobiledata, size: 32),
                    SizedBox(width: 16),
                    Icon(Icons.facebook, size: 28),
                    SizedBox(width: 16),
                    Icon(Icons.apple, size: 28),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? "),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(
                        context, MaterialPageRoute(builder: (_) => const LoginPage())),
                      child: const Text("Sign In", style: TextStyle(color: Colors.orange)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Center(child: Image.asset("assets/images/xcess_logo.jpeg", height: 70)),
                const SizedBox(height: 30),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
