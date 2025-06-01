// lib/screens/add_note_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:visual_notes/services/notes_service.dart';
import 'package:visual_notes/utils/custom_snackbars.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class AddNoteScreen extends StatefulWidget {
  const AddNoteScreen({super.key});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final TextEditingController _titleController = TextEditingController();
  XFile? _pickedImage;
  String _extractedTextPreview = '';
  bool _isProcessingImage = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _pickedImage = image;
          _extractedTextPreview = 'Processing text...';
          _isProcessingImage = true;
        });
        await _performOCR(image);
      } else {
        if (!mounted) return;
        setState(() {
          _pickedImage = null;
          _extractedTextPreview = '';
        });
        showSnackBar(context, 'No image selected.');
      }
    } catch (e) {
      if (!mounted) return;
      showSnackBar(context, 'Failed to pick image: $e', isError: true);
      setState(() {
        _isProcessingImage = false;
        _extractedTextPreview = 'Error picking image.';
      });
    }
  }

  Future<void> _performOCR(XFile image) async {
    final textRecognizer = TextRecognizer();
    try {
      final InputImage inputImage = InputImage.fromFilePath(image.path);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      if (!mounted) return;
      setState(() {
        _extractedTextPreview = recognizedText.text.isEmpty ? 'No text found in image.' : recognizedText.text;
      });
    } catch (e) {
      if (!mounted) return;
      showSnackBar(context, 'Failed to extract text: $e', isError: true);
      setState(() {
        _extractedTextPreview = 'Error extracting text.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isProcessingImage = false;
      });
      textRecognizer.close();
    }
  }

  Future<void> _saveNote() async {
    if (_pickedImage == null) {
      showSnackBar(context, 'Please select an image first.', isError: true);
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      showSnackBar(context, 'Please enter a title for your note.', isError: true);
      return;
    }
    if (_isProcessingImage) {
      showSnackBar(context, 'Please wait for text extraction to complete.', isError: true);
      return;
    }
    if (_extractedTextPreview.isEmpty || _extractedTextPreview == 'No text extracted.' || _extractedTextPreview.contains('Error')) {
      showSnackBar(context, 'Text extraction failed or not complete. Please try again or select a different image.', isError: true);
      return;
    }

    final notesService = Provider.of<NotesService>(context, listen: false);
    await notesService.addNote(
      context: context,
      title: _titleController.text.trim(),
      imageFile: _pickedImage!,
    );

    if (!notesService.isLoading && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final notesService = Provider.of<NotesService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Note', style: Theme.of(context).textTheme.titleLarge),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Preview Area
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface, // Use surface color (white)
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: Colors.grey.shade300, width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: _pickedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10.0), // Match input field rounding
                        child: Image.file(
                          File(_pickedImage!.path),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 60, color: Colors.grey[500]),
                          const SizedBox(height: 12),
                          Text(
                            'Tap to pick an image',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]), // Use bodyLarge
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 32),

            // Title Input
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Note Title',
                hintText: 'e.g., Meeting Notes, Grocery List',
                prefixIcon: Icon(Icons.title),
              ),
              maxLength: 100,
            ),
            const SizedBox(height: 32),

            // Extracted Text Preview
            Text(
              'Extracted Text Preview:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface, // Use surface color (white)
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              constraints: const BoxConstraints(minHeight: 120),
              child: _isProcessingImage
                  ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
                  : SelectableText(
                      _extractedTextPreview.isEmpty ? 'No image selected or text extracted yet.' : _extractedTextPreview,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6, color: Theme.of(context).colorScheme.onSurface), // Use onSurface
                    ),
            ),
            const SizedBox(height: 40),

            // Save Button
            notesService.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _saveNote,
                    child: const Text('Save Note'),
                  ),
          ],
        ),
      ),
    );
  }
}