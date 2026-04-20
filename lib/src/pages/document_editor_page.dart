import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart'; //used for input filtering

//enums for suspension values for dropdown
enum suspension{
  Compression("Compression"),
  Rebound("Rebound"),
  Swaybar("Sway Bar");

  final String label;

  const suspension(this.label);
}

//enums to set the aero values for dropdown
enum aero{
  SplitterAngle("Splinter Angle"),
  WingAngle("Wing Angle");

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
  final notesController = TextEditingController();
  final startController = TextEditingController();
  final driverController = TextEditingController();
  var suspensionController = TextEditingController(); //this and the following are vars as they are instantiated later.
  var aeroController = TextEditingController();

  //post value fields
  final lapsController = TextEditingController();
  final durationController = TextEditingController();
  final endController = TextEditingController();

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
    trackController.text = snap['content'] ?? '';
    setState(() => loading = false);
  }

  //saving document method
  Future<void> _save() async {
    await widget.docRef.update({
      'content': trackController.text.trim(),
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

    //two values for inputs later
    suspension? SusType;
    aero? aeroType;

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Document")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children:[
            //This sets up the date picker and will make a dropdown for date selection
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
            Text("Pre-Session"),
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
            Text("Cold Tire PSI"),
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
                  TextField(decoration: InputDecoration(labelText: "LF")),
                  TextField(decoration: InputDecoration(labelText: "RF")),
                  TextField(decoration: InputDecoration(labelText: "LR")),
                  TextField(decoration: InputDecoration(labelText: "RR")),
                ],
              ),
            ),
            const SizedBox(height: 16),

            //post-session information
            Text("Post-Session"),
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
            Text("Hot Tire PSI"),
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
                  TextField(decoration: InputDecoration(labelText: "LF")),
                  TextField(decoration: InputDecoration(labelText: "RF")),
                  TextField(decoration: InputDecoration(labelText: "LR")),
                  TextField(decoration: InputDecoration(labelText: "RR")),
                ],
              ),
            ),
            const SizedBox(height: 16),

            //total laps, must be a number
            TextField(
              controller: lapsController,
              keyboardType: TextInputType.number,

              //constricts inputs to only be a number
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],

              decoration: const InputDecoration(
                labelText: "Number of Laps",
                border: OutlineInputBorder(),
              ),
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