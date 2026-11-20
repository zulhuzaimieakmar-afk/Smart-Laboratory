
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Center(
          child: CircleAvatar(
            radius: 42,
            backgroundColor: Color(0xFF164E63),
            child: Icon(
              Icons.person,
              color: Colors.cyan,
              size: 45,
            ),
          ),
        ),

        const SizedBox(height: 15),

        const Center(
          child: Text(
            'Account Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 25),

        Card(
          color: const Color(0xFF1E293B),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.email,
                  color: Colors.cyan,
                ),
                title: const Text('Email'),
                subtitle: Text(
                  user?.email ?? 'Not available',
                ),
              ),

              const Divider(height: 1),

              const ListTile(
                leading: Icon(
                  Icons.cloud,
                  color: Colors.cyan,
                ),
                title: Text('Firebase Project'),
                subtitle: Text('test-app-imi'),
              ),

              const Divider(height: 1),

              const ListTile(
                leading: Icon(
                  Icons.storage,
                  color: Colors.cyan,
                ),
                title: Text('Database'),
                subtitle: Text('Firebase Realtime Database'),
              ),

              const Divider(height: 1),

              const ListTile(
                leading: Icon(
                  Icons.folder,
                  color: Colors.cyan,
                ),
                title: Text('Database Path'),
                subtitle: Text('SmartLab'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        const Card(
          color: Color(0xFF1E293B),
          child: ListTile(
            leading: Icon(
              Icons.info_outline,
              color: Colors.cyan,
            ),
            title: Text('About Application'),
            subtitle: Text(
              'Smart Laboratory Safety Monitoring System\n'
                  'Monitor Laboratory Environment'
            ),
          ),
        ),

        const SizedBox(height: 25),

        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
              } catch (e) {
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Logout failed: $e'),
                  ),
                );
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('LOG OUT'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 20),

        const Center(
          child: Text(
            'Smart Laboratory v1.0',
            style: TextStyle(
              color: Colors.white38,
            ),
          ),
        ),
      ],
    );
  }
}
