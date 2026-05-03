import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // IMPORTANT: Replace this with your Render.com URL before deploying to Vercel
  // Example: 'https://my-vote-api.onrender.com/api'
  static String get baseUrl {
    if (kIsWeb && Uri.base.host != 'localhost') {
      return 'https://YOUR_RENDER_URL_HERE.onrender.com/api';
    }
    return 'http://localhost:3000/api';
  }
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  Future<Map<String, dynamic>> getHealth() async {
    final res = await http.get(Uri.parse('$baseUrl/health'));
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> setupElection() async {
    final res = await http.post(Uri.parse('$baseUrl/election/setup'));
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> getPublicKey() async {
    final res = await http.get(Uri.parse('$baseUrl/election/public-key'));
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> getElectionStatus() async {
    final res = await http.get(Uri.parse('$baseUrl/election/status'));
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> registerVoter(String name) async {
    final res = await http.post(
      Uri.parse('$baseUrl/voter/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'voterName': name}),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> checkVoter(String hash) async {
    final res = await http.get(Uri.parse('$baseUrl/voter/check/$hash'));
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> castVote(String voterHash, String candidateId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/vote/cast'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'voterHash': voterHash, 'candidateId': candidateId}),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> getTally() async {
    final res = await http.get(Uri.parse('$baseUrl/vote/tally'));
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> getBlocks() async {
    final res = await http.get(Uri.parse('$baseUrl/ledger/blocks'));
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> verifyLedger() async {
    final res = await http.get(Uri.parse('$baseUrl/ledger/verify'));
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> launchSybilAttack({int count = 100}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/attack/sybil'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'count': count}),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> launchReplayAttack() async {
    final res = await http.post(Uri.parse('$baseUrl/attack/replay'));
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> launchTamperAttack() async {
    final res = await http.post(Uri.parse('$baseUrl/attack/tamper'));
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> launchMitmAttack() async {
    final res = await http.post(Uri.parse('$baseUrl/attack/mitm'));
    return jsonDecode(res.body);
  }
}
