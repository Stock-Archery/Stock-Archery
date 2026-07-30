import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/mongodb_service.dart';

class UserAccessPage extends StatefulWidget {
  const UserAccessPage({super.key});

  @override
  State<UserAccessPage> createState() => _UserAccessPageState();
}

class _UserAccessPageState extends State<UserAccessPage> {
  final MongoDBService _mongoService = MongoDBService();
  final TextEditingController _searchController = TextEditingController();

  bool _isSearching = false;
  bool _isSaving = false;
  Map<String, dynamic>? _foundUser;
  bool _hasSearched = false;

  // Track the premium switch values locally
  bool _isSOB = false;
  bool _isXaud = false;
  bool _isCrypto = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Perform search for user by email or phone number
  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an email address or phone number'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    print('[log] UserAccessPage — searching user: "$query"');
    setState(() {
      _isSearching = true;
      _foundUser = null;
      _hasSearched = true;
    });

    try {
      final user = await _mongoService.searchUser(query);
      if (user != null) {
        print('[log] UserAccessPage — user found: ${user['email']}');
        setState(() {
          _foundUser = user;
          _isSOB = user['isSOB_alert_premium'] ?? false;
          _isXaud = user['isXaud_alert_premium'] ?? false;
          _isCrypto = user['isCrypto_alert_premium'] ?? false;
        });
      } else {
        print('[log] UserAccessPage — user not found for "$query"');
        setState(() {
          _foundUser = null;
        });
      }
    } catch (e) {
      print('[log] UserAccessPage — search error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  // Save the updated subscription settings via admin server API
  Future<void> _saveAccess() async {
    if (_foundUser == null) return;

    setState(() {
      _isSaving = true;
    });

    final firebaseUid = _foundUser!['firebaseUid'];
    final updates = {
      'isSOB_alert_premium': _isSOB,
      'isXaud_alert_premium': _isXaud,
      'isCrypto_alert_premium': _isCrypto,
    };

    print('[log] UserAccessPage — saving alert access for uid: $firebaseUid, updates: $updates');
    try {
      final success = await _mongoService.updateUserAlertAccess(firebaseUid, updates);
      print('[log] UserAccessPage — save result: $success');
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Alert access updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        // Refresh local user details display
        setState(() {
          _foundUser!['isSOB_alert_premium'] = _isSOB;
          _foundUser!['isXaud_alert_premium'] = _isXaud;
          _foundUser!['isCrypto_alert_premium'] = _isCrypto;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update alert access in backend'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Give Alert Access',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Input Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search User Profile',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: GoogleFonts.outfit(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Enter Email or Phone number...',
                              hintStyle: GoogleFonts.outfit(color: Colors.white38, fontSize: 14),
                              prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            onSubmitted: (_) => _performSearch(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isSearching ? null : _performSearch,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSearching
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Search Results Section
            if (_hasSearched && !_isSearching) ...[
              if (_foundUser == null) ...[
                // User Not Found State
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Column(
                      children: [
                        const Icon(Icons.person_off_rounded, color: Colors.white24, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          'User Not Found',
                          style: GoogleFonts.outfit(color: Colors.white54, fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'No registered profile matches this query.',
                          style: GoogleFonts.outfit(color: Colors.white38, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // User Details and Toggle Dashboard Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                            child: Text(
                              _foundUser!['name']?.substring(0, 1).toUpperCase() ?? 'U',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF6366F1),
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _foundUser!['name'] ?? 'Unknown User',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _foundUser!['email'] ?? '',
                                  style: GoogleFonts.outfit(color: Colors.white54, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white10, height: 32),

                      // User Metadata
                      _buildDetailRow('Phone Number', _foundUser!['phoneNumber'] ?? '-'),
                      const SizedBox(height: 12),
                      _buildDetailRow('Location', _foundUser!['location'] ?? '-'),
                      const SizedBox(height: 12),
                      _buildDetailRow('Firebase UID', _foundUser!['firebaseUid'] ?? '-'),
                      
                      const Divider(color: Colors.white10, height: 32),

                      // Access Settings Section
                      Text(
                        'Premium Alert Subscriptions',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Toggle 1: SOB Alerts
                      _buildAlertSwitchTile(
                        title: 'SOB Alert Premium',
                        subtitle: 'Toggles access for Strategy of Breakout alerts',
                        value: _isSOB,
                        onChanged: (val) => setState(() => _isSOB = val),
                      ),
                      const SizedBox(height: 12),

                      // Toggle 2: XAUD Alerts
                      _buildAlertSwitchTile(
                        title: 'XAUD Alert Premium',
                        subtitle: 'Toggles access for Gold/XAUUSD alerts',
                        value: _isXaud,
                        onChanged: (val) => setState(() => _isXaud = val),
                      ),
                      const SizedBox(height: 12),

                      // Toggle 3: Crypto Alerts
                      _buildAlertSwitchTile(
                        title: 'Crypto Alert Premium',
                        subtitle: 'Toggles access for cryptocurrency alerts',
                        value: _isCrypto,
                        onChanged: (val) => setState(() => _isCrypto = val),
                      ),

                      const SizedBox(height: 32),

                      // Submit/Save Updates
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveAccess,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                            shadowColor: const Color(0xFF6366F1).withOpacity(0.3),
                          ),
                          child: _isSaving
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  'Save Alert Subscriptions',
                                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13)),
        Text(value, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildAlertSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF6366F1),
            activeTrackColor: const Color(0xFF6366F1).withOpacity(0.3),
            inactiveThumbColor: Colors.white38,
            inactiveTrackColor: Colors.white10,
          ),
        ],
      ),
    );
  }
}
