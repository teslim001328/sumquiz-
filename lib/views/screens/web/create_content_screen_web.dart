import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sumquiz/services/content_extraction_service.dart';
import 'package:sumquiz/widgets/pro_gate.dart';

class CreateContentScreenWeb extends StatefulWidget {
  const CreateContentScreenWeb({super.key});

  @override
  State<CreateContentScreenWeb> createState() => _CreateContentScreenWebState();
}

class _CreateContentScreenWebState extends State<CreateContentScreenWeb> {
  int _selectedInputIndex = 0;
  bool _isLoading = false;

  // Controllers
  final TextEditingController _textInputController = TextEditingController();
  final TextEditingController _urlInputController = TextEditingController();

  PlatformFile? _selectedFile;

  final List<Map<String, dynamic>> _inputMethods = [
    {
      'icon': Icons.description_outlined,
      'label': 'Text',
      'description': 'Paste text directly'
    },
    {'icon': Icons.link, 'label': 'Link', 'description': 'Article or YouTube'},
    {
      'icon': Icons.upload_file,
      'label': 'PDF',
      'description': 'Upload document'
    },
    {
      'icon': Icons.image_outlined,
      'label': 'Image',
      'description': 'Photo or screenshot'
    },
  ];

  @override
  void dispose() {
    _textInputController.dispose();
    _urlInputController.dispose();
    super.dispose();
  }

  Future<void> _handleFileSelection(bool isImage) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: isImage ? FileType.image : FileType.custom,
        allowedExtensions: isImage ? null : ['pdf'],
        withData: true, // Important for web
      );

      if (result != null) {
        setState(() {
          _selectedFile = result.files.first;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  Future<void> _processContent() async {
    setState(() => _isLoading = true);

    try {
      final extractionService = context.read<ContentExtractionService>();
      String extractedText = '';

      switch (_selectedInputIndex) {
        case 0: // Text
          extractedText = _textInputController.text;
          break;
        case 1: // Link
          extractedText = await extractionService.extractContent(
            type: 'link',
            input: _urlInputController.text,
          );
          break;
        case 2: // PDF
          if (_selectedFile != null && _selectedFile!.bytes != null) {
            extractedText = await extractionService.extractContent(
              type: 'pdf',
              input: _selectedFile!.bytes,
            );
          }
          break;
        case 3: // Image
          if (_selectedFile != null && _selectedFile!.bytes != null) {
            extractedText = await extractionService.extractContent(
              type: 'image',
              input: _selectedFile!.bytes,
            );
          }
          break;
      }

      if (extractedText.isNotEmpty) {
        if (mounted) {
          context.go('/create/extraction-view', extra: extractedText);
        }
      } else {
        throw Exception('No content extracted');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Extraction failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Create Content',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, color: const Color(0xFF1A237E))),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A237E)),
          onPressed: () => context.go('/'),
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
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  // Left Side - Input Selection
                  Expanded(
                    flex: 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.6),
                                width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Create New",
                                  style: GoogleFonts.poppins(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1A237E))),
                              const SizedBox(height: 8),
                              Text(
                                  "Import content to generate summaries and quizzes",
                                  style: GoogleFonts.inter(
                                      fontSize: 16, color: Colors.grey[700])),
                              const SizedBox(height: 48),

                              // Input Methods Grid
                              SizedBox(
                                height: 120,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _inputMethods.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(width: 16),
                                  itemBuilder: (context, index) {
                                    final method = _inputMethods[index];
                                    final isSelected =
                                        _selectedInputIndex == index;
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedInputIndex = index;
                                          _selectedFile = null;
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration: 200.ms,
                                        width: 140,
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                            color: isSelected
                                                ? const Color(0xFF1A237E)
                                                : Colors.white
                                                    .withValues(alpha: 0.5),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                                color: isSelected
                                                    ? Colors.transparent
                                                    : Colors.white),
                                            boxShadow: isSelected
                                                ? [
                                                    BoxShadow(
                                                        color: const Color(
                                                                0xFF1A237E)
                                                            .withValues(
                                                                alpha: 0.3),
                                                        blurRadius: 12,
                                                        offset:
                                                            const Offset(0, 4))
                                                  ]
                                                : []),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(method['icon'] as IconData,
                                                color: isSelected
                                                    ? Colors.white
                                                    : const Color(0xFF1A237E),
                                                size: 28),
                                            const SizedBox(height: 8),
                                            Text(method['label'] as String,
                                                style: GoogleFonts.inter(
                                                    fontWeight: FontWeight.w600,
                                                    color: isSelected
                                                        ? Colors.white
                                                        : Colors.grey[800])),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              const SizedBox(height: 40),

                              // Divider
                              Divider(color: Colors.grey.shade300),
                              const SizedBox(height: 40),

                              // Input Area
                              Expanded(
                                child: AnimatedSwitcher(
                                  duration: 300.ms,
                                  child: _buildInputArea(),
                                ),
                              ),

                              // Action Bar
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed:
                                      _isLoading ? null : _processContent,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1A237E),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                    elevation: 4,
                                    shadowColor: const Color(0xFF1A237E)
                                        .withValues(alpha: 0.3),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2))
                                      : Text("NEXT STEP",
                                          style: GoogleFonts.inter(
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 24),

                  // Right Side - Illustration/Preview
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_selectedInputIndex >= 2)
                            Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: ProGate(
                                featureName: _inputMethods[_selectedInputIndex]
                                    ['label'] as String,
                                proContent: () => _buildSafetyInfo(),
                                freeContent: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                        sigmaX: 10, sigmaY: 10),
                                    child: Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.7),
                                          borderRadius:
                                              BorderRadius.circular(24),
                                          border: Border.all(
                                              color: Colors.white
                                                  .withValues(alpha: 0.6)),
                                        ),
                                        child: Column(
                                          children: [
                                            const Icon(Icons.star_border,
                                                size: 48, color: Colors.amber),
                                            const SizedBox(height: 16),
                                            Text("Pro Feature",
                                                style: GoogleFonts.poppins(
                                                    fontSize: 20,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            const SizedBox(height: 8),
                                            const Text(
                                                "Upload unlimited PDFs and Images with Pro.",
                                                textAlign: TextAlign.center),
                                          ],
                                        )),
                                  ),
                                ),
                              ),
                            )
                          else
                            _buildSafetyInfo(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    switch (_selectedInputIndex) {
      case 0:
        return TextField(
          controller: _textInputController,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          decoration: InputDecoration(
              hintText: "Paste your text here...",
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(24)),
        );
      case 1:
        return Column(
          children: [
            TextField(
              controller: _urlInputController,
              decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.link),
                  hintText: "Paste URL (Article, YouTube, etc.)",
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(24)),
            ),
          ],
        );
      case 2:
      case 3:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                  _selectedFile == null
                      ? Icons.cloud_upload_outlined
                      : Icons.check_circle_outline,
                  size: 64,
                  color:
                      _selectedFile == null ? Colors.grey[400] : Colors.green),
              const SizedBox(height: 16),
              Text(
                _selectedFile == null
                    ? "Drag & drop or click to upload"
                    : _selectedFile!.name,
                style: GoogleFonts.inter(
                    fontSize: 16,
                    color:
                        _selectedFile == null ? Colors.grey[600] : Colors.black,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => _handleFileSelection(_selectedInputIndex == 3),
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                child:
                    Text(_selectedFile == null ? "Select File" : "Change File"),
              )
            ],
          ),
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildSafetyInfo() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
              )
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A237E).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome,
                    size: 48, color: Color(0xFF1A237E)),
              ),
              const SizedBox(height: 24),
              Text("Smart Generation",
                  style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A237E))),
              const SizedBox(height: 12),
              Text(
                "Our AI automatically analyzes your content to create the best study materials. Please verify the generated content for accuracy.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(height: 1.5, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
