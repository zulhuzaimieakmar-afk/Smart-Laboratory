
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ControlsPage extends StatefulWidget {
  final DatabaseReference database;

  const ControlsPage({
    super.key,
    required this.database,
  });

  @override
  State<ControlsPage> createState() =>
      _ControlsPageState();
}

class _ControlsPageState extends State<ControlsPage> {
  bool sending = false;

  Map<String, dynamic> asMap(Object? value) {
    if (value is Map) {
      return value.map(
            (key, value) => MapEntry(key.toString(), value),
      );
    }
    return {};
  }

  Future<void> sendCommand(
      String device,
      bool value,
      ) async {
    setState(() => sending = true);

    try {
      await widget.database
          .child('Commands/$device')
          .set(value);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$device command sent: '
                '${value ? 'ON' : 'OFF'}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Command failed: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => sending = false);
      }
    }
  }

  Widget controlCard({
    required String title,
    required String device,
    required IconData icon,
    required bool command,
    required bool actual,
    required bool danger,
  }) {
    return Card(
      color: const Color(0xFF1E293B),
      margin: const EdgeInsets.only(bottom: 15),
      child: Column(
        children: [
          SwitchListTile(
            secondary: Icon(
              icon,
              size: 32,
              color: Colors.cyan,
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'Requested: ${command ? 'ON' : 'OFF'}',
            ),
            value: command,
            onChanged: sending
                ? null
                : (value) {
              if (danger && !value) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Cannot turn OFF alarm '
                          'during DANGER status.',
                    ),
                  ),
                );
                return;
              }

              sendCommand(device, value);
            },
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              16, 0, 16, 14,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'ESP32 reported: ${actual ? 'ON' : 'OFF'}',
                style: const TextStyle(
                  color: Colors.white60,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: widget.database.onValue,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Firebase error: ${snapshot.error}',
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final data = asMap(
          snapshot.data!.snapshot.value,
        );

        final commands = asMap(data['Commands']);
        final actuators = asMap(data['Actuators']);
        final safety = asMap(data['SafetyStatus']);

        final status = (safety['status'] ?? 'UNKNOWN')
            .toString()
            .toUpperCase();

        final danger = status == 'DANGER';

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Actuator Control',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'Control laboratory devices through Firebase',
              style: TextStyle(
                color: Colors.white60,
              ),
            ),

            const SizedBox(height: 22),

            controlCard(
              title: 'Warning LED',
              device: 'led',
              icon: Icons.lightbulb,
              command: commands['led'] == true,
              actual: actuators['led'] == true,
              danger: danger,
            ),

            controlCard(
              title: 'Buzzer Alarm',
              device: 'buzzer',
              icon: Icons.notifications_active,
              command: commands['buzzer'] == true,
              actual: actuators['buzzer'] == true,
              danger: danger,
            ),

            const SizedBox(height: 15),

            Card(
              color: const Color(0xFF1E293B),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.security,
                          color: Colors.orangeAccent,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Automatic Safety Mode',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Text('Current Status: $status'),

                    const SizedBox(height: 10),

                    const Text(
                      'During DANGER, the ESP32 must '
                          'keep the LED and buzzer activated '
                          'even if a manual OFF command is sent.',
                      style: TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
