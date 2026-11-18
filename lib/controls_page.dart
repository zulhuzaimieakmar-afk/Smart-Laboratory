import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ControlsPage extends StatefulWidget {
  final DatabaseReference database;

  const ControlsPage({
    super.key,
    required this.database,
  });

  @override
  State<ControlsPage> createState() => _ControlsPageState();
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
            '$device command sent: ${value ? 'ON' : 'OFF'}',
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 6,
            ),
            secondary: Icon(
              icon,
              size: 32,
              color: Colors.cyan,
            ),
            title: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            subtitle: Text(
              'Requested: ${command ? 'ON' : 'OFF'}',
              style: const TextStyle(
                color: Colors.white70,
              ),
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
                      'Cannot turn OFF alarm during DANGER status.',
                    ),
                  ),
                );
                return;
              }

              sendCommand(device, value);
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'ESP32 reported: ${actual ? 'ON' : 'OFF'}',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget automaticSafetyCard(String status) {
    Color statusColor;

    if (status == 'SAFE') {
      statusColor = Colors.greenAccent;
    } else if (status == 'DANGER') {
      statusColor = Colors.redAccent;
    } else {
      statusColor = Colors.orangeAccent;
    }

    return Card(
      color: const Color(0xFF1E293B),
      margin: const EdgeInsets.only(top: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 20,
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.security,
                color: statusColor,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Automatic Safety Mode',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Current Status',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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

        final data = asMap(snapshot.data!.snapshot.value);

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
            automaticSafetyCard(status),
          ],
        );
      },
    );
  }
}