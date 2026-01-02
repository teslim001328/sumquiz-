import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sumquiz/services/enhanced_ai_service.dart';
import 'package:sumquiz/services/local_database_service.dart';
import 'package:sumquiz/services/usage_service.dart';
import 'package:sumquiz/models/user_model.dart';
import 'package:sumquiz/views/widgets/upgrade_dialog.dart';

class ExtractionViewScreenWeb extends StatefulWidget {
  final String? initialText;

  const ExtractionViewScreenWeb({super.key, this.initialText});

  @override
  State<ExtractionViewScreenWeb> createState() =>
      _ExtractionViewScreenWebState();
}

enum OutputType { summary, quiz, flashcards }

class _ExtractionViewScreenWebState extends State<ExtractionViewScreenWeb> {
  late TextEditingController _textController;
  final TextEditingController _titleController =
      TextEditingController(text: 'Untitled Creation');
  final Set<OutputType> _selectedOutputs = {OutputType.summary};
  bool _isLoading = false;
  String _loadingMessage = 'Generating...';

  static const int minTextLength = 10;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialText ?? '');
  }

  @override
  void dispose() {
    _textController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _toggleOutput(OutputType type) {
    setState(() {
      if (_selectedOutputs.contains(type)) {
        _selectedOutputs.remove(type);
      } else {
        _selectedOutputs.add(type);
      }
    });
  }

  Future<void> _handleGenerate() async {
    if (_textController.text.trim().length < minTextLength) {
      _showError(
          'Text is too short. Please provide at least $minTextLength characters.');
      return;
    }

    if (_selectedOutputs.isEmpty) {
      _showError('Please select at least one output type.');
      return;
    }

    final user = context.read<UserModel?>();
    final usageService = context.read<UsageService?>();

    if (user != null && !user.isPro && usageService != null) {
      for (var output in _selectedOutputs) {
        if (!await usageService.canPerformAction(output.name)) {
          if (mounted)
            showDialog(
                context: context,
                builder: (_) => UpgradeDialog(featureName: output.name));
          return;
        }
      }
    }

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Preparing generation...';
    });

    try {
      final aiService = context.read<EnhancedAIService>();
      final localDb = context.read<LocalDatabaseService>();
      final userId = user?.uid ?? 'unknown_user';
      final requestedOutputs = _selectedOutputs.map((e) => e.name).toList();

      final folderId = await aiService.generateAndStoreOutputs(
        text: _textController.text,
        title: _titleController.text.isNotEmpty
            ? _titleController.text
            : 'Untitled Creation',
        requestedOutputs: requestedOutputs,
        userId: userId,
        localDb: localDb,
        onProgress: (message) {
          if (mounted) {
            setState(() => _loadingMessage = message);
          }
        },
      );

      if (user != null && !user.isPro && usageService != null) {
        for (var output in _selectedOutputs) {
          await usageService.recordAction(output.name);
        }
      }

      if (mounted) context.go('/library/results-view/$folderId');
    } catch (e) {
      if (mounted) _showError('Generation failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB), // Light grey background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Text("Create Content",
            style: GoogleFonts.poppins(
                color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: Row(
        children: [
          // Left: Editor
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text("Source Text",
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  Divider(height: 1, color: Colors.grey.shade200),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      maxLines: null,
                      expands: true,
                      style: GoogleFonts.robotoMono(fontSize: 14, height: 1.5),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.all(24),
                        border: InputBorder.none,
                        hintText:
                            "Review and edit your text here before generating...",
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().slideX(begin: -0.05).fadeIn(),

          // Right: Configuration
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Configuration",
                      style: GoogleFonts.poppins(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 32),

                  // Title Input
                  Text("Title",
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700])),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      hintText: "Enter a title for this study set",
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Outputs
                  Text("Generate",
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700])),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: OutputType.values.map((type) {
                      final isSelected = _selectedOutputs.contains(type);
                      return FilterChip(
                        selected: isSelected,
                        label: Text(type.name.toUpperCase()),
                        onSelected: (_) => _toggleOutput(type),
                        backgroundColor: Colors.grey.shade100,
                        selectedColor:
                            const Color(0xFF1A237E).withValues(alpha: 0.1),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? const Color(0xFF1A237E)
                              : Colors.grey[700],
                          fontWeight: FontWeight.bold,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFF1A237E)
                                : Colors.transparent,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const Spacer(),

                  // Generate Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleGenerate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        foregroundColor: Colors.white,
                        // dropdownColor: Colors.white, // REMOVED invalid parameter
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2)),
                                const SizedBox(width: 12),
                                Text(_loadingMessage),
                              ],
                            )
                          : const Text("GENERATE CONTENT",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1)),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().slideX(begin: 0.05).fadeIn(),
        ],
      ),
    );
  }
}
