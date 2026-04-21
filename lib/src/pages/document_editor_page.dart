import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart'; //used for input filtering

class DocumentEditorPage extends StatefulWidget {
  final DocumentReference docRef;

  const DocumentEditorPage({super.key, required this.docRef});

  @override
  State<DocumentEditorPage> createState() => _DocumentEditorPageState();
}

class _DocumentEditorPageState extends State<DocumentEditorPage> {
  //full set of controllers for input fields

  //Original fields
  final trackController = TextEditingController();
  final carController = TextEditingController();
  final dateController = TextEditingController();
  final weatherController = TextEditingController();

  //pre value fields
  final startController = TextEditingController();
  final driverController = TextEditingController();

  //suspension setup fields
  final compressionController = TextEditingController();
  final reboundController = TextEditingController();
  final swayBarController = TextEditingController();

  //Aero fields
  final wingAngleController = TextEditingController();
  final splitterAngleController = TextEditingController();

  //cold Tire Values
  final coldLFController = TextEditingController();
  final coldRFController = TextEditingController();
  final coldLRController = TextEditingController();
  final coldRRController = TextEditingController();

  //post value fields
  final notesController = TextEditingController();
  final lapsController = TextEditingController();  //might remove
  final durationController = TextEditingController();
  final endController = TextEditingController();

  //used to get the lap times.
  List<TextEditingController> lapControllers = [];

  //hot Tire Values
  final hotLFController = TextEditingController();
  final hotRFController = TextEditingController();
  final hotLRController = TextEditingController();
  final hotRRController = TextEditingController();

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadDocument();

    // Only set today's date if the field is empty,
    if (dateController.text.isEmpty) {
      final today = DateTime.now();
      dateController.text = today.toIso8601String().split('T').first;
    }
  }

  //loading document method
  Future<void> _loadDocument() async {
    try {
      final snap = await widget.docRef.get();

      // Safely get data. If it's a new doc, this map might be empty.
      final data = snap.data() as Map<String, dynamic>? ?? {};

      // Standard Fields
      trackController.text = data['track']?.toString() ?? '';
      carController.text = data['car']?.toString() ?? '';
      weatherController.text = data['weather']?.toString() ?? '';
      dateController.text = data['date']?.toString() ?? '';

      //Individual Suspension Fields
      compressionController.text = data['compression']?.toString() ?? '';
      reboundController.text = data['rebound']?.toString() ?? '';
      swayBarController.text = data['swayBar']?.toString() ?? '';

      //Individual Aero Fields
      wingAngleController.text = data['wingAngle']?.toString() ?? '';
      splitterAngleController.text = data['splitterAngle']?.toString() ?? '';

      //Tire PSI (Cold)
      coldLFController.text = data['coldLF']?.toString() ?? '';
      coldRFController.text = data['coldRF']?.toString() ?? '';
      coldLRController.text = data['coldLR']?.toString() ?? '';
      coldRRController.text = data['coldRR']?.toString() ?? '';

      //Session Data
      startController.text = data['start']?.toString() ?? '';
      driverController.text = data['driver']?.toString() ?? '';
      notesController.text = data['notes']?.toString() ?? '';
      durationController.text = data['duration']?.toString() ?? '';
      endController.text = data['end']?.toString() ?? '';

      //Lap List handling
      lapControllers.clear();
      final laps = List<dynamic>.from(data['laps'] ?? []);
      for (final lap in laps) {
        lapControllers.add(TextEditingController(text: lap.toString()));
      }

      // Tire PSI (Hot)
      hotLFController.text = data['hotLF']?.toString() ?? '';
      hotRFController.text = data['hotRF']?.toString() ?? '';
      hotLRController.text = data['hotLR']?.toString() ?? '';
      hotRRController.text = data['hotRR']?.toString() ?? '';

      setState(() => loading = false);
    } catch (e) {
      print("Error loading document: $e");
      // Even if there's an error, stop the loading spinner
      setState(() => loading = false);
    }
  }

  //saving document method
  Future<void> _save() async {
    //created to make the laptimes json
    final lapTimes = lapControllers.map((c) => c.text).toList();

    await widget.docRef.update({
      'track': trackController.text.trim(),
      'car': carController.text.trim(),
      'weather': weatherController.text.trim(),
      'date': dateController.text, //no trimming due to cannot be typical input
      'start': startController.text, //no trimming due to cannot be typical input
      'driver': driverController.text.trim(),

      'compression': compressionController.text.trim(),
      'rebound': reboundController.text.trim(),
      'swayBar': swayBarController.text.trim(),
      'wingAngle': wingAngleController.text.trim(),
      'splitterAngle': splitterAngleController.text.trim(),

      'coldLF': coldLFController.text.trim(),
      'coldRF': coldRFController.text.trim(),
      'coldLR': coldLRController.text.trim(),
      'coldRR': coldRRController.text.trim(),

      'duration': durationController.text.trim(),
      'end': endController.text.trim(),
      'notes': notesController.text.trim(),

      'laps': lapTimes,

      'hotLF': hotLFController.text.trim(),
      'hotRF': hotRFController.text.trim(),
      'hotLR': hotLRController.text.trim(),
      'hotRR': hotRRController.text.trim(),

      'updatedAt': FieldValue.serverTimestamp(),
    });
    Navigator.pop(context);
  }

  //helper method to build consistent numeric input fields
  Widget _buildNumericField(TextEditingController controller, String label, {String suffix = ""}) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix, //Useful for showing degrees (°)
        border: const OutlineInputBorder(),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Document")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children:[
            //This sets up the date picker and will make a dropdown for date selection
            const SizedBox(height: 16),
            TextField(
              controller: dateController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: "Date",
                border: OutlineInputBorder(),
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2100),
                );

                if (picked != null) {
                  dateController.text = picked.toIso8601String().split('T').first;
                }
              },
            ),
            const SizedBox(height: 16),

            //Sets up the name of the track
            TextField(
              controller: trackController,
              maxLines: null,
              decoration: const InputDecoration(
                labelText: "Track",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            //sets up the info for the cars
            TextField(
              controller: carController,
              maxLines: null,
              decoration: const InputDecoration(
                labelText: "Car",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            //sets up the info for the cars
            TextField(
              controller: weatherController,
              maxLines: null,
              decoration: const InputDecoration(
                labelText: "Weather",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            //pre-session information
            Text("Pre-Session", style: TextStyle(fontSize: 24)),
            const SizedBox(height: 16),

            //Driver, name text field
            TextField(
              controller: driverController,
              maxLines: null,
              decoration: const InputDecoration(
                labelText: "Driver",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            //startTime, edit this to only accept times
            TextField(
              controller: startController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: "Start Time",
                border: OutlineInputBorder(),
              ),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );

                if (picked != null) {
                  final formatted = picked.format(context);
                  setState(() {
                    startController.text = formatted;        //Stores the context string
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            //suspension settings
            // CHANGED: Replaced Suspension Dropdown with individual inputs
            const Text("Suspension Settings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildNumericField(compressionController, "Compression"),
            const SizedBox(height: 12),
            _buildNumericField(reboundController, "Rebound"),
            const SizedBox(height: 12),
            _buildNumericField(swayBarController, "Sway Bar"),
            const SizedBox(height: 24),

            // CHANGED: Replaced Aero Dropdown with individual inputs
            const Text("Aero Settings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _buildNumericField(wingAngleController, "Wing Angle", suffix: "°"),
            const SizedBox(height: 12),
            _buildNumericField(splitterAngleController, "Splitter Angle", suffix: "°"),
            const SizedBox(height: 24),

            //tire psi
            Text("Cold Tire PSI", style: TextStyle(fontSize: 18)),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                childAspectRatio: 3,
                children: [
                  //interior children for inputs
                  TextField(
                      controller: coldLFController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        // Allows digits and only one dot
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],

                      decoration: InputDecoration(labelText: "Left Front", border: OutlineInputBorder(),)
                  ),
                  TextField(
                      controller: coldRFController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        // Allows digits and only one dot
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],

                      decoration: InputDecoration(labelText: "Right Front", border: OutlineInputBorder(),)
                  ),
                  TextField(
                      controller: coldLRController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        // Allows digits and only one dot
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],

                      decoration: InputDecoration(labelText: "Left Rear", border: OutlineInputBorder(),)
                  ),
                  TextField(
                      controller: coldRRController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        // Allows digits and only one dot
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],

                      decoration: InputDecoration(labelText: "Right Rear", border: OutlineInputBorder(),)
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            //post-session information
            Text("Post-Session", style: TextStyle(fontSize: 24)),
            const SizedBox(height: 16),

            //Endtime, must have a time for ending
            TextField(
              controller: endController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: "End Time",
                border: OutlineInputBorder(),
              ),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );

                if (picked != null) {
                  final formatted = picked.format(context);
                  setState(() {
                    endController.text = formatted;        //Stores the context string
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            //tire psi
            Text("Hot Tire PSI", style: TextStyle(fontSize: 18)),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                childAspectRatio: 3,
                children: [
                  //interior boxes for inputs
                  TextField(
                      controller: hotLFController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        // Allows digits and only one dot
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],

                      decoration: InputDecoration(labelText: "Left Front", border: OutlineInputBorder(),)
                  ),
                  TextField(
                      controller: hotRFController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        // Allows digits and only one dot
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],

                      decoration: InputDecoration(labelText: "Right Front", border: OutlineInputBorder(),)
                  ),
                  TextField(
                      controller: hotLRController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        // Allows digits and only one dot
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],

                      decoration: InputDecoration(labelText: "Left Rear", border: OutlineInputBorder(),)
                  ),
                  TextField(
                      controller: hotRRController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        // Allows digits and only one dot
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],

                      decoration: InputDecoration(labelText: "Right Rear", border: OutlineInputBorder(),)
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            //total laps, must be a number
            Text("Laps", style: TextStyle(fontSize: 18)),
            Column(
              children: [
                ...List.generate(lapControllers.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: lapControllers[index],
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Lap ${index + 1}",
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              lapControllers.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                  );
                }),

                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      lapControllers.add(TextEditingController());
                    });
                  },
                  child: const Text("Add Lap"),
                ),
              ],
            ),
            const SizedBox(height: 16),

            //sets up notes for use.
            TextField(
              controller: notesController,
              maxLines: null,
              decoration: const InputDecoration(
                labelText: "Notes",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
            onPressed: _save,
            child: const Text("Save Document"),
        ),
      ),
    );
  }
}