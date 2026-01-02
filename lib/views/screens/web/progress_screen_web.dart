import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sumquiz/models/user_model.dart';
import 'package:sumquiz/services/progress_service.dart';

class ProgressScreenWeb extends StatefulWidget {
  const ProgressScreenWeb({super.key});

  @override
  State<ProgressScreenWeb> createState() => _ProgressScreenWebState();
}

class _ProgressScreenWebState extends State<ProgressScreenWeb> {
  // Stats
  int _summariesCount = 0;
  int _quizzesCount = 0;
  int _flashcardsCount = 0;
  double _averageAccuracy = 0;
  List<FlSpot> _weeklyActivity = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final user = context.read<UserModel?>();
      if (user == null) return;

      final progressService =
          context.read<ProgressService?>() ?? ProgressService();

      final summaries = await progressService.getSummariesCount(user.uid);
      final quizzes = await progressService.getQuizzesCount(user.uid);
      final flashcards = await progressService.getFlashcardsCount(user.uid);
      final accuracy = await progressService.getAverageAccuracy(user.uid);
      final activity = await progressService.getWeeklyActivity(user.uid);

      if (mounted) {
        setState(() {
          _summariesCount = summaries;
          _quizzesCount = quizzes;
          _flashcardsCount = flashcards;
          _averageAccuracy = accuracy;
          _weeklyActivity = activity;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint('Error loading stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Your Progress",
                style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black)),
            const SizedBox(height: 8),
            Text("Track your learning journey and stats",
                style:
                    GoogleFonts.inter(fontSize: 16, color: Colors.grey[600])),
            const SizedBox(height: 48),

            // Top Stats Row
            Row(
              children: [
                _buildStatCard("Total Summaries", _summariesCount.toString(),
                    Icons.article_outlined, Colors.blue),
                const SizedBox(width: 24),
                _buildStatCard("Quizzes Taken", _quizzesCount.toString(),
                    Icons.quiz_outlined, Colors.orange),
                const SizedBox(width: 24),
                _buildStatCard("Flashcards", _flashcardsCount.toString(),
                    Icons.view_carousel_outlined, Colors.purple),
                const SizedBox(width: 24),
                _buildStatCard(
                    "Avg. Accuracy",
                    "${(_averageAccuracy * 100).toStringAsFixed(1)}%",
                    Icons.show_chart,
                    Colors.green),
              ],
            ),

            const SizedBox(height: 40),

            // Charts Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildActivityChart(),
                ),
                const SizedBox(width: 24),
                // Placeholder for another chart or breakdown
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 400,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10)
                        ]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Quick Insights",
                            style: GoogleFonts.poppins(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        _buildInsightRow("Most Active Day",
                            "Wednesday"), // Placeholder logic
                        _buildInsightRow(
                            "Best Subject", "Physics"), // Placeholder logic
                        _buildInsightRow(
                            "Learning Streak", "5 Days"), // Placeholder logic
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
            ]),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: GoogleFonts.poppins(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 13, color: Colors.grey[600])),
              ],
            ),
          ],
        ),
      )
          .animate()
          .scale(delay: 100.ms, duration: 400.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildActivityChart() {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Weekly Activity",
              style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        // meta required here
                        const days = [
                          'Mon',
                          'Tue',
                          'Wed',
                          'Thu',
                          'Fri',
                          'Sat',
                          'Sun'
                        ];
                        // Simple mapping, ideally match actual dates from data
                        if (value.toInt() >= 0 && value.toInt() < 7) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(days[value.toInt()],
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                          );
                        }
                        return const Text('');
                      },
                      interval: 1,
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _weeklyActivity, // Using fetched data
                    isCurved: true,
                    color: const Color(0xFF1A237E),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF1A237E).withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildInsightRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: Colors.grey[600])),
          Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
