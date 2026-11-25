import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../data/translation_repository.dart';
import '../../domain/models/translation_models.dart';
import '../providers/translation_provider.dart';

class TranslatorPhrasebookPage extends ConsumerStatefulWidget {
  const TranslatorPhrasebookPage({
    super.key,
    this.tripId,
    this.initialLanguageOrCountry,
  });

  final String? tripId;
  final String? initialLanguageOrCountry;

  @override
  ConsumerState<TranslatorPhrasebookPage> createState() =>
      _TranslatorPhrasebookPageState();
}

class _TranslatorPhrasebookPageState
    extends ConsumerState<TranslatorPhrasebookPage> {
  late String _selectedLanguage;
  String _selectedCategory = 'all';
  final TextEditingController _translateController = TextEditingController();
  bool _consentCloud = false;
  bool _isTranslating = false;
  TranslationResult? _translationResult;
  String? _translationError;

  @override
  void initState() {
    super.initState();
    final init = widget.initialLanguageOrCountry?.trim();
    _selectedLanguage = (init != null && init.isNotEmpty)
        ? TranslationRepository.resolveOfflinePhrasebook(init).languageCode
        : 'ja';
  }

  @override
  void dispose() {
    _translateController.dispose();
    super.dispose();
  }

  Future<void> _runTranslate() async {
    final text = _translateController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isTranslating = true;
      _translationError = null;
    });

    try {
      final repo = ref.read(translationRepositoryProvider);
      final result = await repo.translateText(
        text: text,
        targetLanguage: _selectedLanguage,
        consentCloud: _consentCloud,
      );
      if (mounted) {
        setState(() {
          _translationResult = result;
          _isTranslating = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _translationError = e.message;
          _translationResult = null;
          _isTranslating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _translationError = e.toString();
          _translationResult = null;
          _isTranslating = false;
        });
      }
    }
  }

  void _showLargePhraseCard(
    BuildContext context, {
    required String english,
    required String localText,
    required String phonetic,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                english,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              SelectableText(
                localText,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                phonetic,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final request = PhrasebookLookupRequest(
      tripId: widget.tripId,
      languageOrCountry: _selectedLanguage,
    );
    final bundleAsync = ref.watch(phrasebookBundleProvider(request));
    final packs = TranslationRepository.bundledOfflinePhrasebooks;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(title: const Text('Translator & Phrasebook')),
      body: Column(
        children: [
          // Destination language selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                for (final pack in packs) ...[
                  ChoiceChip(
                    label: Text('${pack.flagEmoji} ${pack.languageName}'),
                    selected: _selectedLanguage == pack.languageCode,
                    onSelected: (_) {
                      setState(() {
                        _selectedLanguage = pack.languageCode;
                        _translationResult = null;
                        _translationError = null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: bundleAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Unable to load phrasebook: $err'),
                ),
              ),
              data: (bundle) {
                final filteredPhrases = _selectedCategory == 'all'
                    ? bundle.phrases
                    : bundle.phrases
                          .where((p) => p.category == _selectedCategory)
                          .toList();

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    // Quick Translator Card
                    Card(
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      color: colorScheme.surfaceContainerLowest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: colorScheme.outlineVariant,
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Translate to ${bundle.languageName} (${bundle.nativeName})',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _translateController,
                              decoration: InputDecoration(
                                hintText: 'Type an English phrase (e.g. I have a food allergy)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                isDense: true,
                              ),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'Allow cloud translation when not in offline pack',
                                style: theme.textTheme.bodySmall,
                              ),
                              value: _consentCloud,
                              onChanged: (value) {
                                setState(() {
                                  _consentCloud = value;
                                });
                              },
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton.icon(
                                onPressed: _isTranslating
                                    ? null
                                    : _runTranslate,
                                icon: const Icon(
                                  Icons.translate_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  _isTranslating
                                      ? 'Translating...'
                                      : 'Translate',
                                ),
                              ),
                            ),
                            if (_translationError != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _translationError!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.error,
                                ),
                              ),
                            ],
                            if (_translationResult != null) ...[
                              const Divider(height: 20),
                              Wrap(
                                spacing: 8,
                                children: [
                                  Chip(
                                    visualDensity: VisualDensity.compact,
                                    label: Text(
                                      _translationResult!.isOfflineMatch
                                          ? 'Offline Phrasebook Match'
                                          : 'Cloud Translation (${_translationResult!.provider})',
                                      style: theme.textTheme.labelSmall,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              SelectableText(
                                _translationResult!.translatedText,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _translationResult!.phonetic,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Category filter chips
                    Text(
                      'Offline Phrasebook (${bundle.languageName})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final cat in ['all', ...bundle.categories]) ...[
                            FilterChip(
                              label: Text(
                                cat[0].toUpperCase() + cat.substring(1),
                              ),
                              selected: _selectedCategory == cat,
                              onSelected: (_) {
                                setState(() {
                                  _selectedCategory = cat;
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Phrase cards
                    for (final entry in filteredPhrases)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: colorScheme.outlineVariant,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    entry.english,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Show large card',
                                  onPressed: () => _showLargePhraseCard(
                                    context,
                                    english: entry.english,
                                    localText: entry.localText,
                                    phonetic: entry.phonetic,
                                  ),
                                  icon: const Icon(
                                    Icons.fullscreen_rounded,
                                    size: 20,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Copy phrase',
                                  onPressed: () async {
                                    await Clipboard.setData(
                                      ClipboardData(text: entry.localText),
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Copied: ${entry.localText}',
                                              ),
                                            ),
                                          );
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.copy_rounded,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              entry.localText,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              entry.phonetic,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (entry.contextNote != null &&
                                entry.contextNote!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                entry.contextNote!,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                    const SizedBox(height: 8),
                    Text(
                      bundle.disclaimer,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
