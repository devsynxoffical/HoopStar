import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../../core/constants/colors.dart';
import '../../../core/models/strategy_model.dart';
import '../../profile/viewmodel/profile_viewmodel.dart';
import '../viewmodel/strategy_viewmodel.dart';

class StrategyScreen extends StatefulWidget {
  const StrategyScreen({super.key});

  @override
  State<StrategyScreen> createState() => _StrategyScreenState();
}

class _StrategyScreenState extends State<StrategyScreen> {
  String _filter = 'all';
  StrategyViewmodel? _strategyViewmodel;

  static const Color primaryColor = Color(0xFFFFD900);
  static const Color bgColor = Color(0xFF131313);
  static const Color surfaceHigh = Color(0xFF201F1F);
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
        final vm = context.read<StrategyViewmodel>();
        _strategyViewmodel = vm;
        await vm.loadStrategies();
        vm.startLiveSync(); // Start real-time updates
        
        final profileVm = context.read<ProfileViewmodel>();
        if (profileVm.user == null) {
          await profileVm.loadProfile(forceRefresh: true);
        }
        break; // Success, exit retry loop
      } catch (e) {
        if (i == retryCount - 1) {
          // Last retry failed, show error
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to load strategies: ${e.toString().replaceAll('Exception: ', '')}'),
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
    _strategyViewmodel?.stopLiveSync();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Consumer<StrategyViewmodel>(
            builder: (context, vm, _) {
              // Show loading state
              if (vm.isLoading && vm.strategies.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: primaryColor),
                      SizedBox(height: 16),
                      Text('Loading Strategies...', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                );
              }

              // Show error state
              if (vm.errorMessage != null && vm.strategies.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          'Error Loading Strategies',
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          vm.errorMessage!,
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
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  const Text('TACTICAL REELS', style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  const SizedBox(height: 16),
                  _buildTacticalReels(vm),
                  const SizedBox(height: 32),
                  _buildFormationAnalytics(),
                  const SizedBox(height: 32),
                  const Text('ACTIVE PLAYBOOK', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Space Grotesk')),
                  const SizedBox(height: 16),
                  ..._buildPlaybookItems(vm),
                  const SizedBox(height: 40),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<ProfileViewmodel>(
      builder: (context, profileVm, _) {
        final canCreate = profileVm.user?.role == 'admin' || 
                         profileVm.user?.role == 'head_coach' || 
                         profileVm.user?.role == 'coach';
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PLAYBOOK INTELLIGENCE', style: TextStyle(color: outlineColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                SizedBox(height: 4),
                Text('TACTICAL STRATEGY', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'Space Grotesk')),
              ],
            ),
            if (canCreate)
              GestureDetector(
                onTap: () => _showCreateStrategyDialog(context),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                  child: const Icon(Icons.add, color: Colors.black, size: 24),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTacticalReels(StrategyViewmodel vm) {
    if (vm.isLoading) return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator(color: primaryColor)));
    final strategies = vm.strategies;
    if (strategies.isEmpty) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(color: surfaceHigh, borderRadius: BorderRadius.circular(24), border: Border.all(color: outlineColor.withOpacity(0.1), style: BorderStyle.solid)),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library_outlined, color: outlineColor, size: 32),
            SizedBox(height: 12),
            Text('NO REELS UPLOADED', style: TextStyle(color: outlineColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ],
        ),
      );
    }
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: strategies.length,
        itemBuilder: (context, index) => _reelCard(strategies[index]),
      ),
    );
  }

  Widget _reelCard(StrategyModel strategy) {
    return GestureDetector(
      onTap: () => _playVideo(context, strategy.videoUrl),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(color: surfaceHigh, borderRadius: BorderRadius.circular(24), image: const DecorationImage(image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuCsae0Oq9Kq-clgdaCm9T3cjOP2BdDAJGUHNDzwFJUZG2kOSJxvHLr5_Gwzo5QriHnVYOSyX26PB5HNtPSFR_z36-ONprr8QczHvqarbUS9k0T8IVlxdsk9HiN5Ww4CTifljkBIgUxa0tCGQYIOaYWPP0jBSPR3PpnLg7Ek2L1yFIGuod-gS5Kelq7B7O416-e1w5ZYM-I8m6pGCs8_NvyuVVhCdxMST0JNmiLXgEiRE1mNi_HWEcYAQXAf0RCFJzLbiqG4ytYczZlX'), fit: BoxFit.cover, opacity: 0.6)),
        child: Stack(
          children: [
            Positioned(bottom: 16, left: 16, right: 16, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(strategy.title.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, fontFamily: 'Space Grotesk'), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(strategy.category.toUpperCase(), style: const TextStyle(color: primaryColor, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ])),
            Center(child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle), child: const Icon(Icons.play_arrow, color: primaryColor, size: 24))),
          ],
        ),
      ),
    );
  }

  Widget _buildFormationAnalytics() {
    return Row(
      children: [
        Expanded(child: _analyticsCard('FORMATION ENGAGEMENT', '88%', Icons.insights, const Color(0xFF28D8FF))),
        const SizedBox(width: 16),
        Expanded(child: _analyticsCard('DRILL COMPLETION', '94%', Icons.check_circle, primaryColor)),
      ],
    );
  }

  Widget _analyticsCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: surfaceHigh, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 16),
          Text(val, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'Space Grotesk')),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: outlineColor, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ],
      ),
    );
  }

  List<Widget> _buildPlaybookItems(StrategyViewmodel vm) {
    if (vm.strategies.isEmpty) return [const Text('No plays active.', style: TextStyle(color: outlineColor))];
    return vm.strategies.map((s) => _playbookItem(s)).toList();
  }

  Widget _playbookItem(StrategyModel s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1C1B1B).withOpacity(0.5), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: surfaceHigh, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.description, color: outlineColor, size: 18)),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.title.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  Text('${s.category.toUpperCase()} • 2.4MB PDF', style: const TextStyle(color: outlineColor, fontSize: 8, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const Icon(Icons.file_download_outlined, color: outlineColor, size: 20),
        ],
      ),
    );
  }

  Future<void> _showCreateStrategyDialog(BuildContext context) async {
    final titleCtrl = TextEditingController();
    final sourceCtrl = TextEditingController();
    final videoCtrl = TextEditingController();
    String category = 'general';
    bool submitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PUBLISH TACTICS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20, fontFamily: 'Space Grotesk')),
                    const SizedBox(height: 20),
                    _dialogField(titleCtrl, 'TITLE'),
                    const SizedBox(height: 12),
                    _dialogField(sourceCtrl, 'DETAILS / TRANSCRIPT', maxLines: 3),
                    const SizedBox(height: 12),
                    _dialogField(videoCtrl, 'VIDEO URL'),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: submitting ? null : () async {
                          if (titleCtrl.text.isEmpty || videoCtrl.text.isEmpty) return;
                          setSheetState(() => submitting = true);
                          try {
                            await context.read<StrategyViewmodel>().createStrategy(
                              title: titleCtrl.text,
                              category: category,
                              sourceType: 'video',
                              sourceText: sourceCtrl.text,
                              videoUrl: videoCtrl.text,
                            );
                            if (context.mounted) Navigator.pop(sheetCtx);
                          } finally {
                            if (context.mounted) setSheetState(() => submitting = false);
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.black, padding: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        child: Text(submitting ? 'PROCESSING...' : 'CONFIRM DEPLOYMENT', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
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

  Widget _dialogField(TextEditingController ctrl, String label, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: outlineColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
        filled: true,
        fillColor: surfaceHigh,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }

  Future<void> _playVideo(BuildContext context, String videoUrl) async {
    showDialog(context: context, builder: (_) => _VideoPlayerDialog(videoUrl: videoUrl));
  }
}

class _VideoPlayerDialog extends StatefulWidget {
  final String videoUrl;
  const _VideoPlayerDialog({required this.videoUrl});

  @override
  State<_VideoPlayerDialog> createState() => _VideoPlayerDialogState();
}

class _VideoPlayerDialogState extends State<_VideoPlayerDialog> {
  VideoPlayerController? _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      if (widget.videoUrl.isEmpty) {
        throw Exception('Video URL is empty');
      }
      
      final uri = Uri.parse(widget.videoUrl);
      if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
        throw Exception('Invalid video URL format');
      }
      
      _controller = VideoPlayerController.networkUrl(uri);
      await _controller!.initialize();
      await _controller!.setLooping(true);
      await _controller!.play();
      if (mounted) {
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load video: ${e.toString().replaceAll('Exception: ', '')}';
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF020617),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Strategy Video',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.white70),
                ),
              )
            else if (_controller != null)
              AspectRatio(
                aspectRatio: _controller!.value.aspectRatio == 0
                    ? (16 / 9)
                    : _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
          ],
        ),
      ),
    );
  }
}
