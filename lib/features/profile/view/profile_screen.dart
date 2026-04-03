import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/profile_viewmodel.dart';
import 'package:ballchart/core/widgets/dialogues/EditAcademyDialog.dart';
import 'package:ballchart/core/widgets/dialogues/CreateTeamDialog.dart';
import 'package:ballchart/features/management/viewmodel/academy_provider.dart';
import 'package:ballchart/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:ballchart/features/coach/team_details/view/team_detail_screen.dart';
import 'package:ballchart/core/models/local_academy_models.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color primaryColor = Color(0xFFFFD900);
  static const Color bgColor = Color(0xFF131313);
  static const Color surfaceHigh = Color(0xFF201F1F);
  static const Color outlineColor = Color(0xFF9D8F79);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Consumer<ProfileViewmodel>(
          builder: (context, viewModel, _) {
            if (viewModel.isLoading) return const Center(child: CircularProgressIndicator(color: primaryColor));
            final user = viewModel.user;
            if (user == null) return const Center(child: Text('TERMINAL OFFLINE', style: TextStyle(color: outlineColor)));

            return RefreshIndicator(
              onRefresh: () => viewModel.loadProfile(forceRefresh: true),
              color: primaryColor,
              backgroundColor: const Color(0xFF2A2A2A),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIdentityHeader(user),
                    const SizedBox(height: 32),
                    _buildAcademyPartnership(context),
                    const SizedBox(height: 32),
                    const Text('COMMAND CENTER PROFILE', style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    const SizedBox(height: 16),
                    _buildBentoGrid(user),
                    const SizedBox(height: 32),
                    const Text('OPERATIONAL SETTINGS', style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    const SizedBox(height: 16),
                    _buildSystemActions(context),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildIdentityHeader(dynamic user) {
    return Column(
      children: [
        Center(
          child: Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [primaryColor, Color(0xFFFFBA29)])),
                child: CircleAvatar(radius: 46, backgroundColor: bgColor, backgroundImage: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuCb0bI6coVpoP1nmq-BKt9hjpg6sZbCVWPBjS4xHT90o3Rs_S3Tl_Vn22nn_J-Q0Ep_Y4PhcKb-FAW4J6RayKzeDP68Hg7ip3OdvUrJztJYBqFM7hP1-9WV8OLlyYGV1bJLKv9gCOa5zxnV9Ln22nn_J-Q0Ep_Y4PhcKb-FAW4J6RayKzeDP68Hg7ip3OdvUrJztJYBqFM7hP1-9WV8OLlyYGV1bJLKv9gCOa5zxnV9LnABtDkoiq_Hqhyq7cTEaGk5bKRWNm8AZceSh8oZG7jmsHsdOYs8300l4GkZ1khbKsEJslLRuMjEnLlPDSg_gAPsAtMM2y9hsNd2PgmSvNwHWxIK26axgbQF7plCm23')),
              ),
              Positioned(right: 2, bottom: 2, child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle, border: Border.fromBorderSide(BorderSide(color: bgColor, width: 3))))),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(user.username.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'Space Grotesk')),
        Text('${user.role.replaceAll('_', ' ').toUpperCase()} // ACTIVE SQUADRON', style: const TextStyle(color: outlineColor, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
      ],
    );
  }

  Widget _buildAcademyPartnership(BuildContext context) {
    return Consumer<AcademyProvider>(
      builder: (context, provider, _) {
        final academy = provider.academy;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(24), border: Border.all(color: primaryColor.withOpacity(0.1))),
          child: Column(
            children: [
              Row(
                children: [
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.shield, color: primaryColor, size: 24)),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('OFFICIAL PARTNERSHIP', style: TextStyle(color: outlineColor, fontSize: 8, fontWeight: FontWeight.bold)),
                        Text(academy.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_note, color: primaryColor, size: 24),
                    onPressed: () => _showEditAcademyDialog(context, provider),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _actionBtn(context, 'NEW SQUAD', Icons.add_moderator, () => _showCreateTeamDialog(context, provider)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _actionBtn(context, 'ENROLL PLAYER', Icons.person_add_alt_1, () {}),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _actionBtn(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(16)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black, size: 14),
            const SizedBox(width: 4),
            Expanded(child: Text(title, style: const TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5), textAlign: TextAlign.center, maxLines: 1)),
          ],
        ),
      ),
    );
  }

  void _showEditAcademyDialog(BuildContext context, AcademyProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditAcademyDialog(
        currentName: provider.academy.name,
        currentLogo: provider.academy.logoUrl,
        currentOwner: provider.adminName,
        currentEmail: provider.adminEmail,
      ),
    );
  }

  void _showCreateTeamDialog(BuildContext context, AcademyProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateTeamDialog(onTeamCreated: (name, tier, color, logo, coachId, assistantId) async {
        await provider.addTeamToBackend(Team(
          id: '',
          name: name,
          ageGroup: tier,
          colorValue: color.value,
          logoPath: logo,
          coachStaffId: coachId,
          assistantCoachStaffId: assistantId,
          players: [],
        ));
      }),
    );
  }

  Widget _buildBentoGrid(dynamic user) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _bentoCard('EMAIL ADDRESS', user.email, Icons.alternate_email)),
            const SizedBox(width: 16),
            Expanded(child: _bentoCard('EXPERIENCE', '12 YEARS', Icons.timeline)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _bentoCard('LICENSE ID', 'CQ-9842-X', Icons.badge)),
            const SizedBox(width: 16),
            Expanded(child: _bentoCard('TACTICAL IQ', '94.2', Icons.psychology)),
          ],
        ),
      ],
    );
  }

  Widget _bentoCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: surfaceHigh, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: outlineColor, size: 18),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          const Divider(color: Colors.white10),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: outlineColor, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildSystemActions(BuildContext context) {
    return Column(
      children: [
        _systemRow('DARK MODE OPERATIONAL', Icons.dark_mode, true),
        const SizedBox(height: 12),
        _systemRow('NOTIFICATIONS ACTIVE', Icons.notifications_active, true),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () => Provider.of<AuthViewmodel>(context, listen: false).logout(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.05), border: Border.all(color: Colors.redAccent.withOpacity(0.2)), borderRadius: BorderRadius.circular(24)),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.power_settings_new, color: Colors.redAccent, size: 20),
                const SizedBox(width: 12),
                Text('TERMINAL LOGOUT', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w900, fontFamily: 'Space Grotesk', letterSpacing: 1.5)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _systemRow(String label, IconData icon, bool val) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: surfaceHigh.withOpacity(0.5), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: outlineColor, size: 18),
              const SizedBox(width: 16),
              Text(label.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          ),
          Switch(value: val, onChanged: (v) {}, activeColor: primaryColor, activeTrackColor: primaryColor.withOpacity(0.2), inactiveTrackColor: Colors.white10),
        ],
      ),
    );
  }
}
