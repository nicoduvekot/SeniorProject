import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart'; //used for input filtering

//enums for suspension values for dropdown
enum suspension{
  COMPRESSSION("Compression"),
  REBOUND("Rebound"),
  SWAYBAR("Sway Bar");

  final String label;

  const suspension(this.label);
}

//enums to set the aero values for dropdown
enum aero{
  SPLINTERANGLE("Splinter Angle"),
  WINGANGLE("Wing Angle");

  final String label;

  const aero(this.label);
}

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
  var suspensionController = TextEditingController(); //this and the following are vars as they are instantiated later.
  var aeroController = TextEditingController();

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
    final snap = await widget.docRef.get();

    trackController.text = snap['track'] ?? '';
    carController.text = snap['car'] ?? '';
    weatherController.text = snap['weather'] ?? '';
    dateController.text = snap['date'] ?? '';

    coldLFController.text = snap['coldLF'];
    coldRFController.text = snap['coldRF'];
    coldLRController.text = snap['coldLR'];
    coldRRController.text = snap['coldRR'];

    startController.text = snap['start'] ?? '';
    driverController.text = snap['driver'] ?? '';
    suspensionController.text = snap['suspension'] ?? '';
    aeroController.text = snap['aero'] ?? '';

    notesController.text = snap['notes'];
    durationController.text = snap['duration'] ?? '';
    endController.text = snap['end'] ?? '';

    //just for the laps setup to rebuild the lap controllers
    lapControllers.clear(); // remove old controllers
    final laps = List<String>.from(snap['laps']);
    for (final lap in laps) {
      lapControllers.add(TextEditingController(text: lap));
    }

    hotLFController.text = snap['hotLF'];
    hotRFController.text = snap['hotRF'];
    hotLRController.text = snap['hotLR'];
    hotRRController.text = snap['hotRR'];

    setState(() => loading = false);
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
      'suspension': suspensionController.text, //no trimming due to cannot be manual input
      'aero': aeroController.text, //no trimming due to cannot be typical input

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

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    //two values for inputs later with enums
    suspension? SusType;
    aero? aeroType;

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
              },
            ),
            const SizedBox(height: 16),

            //suspension settings
            DropdownButtonFormField<suspension>(
              value: SusType,
              decoration: const InputDecoration(
                labelText: "Suspension Type",
                border: OutlineInputBorder(),
              ),
              items: suspension.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.label),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  SusType = value;
                  suspensionController.text = value!.name;
                });
              },
            ),
            const SizedBox(height: 16),

            //aero settings
            DropdownButtonFormField<aero>(
              value: aeroType,
              decoration: const InputDecoration(
                labelText: "Aero Type",
                border: OutlineInputBorder(),
              ),
              items: aero.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.label),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  aeroType = value;
                  aeroController.text = value!.name;
                });
              },
            ),
            const SizedBox(height: 16),

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
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        // Allows digits and only one dot
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],

                      decoration: InputDecoration(labelText: "Left Front")
                  ),
                  TextField(
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        // Allows digits and only one dot
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],

                      decoration: InputDecoration(labelText: "Right Front")
                  ),
                  TextField(
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        // Allows digits and only one dot
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],

                      decoration: InputDecoration(labelText: "Left Rear")
                  ),
                  TextField(
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        // Allows digits and only one dot
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],

                      decoration: InputDecoration(labelText: "Right Rear")
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
              },
            ),
            const SizedBox(height: 16),

            //duration, edit this to only accept amount of time
            TextField(
              controller: durationController,
              maxLines: null,
              decoration: const InputDecoration(
                labelText: "Duration",
                border: OutlineInputBorder(),
              ),
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
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        // Allows digits and only one dot
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],

                      decoration: InputDecoration(labelText: "Left Front")
                  ),
                  TextField(
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        // Allows digits and only one dot
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],

                      decoration: InputDecoration(labelText: "Right Front")
                  ),
                  TextField(
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        // Allows digits and only one dot
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],

                      decoration: InputDecoration(labelText: "Left Rear")
                  ),
                  TextField(
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        // Allows digits and only one dot
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],

                      decoration: InputDecoration(labelText: "Right Rear")
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