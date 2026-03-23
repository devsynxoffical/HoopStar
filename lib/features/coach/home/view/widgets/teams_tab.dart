import 'package:flutter/material.dart';
import 'package:courtiq/core/widgets/dialogues/CreateTeamDialog.dart';
import 'package:courtiq/core/widgets/home/team_card.dart';
import 'package:courtiq/core/models/local_academy_models.dart';
import 'package:courtiq/features/coach/team_details/view/team_detail_screen.dart';
import 'package:courtiq/core/repositories/dashboard_repository.dart';
import 'package:courtiq/features/management/viewmodel/academy_provider.dart';
import 'package:provider/provider.dart';

class TeamsTab extends StatefulWidget {
  const TeamsTab({super.key});

  @override
  State<TeamsTab> createState() => _TeamsTabState();
}

class _TeamsTabState extends State<TeamsTab> {
  final DashboardRepository _dashboardRepository = DashboardRepository();
  late Future<List<Map<String, dynamic>>> _teamsFuture;

  // BallChart Design Tokens
  static const Color primaryColor = Color(0xFFFFD900);
  static const Color bgColor = Color(0xFF111111);

  @override
  void initState() {
    super.initState();
    _teamsFuture = _loadTeams();
  }

  Future<List<Map<String, dynamic>>> _loadTeams() async {
    final data = await _dashboardRepository.getCoachDashboard();
    final teams = (data['teams'] as List? ?? [])
        .cast<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList();
    return teams;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'ACADEMY TEAMS',
            style: TextStyle(
              color: primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Manage rosters and elite divisions for the academy.',
            style: TextStyle(color: Colors.white60, fontSize: 14),
          ),
          const SizedBox(height: 32),

          FutureBuilder<List<Map<String, dynamic>>>(
            future: _teamsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: CircularProgressIndicator(color: primaryColor),
                  ),
                );
              }
              
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading teams',
                    style: TextStyle(color: Colors.redAccent.withOpacity(0.7)),
                  ),
                );
              }

              final teams = snapshot.data ?? [];
              
              if (teams.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(48),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.shield_outlined, color: Colors.white.withOpacity(0.1), size: 64),
                      const SizedBox(height: 16),
                      const Text('No teams active', style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                );
              }

              return Column(
                children: teams
                    .map((team) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TeamDetailScreen(teamName: team['name']?.toString() ?? ''),
                                ),
                              );
                            },
                            child: TeamCard(
                              title: team['name']?.toString() ?? 'Team',
                              members: '${(team['players'] as List? ?? []).length} members',
                              icon: Icons.shield_rounded,
                              iconBg: Color((team['colorValue'] is int) ? team['colorValue'] as int : 0xFFF59E0B),
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
          
          const SizedBox(height: 32),
          
          // Add Team Button
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                barrierDismissible: true,
                builder: (_) => CreateTeamDialog(
                  onTeamCreated: (name, age, color, logoPath) async {
                    final provider = context.read<AcademyProvider>();
                    await provider.addTeamToBackend(
                      Team(
                        id: provider.nextId('t'),
                        name: name,
                        players: const [],
                        ageGroup: age,
                        colorValue: color.toARGB32(),
                        logoPath: logoPath,
                      ),
                    );
                    if (mounted) {
                      setState(() {
                        _teamsFuture = _loadTeams();
                      });
                    }
                  },
                ),
              );
            },
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
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_business_rounded, color: Colors.black, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'CREATE NEW TEAM',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
