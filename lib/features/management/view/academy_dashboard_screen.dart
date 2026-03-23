import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:courtiq/core/models/local_academy_models.dart';
import 'package:courtiq/core/constants/colors.dart';
import 'package:courtiq/core/widgets/dialogues/CreateTeamDialog.dart';
import 'package:courtiq/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:courtiq/features/coach/team_details/view/team_detail_screen.dart';
import 'package:courtiq/features/management/viewmodel/academy_provider.dart';

class AcademyDashboardScreen extends StatefulWidget {
  const AcademyDashboardScreen({super.key});

  @override
  State<AcademyDashboardScreen> createState() => _AcademyDashboardScreenState();
}

class _AcademyDashboardScreenState extends State<AcademyDashboardScreen> {
  int _currentTab = 0;
  final ImagePicker _imagePicker = ImagePicker();

  // BallChart Design Token
  static const Color primaryColor = Color(0xFFFFD900);
  static const Color bgColor = Color(0xFF111111);
  static const Color surfaceColor = Color(0xFF1A1A1A);
  static const Color cardColor = Color(0xFF222222);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AcademyProvider>().loadAdminOverview();
    });
  }

  void _showInfo(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background Gradient Overlay
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withOpacity(0.04),
                boxShadow: [
                  BoxShadow(color: primaryColor.withOpacity(0.05), blurRadius: 100, spreadRadius: 50),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Consumer<AcademyProvider>(
              builder: (context, provider, _) {
                return Column(
                  children: [
                    _buildTopHeader(provider),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _buildBody(provider),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildModernBottomNav(),
    );
  }

  Widget _buildTopHeader(AcademyProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BALLCHART',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'Academy Admin',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _headerIcon(Icons.search_rounded),
                  const SizedBox(width: 8),
                  _headerIcon(Icons.notifications_none_rounded),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _confirmLogout,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  Widget _buildBody(AcademyProvider provider) {
    switch (_currentTab) {
      case 0: return _buildDashboardSection(provider);
      case 1: return _buildStaffSection(provider);
      case 2: return _buildStatsSection(provider); // Battles/Stats
      case 3: return _buildProfileSection(provider);
      default: return _buildDashboardSection(provider);
    }
  }

  Widget _buildDashboardSection(AcademyProvider provider) {
    final totalPlayers = provider.academy.teams.fold<int>(0, (sum, team) => sum + team.players.length);
    
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Metrics Grid
        Row(
          children: [
            Expanded(child: _metricCard('Active Teams', '${provider.academy.teams.length}', Icons.groups_rounded)),
            const SizedBox(width: 12),
            Expanded(child: _metricCard('Total Staff', '${provider.academy.staff.length}', Icons.badge_rounded)),
            const SizedBox(width: 12),
            Expanded(child: _metricCard('Players', '$totalPlayers', Icons.sports_basketball_rounded)),
          ],
        ),
        const SizedBox(height: 32),

        // Active Teams Section
        _sectionHeader('Active Teams', 'View All', () => setState(() => _currentTab = 1)),
        const SizedBox(height: 16),
        if (provider.academy.teams.isEmpty)
          _emptyState('No teams created yet', Icons.group_off_rounded)
        else
          ...provider.academy.teams.take(3).map((team) => _teamListTile(team)),

        const SizedBox(height: 32),

        // Staff Overview
        _sectionHeader('Staff Overview', 'Manage', () => setState(() => _currentTab = 1)),
        const SizedBox(height: 16),
        if (provider.academy.staff.isEmpty)
          _emptyState('No staff members added', Icons.person_off_rounded)
        else
          ...provider.academy.staff.take(2).map((staff) => _staffListTile(staff)),
          
        const SizedBox(height: 24),
        
        // Add Button
        _actionButton('ADD NEW TEAM', Icons.add_rounded, () => _showCreateTeamDialog(context)),
        const SizedBox(height: 80), // Space for bottom nav
      ],
    );
  }

  Widget _metricCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryColor, size: 20),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String actionText, VoidCallback onAction) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        GestureDetector(
          onTap: onAction,
          child: Text(
            actionText,
            style: const TextStyle(color: primaryColor, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _teamListTile(Team team) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Color(team.colorValue).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.shield_rounded, color: Color(team.colorValue)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(team.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  '${team.players.length} Players • ${team.ageGroup}',
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white24),
        ],
      ),
    );
  }

  Widget _staffListTile(Staff staff) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: primaryColor.withOpacity(0.1),
            child: Text(staff.name[0], style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(staff.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(
                  staff.role.toUpperCase(),
                  style: TextStyle(color: primaryColor.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String text, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5)),
          ],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: bgColor, size: 20),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(color: bgColor, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String message, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white10, size: 48),
        const SizedBox(height: 12),
        Text(message, style: const TextStyle(color: Colors.white24)),
      ],
    );
  }

  Widget _buildModernBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _navItem(0, Icons.grid_view_rounded, 'Dashboard'),
          _navItem(1, Icons.group_rounded, 'Staff'),
          _navItem(2, Icons.swords, 'Battles'),
          _navItem(3, Icons.person_rounded, 'Profile'),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final bool isSelected = _currentTab == index;
    return GestureDetector(
      onTap: () => setState(() => _currentTab = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? primaryColor : Colors.white24, size: 24),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? primaryColor : Colors.white24,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // --- Placeholder methods for functionality (Need to keep original logic) ---

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text('Log out', style: TextStyle(color: Colors.white)),
        content: const Text('Do you want to log out of admin dashboard?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (shouldLogout == true && mounted) {
      await context.read<AuthViewmodel>().logout(context);
    }
  }

  void _showCreateTeamDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => const CreateTeamDialog());
  }

  // Define these to avoid compile errors, will implement properly in next steps
  Widget _buildStaffSection(AcademyProvider provider) => _buildDashboardSection(provider);
  Widget _buildStatsSection(AcademyProvider provider) => _buildDashboardSection(provider);
  Widget _buildProfileSection(AcademyProvider provider) => _buildDashboardSection(provider);
}
