import 'package:flutter/material.dart';
import 'widgets/hierarchy_management_widget.dart';
import 'package:provider/provider.dart';
import '../../../profile/viewmodel/profile_viewmodel.dart';
import '../../../../core/repositories/dashboard_repository.dart';
import '../../../staff/service/staff_service.dart';

class TeamDetailScreen extends StatefulWidget {
  final String teamName;

  const TeamDetailScreen({super.key, required this.teamName});

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  final DashboardRepository _dashboardRepository = DashboardRepository();
  final StaffService _staffService = StaffService();

  // BallChart Design Tokens
  static const Color primaryColor = Color(0xFFFFD900);
  static const Color bgColor = Color(0xFF111111);
  static const Color cardColor = Color(0xFF1A1A1A);

  String? _extractStaffName(
    dynamic staffRef,
    List<Map<String, dynamic>> staffList,
  ) {
    if (staffRef is Map) {
      final mapped = staffRef.cast<String, dynamic>();
      final username = mapped['username']?.toString();
      if (username != null && username.isNotEmpty) return username;
      final id = mapped['_id']?.toString();
      if (id != null && id.isNotEmpty) {
        final matched = staffList.where((s) => s['_id']?.toString() == id).toList();
        if (matched.isNotEmpty) return matched.first['username']?.toString();
      }
    } else if (staffRef != null) {
      final id = staffRef.toString();
      if (id.isNotEmpty) {
        final matched = staffList.where((s) => s['_id']?.toString() == id).toList();
        if (matched.isNotEmpty) return matched.first['username']?.toString();
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<ProfileViewmodel>().user;
    final localRole = user?.role;

    return Scaffold(
      backgroundColor: bgColor,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardRepository.getCoachDashboard(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }
          final data = snapshot.data!;
          final profile = (data['profile'] as Map?)?.cast<String, dynamic>() ?? {};
          final role = (profile['role']?.toString() ?? localRole ?? 'coach');
          final permissions = (profile['permissions'] as Map?)?.cast<String, dynamic>() ?? {};
          final isAdminLike = role == 'admin' || role == 'head_coach';
          final canCreatePlayers = isAdminLike || permissions['createPlayer'] == true;
          final canUpdatePlayers = isAdminLike || permissions['updatePlayer'] == true;
          final canDeletePlayers = isAdminLike || permissions['deletePlayer'] == true;

          final teams = (data['teams'] as List? ?? [])
              .cast<Map>()
              .map((e) => e.cast<String, dynamic>())
              .toList();
          final staffList = (data['staff'] as List? ?? [])
              .cast<Map>()
              .map((e) => e.cast<String, dynamic>())
              .toList();
          final team = teams.firstWhere(
            (t) => (t['name']?.toString().toLowerCase() ?? '') == widget.teamName.toLowerCase(),
            orElse: () => {},
          );
          final players = (team['players'] as List? ?? [])
              .cast<Map>()
              .map((e) => e.cast<String, dynamic>())
              .toList();
          final teamId = team['_id']?.toString() ?? '';
          final coachName = _extractStaffName(team['coachStaffId'], staffList);
          final assistantCoachName = _extractStaffName(team['assistantCoachStaffId'], staffList);

          return CustomScrollView(
            slivers: [
              // Beautiful Header
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: bgColor,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
                  title: Text(
                    widget.teamName.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                      letterSpacing: -0.5,
                    ),
                  ),
                  background: Stack(
                    children: [
                      Positioned(
                        right: -20,
                        top: -20,
                        child: Icon(Icons.shield_rounded, size: 140, color: Colors.white.withOpacity(0.03)),
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hierarchy Visualization
                      const Text(
                        'TEAM ARCHITECTURE',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      HierarchyManagementWidget(
                        onPlayerAdded: (_) {
                          if (mounted) setState(() {});
                        },
                        role: role,
                        teamId: teamId,
                        canCreatePlayer: canCreatePlayers,
                        coachName: coachName,
                        assistantCoachName: assistantCoachName,
                      ),
                      
                      const SizedBox(height: 48),

                      // Roster Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TEAM ROSTER',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${players.length}',
                              style: const TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      if (players.isEmpty)
                        _buildEmptyRoster()
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: players.length,
                          itemBuilder: (context, index) {
                            final p = players[index];
                            return _buildRosterItem(
                              p['_id']?.toString() ?? '',
                              p['username']?.toString() ?? 'Player',
                              p['position']?.toString() ?? '-',
                              p['email']?.toString() ?? '',
                              (index + 1).toString().padLeft(2, '0'),
                              canUpdatePlayers,
                              canDeletePlayers,
                              () => _deletePlayer(p['_id']?.toString() ?? ''),
                              () => _editPlayerDialog(
                                p['_id']?.toString() ?? '',
                                p['username']?.toString() ?? '',
                                p['email']?.toString() ?? '',
                                p['position']?.toString() ?? '',
                                p['ageRange']?.toString() ?? '',
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyRoster() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Icon(Icons.person_add_disabled_rounded, color: Colors.white10, size: 64),
          const SizedBox(height: 16),
          const Text('Roster is currently empty', style: TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _buildRosterItem(
    String playerId,
    String name,
    String position,
    String email,
    String number,
    bool canEdit,
    bool canDelete,
    VoidCallback onRemove,
    VoidCallback onEdit,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: const TextStyle(color: primaryColor, fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  position.toUpperCase(),
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit_note_rounded, color: Colors.white24, size: 22),
              onPressed: onEdit,
            ),
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent.withOpacity(0.3), size: 22),
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }

  Future<void> _deletePlayer(String playerId) async {
    if (playerId.isEmpty) return;
    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Remove Athlete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: const Text('Are you sure you want to remove this player from the roster?', style: TextStyle(color: Colors.white70)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                child: const Text('REMOVE'),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;

    try {
      await _staffService.deletePlayer(playerId);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Player removed from roster'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _editPlayerDialog(
    String playerId,
    String currentName,
    String currentEmail,
    String currentPosition,
    String currentAgeRange,
  ) async {
    if (playerId.isEmpty) return;
    final nameController = TextEditingController(text: currentName);
    final emailController = TextEditingController(text: currentEmail);
    final passwordController = TextEditingController();
    final positionController = TextEditingController(text: currentPosition);
    final ageRangeController = TextEditingController(text: currentAgeRange);

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Edit Athlete Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogField('Name', nameController),
              const SizedBox(height: 16),
              _buildDialogField('Login Email', emailController, type: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildDialogField('Reset Password (Optional)', passwordController, obscure: true),
              const SizedBox(height: 16),
              _buildDialogField('Position', positionController),
              const SizedBox(height: 16),
              _buildDialogField('Age Range', ageRangeController),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL', style: TextStyle(color: Colors.white24))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.black),
            child: const Text('SAVE CHANGES', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (saved != true) return;

    try {
      await _staffService.updatePlayer(
        playerId: playerId,
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        position: positionController.text.trim(),
        ageRange: ageRangeController.text.trim(),
      );
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Widget _buildDialogField(String label, TextEditingController controller, {TextInputType type = TextInputType.text, bool obscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: type,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.03),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryColor)),
          ),
        ),
      ],
    );
  }
}
