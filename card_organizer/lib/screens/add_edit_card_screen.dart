import 'package:flutter/material.dart';
import '../models/folder.dart';
import '../models/playing_card.dart';
import '../repositories/card_repository.dart';

class AddEditCardScreen extends StatefulWidget {
  final Folder folder;
  final PlayingCard? existingCard;

  const AddEditCardScreen({
    Key? key,
    required this.folder,
    this.existingCard,
  }) : super(key: key);

  @override
  State<AddEditCardScreen> createState() => _AddEditCardScreenState();
}

class _AddEditCardScreenState extends State<AddEditCardScreen> {
  final CardRepository _cardRepository = CardRepository();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _cardNameController;
  late TextEditingController _imageUrlController;

  final List<String> _suits = ['Hearts', 'Diamonds', 'Clubs', 'Spades'];
  String _selectedSuit = 'Hearts';
  bool _isSaving = false;

  bool get _isEditing => widget.existingCard != null;

  @override
  void initState() {
    super.initState();
    _cardNameController = TextEditingController(
      text: _isEditing ? widget.existingCard!.cardName : '',
    );
    _imageUrlController = TextEditingController(
      text: _isEditing ? (widget.existingCard!.imageUrl ?? '') : '',
    );
    if (_isEditing) {
      _selectedSuit = widget.existingCard!.suit;
    } else {
      _selectedSuit = widget.folder.folderName;
    }
  }

  @override
  void dispose() {
    _cardNameController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveCard() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final imageUrl = _imageUrlController.text.trim().isEmpty
          ? null
          : _imageUrlController.text.trim();

      if (_isEditing) {
        final updated = widget.existingCard!.copyWith(
          cardName: _cardNameController.text.trim(),
          suit: _selectedSuit,
          imageUrl: imageUrl,
        );
        await _cardRepository.updateCard(updated);
      } else {
        final newCard = PlayingCard(
          cardName: _cardNameController.text.trim(),
          suit: _selectedSuit,
          imageUrl: imageUrl,
          folderId: widget.folder.id!,
        );
        await _cardRepository.insertCard(newCard);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save card: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Card' : 'Add Card'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Card name field
              TextFormField(
                controller: _cardNameController,
                decoration: const InputDecoration(
                  labelText: 'Card Name',
                  hintText: 'e.g. Ace, King, 7',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Card name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Suit dropdown
              DropdownButtonFormField<String>(
                value: _selectedSuit,
                decoration: const InputDecoration(
                  labelText: 'Suit',
                  border: OutlineInputBorder(),
                ),
                items: _suits
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedSuit = value);
                },
              ),
              const SizedBox(height: 16),

              // Image URL field
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Image URL or Asset Path (optional)',
                  hintText: 'assets/cards/hearts_Ace.png or https://...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),

              // Save button
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveCard,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_isEditing ? 'Update Card' : 'Add Card'),
                ),
              ),
              const SizedBox(height: 12),

              // Cancel button
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}