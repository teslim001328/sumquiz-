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
      backgroundColor: const Color(0xFFF5F7FB),
      body: Row(
        children: [
          // Left Side - Input Selection
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(40),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Create New",
                      style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                  const SizedBox(height: 8),
                  Text("Import content to generate summaries and quizzes",
                      style: GoogleFonts.inter(
                          fontSize: 16, color: Colors.grey[600])),
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
                        final isSelected = _selectedInputIndex == index;
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
                                    : Colors.grey[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: isSelected
                                        ? Colors.transparent
                                        : Colors.grey[200]!),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                            color: const Color(0xFF1A237E)
                                                .withValues(alpha: 0.3),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4))
                                      ]
                                    : []),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(method['icon'] as IconData,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey[600],
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
                  Divider(color: Colors.grey.shade200),
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
                      onPressed: _isLoading ? null : _processContent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
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

          // Right Side - Illustration/Preview
          Expanded(
            flex: 3,
            child: Container(
              color: const Color(0xFFF5F7FB),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Using ProGate for premium feature (e.g., Image/PDF)
                  if (_selectedInputIndex >= 2)
                    Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: ProGate(
                        featureName: _inputMethods[_selectedInputIndex]['label']
                            as String,
                        proContent: () => _buildSafetyInfo(),
                        freeContent: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16)),
                            child: Column(
                              children: [
                                const Icon(Icons.star_border,
                                    size: 48, color: Colors.amber),
                                const SizedBox(height: 16),
                                Text("Pro Feature",
                                    style: GoogleFonts.poppins(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                const Text(
                                    "Upload unlimited PDFs and Images with Pro.",
                                    textAlign: TextAlign.center),
                              ],
                            )),
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
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05), blurRadius: 20)
          ]),
      child: Column(
        children: [
          Image.network(
              "https://cdn-icons-png.flaticon.com/512/2910/2910768.png",
              height: 120),
          const SizedBox(height: 24),
          Text("Smart Generation",
              style: GoogleFonts.poppins(
                  fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            "Our AI automatically analyzes your content to create the best study materials. Please verify the generated content for accuracy.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(height: 1.5, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
