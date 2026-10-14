
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'catalogue_repository.dart';
import 'catalogue_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final helper = DatabaseHelper();

  try {
    await helper.init();
  } catch (error, stackTrace) {
    debugPrint('Database initialization failed: $error\n$stackTrace');

    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Could not open local storage. Restart the app and check the logs.',
            ),
          ),
        ),
      ),
    );
    return;
  }

  runApp(FestivalApp(helper: helper));
}

class FestivalApp extends StatelessWidget {
  final DatabaseHelper helper;

  const FestivalApp({super.key, required this.helper});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Local Storage Lab',
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Local Storage Lab')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FestivalRoster(helper: helper),
                    ),
                  ),
                  child: const Text('Part I - Guest Roster'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CatalogueScreen(
                        repository: CatalogueRepository(helper),
                      ),
                    ),
                  ),
                  child: const Text('Part II - Card Catalogue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FestivalRoster extends StatefulWidget {
  final DatabaseHelper helper;

  const FestivalRoster({super.key, required this.helper});

  @override
  State<FestivalRoster> createState() => _FestivalRosterState();
}

class _FestivalRosterState extends State<FestivalRoster> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();

  List<Map<String, dynamic>> _rows = [];
  int _count = 0;

  bool _loading = true;
  bool _busy = false;

  int? _selectedId;

  String? _message;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadGuests();
  }

  Future<void> _loadGuests() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final rows = await widget.helper.queryAllRows();
      final count = await widget.helper.queryRowCount();

      if (!mounted) return;

      setState(() {
        _rows = rows;
        _count = count;
        _loading = false;
      });
    } catch (error) {
      debugPrint('Read failed: $error');

      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage = 'Could not load guests. Press Refresh to try again.';
      });
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter a name.';
    }
    return null;
  }

  String? _validateAge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter an age.';
    }

    final age = int.tryParse(value.trim());

    if (age == null) {
      return 'Age must be a whole number.';
    }

    if (age < 0 || age > 130) {
      return 'Age must be from 0 to 130.';
    }

    return null;
  }

  Future<void> _saveGuest() async {
    if (_busy) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final age = int.parse(_ageController.text.trim());

    setState(() {
      _busy = true;
      _message = null;
      _errorMessage = null;
    });

    bool writeSucceeded = false;

    try {
      if (_selectedId == null) {
        final id = await widget.helper.insert({
          DatabaseHelper.columnName: name,
          DatabaseHelper.columnAge: age,
        });

        writeSucceeded = true;
        _message = 'Guest saved with ID $id.';
      } else {
        final id = _selectedId!;

        final updated = await widget.helper.update({
          DatabaseHelper.columnId: id,
          DatabaseHelper.columnName: name,
          DatabaseHelper.columnAge: age,
        });

        if (updated == 1) {
          writeSucceeded = true;
          _message = 'Updated ID $id. Rows affected: $updated.';
        } else {
          _errorMessage = 'Guest ID $id was not found.';
        }
      }

      if (writeSucceeded) {
        _nameController.clear();
        _ageController.clear();
        _selectedId = null;

        try {
          final rows = await widget.helper.queryAllRows();
          final count = await widget.helper.queryRowCount();

          if (!mounted) return;

          setState(() {
            _rows = rows;
            _count = count;
          });
        } catch (error) {
          debugPrint('Refresh after save failed: $error');
          _errorMessage = 'Saved, but refresh failed. Press Refresh.';
        }
      } else {
        try {
          final rows = await widget.helper.queryAllRows();
          final count = await widget.helper.queryRowCount();

          if (!mounted) return;

          setState(() {
            _rows = rows;
            _count = count;
          });
        } catch (error) {
          debugPrint('Reload failed: $error');
        }
      }
    } catch (error) {
      debugPrint('Save failed: $error');

      if (mounted) {
        _errorMessage = 'Could not save the guest. Try again.';
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  void _startEdit(Map<String, dynamic> row) {
    if (_busy) return;

    setState(() {
      _selectedId = row[DatabaseHelper.columnId] as int;
      _nameController.text = row[DatabaseHelper.columnName].toString();
      _ageController.text = row[DatabaseHelper.columnAge].toString();
      _message = 'Editing ID $_selectedId.';
      _errorMessage = null;
    });
  }

  void _cancelEdit() {
    if (_busy) return;

    setState(() {
      _selectedId = null;
      _nameController.clear();
      _ageController.clear();
      _message = 'Edit canceled.';
      _errorMessage = null;
    });
  }

  Future<void> _deleteGuest(Map<String, dynamic> row) async {
    if (_busy) return;

    final id = row[DatabaseHelper.columnId] as int;
    final name = row[DatabaseHelper.columnName].toString();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete guest?'),
          content: Text('Delete ID $id - $name?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _busy = true;
      _message = null;
      _errorMessage = null;
    });

    try {
      final deleted = await widget.helper.delete(id);

      if (deleted == 1) {
        if (_selectedId == id) {
          _selectedId = null;
          _nameController.clear();
          _ageController.clear();
        }

        _message = 'Deleted ID $id. Rows affected: $deleted.';

        try {
          final rows = await widget.helper.queryAllRows();
          final count = await widget.helper.queryRowCount();

          if (!mounted) return;

          setState(() {
            _rows = rows;
            _count = count;
          });
        } catch (error) {
          debugPrint('Refresh after delete failed: $error');
          _errorMessage = 'Deleted, but refresh failed. Press Refresh.';
        }
      } else {
        _errorMessage = 'Guest ID $id was not found.';

        final rows = await widget.helper.queryAllRows();
        final count = await widget.helper.queryRowCount();

        if (!mounted) return;

        setState(() {
          _rows = rows;
          _count = count;
        });
      }
    } catch (error) {
      debugPrint('Delete failed: $error');

      if (mounted) {
        _errorMessage = 'Could not delete the guest. Try again.';
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    if (_busy) return;

    setState(() {
      _busy = true;
      _message = null;
      _errorMessage = null;
    });

    try {
      final rows = await widget.helper.queryAllRows();
      final count = await widget.helper.queryRowCount();

      if (!mounted) return;

      setState(() {
        _rows = rows;
        _count = count;
        _message = 'Roster refreshed.';
      });
    } catch (error) {
      debugPrint('Refresh failed: $error');

      if (mounted) {
        setState(() {
          _errorMessage = 'Refresh failed. Try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fall Festival Roster'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    enabled: !_busy,
                    decoration: const InputDecoration(
                      labelText: 'Guest Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateName,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _ageController,
                    enabled: !_busy,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Age',
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateAge,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _busy ? null : _saveGuest,
                          child: Text(
                            _selectedId == null ? 'Add Guest' : 'Save Changes',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed:
                            (_selectedId == null || _busy) ? null : _cancelEdit,
                        child: const Text('Cancel Edit'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _busy ? null : _refresh,
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Record Count: $_count',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_message != null) ...[
              const SizedBox(height: 6),
              Text(_message!),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 6),
              Text(_errorMessage!),
            ],
            const Divider(height: 24),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null && _rows.isEmpty
                      ? Center(
                          child: ElevatedButton(
                            onPressed: _busy ? null : _refresh,
                            child: const Text('Retry'),
                          ),
                        )
                      : _rows.isEmpty
                          ? const Center(
                              child: Text('No festival guests yet'),
                            )
                          : ListView.builder(
                              itemCount: _rows.length,
                              itemBuilder: (context, index) {
                                final row = _rows[index];

                                final id =
                                    row[DatabaseHelper.columnId] as int;
                                final name =
                                    row[DatabaseHelper.columnName].toString();
                                final age =
                                    row[DatabaseHelper.columnAge].toString();

                                return Card(
                                  child: ListTile(
                                    title: Text('$name, age $age'),
                                    subtitle: Text('ID: $id'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          onPressed: _busy
                                              ? null
                                              : () => _startEdit(row),
                                          icon: const Icon(Icons.edit),
                                          tooltip: 'Edit',
                                        ),
                                        IconButton(
                                          onPressed: _busy
                                              ? null
                                              : () => _deleteGuest(row),
                                          icon: const Icon(Icons.delete),
                                          tooltip: 'Delete',
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
