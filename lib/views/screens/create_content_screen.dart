import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../services/content_extraction_service.dart';
import '../../utils/app_colors.dart';
import 'dart:typed_data';

class CreateContentScreen extends StatefulWidget {
  const CreateContentScreen({super.key});

  @override
  State<CreateContentScreen> createState() => _CreateContentScreenState();
}

class _CreateContentScreenState extends State<CreateContentScreen> {
  final List<ContentItem> _contentItems = [];
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
  }

  void _addTextCard() {
    setState(() {
      _contentItems.add(ContentItem(type: ContentType.text));
    });
  }

  void _addLinkCard() {
    setState(() {
      _contentItems.add(ContentItem(type: ContentType.link));
    });
  }

  void _addPdfCard() {
    setState(() {
      _contentItems.add(ContentItem(type: ContentType.pdf));
    });
  }

  void _addImageCard() {
    setState(() {
      _contentItems.add(ContentItem(type: ContentType.image));
    });
  }

  void _removeCard(int index) {
    setState(() {
      _contentItems.removeAt(index);
    });
  }

  Future<void> _pickPdf(int index) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result != null) {
      setState(() {
        _contentItems[index].filePath = result.files.single.path;
        _contentItems[index].fileName = result.files.single.name;
        _contentItems[index].fileBytes = result.files.single.bytes;
      });
    }
  }

  Future<void> _pickImage(int index) async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _contentItems[index].filePath = image.path;
        _contentItems[index].fileName = image.name;
        _contentItems[index].fileBytes = bytes;
      });
    }
  }

  Future<void> _captureImage(int index) async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _contentItems[index].filePath = image.path;
        _contentItems[index].fileName = image.name;
        _contentItems[index].fileBytes = bytes;
      });
    }
  }

  Future<String> _extractContent() async {
    final StringBuffer combinedContent = StringBuffer();

    for (final item in _contentItems) {
      switch (item.type) {
        case ContentType.text:
          if (item.content != null && item.content!.isNotEmpty) {
            combinedContent.writeln(item.content);
            combinedContent.writeln('\n');
          }
          break;

        case ContentType.link:
          if (item.content != null && item.content!.isNotEmpty) {
            try {
              final extractedText =
                  await ContentExtractionService.extractFromUrl(item.content!);
              combinedContent.writeln(extractedText);
              combinedContent.writeln('\n');
            } catch (e) {
              // Handle error silently or show a warning
              combinedContent.writeln(
                  '[Failed to extract content from URL: ${item.content}]\n');
            }
          }
          break;

        case ContentType.pdf:
          if (item.fileBytes != null) {
            try {
              final extractedText =
                  await ContentExtractionService.extractFromPdfBytes(
                      item.fileBytes!);
              combinedContent.writeln(extractedText);
              combinedContent.writeln('\n');
            } catch (e) {
              combinedContent.writeln(
                  '[Failed to extract content from PDF: ${item.fileName}]\n');
            }
          }
          break;

        case ContentType.image:
          if (item.fileBytes != null) {
            try {
              final extractedText =
                  await ContentExtractionService.extractFromImageBytes(
                      item.fileBytes!);
              combinedContent.writeln(extractedText);
              combinedContent.writeln('\n');
            } catch (e) {
              combinedContent.writeln(
                  '[Failed to extract text from image: ${item.fileName}]\n');
            }
          }
          break;
      }
    }

    return combinedContent.toString().trim();
  }

  Future<void> _navigateToExtraction() async {
    if (_contentItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add some content first.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Extract all content
      final combinedText = await _extractContent();

      if (combinedText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'No content to process. Please add some text or files.')),
        );
        return;
      }

      // Navigate to extraction view with the extracted content
      if (mounted) {
        context.push('/extraction-view', extra: combinedText);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing content: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAddCardOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Add New Card',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading:
                    const Icon(Icons.text_fields, color: AppColors.primary),
                title: const Text('Add Text Card'),
                onTap: () {
                  Navigator.pop(context);
                  _addTextCard();
                },
              ),
              ListTile(
                leading: const Icon(Icons.link, color: AppColors.primary),
                title: const Text('Add Link Card'),
                onTap: () {
                  Navigator.pop(context);
                  _addLinkCard();
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.picture_as_pdf, color: AppColors.primary),
                title: const Text('Add PDF Card'),
                onTap: () {
                  Navigator.pop(context);
                  _addPdfCard();
                },
              ),
              ListTile(
                leading: const Icon(Icons.image, color: AppColors.primary),
                title: const Text('Add Image Card'),
                onTap: () {
                  Navigator.pop(context);
                  _addImageCard();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Content'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _contentItems.length,
              itemBuilder: (context, index) {
                return _buildContentCard(index, _contentItems[index]);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCardOptions,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildContentCard(int index, ContentItem item) {
    switch (item.type) {
      case ContentType.text:
        return _buildTextCard(index);
      case ContentType.link:
        return _buildLinkCard(index);
      case ContentType.pdf:
        return _buildPdfCard(index);
      case ContentType.image:
        return _buildImageCard(index);
    }
  }

  Widget _buildTextCard(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Text Input',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => _removeCard(index),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 120,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Color(0xFFE0E0E0)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: TextField(
              maxLines: null,
              expands: true,
              decoration: const InputDecoration(
                hintText: 'Enter your text here...',
                border: InputBorder.none,
              ),
              onChanged: (value) {
                _contentItems[index].content = value;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkCard(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Web Link',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => _removeCard(index),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Color(0xFFE0E0E0)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'https://example.com/link',
                border: InputBorder.none,
              ),
              keyboardType: TextInputType.url,
              onChanged: (value) {
                _contentItems[index].content = value;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfCard(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Upload PDF',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => _removeCard(index),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_contentItems[index].filePath == null)
            Column(
              children: [
                ElevatedButton(
                  onPressed: () => _pickPdf(index),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4285F4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Choose PDF'),
                ),
                const SizedBox(height: 8),
                const Text(
                  'No file selected',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: () => _pickPdf(index),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4285F4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Choose PDF'),
                ),
                const SizedBox(height: 8),
                Text(
                  _contentItems[index].fileName ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildImageCard(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Upload Image',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => _removeCard(index),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_contentItems[index].filePath == null)
            Column(
              children: [
                ElevatedButton(
                  onPressed: () => _pickImage(index),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4285F4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Choose Image'),
                ),
                const SizedBox(height: 8),
                const Text(
                  'No image selected',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: () => _pickImage(index),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4285F4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Choose Image'),
                ),
                const SizedBox(height: 8),
                Text(
                  _contentItems[index].fileName ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

enum ContentType {
  text,
  link,
  pdf,
  image,
}

class ContentItem {
  ContentType type;
  String? content;
  String? filePath;
  String? fileName;
  Uint8List? fileBytes;

  ContentItem({
    required this.type,
    this.content,
    this.filePath,
    this.fileName,
    this.fileBytes,
  });
}
