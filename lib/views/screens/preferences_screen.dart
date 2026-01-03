import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sumquiz/providers/theme_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Calculate current font size index for UI selection
    int fontSizeIndex = 1;
    if (themeProvider.fontScale == 0.8) fontSizeIndex = 0;
    if (themeProvider.fontScale == 1.2) fontSizeIndex = 2;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Preferences',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, color: const Color(0xFF1A237E)),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1A237E)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // Animated Background
          Animate(
            onPlay: (controller) => controller.repeat(reverse: true),
            effects: [
              CustomEffect(
                duration: 6.seconds,
                builder: (context, value, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFF3F4F6),
                          Color.lerp(const Color(0xFFE8EAF6),
                              const Color(0xFFC5CAE9), value)!,
                        ],
                      ),
                    ),
                    child: child,
                  );
                },
              )
            ],
            child: Container(),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: ListView(
                  padding: const EdgeInsets.all(24.0),
                  children: [
                    _buildSectionHeader('Appearance')
                        .animate()
                        .fadeIn()
                        .slideX(),
                    const SizedBox(height: 16),
                    _buildGlassSection(
                      children: [
                        _buildDarkModeTile(themeProvider),
                        _buildDivider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          child: _buildFontSizeSelector(
                              themeProvider, fontSizeIndex),
                        ),
                      ],
                    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                    const SizedBox(height: 32),
                    _buildSectionHeader('Interaction')
                        .animate()
                        .fadeIn(delay: 200.ms)
                        .slideX(),
                    const SizedBox(height: 16),
                    _buildGlassSection(
                      children: [
                        _buildToggleOption(
                          context,
                          title: 'Notifications',
                          value: themeProvider.notificationsEnabled,
                          icon: Icons.notifications_none,
                          onChanged: (value) {
                            themeProvider.toggleNotifications(value);
                          },
                        ),
                        _buildDivider(),
                        _buildToggleOption(
                          context,
                          title: 'Haptic Feedback',
                          value: themeProvider.hapticFeedbackEnabled,
                          icon: Icons.vibration,
                          onChanged: (value) {
                            themeProvider.toggleHapticFeedback(value);
                          },
                        ),
                      ],
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1A237E),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildGlassSection({required List<Widget> children}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: Colors.grey.withValues(alpha: 0.2),
    );
  }

  Widget _buildDarkModeTile(ThemeProvider themeProvider) {
    return SwitchListTile(
      title: Text('Dark Mode',
          style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87)),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A237E).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.dark_mode_outlined,
            color: Color(0xFF1A237E), size: 20),
      ),
      value: themeProvider.themeMode == ThemeMode.dark,
      onChanged: (value) => themeProvider.toggleTheme(),
      activeTrackColor: const Color(0xFF1A237E),
      hoverColor: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    );
  }

  Widget _buildFontSizeSelector(
      ThemeProvider themeProvider, int currentSizeIndex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.format_size,
                  color: Colors.blueAccent, size: 20),
            ),
            const SizedBox(width: 16),
            Text('Font Size',
                style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87)),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildFontSizeOption(
                  themeProvider, 0, 'Small', 0.8, currentSizeIndex),
              _buildFontSizeOption(
                  themeProvider, 1, 'Medium', 1.0, currentSizeIndex),
              _buildFontSizeOption(
                  themeProvider, 2, 'Large', 1.2, currentSizeIndex),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildFontSizeOption(ThemeProvider themeProvider, int index,
      String text, double scale, int currentIndex) {
    final isSelected = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          themeProvider.setFontScale(scale);
        },
        child: AnimatedContainer(
          duration: 200.ms,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2))
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: isSelected ? const Color(0xFF1A237E) : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleOption(
    BuildContext context, {
    required String title,
    required bool value,
    required IconData icon,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title,
          style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87)),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.pinkAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.pinkAccent, size: 20),
      ),
      value: value,
      onChanged: onChanged,
      activeTrackColor: Colors.pinkAccent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    );
  }
}
