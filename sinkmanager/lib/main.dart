import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Needed for SystemNavigator
import 'package:process_run/process_run.dart';

void main() {
  runApp(const SinkManagerApp());
}

class SinkManagerApp extends StatelessWidget {
  const SinkManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SinkManager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const SinkManagerHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// --- Real Data Model for Sinks ---
class VirtualSink {
  final int id; // This is the 'module index'
  final String name;
  final String description;

  VirtualSink({required this.id, required this.name, required this.description});
}
// --- End Data Model ---

class SinkManagerHomePage extends StatefulWidget {
  const SinkManagerHomePage({super.key});

  @override
  State<SinkManagerHomePage> createState() => _SinkManagerHomePageState();
}

class _SinkManagerHomePageState extends State<SinkManagerHomePage> {
  // Service to run all our shell commands
  final _pulse = PulseAudioService();

  List<VirtualSink> _sinks = [];
  bool _isLoading = true;

  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshSinkData(); // Changed name
  }

  /// Fetches only the sinks from PulseAudio
  Future<void> _refreshSinkData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch only sinks now
      final sinksResult = await _pulse.getSinks();

      if (!mounted) return;
      setState(() {
        _sinks = sinksResult;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading sinks: $e"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Shows the dialog to create a new sink.
  void _showCreateSinkDialog() {
    _nameController.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Create New Sink"),
          content: TextField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: "Sink Name",
              hintText: "e.g., JAERO_Sink",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            FilledButton(
              child: const Text("Create"),
              onPressed: () async {
                final String name = _nameController.text;
                if (name.isEmpty) return;

                Navigator.of(context).pop(); // Close dialog first
                try {
                  await _pulse.createSink(name);
                  await _refreshSinkData(); // Refresh list
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error creating sink: $e"),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  /// Shows a confirmation dialog before deleting a sink.
  void _showDeleteConfirmDialog(VirtualSink sink) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Sink?"),
          content: Text(
              "Are you sure you want to delete \"${sink.name}\"?\n\nThis may disconnect any applications currently using it."),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade800,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.delete_forever),
              label: const Text("Delete"),
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog first
                try {
                  await _pulse.deleteSink(sink.id);
                  await _refreshSinkData(); // Refresh list
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error deleting sink: $e"),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SinkManager"),
        elevation: 1,
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh Sinks",
            onPressed: _refreshSinkData,
          ),
          // Create Sink button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: FilledButton.icon(
              onPressed: _showCreateSinkDialog,
              icon: const Icon(Icons.add),
              label: const Text("Create Sink"),
            ),
          ),
          // --- NEW CLOSE BUTTON ---
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: "Close Application",
            onPressed: () {
              // This closes the application
              SystemNavigator.pop();
            },
          ),
          const SizedBox(width: 8), // Add a little spacing
          // --- END NEW CLOSE BUTTON ---
        ],
      ),
      // Body is now centered and constrained, directly showing the sink list
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildSinkList(),
        ),
      ),
    );
  }

  /// Builds the list of virtual sinks.
  Widget _buildSinkList() {
    if (_sinks.isEmpty) {
      return _buildEmptyState(
        "No Virtual Sinks",
        "Click 'Create Sink' to get started.",
        Icons.speaker_group_outlined,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12.0), // Added padding back
      itemCount: _sinks.length,
      itemBuilder: (context, index) {
        final sink = _sinks[index];

        // Determine the best title and subtitle to show
        String title;
        String subtitle;

        if (sink.name.isNotEmpty) {
          title = sink.name;
          subtitle = (sink.description.isNotEmpty && sink.description != title)
              ? sink.description
              : "Virtual Sink";
        } else if (sink.description.isNotEmpty) {
          title = sink.description;
          subtitle = "Virtual Sink";
        } else {
          title = "Unnamed Sink";
          subtitle = "Virtual Sink";
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6.0), // Added margin back
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              child: const Icon(Icons.speaker_group_outlined),
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(subtitle),
            trailing: IconButton(
              icon: Icon(
                Icons.delete_outline,
                color: Colors.red.shade300,
              ),
              tooltip: "Delete $title",
              onPressed: () {
                _showDeleteConfirmDialog(sink);
              },
            ),
          ),
        );
      },
    );
  }

  /// Helper widget for empty list placeholders.
  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 70,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// == SERVICE CLASS
// =====================================================================
class PulseAudioService {
  final _shell = Shell();

  /// Runs 'pactl' and parses the output.
  Future<List<String>> _runPactl(String command) async {
    try {
      final result = await _shell.run('pactl $command');
      if (result.first.exitCode != 0) {
        throw Exception("pactl error: ${result.first.stderr}");
      }
      return result.first.outLines.toList();
    } catch (e) {
      throw Exception("Failed to run pactl. Is PulseAudio or PipeWire running? Error: $e");
    }
  }

  /// Parses a key=value string from the Argument line.
  String _parseArgumentProperty(String argumentLine, String key) {
     final pattern = RegExp('$key=([^ ]+)');
     final match = pattern.firstMatch(argumentLine);
     // Remove quotes if they exist around the value
     return match?.group(1)?.replaceAll('"', '') ?? '';
  }

  /// Parses a key="value" string from the sink_properties part.
  String _parseSinkProperty(String sinkProps, String key) {
     // Updated regex to handle both quoted and unquoted descriptions
     // Tries to find key="value" first, then falls back to key=value
     final quotedPattern = RegExp('$key=\\\\"([^"]+)\\\\"');
     var match = quotedPattern.firstMatch(sinkProps);
     if (match != null) {
       return match.group(1) ?? '';
     } else {
       final unquotedPattern = RegExp('$key=([^ ]+)');
       match = unquotedPattern.firstMatch(sinkProps);
       return match?.group(1) ?? '';
     }
  }


  /// Gets all loaded null-sinks.
  Future<List<VirtualSink>> getSinks() async {
    final lines = await _runPactl('list modules');
    final sinks = <VirtualSink>[];
    int currentModuleId = -1;
    bool isNullSinkModule = false;
    String argumentLine = "";

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.startsWith('Module #')) {
        if (isNullSinkModule && currentModuleId != -1 && argumentLine.isNotEmpty) {
           _parseAndAddSink(sinks, currentModuleId, argumentLine);
        }
        try {
          currentModuleId = int.parse(trimmedLine.split('#').last);
          isNullSinkModule = false;
          argumentLine = "";
        } catch (e) { currentModuleId = -1; }
      }
      else if (currentModuleId != -1 && trimmedLine.startsWith('Name: module-null-sink')) {
        isNullSinkModule = true;
      }
      else if (currentModuleId != -1 && trimmedLine.startsWith('Argument: ')) {
        argumentLine = trimmedLine.substring('Argument: '.length);
      }
    }
    if (isNullSinkModule && currentModuleId != -1 && argumentLine.isNotEmpty) {
       _parseAndAddSink(sinks, currentModuleId, argumentLine);
    }
    return sinks;
  }

  /// Helper function to parse the Argument line and add the sink
  void _parseAndAddSink(List<VirtualSink> sinks, int moduleId, String argumentLine) {
    String name = "";
    String description = "";

    // Parse sink_name=...
    name = _parseArgumentProperty(argumentLine, 'sink_name');

    // Parse sink_properties=...
    final propsString = _parseArgumentProperty(argumentLine, 'sink_properties');
    if (propsString.isNotEmpty) {
      // Parse device.description="..." within the properties
      description = _parseSinkProperty(propsString, 'device.description');
    }

    sinks.add(VirtualSink(
      id: moduleId,
      name: name,
      description: description,
    ));
  }


  /// Creates a new null-sink.
  Future<void> createSink(String name) async {
    final safeName = name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
    if (safeName.isEmpty) throw Exception("Invalid name");
    // Ensure description is also set when creating
    await _runPactl(
      'load-module module-null-sink sink_name="$safeName" sink_properties=device.description="$safeName"',
    );
  }

  /// Deletes a null-sink by its module ID.
  Future<void> deleteSink(int moduleId) async {
    await _runPactl('unload-module $moduleId');
  }

}