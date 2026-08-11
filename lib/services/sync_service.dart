import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/habit_model.dart';
import '../models/user_profile_model.dart';
import 'database_helper.dart';

class SyncService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if internet is available
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // Upload a single habit to Firestore
  static Future<bool> uploadHabit(String uid, HabitModel habit) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('habits')
          .doc(habit.id)
          .set(habit.toMap());
      return true;
    } catch (e) {
      print('Firestore upload failed: $e');
      return false;
    }
  }

  // Delete a habit from Firestore
  static Future<bool> deleteHabit(String uid, String habitId) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('habits')
          .doc(habitId)
          .delete();
      return true;
    } catch (e) {
      print('Firestore delete failed: $e');
      return false;
    }
  }

  // Download all habits of a user from Firestore
  static Future<List<HabitModel>> downloadHabits(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('habits')
          .get();
      return snapshot.docs.map((doc) => HabitModel.fromMap(doc.data())).toList();
    } catch (e) {
      print('Firestore download failed: $e');
      return [];
    }
  }

  // Upload user profile to Firestore
  static Future<bool> uploadProfile(String uid, UserProfileModel profile) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .set({
            'name': profile.name,
            'avatarUrl': profile.avatarUrl,
            'avatarData': profile.avatarData != null ? Blob(profile.avatarData!) : null,
            'overallStreak': profile.overallStreak,
            'joinedDate': profile.joinedDate,
          });
      return true;
    } catch (e) {
      print('Firestore profile upload failed: $e');
      return false;
    }
  }

  // Download user profile from Firestore
  static Future<UserProfileModel?> downloadProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final blob = data['avatarData'] as Blob?;
        return UserProfileModel(
          userId: uid,
          name: data['name'] as String? ?? '',
          avatarUrl: data['avatarUrl'] as String? ?? '',
          avatarData: blob?.bytes,
          overallStreak: data['overallStreak'] as int? ?? 12,
          joinedDate: data['joinedDate'] as String? ?? '',
        );
      }
    } catch (e) {
      print('Firestore profile download failed: $e');
    }
    return null;
  }

  // Push all unsynced local habits to Firestore
  static Future<void> syncPending(String uid) async {
    final hasInternet = await hasInternetConnection();
    if (!hasInternet) return;

    final db = DatabaseHelper.instance;
    final unsynced = await db.getUnsyncedHabits();

    for (final habit in unsynced) {
      final success = await uploadHabit(uid, habit);
      if (success) {
        await db.markHabitSynced(habit.id);
      }
    }

    // Also sync profile if needed
    final email = await db.getLoggedInUserEmail();
    if (email != null) {
      final syncEnabled = await db.isCloudSyncEnabled(email);
      if (syncEnabled) {
        final profile = await db.getUserProfile(uid);
        await uploadProfile(uid, profile);
      }
    }
  }
}
