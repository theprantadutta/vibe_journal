import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<String?> _fetchUserName(User user) async {
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName;
    }
    return user.email;
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('VibeJournal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              if (currentUser != null)
                FutureBuilder<String?>(
                  future: _fetchUserName(
                    currentUser,
                  ), // Or directly use currentUser.email
                  builder: (context, snapshot) {
                    String greetingName = 'Viber'; // Default
                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.hasData) {
                      greetingName = snapshot.data!;
                    }
                    return Text(
                      'Welcome back, $greetingName!',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    );
                  },
                )
              else
                Text(
                  'Welcome to VibeJournal!',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 20),
              Text(
                'Ready to log your vibe for today?',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.mic_rounded),
                label: const Text('Record New Vibe'),
                onPressed: () {
                  // Navigate to your recording screen
                },
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                icon: const Icon(Icons.calendar_today_rounded),
                label: const Text('View Mood Calendar'),
                onPressed: () {
                  // Navigate to your mood calendar screen
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
