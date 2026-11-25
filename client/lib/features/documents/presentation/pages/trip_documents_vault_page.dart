import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/models/travel_document.dart';
import '../providers/travel_document_provider.dart';
import '../widgets/add_travel_document_sheet.dart';

class TripDocumentsVaultPage extends ConsumerWidget {
  const TripDocumentsVaultPage({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final docsAsync = ref.watch(tripDocumentsProvider(tripId));

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Travel Documents Vault'),
        actions: [
          IconButton(
            tooltip: 'Add Document',
            onPressed: () => AddTravelDocumentSheet.show(context, tripId),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddTravelDocumentSheet.show(context, tripId),
        icon: const Icon(Icons.add_moderator_outlined),
        label: const Text('Add Document'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.enhanced_encryption_outlined,
                  size: 20,
                  color: colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Encrypted at rest • Owner-only by default • Reference numbers are never shared with other Circle members.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: docsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Unable to load travel documents: $err'),
                ),
              ),
              data: (docs) {
                if (docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.folder_special_outlined,
                            size: 48,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No travel documents saved yet',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Store encrypted visa references, travel insurance policy numbers, and voucher notes for offline access.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    return _TravelDocumentCard(
                      tripId: tripId,
                      document: doc,
                      onEdit: () => AddTravelDocumentSheet.show(
                        context,
                        tripId,
                        existingDocument: doc,
                      ),
                      onDelete: () async {
                        await ref
                            .read(travelDocumentRepositoryProvider)
                            .deleteDocument(tripId, doc.id);
                        ref.invalidate(tripDocumentsProvider(tripId));
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TravelDocumentCard extends StatelessWidget {
  const _TravelDocumentCard({
    required this.tripId,
    required this.document,
    required this.onEdit,
    required this.onDelete,
  });

  final String tripId;
  final TravelDocument document;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(
                          document.typeLabel,
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                      Chip(
                        visualDensity: VisualDensity.compact,
                        avatar: Icon(
                          document.isSharedWithCircle
                              ? Icons.group_outlined
                              : Icons.lock_outline_rounded,
                          size: 14,
                        ),
                        label: Text(
                          document.isSharedWithCircle
                              ? 'Shared with Circle'
                              : 'Private (Only You)',
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                    ],
                  ),
                ),
                if (document.isOwner) ...[
                  IconButton(
                    tooltip: 'Edit document',
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                  ),
                  IconButton(
                    tooltip: 'Delete document',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              document.displayName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (document.issuer != null && document.issuer!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'Issuer: ${document.issuer}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (document.hasAttachment) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.attach_file_rounded,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        document.originalFilename ??
                            'Encrypted file attached (Owner only)',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (document.downloadUrl != null &&
                        document.downloadUrl!.isNotEmpty)
                      TextButton(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: () async {
                          final uri = Uri.tryParse(document.downloadUrl!);
                          if (uri != null) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        child: const Text('View File'),
                      ),
                  ],
                ),
              ),
            ],
            if (document.referenceNumber != null &&
                document.referenceNumber!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.vpn_key_outlined,
                    size: 14,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Ref: ${document.referenceNumber}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Copy reference number',
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: document.referenceNumber!),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Copied reference number'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                  ),
                ],
              ),
            ],
            if (document.expiresOn != null &&
                document.expiresOn!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                document.isExpired
                    ? 'Expired on ${document.expiresOn}'
                    : 'Expires on ${document.expiresOn}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: document.isExpired
                      ? colorScheme.error
                      : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (document.notesPrivate != null &&
                document.notesPrivate!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(document.notesPrivate!, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
