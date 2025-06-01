// lib/services/notes_service.dart
import 'dart:io'; // For File operations
import 'dart:typed_data'; // For Uint8List
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:visual_notes/models/note.dart';
import 'package:visual_notes/utils/custom_snackbars.dart';
import 'package:image/image.dart' as img_lib; // For image pre-processing
import 'package:path_provider/path_provider.dart'; // For temporary directory access

class NotesService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();
  
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  

  List<Note> _notes = [];
  List<Note> get notes => _notes;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // --- Fetch all notes for the current user ---
  Future<void> fetchNotes(BuildContext context) async {
    _setLoading(true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (!context.mounted) return;
        showSnackBar(context, 'You are not logged in.', isError: true);
        _notes = [];
        notifyListeners();
        return;
      }

      final List<dynamic> response = await _supabase
          .from('notes')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      _notes =
          response
              .map((json) => Note.fromMap(json as Map<String, dynamic>))
              .toList();
      notifyListeners();
    } catch (e) {
      if (!context.mounted) return;
      showSnackBar(context, 'Failed to fetch notes: $e', isError: true);
      _notes = [];
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // --- Add a new note (Image Picker -> OCR -> Upload to Storage -> Save to DB) ---
  Future<void> addNote({
    required BuildContext context,
    required String title,
    XFile? imageFile,
  }) async {
    _setLoading(true);

    // Declare variables outside try block so they are accessible in finally
    String? originalImagePath; // Made nullable to handle initial pick failure
    String? processedImagePath; // Made nullable

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (!context.mounted) return;
        showSnackBar(
          context,
          'You must be logged in to add a note.',
          isError: true,
        );
        return;
      }

      XFile? pickedImage = imageFile;
      if (pickedImage == null) {
        pickedImage = await _picker.pickImage(source: ImageSource.gallery);
        if (pickedImage == null) {
          if (!context.mounted) return;
          showSnackBar(context, 'No image selected.', isError: true);
          return;
        }
      }

      originalImagePath = pickedImage.path;
      processedImagePath = originalImagePath; // Initialize with original path

      // --- Image Pre-processing for better OCR ---
      try {
        final List<int> imageBytes = await File(originalImagePath).readAsBytes();
        final img_lib.Image? originalImage = img_lib.decodeImage(Uint8List.fromList(imageBytes));

        if (originalImage != null) {
          final img_lib.Image grayscaleImage = img_lib.grayscale(originalImage);
          final String tempDir = (await getTemporaryDirectory()).path;
          final String tempPath = '$tempDir/processed_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
          await File(tempPath).writeAsBytes(img_lib.encodeJpg(grayscaleImage, quality: 90));
          processedImagePath = tempPath;
          print('Image processed to grayscale for OCR: $processedImagePath');
        }
      } catch (e) {
        print('Error during image pre-processing (grayscale): $e. Using original image.');
        // Fallback to original image if pre-processing fails
      }
      // --- END Image Pre-processing ---

      // 2. Perform OCR with Google ML Kit using the PROCESSED image
      final InputImage inputImage = InputImage.fromFilePath(processedImagePath!); // Use null-check or '!' if confident
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );
      final String extractedText =
          recognizedText.text.isEmpty
              ? 'No text extracted.'
              : recognizedText.text;

      // 3. Upload Image to Supabase Storage (upload original image for better display)
      final String fileNameInStorage =
          '${user.id}/${DateTime.now().millisecondsSinceEpoch}_${pickedImage.name}';
      await _supabase.storage
          .from('user-notes-images')
          .upload(
            fileNameInStorage,
            File(originalImagePath),
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // Get the *public* URL of the uploaded image
      final String fullImageUrl = _supabase.storage
          .from('user-notes-images')
          .getPublicUrl(
            fileNameInStorage,
          );

      // 4. Save Note metadata to Supabase Database
      final Map<String, dynamic> newNoteData = {
        'user_id': user.id,
        'title': title,
        'extracted_text': extractedText,
        'image_url': fullImageUrl,
      };

      final List<dynamic> response =
          await _supabase.from('notes').insert(newNoteData).select();

      if (response.isNotEmpty) {
        final Note newNote = Note.fromMap(
          response.first as Map<String, dynamic>,
        );
        _notes.insert(0, newNote);
        if (!context.mounted) return;
        showSnackBar(context, 'Note added successfully!');
        notifyListeners();
      } else {
        if (!context.mounted) return;
        showSnackBar(
          context,
          'Failed to add note: No data returned from Supabase.',
          isError: true,
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      showSnackBar(context, 'Failed to add note: $e', isError: true);
    } finally {
      _setLoading(false);
      // Clean up the temporary processed image file if it was created
      // Check if processedImagePath is not null AND if it's different from the original
      if (processedImagePath != null && originalImagePath != null && processedImagePath != originalImagePath) {
        try {
          await File(processedImagePath).delete();
        } catch (e) {
          print('Error deleting temporary processed image: $e');
        }
      }
    }
  }

   // --- Search notes ---
  Future<List<Note>> searchNotes(BuildContext context, String query) async {
    if (query.trim().isEmpty) {
      await fetchNotes(context);
      return _notes;
    }

    _setLoading(true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (!context.mounted) return [];
        showSnackBar(context, 'You are not logged in.', isError: true);
        return [];
      }

      final String searchTerm = query.trim();

      final List<dynamic> response = await _supabase
          .from('notes')
          .select('*')
          .eq('user_id', user.id)
          .textSearch('fts_vector', searchTerm, type: TextSearchType.websearch)
          .order('created_at', ascending: false);

      final List<Note> searchResults = response.map((json) => Note.fromMap(json as Map<String, dynamic>)).toList();
      return searchResults;
    } catch (e) {
      if (!context.mounted) return [];
      showSnackBar(context, 'Failed to search notes: $e', isError: true);
      return [];
    } finally {
      _setLoading(false);
    }
  }

  // --- Delete a note ---
  Future<void> deleteNote(BuildContext context, Note note) async {
    _setLoading(true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null || user.id != note.userId) {
        if (!context.mounted) return;
        showSnackBar(
          context,
          'Unauthorized to delete this note.',
          isError: true,
        );
        return;
      }

      final String bucketUrlPart =
          '${_supabase.storage.url}/user-notes-images/';
      final String pathInStorage = note.imageUrl.substring(
        note.imageUrl.indexOf(bucketUrlPart) + bucketUrlPart.length,
      );

      await _supabase.storage.from('user-notes-images').remove([
        pathInStorage,
      ]);

      await _supabase.from('notes').delete().eq('id', note.id);

      _notes.removeWhere((n) => n.id == note.id);
      if (!context.mounted) return;
      showSnackBar(context, 'Note deleted successfully!');
      notifyListeners();
    } catch (e) {
      if (!context.mounted) return;
      showSnackBar(context, 'Failed to delete note: $e', isError: true);
    } finally {
      _setLoading(false);
    }
  }

  // --- Update note title ---
  Future<void> updateNoteTitle(
    BuildContext context,
    Note note,
    String newTitle,
  ) async {
    _setLoading(true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null || user.id != note.userId) {
        if (!context.mounted) return;
        showSnackBar(
          context,
          'Unauthorized to update this note.',
          isError: true,
        );
        return;
      }

      final List<dynamic> response =
          await _supabase
              .from('notes')
              .update({
                'title': newTitle,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', note.id)
              .select();

      if (response.isNotEmpty) {
        final updatedNote = Note.fromMap(
          response.first as Map<String, dynamic>,
        );
        final index = _notes.indexWhere((n) => n.id == updatedNote.id);
        if (index != -1) {
          _notes[index] = updatedNote;
        }
        if (!context.mounted) return;
        showSnackBar(context, 'Note title updated successfully!');
        notifyListeners();
      }
    } catch (e) {
      if (!context.mounted) return;
      showSnackBar(context, 'Failed to update note title: $e', isError: true);
    } finally {
      _setLoading(false);
    }
  }

  @override
  void dispose() {
    textRecognizer
        .close(); // Clean up ML Kit resources when service is disposed
    super.dispose();
  }
}