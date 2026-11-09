import 'package:flutter/material.dart';

import '../../domain/models/journal_entry.dart';

class AddJournalEntrySheet extends StatefulWidget {
  const AddJournalEntrySheet({
    super.key,
    required this.tripId,
    this.existingEntry,
    required this.onSave,
  });

  final String tripId;
  final JournalEntry? existingEntry;
  final Future<void> Function({
    required String title,
    required String content,
    required String entryDate,
    String? locationName,
    String? weather,
    String? mood,
    required bool isShared,
    List<String>? photos,
  })
  onSave;

  @override
  State<AddJournalEntrySheet> createState() => _AddJournalEntrySheetState();
}

class _AddJournalEntrySheetState extends State<AddJournalEntrySheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _locationController;
  late final TextEditingController _photoUrlController;
  late String _entryDate;
  String? _selectedMood;
  String? _selectedWeather;
  bool _isShared = false;
  late List<String> _photos;
  bool _isSaving = false;

  final List<({String key, String label, String emoji})> _moodOptions = const [
    (key: 'amazed', label: 'Amazed', emoji: '🤩'),
    (key: 'happy', label: 'Happy', emoji: '😊'),
    (key: 'peaceful', label: 'Peaceful', emoji: '😌'),
    (key: 'excited', label: 'Excited', emoji: '🎉'),
    (key: 'tired', label: 'Tired', emoji: '😴'),
    (key: 'grateful', label: 'Grateful', emoji: '🙏'),
    (key: 'adventurous', label: 'Adventurous', emoji: '🏔️'),
  ];

  final List<({String key, String label, IconData icon})> _weatherOptions =
      const [
        (key: 'sunny', label: 'Sunny', icon: Icons.wb_sunny_rounded),
        (key: 'cloudy', label: 'Cloudy', icon: Icons.wb_cloudy_rounded),
        (key: 'rainy', label: 'Rainy', icon: Icons.grain_rounded),
        (key: 'snowy', label: 'Snowy', icon: Icons.ac_unit_rounded),
        (key: 'windy', label: 'Windy', icon: Icons.air_rounded),
      ];

  @override
  void initState() {
    super.initState();
    final entry = widget.existingEntry;
    _titleController = TextEditingController(text: entry?.title ?? '');
    _contentController = TextEditingController(text: entry?.content ?? '');
    _locationController = TextEditingController(
      text: entry?.locationName ?? '',
    );
    _photoUrlController = TextEditingController();
    _entryDate =
        entry?.entryDate ?? DateTime.now().toIso8601String().substring(0, 10);
    _selectedMood = entry?.mood;
    _selectedWeather = entry?.weather;
    _isShared = entry?.isShared ?? false;
    _photos = List<String>.from(entry?.photos ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _locationController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final currentParsed = DateTime.tryParse(_entryDate) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: currentParsed,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _entryDate = picked.toIso8601String().substring(0, 10);
      });
    }
  }

  void _addPhotoUrl() {
    final url = _photoUrlController.text.trim();
    if (url.isNotEmpty && !_photos.contains(url)) {
      setState(() {
        _photos.add(url);
        _photoUrlController.clear();
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await widget.onSave(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        entryDate: _entryDate,
        locationName: _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
        weather: _selectedWeather,
        mood: _selectedMood,
        isShared: _isShared,
        photos: _photos,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save journal reflection: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEditing = widget.existingEntry != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? 'Edit Reflection' : 'New Travel Reflection',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Form content
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Title
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Reflection Title *',
                            hintText: 'e.g. Sunset over Senso-ji temple',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.bookmark_border_rounded),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter a title';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Date & Location Row
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: _pickDate,
                                borderRadius: BorderRadius.circular(8),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Date *',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(
                                      Icons.calendar_today_outlined,
                                      size: 18,
                                    ),
                                  ),
                                  child: Text(_entryDate),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _locationController,
                                decoration: const InputDecoration(
                                  labelText: 'Location',
                                  hintText: 'e.g. Tokyo',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(
                                    Icons.location_on_outlined,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Mood selector
                        Text(
                          'How did this moment feel?',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _moodOptions.map((opt) {
                              final isSelected = _selectedMood == opt.key;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  avatar: Text(opt.emoji),
                                  label: Text(opt.label),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedMood = selected ? opt.key : null;
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Weather selector
                        Text(
                          'Weather',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _weatherOptions.map((opt) {
                              final isSelected = _selectedWeather == opt.key;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  avatar: Icon(
                                    opt.icon,
                                    size: 16,
                                    color: isSelected
                                        ? colorScheme.onPrimary
                                        : Colors.orange,
                                  ),
                                  label: Text(opt.label),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedWeather = selected
                                          ? opt.key
                                          : null;
                                    });
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Content (Reflection notes)
                        TextFormField(
                          controller: _contentController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Reflection Notes *',
                            hintText:
                                'Capture what you saw, felt, or discovered...',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please write a reflection note';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Privacy sharing toggle (TC-8.1: Default private!)
                        Card(
                          color: _isShared
                              ? Colors.teal.withValues(alpha: 0.08)
                              : colorScheme.surfaceContainerHighest,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: _isShared
                                  ? Colors.teal.withValues(alpha: 0.4)
                                  : Colors.transparent,
                            ),
                          ),
                          child: SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            title: Row(
                              children: [
                                Icon(
                                  _isShared
                                      ? Icons.group_rounded
                                      : Icons.lock_outline_rounded,
                                  color: _isShared
                                      ? Colors.teal
                                      : Colors.amber.shade800,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isShared
                                      ? 'Share with Circle'
                                      : 'Keep Private (Only You)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: _isShared
                                        ? Colors.teal
                                        : colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              _isShared
                                  ? 'Companions in this trip circle can see this memory in their journal feed.'
                                  : 'Only you can view and edit this memory. (Default private)',
                              style: theme.textTheme.bodySmall,
                            ),
                            value: _isShared,
                            onChanged: (val) {
                              setState(() => _isShared = val);
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Photos section
                        Text(
                          'Photos & Memories',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _photoUrlController,
                                decoration: const InputDecoration(
                                  hintText: 'Add photo URL or path',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                onSubmitted: (_) => _addPhotoUrl(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: _addPhotoUrl,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add'),
                            ),
                          ],
                        ),

                        if (_photos.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 70,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _photos.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final photo = _photos[index];
                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        width: 70,
                                        height: 70,
                                        color:
                                            colorScheme.surfaceContainerHighest,
                                        child: Image.network(
                                          photo,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) =>
                                              const Icon(Icons.image_outlined),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            _photos.removeAt(index);
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                            color: Colors.black87,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Submit Button
                        FilledButton.icon(
                          onPressed: _isSaving ? null : _handleSave,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_rounded),
                          label: Text(
                            isEditing
                                ? 'Save Reflection'
                                : 'Save Travel Memory',
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
