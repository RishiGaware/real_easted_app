// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:inhabit_realties/constants/role_utils.dart';
import 'dart:convert';

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:inhabit_realties/controllers/auth/authController.dart';
import 'package:inhabit_realties/controllers/permissions/internetConnection.dart';
import 'package:inhabit_realties/controllers/role/roleController.dart';
import 'package:inhabit_realties/pages/widgets/appSnackBar.dart';
import 'package:inhabit_realties/pages/widgets/loader.dart';
import 'package:shared_preferences/shared_preferences.dart';

//splash page
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _isLoading = true;
  Timer? _navigationTimer;
  final InternetConnection _internetConnection = InternetConnection();
  final AuthController _auth = AuthController();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      await RoleUtils.initializeCurrentUser();
      // Start minimum display timer immediately
      final displayCompleter = Completer<void>();
      _navigationTimer = Timer(const Duration(seconds: 2), () {
        if (!displayCompleter.isCompleted) {
          displayCompleter.complete();
        }
      });

      // First check internet connectivity
      bool isInternetConnected = await _internetConnection
          .checkInternetConnection()
          .timeout(const Duration(seconds: 10));

      if (!isInternetConnected) {
        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.pushReplacementNamed(context, '/error/noInternet');
        }
        return;
      }

      // Get authentication and onboarding status
      final prefs = await SharedPreferences.getInstance();
      final seenOnboarding = prefs.getBool('onboarding_seen') ?? false;
      final authResult = await _auth.isAuthenticated();

      // Wait for minimum display time
      await displayCompleter.future;

      if (!mounted) return;

      setState(() => _isLoading = false);

      // Handle authentication result
      if (!authResult['success']) {
        // If auth check failed due to server error
        Navigator.pushReplacementNamed(context, '/error/serverError');
        return;
      }

      // Navigate based on auth status
      if (!authResult['isAuthenticated']) {
        Navigator.pushReplacementNamed(context, '/auth/login');
      } else {
        //await _initRole();
        if (seenOnboarding) {
          AppSnackBar.showSnackBar(
            context,
            'Welcome Back!',
            'Nice to see you again',
            ContentType.success,
          );
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          AppSnackBar.showSnackBar(
            context,
            'Welcome!',
            'Let\'s take a quick tour of the app',
            ContentType.help,
          );
          Navigator.pushReplacementNamed(context, '/onboarding');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/error/serverError');
      }
    }
  }

  Future<void> _initRole() async {
    var roleController = RoleController();
    final prefs = await SharedPreferences.getInstance();
    final currentUser = jsonDecode(prefs.getString('currentUser') ?? '{}');
    var currentUserRole = await roleController.getRoleById(
      currentUser['roleId'],
    );
    if (currentUserRole['statusCode'] == 200) {
      await prefs.setString(
          'currentUserRole', jsonEncode(currentUserRole['data']));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/applogo.png',
                height: 300,
                width: 300,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              Text(
                'INHABIT REALTIES',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                'WE PRESENT YOUR DREAMS',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 30),
              const Loader(),
            ],
          ),
        ),
      ),
    );
  }
}
