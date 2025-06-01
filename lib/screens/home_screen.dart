// lib/screens/home_screen.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:visual_notes/models/note.dart';
import 'package:visual_notes/screens/add_note_screen.dart';
import 'package:visual_notes/screens/note_detail_screen.dart';
import 'package:visual_notes/services/notes_service.dart';
import 'package:visual_notes/screens/profile_screen.dart'; // Import ProfileScreen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Note> _displayedNotes = [];
  String _currentSearchQuery = '';
  Future<void>? _searchDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotesService>(context, listen: false).fetchNotes(context).then((_) {
        setState(() {
          _displayedNotes = Provider.of<NotesService>(context, listen: false).notes;
        });
      });
    });

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query == _currentSearchQuery) return;
    _currentSearchQuery = query;

    _searchDebounce = null;
    if (query.isEmpty) {
      setState(() {
        _displayedNotes = Provider.of<NotesService>(context, listen: false).notes;
      });
    } else {
      _searchDebounce = Future.delayed(const Duration(milliseconds: 500), () {
        _performSearch(query);
      });
    }
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;
    final notesService = Provider.of<NotesService>(context, listen: false);
    final results = await notesService.searchNotes(context, query);
    if (!mounted) return;
    setState(() {
      _displayedNotes = results;
    });
  }

  Future<void> _onRefresh() async {
    _searchController.clear();
    await Provider.of<NotesService>(context, listen: false).fetchNotes(context);
    if (!mounted) return;
    setState(() {
      _displayedNotes = Provider.of<NotesService>(context, listen: false).notes;
    });
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

  @override
  Widget build(BuildContext context) {
    final notesService = Provider.of<NotesService>(context);
    if (_searchController.text.isEmpty && notesService.notes != _displayedNotes) {
      _displayedNotes = notesService.notes;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SNAP NOTE',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person_2_rounded, color: Theme.of(context).appBarTheme.iconTheme?.color), // Consistent icon color
            tooltip: 'Profile',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
         
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search notes...',
                prefixIcon: Icon(Icons.search, color: Theme.of(context).inputDecorationTheme.prefixIconColor), // Consistent icon color
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Theme.of(context).inputDecorationTheme.prefixIconColor),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged();
                        },
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
      body: notesService.isLoading && _displayedNotes.isEmpty && _searchController.text.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _onRefresh,
              child: _displayedNotes.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notes, size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty ? 'No notes yet. Tap + to add one!' : 'No notes found for "${_searchController.text}".',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                            if (_searchController.text.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextButton(
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                  child: const Text('Show All Notes'),
                                ),
                              ),
                          ],
                        ),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16.0), // Increased overall padding
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16.0, // Increased spacing
                        mainAxisSpacing: 16.0, // Increased spacing
                        childAspectRatio: 0.8,
                      ),
                      itemCount: _displayedNotes.length,
                      itemBuilder: (context, index) {
                        final note = _displayedNotes[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => NoteDetailScreen(note: note),
                              ),
                            ).then((_) {
                              _onRefresh();
                            });
                          },
                          child: Card( // Card theme is now global
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surface, // Use surface color
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)), // Matches card theme
                                    ),
                                    child: FutureBuilder<String>(
                                      future: _getImageUrl(note.imageUrl),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return Center(child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.primary));
                                        }
                                        
                                        final imageUrl = snapshot.data ?? note.imageUrl;
                                        
                                        return CachedNetworkImage(
                                          imageUrl: imageUrl,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          placeholder: (context, url) => Center(child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.primary)),
                                          errorWidget: (context, url, error) {
                                            print('DEBUG (Home): ERROR loading image for URL: $url - Error: $error');
                                            if (error is Exception) {
                                              print('DEBUG (Home): Exception Type: ${error.runtimeType}');
                                              print('DEBUG (Home): Exception Message: ${error.toString()}');
                                            }
                                            return const Icon(Icons.broken_image, size: 40, color: Color(0xFFFF3B30)); // iOS Red
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        note.title,
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        note.extractedText,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddNoteScreen()),
          );
        },
        tooltip: 'Add New Note',
        child: const Icon(Icons.add),
      ),
    );
  }
}