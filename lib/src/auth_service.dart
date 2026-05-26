import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'db.dart';

class AppUser {
  final String id;
  final String? email;
  final String? phone;
  final String? displayName;
  final String? photoUrl;
  final String provider;

  AppUser({required this.id, this.email, this.phone, this.displayName, this.photoUrl, required this.provider});

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'phone': phone,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'provider': provider,
      };

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
        id: m['id'] as String,
        email: m['email'] as String?,
        phone: m['phone'] as String?,
        displayName: m['displayName'] as String?,
        photoUrl: m['photoUrl'] as String?,
        provider: m['provider'] as String? ?? 'local',
      );
}

class AuthService {
  static AppUser? currentUser;

  Future<String> _hashPassword(String password) async {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> signUpWithEmail(String id, String email, String password, {String? displayName}) async {
    final db = await DatabaseProvider.database();
    final users = await db.query('users', where: 'email = ?', whereArgs: [email]);
    if (users.isNotEmpty) {
      return false;
    }

    final hash = await _hashPassword(password);
    final now = DateTime.now().toIso8601String();
    await db.insert('users', {
      'id': id,
      'email': email,
      'displayName': displayName,
      'passwordHash': hash,
      'provider': 'local',
      'createdAt': now,
    });
    return true;
  }

  Future<AppUser?> signInWithEmail(String email, String password) async {
    final db = await DatabaseProvider.database();
    final hash = await _hashPassword(password);
    final rows = await db.query('users', where: 'email = ? AND passwordHash = ?', whereArgs: [email, hash]);
    if (rows.isEmpty) return null;
    return AppUser.fromMap(rows.first);
  }

  Future<AppUser?> signInWithPhone(String phone, String pin) async {
    // Simple local phone+pin auth: pin is stored in passwordHash field for demo only.
    final db = await DatabaseProvider.database();
    final rows = await db.query('users', where: 'phone = ? AND passwordHash = ?', whereArgs: [phone, pin]);
    if (rows.isEmpty) return null;
    final user = AppUser.fromMap(rows.first);
    currentUser = user;
    return user;
  }

  Future<void> signUpWithPhone(String id, String phone, String pin) async {
    final db = await DatabaseProvider.database();
    final now = DateTime.now().toIso8601String();
    await db.insert('users', {
      'id': id,
      'phone': phone,
      'passwordHash': pin,
      'provider': 'phone',
      'createdAt': now,
    });
  }

  Future<void> signOut() async {
    final db = await DatabaseProvider.database();
    await db.delete('settings', where: 'key = ?', whereArgs: ['current_user_id']);
    currentUser = null;
  }

  Future<void> saveSession(String userId) async {
    final db = await DatabaseProvider.database();
    await db.insert('settings', {'key': 'current_user_id', 'value': userId});
  }

  Future<AppUser?> getSavedUser() async {
    final db = await DatabaseProvider.database();
    final res = await db.query('settings', where: 'key = ?', whereArgs: ['current_user_id']);
    if (res.isEmpty) return null;
    final userId = res.first['value'] as String;
    final users = await db.query('users', where: 'id = ?', whereArgs: [userId]);
    if (users.isEmpty) return null;
    final user = AppUser.fromMap(users.first);
    currentUser = user;
    return user;
  }
}
