import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:visual_notes/utils/custom_snackbars.dart'; // Import our custom snackbar utility

class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;
  bool get isLoading => _isLoading; // Expose loading state to UI

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners(); // Notify listeners (UI widgets) when loading state changes
  }

  // --- Sign In Function ---
  Future<void> signIn({
    required String email,
    required String password,
    required BuildContext context, // Pass context for SnackBar
  }) async {
    _setLoading(true); // Start loading
    try {
      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (res.user != null) {
        showSnackBar(context, 'Signed in successfully!');
      }
    } on AuthException catch (e) {
      showSnackBar(context, e.message, isError: true); // Show Supabase Auth errors
    } catch (e) {
      showSnackBar(context, 'An unexpected error occurred: $e', isError: true); // Catch other errors
    } finally {
      _setLoading(false); // Stop loading regardless of success/failure
    }
  }

  // --- Sign Up Function ---
  Future<void> signUp({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    _setLoading(true);
    try {
      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      if (res.user != null) {
        // Supabase might send a verification email depending on settings
        showSnackBar(context, 'Account created! Please check your email for verification if required.');
      }
    } on AuthException catch (e) {
      showSnackBar(context, e.message, isError: true);
    } catch (e) {
      showSnackBar(context, 'An unexpected error occurred: $e', isError: true);
    } finally {
      _setLoading(false);
    }
  }

  // --- Sign Out Function ---
  Future<void> signOut(BuildContext context) async {
    _setLoading(true);
    try {
      await _supabase.auth.signOut();
      showSnackBar(context, 'Signed out.');
    } on AuthException catch (e) {
      showSnackBar(context, e.message, isError: true);
    } catch (e) {
      showSnackBar(context, 'An unexpected error occurred: $e', isError: true);
    } finally {
      _setLoading(false);
    }
  }
}