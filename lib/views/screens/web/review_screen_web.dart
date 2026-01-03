import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/auth_service.dart';
import '../../../services/local_database_service.dart';
import '../../../models/flashcard.dart';
import '../../../models/flashcard_set.dart';
import '../../../models/user_model.dart';
import '../../../models/daily_mission.dart';
import '../../../services/mission_service.dart';
import '../../../services/user_service.dart';
import '../flashcards_screen.dart';
import '../summary_screen.dart';
import '../quiz_screen.dart';
import '../../../models/local_summary.dart';
import '../../../models/local_quiz.dart';
import '../../../models/local_flashcard_set.dart';
import 'package:rxdart/rxdart.dart';

class ReviewScreenWeb extends StatefulWidget {
  const ReviewScreenWeb({super.key});

  @override
  State<ReviewScreenWeb> createState() => _ReviewScreenWebState();
}

class _ReviewScreenWebState extends State<ReviewScreenWeb> {
  DailyMission? _dailyMission;
  bool _isLoading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadMission();
  }

  Future<void> _loadMission() async {
    if (!mounted) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.uid;

    if (userId == null) {
      setState(() {
        _isLoading = false;
        _error = "User not found.";
      });
      return;
    }

    try {
      final missionService =
          Provider.of<MissionService>(context, listen: false);
      final mission = await missionService.generateDailyMission(userId);

      setState(() {
        _dailyMission = mission;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = "Error loading mission: $e";
      });
    }
  }

  Future<List<Flashcard>> _fetchMissionCards(List<String> cardIds) async {
    final userId =
        Provider.of<AuthService>(context, listen: false).currentUser?.uid;
    if (userId == null) return [];

    final localDb = Provider.of<LocalDatabaseService>(context, listen: false);
    final sets = await localDb.getAllFlashcardSets(userId);

    final allCards = sets.expand((s) => s.flashcards).map((localCard) {
      return Flashcard(
        id: localCard.id,
        question: localCard.question,
        answer: localCard.answer,
      );
    }).toList();

    return allCards.where((c) => cardIds.contains(c.id)).toList();
  }

  Future<void> _startMission() async {
    if (_dailyMission == null) return;

    setState(() => _isLoading = true);

    try {
      final cards = await _fetchMissionCards(_dailyMission!.flashcardIds);

      if (cards.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Could not find mission cards. They might be deleted.',
                    style: GoogleFonts.inter())),
          );
          setState(() => _isLoading = false);
        }
        return;
      }

      setState(() => _isLoading = false);
      if (!mounted) return;

      final reviewSet = FlashcardSet(
        id: 'mission_session',
        title: 'Daily Mission',
        flashcards: cards,
        timestamp: Timestamp.now(),
      );

      // On web we might want a dialog or a new route for flashcards,
      // but strictly following ReviewScreen logic for now:
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FlashcardsScreen(flashcardSet: reviewSet),
        ),
      );

      if (result != null && result is double) {
        await _completeMission(result);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = "Failed to start mission: $e";
      });
    }
  }

  Future<void> _completeMission(double score) async {
    if (_dailyMission == null) return;

    final userId =
        Provider.of<AuthService>(context, listen: false).currentUser?.uid;
    if (userId == null) return;

    final missionService = Provider.of<MissionService>(context, listen: false);
    await missionService.completeMission(userId, _dailyMission!, score);

    final userService = UserService();
    await userService.incrementItemsCompleted(userId);

    _loadMission();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Dashboard',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, color: const Color(0xFF1A237E))),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFF1A237E)),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background - Static or simpler for web performance, or same animate
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF3F4F6), Color(0xFFE8EAF6)],
              ),
            ),
          ),

          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, style: GoogleFonts.inter()))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 24),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1200),
                            child: _buildDesktopDashboard(user),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopDashboard(UserModel? user) {
    if (_dailyMission == null) return const SizedBox();
    final isCompleted = _dailyMission!.isCompleted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Welcome Header
        Text(
          'Hello, ${user?.displayName ?? 'Student'}',
          style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A237E)),
        ).animate().fadeIn().slideX(),

        const SizedBox(height: 32),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Mission & Stats
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _buildMissionCard(isCompleted),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                          child: _buildGlassStatCard(
                              'Momentum',
                              (user?.currentMomentum ?? 0).toStringAsFixed(0),
                              Icons.local_fire_department_rounded,
                              Colors.orangeAccent)),
                      const SizedBox(width: 24),
                      Expanded(child: _buildDailyGoalCard(user)),
                    ],
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
            ),

            const SizedBox(width: 32),

            // Right Column: Recent Activity (Vertical List on Web)
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Jump Back In',
                      style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800])),
                  const SizedBox(height: 16),
                  _buildRecentActivityList(user),
                ],
              ).animate().fadeIn(delay: 400.ms),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGlassCard(
      {required Widget child, EdgeInsets? padding, Color? borderColor}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding ?? const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: borderColor ?? Colors.white.withValues(alpha: 0.6),
                width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlassStatCard(
      String label, String value, IconData icon, Color iconColor) {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor, size: 32),
            ],
          ),
          const SizedBox(height: 16),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A1A))),
          Text(label,
              style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildDailyGoalCard(UserModel? user) {
    final current = user?.itemsCompletedToday ?? 0;
    final target = user?.dailyGoal ?? 5;
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final isDone = current >= target;

    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircularProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                color: isDone ? Colors.green : const Color(0xFF1A237E),
                strokeWidth: 8,
                strokeCap: StrokeCap.round,
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: isDone ? Colors.green : Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('$current/$target items',
              style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A1A))),
          Text('Daily Goal',
              style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildMissionCard(bool isCompleted) {
    return _buildGlassCard(
        borderColor: isCompleted
            ? Colors.green.withValues(alpha: 0.5)
            : const Color(0xFF1A237E).withValues(alpha: 0.3),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.green.withValues(alpha: 0.1)
                        : const Color(0xFF1A237E).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.rocket_launch_rounded,
                    color: isCompleted ? Colors.green : const Color(0xFF1A237E),
                    size: 40,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          isCompleted
                              ? 'Mission Accomplished!'
                              : "Today's Mission",
                          style: GoogleFonts.poppins(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      if (!isCompleted)
                        Text('Boost your momentum now',
                            style: GoogleFonts.inter(
                                color: Colors.grey[600], fontSize: 15)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (!isCompleted) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMissionMetric(Icons.timelapse,
                      "${_dailyMission!.estimatedTimeMinutes}m"),
                  _buildMissionMetric(Icons.style,
                      "${_dailyMission!.flashcardIds.length} cards"),
                  _buildMissionMetric(
                      Icons.speed, "+${_dailyMission!.momentumReward} pts"),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _startMission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    shadowColor: const Color(0xFF1A237E).withValues(alpha: 0.4),
                  ),
                  child: Text('Start Mission',
                      style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                ),
              ),
            ] else ...[
              Text(
                "You've earned +${_dailyMission!.momentumReward} momentum score today!",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                    child: Text('Come back tomorrow',
                        style: GoogleFonts.poppins(
                            color: Colors.green[800],
                            fontSize: 16,
                            fontWeight: FontWeight.w600))),
              ),
            ],
          ],
        ));
  }

  Widget _buildMissionMetric(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, size: 24, color: const Color(0xFF5C6BC0)),
        const SizedBox(height: 8),
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800])),
      ],
    );
  }

  Widget _buildRecentActivityList(UserModel? user) {
    if (user == null) return const SizedBox();
    final localDb = Provider.of<LocalDatabaseService>(context, listen: false);

    return StreamBuilder(
      stream: Rx.combineLatest3(
        localDb.watchAllFlashcardSets(user.uid),
        localDb.watchAllQuizzes(user.uid),
        localDb.watchAllSummaries(user.uid),
        (sets, quizzes, summaries) {
          final all = <dynamic>[...sets, ...quizzes, ...summaries];
          all.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return all.take(8).toList(); // Show more items on web
        },
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data as List<dynamic>;

        if (items.isEmpty) {
          return SizedBox(
            height: 200,
            child: Center(
                child: Text('No recent activity',
                    style: GoogleFonts.inter(color: Colors.grey))),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = items[index];
            String title = item.title;
            IconData icon = Icons.article_rounded;
            Color color = Colors.blue;
            String type = 'Summary';

            if (item is LocalFlashcardSet) {
              icon = Icons.style_rounded;
              color = Colors.orange;
              type = 'Flashcards';
            } else if (item is LocalQuiz) {
              icon = Icons.quiz_rounded;
              color = Colors.teal;
              type = 'Quiz';
            }

            return _buildGlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: InkWell(
                onTap: () {
                  if (item is LocalFlashcardSet) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => FlashcardsScreen(
                                flashcardSet: FlashcardSet(
                                    id: item.id,
                                    title: item.title,
                                    flashcards: item.flashcards
                                        .map((f) => Flashcard(
                                            id: f.id,
                                            question: f.question,
                                            answer: f.answer))
                                        .toList(),
                                    timestamp:
                                        Timestamp.fromDate(item.timestamp)))));
                  } else if (item is LocalQuiz) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => QuizScreen(quiz: item)));
                  } else if (item is LocalSummary) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => SummaryScreen(summary: item)));
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          shape: BoxShape.circle),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Colors.black87)),
                          Text(type,
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios,
                        size: 16, color: Colors.grey[400]),
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
