import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pokedex/pokedex_screen.dart';

import 'firebase_options.dart';
import 'user.dart';

Future<void> main() async {
  runApp(const MaterialApp(
      debugShowCheckedModeBanner: false, title: "Pokedex", home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool firebaseReady = false;
  @override
  void initState() {
    super.initState();
    Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).then((value) => setState(() => firebaseReady = true));
  }

  @override
  Widget build(BuildContext context) {
    if (!firebaseReady) return const Center(child: CircularProgressIndicator());

    // currentUser will be null if no one is signed in.
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) return PokedexScreen();
    return const LoginScreen();
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String? email;
  String? password;
  String? error;
  final _formKey = GlobalKey<FormState>();

  void tryLogin() async {
    try {
      // The await keyword blocks execution to wait for
      // signInWithEmailAndPassword to complete its asynchronous execution and
      // return a result.
      //
      // FirebaseAuth with raise an exception if the email or password
      // are determined to be invalid, e.g., the email doesn't exist.
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email!, password: password!);
      if (kDebugMode) {
        print("Logged in ${credential.user}");
      }
      error = null; // clear the error message if exists.
      setState(() {}); // Trigger a rebuild

      // We need this next check to use the Navigator in an async method.
      // It basically makes sure LoginScreen is still visible.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Success! $email is logged in")));

      // pop the navigation stack so people cannot "go back" to the login screen
      // after logging in.
      Navigator.of(context).pop();
      // Now go to the HomeScreen.
      Navigator.of(context).push(MaterialPageRoute(
        // builder: (context) => PokedexScreen(data.pokemon),
        builder: (context) => PokedexScreen(),
      ));
    } on FirebaseAuthException catch (e) {
      // Exceptions are raised if the Firebase Auth service
      // encounters an error. We need to display these to the user.
      if (e.code == 'user-not-found') {
        error = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        error = 'Wrong password provided for that user.';
      } else {
        error = 'An error occurred: ${e.message}';
      }

      // Call setState to redraw the widget, which will display
      // the updated error text.
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(children: [
                Image.asset('assets/images/pokedex_logo.png'),
                Image.asset(
                  'assets/images/charizard.png',
                  scale: 3,
                )
              ]),
              // TextFields
              Column(
                children: [
                  TextFormField(
                      decoration:
                          const InputDecoration(hintText: "Enter your email"),
                      maxLength: 64,
                      onChanged: (value) => email = value,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter your email";
                        }
                        return null; // Returning null means "no issues"
                      }),
                  TextFormField(
                      decoration: const InputDecoration(
                          hintText: "Enter your password"),
                      obscureText: true,
                      onChanged: (value) => password = value,
                      validator: (value) {
                        if (value == null || value.length < 8) {
                          return "password must be at least 8 characters\n"
                              "have an uppercase letter\n"
                              "have a number\nhave a special character";
                        }
                        return null; // Returning null means "no issues"
                      }),
                ],
              ),
              // Buttons
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(height: 50),
                      ElevatedButton(
                          child: const Text("Sign Up"),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const SignUpPage()));
                          }),
                      const SizedBox(height: 50),
                      ElevatedButton(
                          child: const Text("Login"),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              tryLogin();
                            }
                          }),
                    ],
                  ),
                  if (error != null)
                    Text("$error",
                        style: TextStyle(color: Colors.red[800], fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  String? email;
  String? password;
  String? repeatPassword;
  String? error;
  final _formKey = GlobalKey<FormState>();
  final userRef = FirebaseFirestore.instance.collection('users');

  void trySignup() async {
    if (_formKey.currentState!.validate()) {
      try {
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email!, password: password!);
        if (kDebugMode) {
          print("Signed up ${credential.user}");
        }
        addUserData(email!, password!);
        error = null;
        setState(() {});

        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Success! Added $email")));

        Navigator.of(context).pop();
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ));
      } on FirebaseAuthException catch (e) {
        if (e.code == 'weak-password') {
          error = 'The password provided is too weak.';
        } else if (e.code == 'email-already-in-use') {
          error = 'The account already exists for that email.';
        } else {
          error = 'An error occurred: ${e.message}';
        }
        setState(() {});
      }
    }
  }

  void addUserData(String email, String password) async {
    try {
      UserData u = UserData(email: email, password: password);

      DocumentReference doc = await userRef.add(u.toMap());
      await userRef.doc(FirebaseAuth.instance.currentUser!.uid).set(u.toMap());

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Success! Added ${doc.id}")));
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Opps Error ${e.message}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Sign Up'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(hintText: 'Email'),
                onChanged: (value) => email = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(hintText: 'Password'),
                obscureText: true,
                onChanged: (value) => password = value,
                validator: (value) {
                  if (!passwordCheck(value)) {
                    return "password must be at least 8 characters\n"
                        "have an uppercase letter\n"
                        "have a number\nhave a special character";
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(hintText: 'Repeat Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please repeat your password';
                  }
                  if (value != password) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
                onChanged: (value) {
                  repeatPassword = value;
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const SizedBox(height: 50),
                  ElevatedButton(
                    onPressed: trySignup,
                    child: const Text('Sign Up'),
                  ),
                  const SizedBox(height: 50),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen()));
                    },
                    child: const Text('Back'),
                  ),
                ],
              ),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(
                  error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Checks that a password passes a security test
bool passwordCheck(String? password) {
  if (password == null || password.isEmpty || password.length < 8) {
    return false;
  }

  bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
  bool hasDigits = password.contains(RegExp(r'[0-9]'));
  bool hasSpecialCharacters =
      password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  return hasDigits & hasUppercase & hasSpecialCharacters;
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Made by Gaetano Panzer II"),
          Expanded(
            child: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Home"),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
