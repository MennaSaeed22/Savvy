import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:savvy/providers/app_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String mobileNumber,
    required String dateOfBirth,
  }) async {
    try {
      final parsedDate = DateFormat("d / M / yyyy").parse(dateOfBirth);
      final formattedDate = DateFormat("yyyy-MM-dd").format(parsedDate);
      final AuthResponse authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'mobile_number': mobileNumber,
          'date_of_birth': formattedDate,
        },
      );
      
      if (authResponse.user != null) {
        try {
          final insertResponse = await _supabase.from('users').insert({
            'user_id': authResponse.user!.id,
            'email': email,
            'full_name': fullName,
            'phonenumber': mobileNumber,
            'data_of_birth': formattedDate, // Note: you have 'data_of_birth' instead of 'date_of_birth'
            'created_at': DateTime.now().toIso8601String(),
          });
          
          // For Supabase insert operations, check for errors differently
          // insertResponse will be a List if successful, or throw an exception if failed
          print('User data inserted successfully: $insertResponse');
          
        } catch (insertError) {
          print('Failed to insert user data: $insertError');
          // You might want to handle this differently - maybe delete the auth user
          // or let the user know there was an issue with profile creation
          throw Exception('Failed to create user profile: $insertError');
        }
      }
      
      return authResponse;
      
    } catch (e) {
      print('SignUp error: $e');
      rethrow;
    }
  }

  Future<AuthResponse> signIn(String email, String password, WidgetRef ref) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email, 
        password: password
      );
      await ref.read(userProvider.notifier).refresh();
      return response;
    } catch (e) {
      print('SignIn error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      print('SignOut error: $e');
      rethrow;
    }
  }

  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  String? getUserEmail() {
    final session = _supabase.auth.currentSession;
    return session?.user.email;
  }
}