import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sumquiz/services/auth_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Settings',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1A237E)),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          // Animated Gradient Background
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    children: [
                      _buildSectionTitle('Account')
                          .animate()
                          .fadeIn(delay: 100.ms),
                      _buildSettingsCard(
                        context,
                        icon: Icons.account_circle,
                        title: 'Profile',
                        subtitle: 'Manage account info',
                        onTap: () => context.push('/settings/account-profile'),
                        delay: 150.ms,
                      ),
                      const SizedBox(height: 12),
                      _buildSettingsCard(
                        context,
                        icon: Icons.workspace_premium_outlined,
                        title: 'Subscription',
                        subtitle: 'Manage your plan',
                        onTap: () => context.push('/settings/subscription'),
                        delay: 200.ms,
                      ),
                      const SizedBox(height: 32),
                      _buildSectionTitle('App Settings')
                          .animate()
                          .fadeIn(delay: 250.ms),
                      _buildSettingsCard(
                        context,
                        icon: Icons.palette_outlined,
                        title: 'Appearance',
                        subtitle: 'Theme & display settings',
                        onTap: () => context.push('/settings/preferences'),
                        delay: 300.ms,
                      ),
                      const SizedBox(height: 12),
                      _buildSettingsCard(
                        context,
                        icon: Icons.storage_outlined,
                        title: 'Data & Storage',
                        subtitle: 'Cache & offline data',
                        onTap: () => context.push('/settings/data-storage'),
                        delay: 350.ms,
                      ),
                      const SizedBox(height: 32),
                      _buildSectionTitle('Support')
                          .animate()
                          .fadeIn(delay: 400.ms),
                      _buildSettingsCard(
                        context,
                        icon: Icons.info_outline,
                        title: 'About & Privacy',
                        subtitle: 'App version, terms & privacy',
                        onTap: () => context.push('/settings/privacy-about'),
                        delay: 450.ms,
                      ),
                      const SizedBox(height: 12),
                      _buildSettingsCard(
                        context,
                        icon: Icons.card_giftcard,
                        title: 'Refer a Friend',
                        subtitle: 'Invite friends & earn rewards',
                        onTap: () => context.push('/settings/referral'),
                        delay: 500.ms,
                      ),
                      const SizedBox(height: 48),
                      _buildLogoutButton(context)
                          .animate()
                          .fadeIn(delay: 550.ms)
                          .slideY(begin: 0.2),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1A237E),
          letterSpacing: 1.2,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Duration delay,
  }) {
    return Animate(
      effects: [FadeEffect(delay: delay), SlideEffect(delay: delay)],
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.6)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A237E).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:
                          Icon(icon, color: const Color(0xFF1A237E), size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                  fontSize: 16)),
                          const SizedBox(height: 2),
                          Text(subtitle,
                              style: GoogleFonts.inter(
                                  color: Colors.grey[700], fontSize: 13)),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios,
                        size: 16, color: Colors.grey[400]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextButton.icon(
            onPressed: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  title: Text('Sign Out',
                      style: GoogleFonts.poppins(
                          color: Colors.black87, fontWeight: FontWeight.bold)),
                  content: Text('Are you sure you want to sign out?',
                      style: GoogleFonts.inter(color: Colors.grey[800])),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Sign Out',
                            style: TextStyle(color: Colors.redAccent))),
                  ],
                ),
              );

              if (shouldLogout == true && context.mounted) {
                await Provider.of<AuthService>(context, listen: false)
                    .signOut();
                if (context.mounted) context.go('/auth');
              }
            },
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            label: Text('Sign Out',
                style: GoogleFonts.inter(
                    color: Colors.redAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ),
    );
  }
}
