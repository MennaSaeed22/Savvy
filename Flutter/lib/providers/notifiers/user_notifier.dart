import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:savvy/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  UserNotifier(AuthService authService) : super(const AsyncValue.loading()) {
    _loadUserProfile();
  }

  final SupabaseClient _supabase = Supabase.instance.client;
  Map<String, dynamic>? _cachedUser;
  DateTime? _lastFetch;
  static const Duration _cacheExpiry = Duration(minutes: 10);

  Future<void> _loadUserProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        state = const AsyncValue.data(null);
        return;
      }
      // Debug: Log user ID
      print('Fetching profile for user ID: $userId');
      // Check cache validity
      if (_cachedUser != null &&  _lastFetch != null && DateTime.now().difference(_lastFetch!) < _cacheExpiry)
       {
        state = AsyncValue.data(_cachedUser);
        return;
      }
      final response = await _supabase
          .from('users')
          .select()
          .eq('user_id', userId)
          .single();
      // Debug: Log response
      print('User profile fetched: $response');
      _cachedUser = response;
      _lastFetch = DateTime.now();
      state = AsyncValue.data(_cachedUser);
    } catch (error, stackTrace) {
      // Debug: Log error
      print('Error fetching user profile: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Refresh user profile data
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    _cachedUser = null;
    _lastFetch = null;
    await _loadUserProfile();
  }

  // Update user profile
  Future<void> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? dateOfBirth,
    String? avatarUrl, 
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (phoneNumber != null) updates['phonenumber'] = phoneNumber;
      if (dateOfBirth != null) updates['data_of_birth'] = dateOfBirth;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      if (updates.isEmpty) return;

      final response = await _supabase
          .from('users')
          .update(updates)
          .eq('user_id', userId)
          .select()
          .single();

      _cachedUser = response;
      _lastFetch = DateTime.now();
      state = AsyncValue.data(_cachedUser);

    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Get cached user data without triggering a fetch
  Map<String, dynamic>? getCachedUser() {
    return _cachedUser;
  }

  // Clear cache (useful for logout)
  void clearCache() {
    _cachedUser = null;
    _lastFetch = null;
    state = const AsyncValue.data(null);
  }

  // Check if cache is expired
  bool get isCacheExpired {
    if (_lastFetch == null) return true;
    return DateTime.now().difference(_lastFetch!) >= _cacheExpiry;
  }

}