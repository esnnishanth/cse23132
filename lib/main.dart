import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_dartio/google_sign_in_dartio.dart';

import 'firebase_options.dart';

const String _windowsGoogleClientId = String.fromEnvironment(
  'WINDOWS_GOOGLE_CLIENT_ID',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
    if (_windowsGoogleClientId.isNotEmpty) {
      await GoogleSignInDart.register(clientId: _windowsGoogleClientId);
    } else {
      debugPrint(
        'WINDOWS_GOOGLE_CLIENT_ID is missing. Use --dart-define=WINDOWS_GOOGLE_CLIENT_ID=<your OAuth client id> for Google Sign-In on Windows.',
      );
    }
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const FormsApp());
}

class FormsApp extends StatelessWidget {
  const FormsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Microsoft Forms Style App',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF3F2F1),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2564CF),
          surface: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFDFDFD),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFD0D7DE)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFD0D7DE)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2564CF), width: 1.4),
          ),
        ),
      ),
      home: const FormsHomePage(),
    );
  }
}

class FormsHomePage extends StatefulWidget {
  const FormsHomePage({super.key});

  @override
  State<FormsHomePage> createState() => _FormsHomePageState();
}

class _FormsHomePageState extends State<FormsHomePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

  StreamSubscription<User?>? _authSubscription;
  User? _currentUser;
  bool _isSigningIn = false;
  bool _isSubmitting = false;
  bool _isSubmitted = false;

  bool get _supportsNativeGoogleSignIn {
    return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.windows;
  }

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _emailController.text = _currentUser?.email ?? '';
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) {
        return;
      }
      setState(() {
        _currentUser = user;
        if ((user?.email ?? '').isNotEmpty) {
          _emailController.text = user!.email!;
        }
      });
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _fullNameController.dispose();
    _emailController.dispose();
    _departmentController.dispose();
    _topicController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    if (_isSigningIn) {
      return;
    }

    setState(() {
      _isSigningIn = true;
    });

    try {
      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        if (!_supportsNativeGoogleSignIn) {
          throw UnsupportedError(
            'Google Sign-In is configured for Android/iOS and Web in this sample.',
          );
        }

        if (defaultTargetPlatform == TargetPlatform.windows &&
            _windowsGoogleClientId.isEmpty) {
          throw StateError(
            'Windows Google Sign-In needs an OAuth client ID. Start with --dart-define=WINDOWS_GOOGLE_CLIENT_ID=<client-id>.',
          );
        }

        final GoogleSignInAccount? googleUser = await GoogleSignIn(
          scopes: <String>['email'],
        ).signIn();
        if (googleUser == null) {
          return;
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await FirebaseAuth.instance.signInWithCredential(credential);
      }
    } catch (error) {
      _showMessage('Google sign-in failed: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSigningIn = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!kIsWeb && _supportsNativeGoogleSignIn) {
        await GoogleSignIn().signOut();
      }
      _showMessage('Signed out successfully.');
    } catch (error) {
      _showMessage('Sign-out failed: $error');
    }
  }

  Future<void> _submitForm() async {
    if (_currentUser == null) {
      _showMessage('Please sign in with Google before submitting.');
      return;
    }

    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('responses')
          .add(<String, dynamic>{
            'uid': _currentUser!.uid,
            'userEmail': _currentUser!.email,
            'userName': _currentUser!.displayName,
            'fullName': _fullNameController.text.trim(),
            'email': _emailController.text.trim(),
            'department': _departmentController.text.trim(),
            'topic': _topicController.text.trim(),
            'details': _detailsController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });

      setState(() {
        _isSubmitted = true;
      });
      _showMessage('Response submitted to Firestore.');
    } catch (error) {
      _showMessage('Submission failed: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  InputDecoration _decoration(String label, {String? hint}) {
    return InputDecoration(labelText: label, hintText: hint);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[Color(0xFF2564CF), Color(0xFF1A4CA8)],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Team Intake Form',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'A Microsoft Forms-style sample with Google Sign-In and Firebase Firestore.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentUser == null
                              ? 'Sign in to continue'
                              : 'Signed in as ${_currentUser!.email ?? 'Unknown email'}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              _currentUser == null
                                  ? 'Authentication Required'
                                  : 'Connected: ${_currentUser!.displayName ?? _currentUser!.email ?? 'Google Account'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (_currentUser == null)
                            FilledButton.icon(
                              onPressed: _isSigningIn
                                  ? null
                                  : _signInWithGoogle,
                              icon: _isSigningIn
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.login),
                              label: Text(
                                _isSigningIn
                                    ? 'Signing in...'
                                    : 'Sign in with Google',
                              ),
                            )
                          else
                            OutlinedButton.icon(
                              onPressed: _signOut,
                              icon: const Icon(Icons.logout),
                              label: const Text('Sign out'),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Text(
                              'Response Form',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'All submissions are stored in Firebase Firestore.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _fullNameController,
                              textInputAction: TextInputAction.next,
                              decoration: _decoration(
                                'Full Name',
                                hint: 'Enter your full name',
                              ),
                              validator: (String? value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Full name is required.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _emailController,
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.emailAddress,
                              decoration: _decoration(
                                'Contact Email',
                                hint: 'name@company.com',
                              ),
                              validator: (String? value) {
                                final String input = value?.trim() ?? '';
                                if (input.isEmpty) {
                                  return 'Email is required.';
                                }
                                if (!RegExp(
                                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                ).hasMatch(input)) {
                                  return 'Enter a valid email address.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _departmentController,
                              textInputAction: TextInputAction.next,
                              decoration: _decoration(
                                'Department',
                                hint: 'Engineering, Sales, HR, ...',
                              ),
                              validator: (String? value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Department is required.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _topicController,
                              textInputAction: TextInputAction.next,
                              decoration: _decoration(
                                'Topic',
                                hint: 'What is this response about?',
                              ),
                              validator: (String? value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Topic is required.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _detailsController,
                              maxLines: 5,
                              decoration: _decoration(
                                'Details',
                                hint: 'Add your details here...',
                              ),
                              validator: (String? value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please provide some details.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            FilledButton(
                              onPressed: _isSubmitting ? null : _submitForm,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Submit Response'),
                            ),
                            if (_isSubmitted)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(
                                  'Thanks! Your response was saved in Firebase.',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: const Color(0xFF107C10),
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
