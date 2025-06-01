// lib/screens/note_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:visual_notes/models/note.dart';
import 'package:visual_notes/services/notes_service.dart';
import 'package:visual_notes/utils/custom_snackbars.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:visual_notes/screens/image_viewer_screen.dart'; // Import ImageViewerScreen
import 'package:intl/intl.dart'; // For date formatting

class NoteDetailScreen extends StatefulWidget {
  final Note note;
  const NoteDetailScreen({super.key, required this.note});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late TextEditingController _titleController;
  late Note _currentNote;

  @override
  void initState() {
    super.initState();
    _currentNote = widget.note;
    _titleController = TextEditingController(text: _currentNote.title);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  // Helper method to get proper image URL (Signed URL)
  Future<String> _getImageUrl(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      
      final bucketIndex = pathSegments.indexOf('user-notes-images');
      if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
        final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
        
        final response = await Supabase.instance.client.storage
            .from('user-notes-images')
            .createSignedUrl(filePath, 3600);
        
        return response;
      }
    } catch (e) {
      print('Error creating signed URL: $e');
    }
    
    return imageUrl;
  }

  Future<void> _showEditTitleDialog() async {
    final newTitleController = TextEditingController(text: _currentNote.title);
    final notesService = Provider.of<NotesService>(context, listen: false);

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Edit Note Title'),
          content: TextField(
            controller: newTitleController,
            decoration: const InputDecoration(hintText: 'Enter new title'),
            maxLength: 100,
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.primary)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            Consumer<NotesService>(
              builder: (context, notesService, child) {
                return ElevatedButton(
                  onPressed: notesService.isLoading
                      ? null
                      : () async {
                          if (newTitleController.text.trim().isEmpty) {
                            showSnackBar(
                              context,
                              'Title cannot be empty.',
                              isError: true,
                            );
                            return;
                          }
                          if (newTitleController.text.trim() == _currentNote.title) {
                            showSnackBar(
                              context,
                              'No changes made.',
                              isError: false,
                            );
                            if (mounted) Navigator.of(dialogContext).pop();
                            return;
                          }

                          await notesService.updateNoteTitle(
                            context,
                            _currentNote,
                            newTitleController.text.trim(),
                          );

                          if (!notesService.isLoading && mounted) {
                            final updatedNoteInList = notesService.notes.firstWhere(
                              (n) => n.id == _currentNote.id,
                              orElse: () => _currentNote,
                            );
                            setState(() {
                              _currentNote = updatedNoteInList;
                              _titleController.text = updatedNoteInList.title;
                            });
                            Navigator.of(dialogContext).pop();
                          }
                        },
                  child: notesService.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Save'),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete() async {
    final notesService = Provider.of<NotesService>(context, listen: false);

    bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Delete Note', style: Theme.of(context).textTheme.titleLarge),
          content: Text('Are you sure you want to delete this note? This action cannot be undone.', style: Theme.of(context).textTheme.bodyMedium),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.primary)),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error), // iOS Red
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await notesService.deleteNote(context, _currentNote);
      if (!notesService.isLoading && mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentNote.title, style: Theme.of(context).textTheme.titleLarge),
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: Theme.of(context).appBarTheme.iconTheme?.color),
            tooltip: 'Edit Title',
            onPressed: _showEditTitleDialog,
          ),
          IconButton(
            icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error), // iOS Red for delete icon
            tooltip: 'Delete Note',
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Display
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface, // Use surface color
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: FutureBuilder<String>(
                  future: _getImageUrl(_currentNote.imageUrl),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      );
                    }
                    
                    final String imageUrlToDisplay = snapshot.data ?? _currentNote.imageUrl;
                    
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ImageViewerScreen(
                              imageUrl: imageUrlToDisplay,
                              imageName: _currentNote.title,
                            ),
                          ),
                        );
                      },
                      child: CachedNetworkImage(
                        imageUrl: imageUrlToDisplay,
                        fit: BoxFit.cover,
                        placeholder: (context, url) {
                          print('DEBUG (Detail): Loading image for URL: $url');
                          return Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          );
                        },
                        errorWidget: (context, url, error) {
                          print('DEBUG (Detail): ERROR loading image for URL: $url - Error: $error');
                          if (error is Exception) {
                            print('DEBUG (Detail): Exception Type: ${error.runtimeType}');
                            print('DEBUG (Detail): Exception Message: ${error.toString()}');
                          }
                          return Icon(Icons.broken_image, size: 60, color: Theme.of(context).colorScheme.error); // iOS Red
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Note Details - Title
            Text(
              'TITLE',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary, // iOS Blue for label
                    letterSpacing: 1.5,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _currentNote.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 48, thickness: 1.5, color: Colors.grey),

            // Extracted Text
            Text(
              'EXTRACTED TEXT',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    letterSpacing: 1.5,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
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
              child: SelectableText(
                _currentNote.extractedText,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6, color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
            const SizedBox(height: 24),

            // Metadata: Created At / Updated At info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CREATED',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600], letterSpacing: 0.8),
                    ),
                    Text(
                      DateFormat('MMM dd, yyyy - hh:mm a').format(_currentNote.createdAt.toLocal()),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'LAST UPDATED',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600], letterSpacing: 0.8),
                    ),
                    Text(
                      DateFormat('MMM dd, yyyy - hh:mm a').format(_currentNote.updatedAt.toLocal()),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}