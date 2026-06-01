import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_flow_showcase/src/widgets/status_indicators.dart';
import '../models/document_status.dart';
import '../services/document_service.dart';
import '../widgets/create_document_dialog.dart';
import 'document_editor_page.dart';
import '../widgets/app_alert.dart';

// Used for assigning an object for search functionality
class MyObject {
  final String name;
  MyObject(this.name);
}

// Holds the current filter state. All fields are optional — null means "no filter"
class _LogFilter {
  final String? track;
  final String? car;
  final String? driver;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  const _LogFilter({
    this.track,
    this.car,
    this.driver,
    this.dateFrom,
    this.dateTo,
  });

  bool get isEmpty =>
      track == null &&
          car == null &&
          driver == null &&
          dateFrom == null &&
          dateTo == null;

  int get activeCount => [
    track,
    car,
    driver,
    if (dateFrom != null || dateTo != null) "date",
  ].length;

  bool matches(Map<String, dynamic> data) {
    if (track != null && data['track']?.toString() != track) return false;
    if (car != null && data['car']?.toString() != car) return false;
    if (driver != null && data['driver']?.toString() != driver) return false;
    if (dateFrom != null || dateTo != null) {
      final date = DateTime.tryParse(data['date']?.toString() ?? '');
      if (date == null) return false;
      if (dateFrom != null && date.isBefore(dateFrom!)) return false;
      if (dateTo != null && date.isAfter(dateTo!.add(const Duration(days: 1)))) {
        return false;
      }
    }
    return true;
  }

  _LogFilter copyWith({
    Object? track = _sentinel,
    Object? car = _sentinel,
    Object? driver = _sentinel,
    Object? dateFrom = _sentinel,
    Object? dateTo = _sentinel,
  }) {
    return _LogFilter(
      track: track == _sentinel ? this.track : track as String?,
      car: car == _sentinel ? this.car : car as String?,
      driver: driver == _sentinel ? this.driver : driver as String?,
      dateFrom: dateFrom == _sentinel ? this.dateFrom : dateFrom as DateTime?,
      dateTo: dateTo == _sentinel ? this.dateTo : dateTo as DateTime?,
    );
  }
}

const _sentinel = Object();

// Extracts the sorted unique non-empty values for a given field across all docs
List<String> _uniqueValues(List<QueryDocumentSnapshot> docs, String field) {
  final values = docs
      .map((d) => (d.data() as Map<String, dynamic>)[field]?.toString().trim() ?? '')
      .where((v) => v.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
  return values;
}

class DocumentsHomePage extends StatefulWidget {
  const DocumentsHomePage({super.key});

  @override
  State<DocumentsHomePage> createState() => _DocumentsHomePageState();
}

class _DocumentsHomePageState extends State<DocumentsHomePage> {
  _LogFilter _filter = const _LogFilter();

  DocumentStatus _getStatusForDoc(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    if (doc.metadata.hasPendingWrites) return DocumentStatus.syncing;
    final hasName = data['name'] != null && data['name'].toString().isNotEmpty;
    final hasContent = data['track'] != null && data['track'].toString().isNotEmpty;
    return (hasName && hasContent) ? DocumentStatus.complete : DocumentStatus.incomplete;
  }

  // Opens the filter sheet, passing the full doc list so it can build dropdowns
  Future<void> _openFilterSheet(List<QueryDocumentSnapshot> allDocs) async {
    final result = await showModalBottomSheet<_LogFilter>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _FilterSheet(initial: _filter, allDocs: allDocs),
    );
    if (result != null) setState(() => _filter = result);
  }

  Widget _filterChip(String label, VoidCallback onRemove) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        deleteIcon: const Icon(Icons.close, size: 14),
        onDeleted: onRemove,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final service = DocumentService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Documents"),
        actions: [
          // Filter button — built inside the StreamBuilder so it can pass allDocs
          StreamBuilder(
            stream: service.userDocumentsStream(),
            builder: (context, snapshot) {
              final allDocs = snapshot.data ?? [];
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.filter_list,
                      color: _filter.isEmpty
                          ? null
                          : Theme.of(context).colorScheme.primary,
                    ),
                    tooltip: "Filter logs",
                    onPressed: () => _openFilterSheet(allDocs),
                  ),
                  if (!_filter.isEmpty)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${_filter.activeCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Log out",
            onPressed: () async {
              final shouldLogout = await AppAlert.showYesNoAlert(
                context,
                "Continue with log out?",
                yesText: "Yes",
                noText: "No",
              );
              if (shouldLogout) await FirebaseAuth.instance.signOut();
            },
          ),
        ],

        // The addition for the search bar functionality
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SearchAnchor(
              builder: (BuildContext context, SearchController controller) {
                return SearchBar(
                  controller: controller,
                  padding: const WidgetStatePropertyAll<EdgeInsets>(
                    EdgeInsets.symmetric(horizontal: 16.0),
                  ),
                  onTap: () { controller.openView(); },
                  onChanged: (_) { controller.openView(); },
                  leading: const Icon(Icons.search),
                );
              },
              suggestionsBuilder: (BuildContext context, SearchController controller) {
                return [
                  StreamBuilder<List<QueryDocumentSnapshot>>(
                    stream: service.userDocumentsStream(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox.shrink();
                      }

                      final docs = snapshot.data!;
                      final query = controller.text.toLowerCase();

                      final filtered = docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final queryLower = query.toLowerCase();

                        final fields = [
                          data['name'],
                          data['notes'],
                          data['track'],
                          data['car'],
                          data['weather'],
                          data['driver'],
                          data['suspension'],
                          data['aero'],
                        ];

                        return fields.any((value) =>
                            (value ?? '').toString().toLowerCase().contains(queryLower));
                      }).toList();

                      return Column(
                        children: filtered.map((doc) {
                          return ListTile(
                            title: Text(doc['name']),
                            onTap: () {
                              controller.closeView(doc['name']); // fills the search bar

                              // This allows for selecting the doc to see the editor
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DocumentEditorPage(docRef: doc.reference),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      );
                    },
                  )
                ];
              },
            ),
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => CreateDocumentDialog(
              onCreate: service.createDocument,
              onCheckName: service.nameExists,
            ),
          );
        },
        child: const Icon(Icons.add),
      ),

      body: Column(
        children: [
          // Active filter chips
          if (!_filter.isEmpty)
            Container(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.filter_list, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (_filter.track != null)
                            _filterChip('Track: ${_filter.track}',
                                    () => setState(() => _filter = _filter.copyWith(track: null))),
                          if (_filter.car != null)
                            _filterChip('Car: ${_filter.car}',
                                    () => setState(() => _filter = _filter.copyWith(car: null))),
                          if (_filter.driver != null)
                            _filterChip('Driver: ${_filter.driver}',
                                    () => setState(() => _filter = _filter.copyWith(driver: null))),
                          if (_filter.dateFrom != null || _filter.dateTo != null)
                            _filterChip(
                              'Date: ${_filter.dateFrom != null ? _fmt(_filter.dateFrom!) : '…'}'
                                  ' – ${_filter.dateTo != null ? _fmt(_filter.dateTo!) : '…'}',
                                  () => setState(() =>
                              _filter = _filter.copyWith(dateFrom: null, dateTo: null)),
                            ),
                          TextButton(
                            onPressed: () => setState(() => _filter = const _LogFilter()),
                            child: const Text("Clear all"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: StreamBuilder(
              stream: service.userDocumentsStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allDocs = snapshot.data!;
                final docs = _filter.isEmpty
                    ? allDocs
                    : allDocs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return _filter.matches(data);
                }).toList();

                if (allDocs.isEmpty) {
                  return const Center(child: Text("No documents yet"));
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text("No logs match your filters"),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => setState(() => _filter = const _LogFilter()),
                          child: const Text("Clear filters"),
                        ),
                      ],
                    ),
                  );
                }

                return ListView(
                  children: docs.map((d) {
                    return ListTile(
                      leading: StatusIndicators(status: _getStatusForDoc(d)),
                      title: Text(d['name']),
                      subtitle: _buildSubtitle(d.data() as Map<String, dynamic>),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: "Delete document",
                        onPressed: () async {
                          final shouldDelete = await AppAlert.showYesNoAlert(
                            context,
                            "Deletion CANNOT be undone!",
                            title: "Delete '${d['name']}'?",
                            yesText: "Delete",
                            noText: "Cancel",
                            titleColor: Colors.red,
                          );
                          if (shouldDelete) await d.reference.delete();
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DocumentEditorPage(docRef: d.reference),
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildSubtitle(Map<String, dynamic> data) {
    final parts = <String>[];
    if ((data['track'] ?? '').toString().isNotEmpty) parts.add(data['track']);
    if ((data['date'] ?? '').toString().isNotEmpty) parts.add(data['date']);
    if (parts.isEmpty) return null;
    return Text(parts.join(' · '),
        style: const TextStyle(fontSize: 12, color: Colors.grey));
  }
}

//Filter bottom sheet

class _FilterSheet extends StatefulWidget {
  final _LogFilter initial;
  final List<QueryDocumentSnapshot> allDocs;

  const _FilterSheet({required this.initial, required this.allDocs});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String? _track;
  String? _car;
  String? _driver;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  late final List<String> _tracks;
  late final List<String> _cars;
  late final List<String> _drivers;

  @override
  void initState() {
    super.initState();
    _track = widget.initial.track;
    _car = widget.initial.car;
    _driver = widget.initial.driver;
    _dateFrom = widget.initial.dateFrom;
    _dateTo = widget.initial.dateTo;

    // Build sorted unique option lists from all docs
    _tracks = _uniqueValues(widget.allDocs, 'track');
    _cars = _uniqueValues(widget.allDocs, 'car');
    _drivers = _uniqueValues(widget.allDocs, 'driver');
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _dateFrom : _dateTo) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _dateFrom = picked;
        if (_dateTo != null && picked.isAfter(_dateTo!)) _dateTo = picked;
      } else {
        _dateTo = picked;
        if (_dateFrom != null && picked.isBefore(_dateFrom!)) _dateFrom = picked;
      }
    });
  }

  void _apply() {
    Navigator.pop(
      context,
      _LogFilter(
        track: _track,
        car: _car,
        driver: _driver,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
      ),
    );
  }

  void _reset() => setState(() {
    _track = null;
    _car = null;
    _driver = null;
    _dateFrom = null;
    _dateTo = null;
  });

  // A labeled dropdown that shows "Any" as the unselected state
  Widget _dropdown({
    required String label,
    required IconData icon,
    required List<String> options,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    // If the saved value no longer exists in the options (doc was deleted),
    // fall back to null so the dropdown doesn't break
    final safeValue = (value != null && options.contains(value)) ? value : null;

    return DropdownButtonFormField<String>(
      value: safeValue,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      hint: Text('Any $label'),
      isExpanded: true,
      items: [
        // "Any" option clears the filter for this field
        DropdownMenuItem<String>(
          value: null,
          child: Text('Any $label',
              style: const TextStyle(color: Colors.grey)),
        ),
        ...options.map((o) => DropdownMenuItem(value: o, child: Text(o))),
      ],
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text("Filter Logs",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton(onPressed: _reset, child: const Text("Reset")),
            ],
          ),
          const SizedBox(height: 16),

          _dropdown(
            label: 'Track',
            icon: Icons.location_on_outlined,
            options: _tracks,
            value: _track,
            onChanged: (v) => setState(() => _track = v),
          ),
          const SizedBox(height: 12),

          _dropdown(
            label: 'Car',
            icon: Icons.directions_car_outlined,
            options: _cars,
            value: _car,
            onChanged: (v) => setState(() => _car = v),
          ),
          const SizedBox(height: 12),

          _dropdown(
            label: 'Driver',
            icon: Icons.person_outline,
            options: _drivers,
            value: _driver,
            onChanged: (v) => setState(() => _driver = v),
          ),
          const SizedBox(height: 16),

          const Text("Date Range",
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDate(isFrom: true),
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    _dateFrom != null ? _fmtDate(_dateFrom!) : "From",
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDate(isFrom: false),
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    _dateTo != null ? _fmtDate(_dateTo!) : "To",
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (_dateFrom != null || _dateTo != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: "Clear dates",
                  onPressed: () => setState(() => _dateFrom = _dateTo = null),
                ),
            ],
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _apply,
              child: const Text("Apply Filters"),
            ),
          ),
        ],
      ),
    );
  }
}