
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class DashboardPage extends StatelessWidget {
  final DatabaseReference database;

  const DashboardPage({
    super.key,
    required this.database,
  });

  Map<String, dynamic> asMap(Object? value) {
    if (value is Map) {
      return value.map(
            (key, value) => MapEntry(key.toString(), value),
      );
    }
    return {};
  }

  String reading(Object? value, String unit) {
    if (value == null || value.toString().isEmpty) {
      return '--';
    }
    return '${value.toString()}$unit';
  }

  Widget sensorCard(
      String title,
      String value,
      IconData icon,
      ) {
    return Card(
      color: const Color(0xFF1E293B),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 34, color: Colors.cyan),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
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
      stream: database.onValue,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Firebase error: ${snapshot.error}',
              textAlign: TextAlign.center,
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final data = asMap(snapshot.data!.snapshot.value);

        if (data.isEmpty) {
          return const Center(
            child: Text('No SmartLab data found'),
          );
        }

        final sensors = asMap(data['Sensors']);
        final actuators = asMap(data['Actuators']);
        final safety = asMap(data['SafetyStatus']);

        final status = (safety['status'] ?? 'UNKNOWN')
            .toString()
            .trim()
            .toUpperCase();

        final displayStatus =
        status.isEmpty ? 'UNKNOWN' : status;

        Color statusColor;

        if (displayStatus == 'SAFE') {
          statusColor = Colors.greenAccent;
        } else if (displayStatus == 'DANGER') {
          statusColor = Colors.redAccent;
        } else {
          statusColor = Colors.orangeAccent;
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Welcome to Smart Lab!',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'Laboratory safety monitoring dashboard',
              style: TextStyle(color: Colors.white60),
            ),

            const SizedBox(height: 18),

            Card(
              color: const Color(0xFF1E293B),
              child: const ListTile(
                leading: Icon(
                  Icons.cloud_done,
                  color: Colors.cyan,
                  size: 32,
                ),
                title: Text('Firebase Connected'),
                subtitle: Text(
                  'Live database listener active',
                ),
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Live Sensor Readings',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 1.12,
              shrinkWrap: true,
              physics:
              const NeverScrollableScrollPhysics(),
              children: [
                sensorCard(
                  'Temperature',
                  reading(sensors['temperature'], ' °C'),
                  Icons.thermostat,
                ),
                sensorCard(
                  'Humidity',
                  reading(sensors['humidity'], ' %'),
                  Icons.water_drop,
                ),
                sensorCard(
                  'Gas Level',
                  reading(sensors['gas'], ''),
                  Icons.air,
                ),
                sensorCard(
                  'Light Level',
                  reading(sensors['light'], ''),
                  Icons.light_mode,
                ),
              ],
            ),

            const SizedBox(height: 16),

            Card(
              color: const Color(0xFF1E293B),
              child: ListTile(
                leading: Icon(
                  Icons.shield,
                  size: 36,
                  color: statusColor,
                ),
                title: const Text('Laboratory Safety'),
                subtitle: Text(
                  displayStatus,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'Actuator Status',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Card(
              color: const Color(0xFF1E293B),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.lightbulb_outline,
                      color: Colors.amber,
                    ),
                    title: const Text('Warning LED'),
                    trailing: Text(
                      actuators['led'] == true
                          ? 'ON'
                          : 'OFF',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const Divider(height: 1),

                  ListTile(
                    leading: const Icon(
                      Icons.notifications_active,
                      color: Colors.cyan,
                    ),
                    title: const Text('Buzzer'),
                    trailing: Text(
                      actuators['buzzer'] == true
                          ? 'ON'
                          : 'OFF',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
