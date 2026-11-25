import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/travel_document.dart';
import '../providers/travel_document_provider.dart';

class AddTravelDocumentSheet extends ConsumerStatefulWidget {
  const AddTravelDocumentSheet({
    super.key,
    required this.tripId,
    this.existingDocument,
  });

  final String tripId;
  final TravelDocument? existingDocument;

  static Future<void> show(
    BuildContext context,
    String tripId, {
    TravelDocument? existingDocument,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddTravelDocumentSheet(
        tripId: tripId,
        existingDocument: existingDocument,
      ),
    );
  }

  @override
  ConsumerState<AddTravelDocumentSheet> createState() =>
      _AddTravelDocumentSheetState();
}

class _AddTravelDocumentSheetState
    extends ConsumerState<AddTravelDocumentSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _documentType;
  late String _accessPolicy;
  late final TextEditingController _displayNameController;
  late final TextEditingController _issuerController;
  late final TextEditingController _referenceController;
  late final TextEditingController _expiresController;
  late final TextEditingController _notesController;
  bool _isSaving = false;
  String? _errorMessage;

  static const Map<String, String> _typeOptions = {
    'passport_note': 'Passport Note',
    'visa_reference': 'Visa Reference',
    'travel_insurance': 'Travel Insurance',
    'ticket_voucher': 'Ticket / Voucher',
    'health_certificate': 'Health Certificate',
    'other': 'Other Document',
  };

  @override
  void initState() {
    super.initState();
    final doc = widget.existingDocument;
    _documentType = doc?.documentType ?? 'passport_note';
    _accessPolicy = doc?.accessPolicy ?? 'owner_only';
    _displayNameController = TextEditingController(
      text: doc?.displayName ?? '',
    );
    _issuerController = TextEditingController(text: doc?.issuer ?? '');
    _referenceController = TextEditingController(
      text: doc?.referenceNumber ?? '',
    );
    _expiresController = TextEditingController(text: doc?.expiresOn ?? '');
    _notesController = TextEditingController(text: doc?.notesPrivate ?? '');
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _issuerController.dispose();
    _referenceController.dispose();
    _expiresController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(travelDocumentRepositoryProvider);
      final existing = widget.existingDocument;
      if (existing == null) {
        await repo.createDocument(
          widget.tripId,
          documentType: _documentType,
          displayName: _displayNameController.text.trim(),
          issuer: _issuerController.text.trim(),
          referenceNumber: _referenceController.text.trim(),
          notesPrivate: _notesController.text.trim(),
          expiresOn: _expiresController.text.trim(),
          accessPolicy: _accessPolicy,
        );
      } else {
        await repo.updateDocument(
          widget.tripId,
          existing.id,
          baseVersion: existing.version,
          documentType: _documentType,
          displayName: _displayNameController.text.trim(),
          issuer: _issuerController.text.trim(),
          referenceNumber: _referenceController.text.trim(),
          notesPrivate: _notesController.text.trim(),
          expiresOn: _expiresController.text.trim(),
          accessPolicy: _accessPolicy,
        );
      }
      ref.invalidate(tripDocumentsProvider(widget.tripId));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.existingDocument != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'Edit Travel Document' : 'Add Travel Document',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Reference numbers and notes are encrypted at rest. Never store full passport images.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _documentType,
                decoration: const InputDecoration(
                  labelText: 'Document Type',
                  border: OutlineInputBorder(),
                ),
                items: _typeOptions.entries
                    .map(
                      (e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _documentType = v);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Document Title *',
                  hintText: 'e.g. Travel Insurance Policy',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Enter a document title'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _issuerController,
                decoration: const InputDecoration(
                  labelText: 'Issuer / Provider (optional)',
                  hintText: 'e.g. Pacific Cross / Embassy of Japan',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _referenceController,
                decoration: const InputDecoration(
                  labelText:
                      'Reference / Policy Number (encrypted, owner-only)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _expiresController,
                decoration: const InputDecoration(
                  labelText: 'Expiry Date YYYY-MM-DD (optional)',
                  hintText: '2028-06-30',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Encrypted Notes / Emergency Claim Hotline',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Share summary with Trip Circle members'),
                subtitle: const Text(
                  'Reference number stays private to you even when shared.',
                ),
                value: _accessPolicy == 'circle_members',
                onChanged: (val) {
                  setState(() {
                    _accessPolicy = val ? 'circle_members' : 'owner_only';
                  });
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: Text(_isSaving ? 'Saving...' : 'Save Document'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
