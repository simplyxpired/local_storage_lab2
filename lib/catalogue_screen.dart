
import 'package:flutter/material.dart';
import 'catalogue_repository.dart';
import 'Folder/card_record.dart';

class CatalogueScreen extends StatefulWidget {
  final CatalogueRepository repository;

  const CatalogueScreen({
    super.key,
    required this.repository,
  });

  @override
  State<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends State<CatalogueScreen> {
  List<Map<String, dynamic>> folders = [];
  bool loading = true;
  bool busy = false;
  String? error;
  String? message;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result =
          await widget.repository.getFoldersWithCounts();

      if (!mounted) return;

      setState(() {
        folders = result;
        loading = false;
      });
    } catch (e) {
      debugPrint('Folder read failed: $e');

      if (!mounted) return;

      setState(() {
        error = 'Could not load folders: $e';
        loading = false;
      });
    }
  }

  void notify(String text) {
    if (!mounted) return;

    setState(() => message = text);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> addFolder() async {
    if (busy) return;

    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Folder name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(ctx, controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    // Wait until the dialog finishes closing.
    await Future<void>.delayed(
      const Duration(milliseconds: 200),
    );
    controller.dispose();

    if (!mounted || name == null) return;

    if (name.trim().isEmpty) {
      notify('Folder name cannot be blank.');
      return;
    }

    setState(() => busy = true);

    int? insertedId;

    try {
      insertedId = await widget.repository.addFolder(name);
    } catch (e) {
      debugPrint('Folder insert failed: $e');
      notify('Could not add folder. Check the name.');
    }

    if (!mounted) return;

    if (insertedId != null) {
      notify('Folder created. ID: $insertedId');
      await load();
    }

    if (mounted) {
      setState(() => busy = false);
    }
  }

  Future<void> deleteFolder(
    Map<String, dynamic> folder,
  ) async {
    if (busy) return;

    final id = folder['id'] as int;
    final name = folder['name'] as String;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete folder?'),
        content: Text(
          'Delete "$name" (ID $id) and all its cards?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => busy = true);

    try {
      final count =
          await widget.repository.deleteFolder(id);

      if (!mounted) return;

      notify('Folder delete affected $count row(s).');
      await load();
    } catch (e) {
      debugPrint('Folder delete failed: $e');
      notify('Could not delete folder.');
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Catalogue'),
        actions: [
          IconButton(
            onPressed: busy ? null : load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: busy ? null : addFolder,
        icon: const Icon(Icons.create_new_folder),
        label: const Text('Add Folder'),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(error!),
                      ElevatedButton(
                        onPressed: load,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : folders.isEmpty
                  ? const Center(
                      child: Text(
                        'No folders yet. Tap Add Folder.',
                      ),
                    )
                  : ListView(
                      children: [
                        if (message != null)
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(message!),
                          ),
                        ...folders.map(
                          (folder) => Card(
                            child: ListTile(
                              title: Text(
                                folder['name'] as String,
                              ),
                              subtitle: Text(
                                'ID: ${folder['id']} | Cards: ${folder['card_count']}',
                              ),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        FolderCardsScreen(
                                      repository:
                                          widget.repository,
                                      folderId:
                                          folder['id'] as int,
                                      folderName:
                                          folder['name'] as String,
                                    ),
                                  ),
                                );

                                if (mounted) await load();
                              },
                              trailing: IconButton(
                                onPressed: busy
                                    ? null
                                    : () => deleteFolder(folder),
                                icon: const Icon(Icons.delete),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 90),
                      ],
                    ),
    );
  }
}

class FolderCardsScreen extends StatefulWidget {
  final CatalogueRepository repository;
  final int folderId;
  final String folderName;

  const FolderCardsScreen({
    super.key,
    required this.repository,
    required this.folderId,
    required this.folderName,
  });

  @override
  State<FolderCardsScreen> createState() =>
      _FolderCardsScreenState();
}

class _FolderCardsScreenState
    extends State<FolderCardsScreen> {
  List<CardRecord> cards = [];
  bool loading = true;
  bool busy = false;
  String? error;
  String? message;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result =
          await widget.repository.getCards(widget.folderId);

      if (!mounted) return;

      setState(() {
        cards = result;
        loading = false;
      });
    } catch (e) {
      debugPrint('Card read failed: $e');

      if (!mounted) return;

      setState(() {
        error = 'Could not load cards: $e';
        loading = false;
      });
    }
  }

  void notify(String text) {
    if (!mounted) return;

    setState(() => message = text);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> editCard([CardRecord? old]) async {
    if (busy) return;

    final title = TextEditingController(
      text: old?.title ?? '',
    );

    final notes = TextEditingController(
      text: old?.notes ?? '',
    );

    final image = TextEditingController(
      text: old?.imageRef ?? '',
    );

    String suit = old?.suit ?? 'Hearts';

    final input = await showDialog<CardRecord>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, updateDialog) => AlertDialog(
          title: Text(
            old == null
                ? 'Add card'
                : 'Edit card ID ${old.id}',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                  ),
                ),
                DropdownButtonFormField<String>(
                  initialValue: suit,
                  decoration: const InputDecoration(
                    labelText: 'Suit',
                  ),
                  items: [
                    'Hearts',
                    'Diamonds',
                    'Clubs',
                    'Spades',
                  ].map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text(s),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      updateDialog(() => suit = value);
                    }
                  },
                ),
                TextField(
                  controller: notes,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                  ),
                ),
                TextField(
                  controller: image,
                  decoration: const InputDecoration(
                    labelText:
                        'Image reference (optional)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (title.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Title cannot be blank.',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.pop(
                  ctx,
                  CardRecord(
                    id: old?.id,
                    title: title.text.trim(),
                    suit: suit,
                    folderId: widget.folderId,
                    notes: notes.text,
                    imageRef: image.text.trim().isEmpty
                        ? null
                        : image.text.trim(),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    await Future<void>.delayed(
      const Duration(milliseconds: 200),
    );

    title.dispose();
    notes.dispose();
    image.dispose();

    if (input == null || !mounted) return;

    setState(() => busy = true);

    try {
      final result = old == null
          ? await widget.repository.addCard(input)
          : await widget.repository.updateCard(input);

      if (!mounted) return;

      notify(
        old == null
            ? 'Card created with ID $result'
            : 'Update affected $result row(s)',
      );

      await load();
    } catch (e) {
      debugPrint('Card save failed: $e');
      notify('Could not save card: $e');
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> deleteCard(CardRecord card) async {
    if (busy) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete card?'),
        content: Text(
          'Delete "${card.title}" (ID ${card.id})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => busy = true);

    try {
      final count =
          await widget.repository.deleteCard(card.id!);

      if (!mounted) return;

      notify('Card delete affected $count row(s).');
      await load();
    } catch (e) {
      debugPrint('Card delete failed: $e');
      notify('Could not delete card.');
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  String suitSymbol(String suit) {
    switch (suit) {
      case 'Hearts':
        return '♥';
      case 'Diamonds':
        return '♦';
      case 'Clubs':
        return '♣';
      default:
        return '♠';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folderName),
        actions: [
          IconButton(
            onPressed: busy ? null : load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: busy ? null : () => editCard(),
        icon: const Icon(Icons.add),
        label: const Text('Add Card'),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(error!),
                      ElevatedButton(
                        onPressed: load,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : cards.isEmpty
                  ? const Center(
                      child: Text(
                        'This folder is empty. Tap Add Card.',
                      ),
                    )
                  : ListView(
                      children: [
                        if (message != null)
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(message!),
                          ),
                        ...cards.map(
                          (card) => Card(
                            child: ListTile(
                              leading: Text(
                                suitSymbol(card.suit),
                                style: const TextStyle(
                                  fontSize: 32,
                                ),
                              ),
                              title: Text(card.title),
                              subtitle: Text(
                                'ID: ${card.id} | ${card.suit}\n'
                                '${card.notes}'
                                '${card.imageRef == null ? '' : '\nImage ref: ${card.imageRef}'}',
                              ),
                              isThreeLine: true,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: busy
                                        ? null
                                        : () => editCard(card),
                                    icon: const Icon(Icons.edit),
                                  ),
                                  IconButton(
                                    onPressed: busy
                                        ? null
                                        : () => deleteCard(card),
                                    icon: const Icon(Icons.delete),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 90),
                      ],
                    ),
    );
  }
}
