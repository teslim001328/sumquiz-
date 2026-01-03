import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyAboutScreen extends StatefulWidget {
  const PrivacyAboutScreen({super.key});

  @override
  State<PrivacyAboutScreen> createState() => _PrivacyAboutScreenState();
}

class _PrivacyAboutScreenState extends State<PrivacyAboutScreen> {
  String _version = 'Loading...';

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = 'v${info.version}';
    });
  }

  Future<void> _launchURL(String url) async {
    try {
      final uri = Uri.parse(url);

      if (!await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      )) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open link: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'About & Privacy',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, color: const Color(0xFF1A237E)),
        ),
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildAboutHeader()
                          .animate()
                          .fadeIn(delay: 100.ms)
                          .slideY(begin: 0.1),
                      const SizedBox(height: 32),
                      _buildLinksCard()
                          .animate()
                          .fadeIn(delay: 200.ms)
                          .slideY(begin: 0.1),
                      const SizedBox(height: 24),
                      Text(
                        '© 2024 SumQuiz. All rights reserved.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                            color: Colors.grey[600], fontSize: 12),
                      ).animate().fadeIn(delay: 400.ms),
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

  Widget _buildAboutHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A237E).withValues(alpha: 0.05),
            shape: BoxShape.circle,
            border: Border.all(
                color: const Color(0xFF1A237E).withValues(alpha: 0.1),
                width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A237E).withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(Icons.info_outline,
              size: 60, color: Color(0xFF1A237E)),
        ),
        const SizedBox(height: 24),
        Text(
          'SumQuiz',
          style: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A237E),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1A237E).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: const Color(0xFF1A237E).withValues(alpha: 0.2)),
          ),
          child: Text(
            _version,
            style: GoogleFonts.inter(
              color: const Color(0xFF1A237E),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLinksCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildLinkTile(
                icon: Icons.shield_outlined,
                title: 'Privacy Policy',
                onTap: () => _launchURL(
                    'https://sites.google.com/view/sumquiz-privacy-policy/home'),
              ),
              _buildDivider(),
              _buildLinkTile(
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                onTap: () => _launchURL(
                    'https://sites.google.com/view/terms-and-conditions-for-sumqu/home'),
              ),
              _buildDivider(),
              _buildLinkTile(
                icon: Icons.contact_support_outlined,
                title: 'Support & Contact',
                onTap: () => _launchURL('mailto:sumquiz6@gmail.com'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinkTile(
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        leading: Icon(icon, color: const Color(0xFF1A237E)),
        title: Text(title,
            style: GoogleFonts.inter(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w500)),
        trailing: Icon(Icons.arrow_forward_ios,
            size: 16, color: Colors.grey.withValues(alpha: 0.4)),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDivider() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Divider(height: 1, color: Colors.grey.withValues(alpha: 0.1)),
      );
}
