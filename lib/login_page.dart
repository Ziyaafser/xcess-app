import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'vendor_inventory_page.dart';
import 'customer_home_page.dart';
import 'admin_dashboard_page.dart';


import 'register_page.dart'; // for navigation if needed

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}


// class CustomerHomePage extends StatelessWidget {
//   const CustomerHomePage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Customer Home')),
//       body: const Center(child: Text('Welcome Customer!')),
//     );
//   }
// }

// class VendorInventoryPage extends StatelessWidget {
//   const VendorInventoryPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Vendor Inventory')),
//       body: const Center(child: Text('Welcome Vendor!')),
//     );
//   }
// }

// class AdminDashboardPage extends StatelessWidget {
//   const AdminDashboardPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Admin Dashboard')),
//       body: const Center(child: Text('Welcome Admin!')),
//     );
//   }
// }


class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

 @override
Widget build(BuildContext context) {
  return Scaffold(
    body: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                "Login to your account.",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text("Please sign in to your account"),
              const SizedBox(height: 30),
             TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "Email Address",
                hintText: "Enter Email",
                labelStyle: TextStyle(color: Colors.black),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              validator: (value) => value!.isEmpty ? "Enter email" : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Password",
                hintText: "Password",
                labelStyle: TextStyle(color: Colors.black),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(5),
                ),
                suffixIcon: Icon(Icons.visibility_off, color: Colors.black),
              ),
              validator: (value) => value!.isEmpty ? "Enter password" : null,
            ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    "Forgot password?",
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loginUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Sign In", style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: const [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text("Or sign in with"),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  Icon(Icons.g_mobiledata, size: 40), // Replace with Google logo
                  Icon(Icons.facebook, size: 40), // Replace with Facebook logo
                  Icon(Icons.apple, size: 40), // Replace with Apple logo
                ],
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RegisterPage()),
                      );
                    },
                    child: const Text(
                      "Register",
                      style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Center(
                child: Image.asset(
                  'assets/images/xcess_logo.jpeg',
                  height: 80,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}


  void _loginUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        // Firebase Auth sign-in
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
                email: _emailController.text.trim(),
                password: _passwordController.text.trim());

        String uid = userCredential.user!.uid;

        // Fetch role from Firestore
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();

        if (userDoc.exists) {
          String role = userDoc.get('role');

          if (context.mounted) {
            Fluttertoast.showToast(msg: 'Login successful as $role');

            // Redirect based on role
            if (role == 'customer') {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const CustomerHomePage()));
            } else if (role == 'vendor') {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const VendorInventoryPage()));
            } else if (role == 'admin') {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const AdminDashboardPage()));
            }
          }
        } else {
          Fluttertoast.showToast(msg: 'User record not found in Firestore');
        }
      } on FirebaseAuthException catch (e) {
        Fluttertoast.showToast(msg: 'Error: ${e.message}');
      } catch (e) {
        Fluttertoast.showToast(msg: 'Unexpected error occurred');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}
