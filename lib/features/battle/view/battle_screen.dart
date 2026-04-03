import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/battle_viewmodel.dart';
import '../../../core/constants/colors.dart';
import '../../../core/widgets/battle/battle_header.dart';
import '../../../core/widgets/battle/rank_progress_card.dart';
import '../../../core/models/battle_model.dart';
import '../../profile/viewmodel/profile_viewmodel.dart';

class BattleScreen extends StatefulWidget {
  const BattleScreen({super.key});

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  BattleViewmodel? _battleViewmodel;
  
  static const Color primaryColor = Color(0xFFFFD900); // FDB927 equivalent
  static const Color bgColor = Color(0xFF131313);
  static const Color surfaceHigh = Color(0xFF2A2A2A); // matching the surface-container-high
  static const Color surfaceLow = Color(0xFF1C1B1B);
  static const Color surfaceContainer = Color(0xFF201F1F);
  static const Color outlineColor = Color(0xFF9D8F79);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataWithRetry();
    });
  }

  Future<void> _loadDataWithRetry({int retryCount = 3}) async {
    for (int i = 0; i < retryCount; i++) {
      try {
        final battleViewModel = context.read<BattleViewmodel>();
        _battleViewmodel = battleViewModel;
        await battleViewModel.loadBattles();
        battleViewModel.startLiveUpdates(); // Start real-time updates
        
        final profileViewModel = context.read<ProfileViewmodel>();
        if (profileViewModel.user == null) {
          await profileViewModel.loadProfile(forceRefresh: true);
        }
        break; // Success, exit retry loop
      } catch (e) {
        if (i == retryCount - 1) {
          // Last retry failed, show error
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to load battle data: ${e.toString().replaceAll('Exception: ', '')}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () => _loadDataWithRetry(),
                ),
              ),
            );
          }
        } else {
          // Wait before retrying
          await Future.delayed(Duration(milliseconds: 1000 * (i + 1)));
        }
      }
    }
  }

  @override
  void dispose() {
    _battleViewmodel?.stopLiveUpdates();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileVm = context.watch<ProfileViewmodel>();
    final battleVm = context.watch<BattleViewmodel>();

    // Show loading state
    if (battleVm.isLoading && battleVm.battles.isEmpty) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: _buildAppBarTitle(),
          backgroundColor: bgColor,
          elevation: 0,
          centerTitle: false,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: primaryColor),
              SizedBox(height: 16),
              Text('Loading Battles...', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    }

    // Show error state
    if (battleVm.errorMessage != null && battleVm.battles.isEmpty) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: _buildAppBarTitle(),
          backgroundColor: bgColor,
          elevation: 0,
          centerTitle: false,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                Text(
                  'Error Loading Battles',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  battleVm.errorMessage!,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _loadDataWithRetry(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('RETRY'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: (profileVm.user?.role == 'coach' || 
          profileVm.user?.role == 'head_coach' || 
          profileVm.user?.role == 'admin')
          ? FloatingActionButton(
              backgroundColor: primaryColor,
              onPressed: () => _showCreateBattleDialog(context),
              child: const Icon(Icons.add, color: Colors.black),
            )
          : null,
      appBar: AppBar(
        title: _buildAppBarTitle(),
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLiveBattleHero(),
              const SizedBox(height: 48),
              _buildBattleRepository(),
              const SizedBox(height: 48),
              _buildStrategicProfiles(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBarTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            Icon(Icons.menu, color: primaryColor),
            SizedBox(width: 8),
            Text('ELITE ATHLETIC', style: TextStyle(color: primaryColor, fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'Space Grotesk', letterSpacing: 2.0)),
          ],
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: surfaceHigh, borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: primaryColor, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  const Text('2 LIVE', style: TextStyle(color: outlineColor, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLiveBattleHero() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: surfaceHigh,
        borderRadius: BorderRadius.circular(32),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor.withOpacity(0.2), bgColor],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ACTIVE STADIUM', style: TextStyle(color: Color(0xFFFFBA29), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
                SizedBox(height: 4),
                Text('CRYPTO.COM ARENA', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF93000A), borderRadius: BorderRadius.circular(4)),
                      child: const Text('LIVE', style: TextStyle(color: Color(0xFFFFDAD6), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    ),
                    const SizedBox(width: 12),
                    const Text('Q3 04:12 REMAINING', style: TextStyle(color: primaryColor, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TITANS', style: TextStyle(color: outlineColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
                          SizedBox(height: 4),
                          Text('102', style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, fontFamily: 'Space Grotesk')),
                        ],
                      ),
                    ),
                    Container(height: 48, width: 1, color: outlineColor.withOpacity(0.3)),
                    const SizedBox(width: 32),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PHANTOMS', style: TextStyle(color: outlineColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
                          SizedBox(height: 4),
                          Text('98', style: TextStyle(color: primaryColor, fontSize: 48, fontWeight: FontWeight.w900, fontFamily: 'Space Grotesk')),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [primaryColor, Color(0xFFFFDCA3)]),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () {},
                          child: const Text('COMMAND CENTER', style: TextStyle(color: Color(0xFF422D00), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: outlineColor.withOpacity(0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        onPressed: () {},
                        child: const Text('PLAY-BY-PLAY', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBattleRepository() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: primaryColor, width: 4)),
          ),
          padding: const EdgeInsets.only(left: 16),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BATTLE REPOSITORY', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
                  SizedBox(height: 4),
                  Text('OPERATIONAL LOGS & SCHEDULING', style: TextStyle(color: outlineColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
                ],
              ),
              Icon(Icons.tune, color: outlineColor),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _repositoryRow('vs METRO STARS', 'Yesterday • Madison Square Garden', 'LOG', primaryColor, 'W 114-92', '+12.4 Efficiency', const Color(0xFFFFE16D)),
        const SizedBox(height: 12),
        _repositoryRow('vs COASTAL KINGS', 'Tomorrow 19:30 • Delta Center', 'UPC', const Color(0xFF14D7FF), null, null, null),
        const SizedBox(height: 12),
        _repositoryRow('vs ELITE UNITED', 'Oct 12 • FTX Arena', 'LOG', primaryColor, 'L 88-102', '-4.2 Fatigue Index', const Color(0xFFFFB4AB)),
      ],
    );
  }

  Widget _repositoryRow(String title, String subtitle, String iconText, Color borderAccColor, String? score, String? stat, Color? statColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: borderAccColor, width: 4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Text(iconText, style: TextStyle(color: borderAccColor, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk'))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
                      const SizedBox(height: 4),
                      Text(subtitle.toUpperCase(), style: const TextStyle(color: outlineColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (score != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(score, style: TextStyle(color: statColor, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
                const SizedBox(height: 4),
                Text(stat!.toUpperCase(), style: TextStyle(color: statColor?.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            )
          else
            OutlinedButton(
               style: OutlinedButton.styleFrom(
                  side: BorderSide(color: outlineColor.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
               ),
               onPressed: () {},
               child: const Text('PREVIEW INTEL', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            ),
        ],
      ),
    );
  }

  Widget _buildStrategicProfiles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: Color(0xFF14D7FF), width: 4)),
          ),
          padding: const EdgeInsets.only(left: 16),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('STRATEGIC PROFILES', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
              SizedBox(height: 4),
              Text('SCOUTING INTELLIGENCE', style: TextStyle(color: outlineColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _scoutCardPlayer(),
        const SizedBox(height: 16),
        _scoutCardTeamAnalysis(),
      ],
    );
  }

  Widget _scoutCardPlayer() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               const Text('TARGET FOCUS', style: TextStyle(color: Color(0xFFADEBFF), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                 decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(4)),
                 child: const Text('ELITE', style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold)),
               ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
             children: [
                Container(
                   width: 50,
                   height: 50,
                   decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                   ),
                   child: const Icon(Icons.person, color: outlineColor, size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                   child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Text('Marcus "Ghost" Chen', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
                      ],
                   ),
                ),
             ],
          ),
          const SizedBox(height: 24),
          Row(
             children: [
                Expanded(child: _scoutStat('PER', '28.4', Colors.white)),
                const SizedBox(width: 8),
                Expanded(child: _scoutStat('DEF', 'A+', const Color(0xFFADEBFF))),
                const SizedBox(width: 8),
                Expanded(child: _scoutStat('STK', '88%', primaryColor)),
             ],
          ),
        ],
      ),
    );
  }

  Widget _scoutStat(String label, String value, Color color) {
    return Container(
       padding: const EdgeInsets.symmetric(vertical: 12),
       decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
       child: Column(
          children: [
             Text(label, style: const TextStyle(color: outlineColor, fontSize: 8, fontWeight: FontWeight.bold)),
             const SizedBox(height: 4),
             Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
          ],
       ),
    );
  }

  Widget _scoutCardTeamAnalysis() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            Container(
               width: 50,
               height: 50,
               decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
               child: const Icon(Icons.analytics, color: outlineColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
               child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      const Text('TEAM ANALYSIS', style: TextStyle(color: outlineColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2.0)),
                      const SizedBox(height: 12),
                      const Text('PHANTOMS OFFENSIVE REED', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
                      const SizedBox(height: 8),
                      const Text('High tendency for corner three conversion in transition. Strategy: Implement heavy double-screen coverage.', style: TextStyle(color: outlineColor, fontSize: 12, height: 1.4)),
                      const SizedBox(height: 16),
                      Wrap(
                         spacing: 8,
                         children: [
                            _tag('TRANSITION PLAY'),
                            _tag('3PT FOCUS'),
                         ],
                      ),
                  ],
               ),
            ),
         ],
      ),
    );
  }

  Widget _tag(String title) {
     return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: const Color(0xFFADEBFF).withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
        child: Text(title, style: const TextStyle(color: Color(0xFFADEBFF), fontSize: 9, fontWeight: FontWeight.bold)),
     );
  }

  void _showCreateBattleDialog(BuildContext context) {
    final locationController = TextEditingController();
    DateTime tempDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceHigh,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CREATE BATTLE', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'Space Grotesk')),
                    const SizedBox(height: 8),
                    const Text('SCHEDULE A MATCH LOCATION AND TIME', style: TextStyle(color: outlineColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const SizedBox(height: 24),
                    TextField(
                      controller: locationController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'LOCATION',
                        labelStyle: const TextStyle(color: outlineColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                        filled: true,
                        fillColor: bgColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'DATE: ${tempDate.year}-${tempDate.month.toString().padLeft(2, '0')}-${tempDate.day.toString().padLeft(2, '0')} ${tempDate.hour.toString().padLeft(2, '0')}:${tempDate.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      trailing: const Icon(Icons.calendar_month, color: primaryColor),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: tempDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          if (!context.mounted) return;
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(tempDate),
                          );
                          if (time != null) {
                            setModalState(() {
                              tempDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                            });
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        onPressed: () async {
                          if (locationController.text.trim().isEmpty) return;
                          final vm = context.read<BattleViewmodel>();
                          Navigator.pop(context);
                          try {
                            await vm.createBattle(location: locationController.text.trim(), dateTime: tempDate);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Battle Scheduled Successfully', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), backgroundColor: primaryColor));
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent));
                            }
                          }
                        },
                        child: const Text('SCHEDULE MATCH', style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
