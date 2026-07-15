import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:play_smart/shared/types/domain_types.dart';

/// A lightweight record of an account previously signed into on this device
/// — supports "Switch Account" (e.g. one person with both an athlete and a
/// recruiter account). Never stores a password; the user still authenticates
/// via Supabase Auth, this only saves the retyping of an email address.
class KnownAccount {
  final String email;
  final String name;
  final AccountRole role;

  const KnownAccount({required this.email, required this.name, required this.role});

  Map<String, dynamic> toJson() => {'email': email, 'name': name, 'role': role.name};

  factory KnownAccount.fromJson(Map<String, dynamic> json) => KnownAccount(
        email: json['email'] as String,
        name: json['name'] as String,
        role: AccountRole.values.byName(json['role'] as String),
      );
}

/// Local-only (per-device) list of known accounts, backed by SharedPreferences.
class KnownAccountsStore {
  static const _key = 'known_accounts';

  Future<List<KnownAccount>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => KnownAccount.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Add or update a remembered account (keyed by email).
  Future<void> remember(User user) async {
    final accounts = await getAll();
    final updated = [
      ...accounts.where((a) => a.email != user.email),
      KnownAccount(email: user.email, name: user.name, role: user.role),
    ];
    await _save(updated);
  }

  Future<void> forget(String email) async {
    final accounts = await getAll();
    await _save(accounts.where((a) => a.email != email).toList());
  }

  Future<void> _save(List<KnownAccount> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(accounts.map((a) => a.toJson()).toList()));
  }
}
