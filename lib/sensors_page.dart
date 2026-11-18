
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class SensorsPage extends StatelessWidget {
  final DatabaseReference database;

  const SensorsPage({
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

  Widget sensorTile(
      String title,
      String value,
      String description,
      IconData icon,
      Color color,
      ) {
    return Card(
      color: const Color(0xFF1E293B),
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFF334155),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            Text(
              value,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
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
      stream: database.child('Sensors').onValue,
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

        final sensors = asMap(
          snapshot.data!.snapshot.value,
        );

        if (sensors.isEmpty) {
          return const Center(
            child: Text('No sensor readings available'),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Sensor Monitoring',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'Monitor laboratory conditions in real time',
              style: TextStyle(
                color: Colors.white60,
              ),
            ),

            const SizedBox(height: 25),

            sensorTile(
              'Temperature',
              reading(sensors['temperature'], ' °C'),
              'DHT11 Temperature Sensor',
              Icons.thermostat,
              Colors.orangeAccent,
            ),

            sensorTile(
              'Humidity',
              reading(sensors['humidity'], ' %'),
              'DHT11 Humidity Sensor',
              Icons.water_drop,
              Colors.lightBlueAccent,
            ),

            sensorTile(
              'Gas Level',
              reading(sensors['gas'], ''),
              'MQ-2 Gas Sensor',
              Icons.air,
              Colors.greenAccent,
            ),

            sensorTile(
              'Light Level',
              reading(sensors['light'], ''),
              'LDR Light Sensor',
              Icons.wb_sunny,
              Colors.amberAccent,
            ),

            const SizedBox(height: 15),

            const Card(
              color: Color(0xFF1E293B),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sensor Information',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 10),

                    Text(
                      'DHT11: Measures temperature and humidity.',
                    ),

                    SizedBox(height: 6),

                    Text(
                      'MQ-2: Detects changes in gas or smoke level.',
                    ),

                    SizedBox(height: 6),

                    Text(
                      'LDR: Measures relative light level.',
                    ),

                    SizedBox(height: 10),

                    Text(
                      'Gas and light readings use raw ADC '
                          'values from 0 to 4095, not ppm or lux.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white60,
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
