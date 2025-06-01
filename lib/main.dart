import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:visual_notes/services/auth_service.dart';
import 'package:visual_notes/services/notes_service.dart';
import 'package:visual_notes/screens/auth/sign_in_screen.dart';
import 'package:visual_notes/screens/home_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  
  await dotenv.load(fileName: ".env");

  // Initialize Supabase using values from .env
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => NotesService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NoteSnap', // A catchy name idea!
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Core Colors for an iOS-like feel
        primarySwatch: Colors.blueGrey, 
        primaryColor: const Color(0xFF5AC8FA), 
        splashColor: const Color(0xFF007AFF).withOpacity(0.2), 
        highlightColor: Colors.transparent, 
        scaffoldBackgroundColor: const Color(0xFFF2F2F7), 

        colorScheme: const ColorScheme.light(
          primary: Color(0xFF007AFF), 
          secondary: Color(0xFFFF9500), 
          surface: Colors.white, 
          error: Color(0xFFFF3B30), 
          onPrimary: Colors.white,
          onSecondary: Colors.white, 
          onSurface: Color(0xFF1C1C1E),
          onError: Colors.white,
        ),
        brightness: Brightness.light,

       
        fontFamily: GoogleFonts.rubik().fontFamily,
        textTheme: GoogleFonts.rubikTextTheme(
          Theme.of(context).textTheme.copyWith(
            headlineLarge: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E)),
            headlineMedium: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E)),
            headlineSmall: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1C1C1E)),
            titleLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF1C1C1E)),
            titleMedium: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1C1C1E)),
            titleSmall: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF1C1C1E)),
            bodyLarge: const TextStyle(fontSize: 16, color: Color(0xFF1C1C1E)),
            bodyMedium: const TextStyle(fontSize: 14, color: Color(0xFF1C1C1E)),
            bodySmall: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)), // Lighter grey for secondary text
            labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
            labelMedium: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF8E8E93)),
          ),
        ),

    
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFFF2F2F7).withOpacity(0.95), // Slightly transparent background
          foregroundColor: const Color(0xFF1C1C1E), // Dark text/icons
          elevation: 0.5, // Subtle bottom shadow
          shadowColor: Colors.grey.withOpacity(0.2),
          titleTextStyle: GoogleFonts.rubik(
            color: const Color(0xFF1C1C1E),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: const IconThemeData(color: Color(0xFF007AFF)), // iOS Blue for icons
        ),

       
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0), // Consistent rounding
            borderSide: BorderSide.none, // No visible border initially
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0), // iOS Blue on focus
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 1.0), // iOS Red for errors
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.error, width: 2.0),
          ),
          hintStyle: TextStyle(color: Colors.grey[500]),
          labelStyle: TextStyle(color: Colors.grey[700]),
          prefixIconColor: WidgetStateColor.resolveWith((states) =>
            states.contains(WidgetState.focused) ? Theme.of(context).colorScheme.primary : Colors.grey[600]!
          ),
        ),

        
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary, // iOS Blue
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0), // Consistent rounding
            ),
            elevation: 2, // Subtle shadow
            shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            textStyle: GoogleFonts.rubik(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),

        // Text Button Theme (iOS Blue text)
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary, // iOS Blue
            textStyle: GoogleFonts.rubik(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),

        
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          foregroundColor: Colors.white,
          elevation: 5,
        ),

        
        cardTheme: CardTheme(
          elevation: 1.5, // Subtle shadow for cards
          shadowColor: Colors.grey.withOpacity(0.1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), // Consistent rounding
          margin: EdgeInsets.zero,
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final session = snapshot.data?.session;
          if (session != null) {
            return const HomeScreen();
          } else {
            return const SignInScreen();
          }
        }
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}