import 'package:flutter/material.dart';
import '../models/folder.dart';
import '../repositories/folder_repository.dart';
import '../repositories/card_repository.dart';
import 'cards_screen.dart';

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({Key? key}) : super(key: key);

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  final FolderRepository _folderRepository = FolderRepository();
  final CardRepository _cardRepository = CardRepository();

  List<Folder> _folders = [];
  Map<int, int> _cardCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    setState(() => _isLoading = true);
    try {
      final folders = await _folderRepository.getAllFolders();
      final Map<int, int> counts = {};
      for (final folder in folders) {
        counts[folder.id!] =
            await _cardRepository.getCardCountByFolder(folder.id!);
      }
      setState(() {
        _folders = folders;
        _cardCounts = counts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error loading folders: $e', isError: true);
    }
  }

  Future<void> _deleteFolder(Folder folder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder?'),
        content: Text(
          'Are you sure you want to delete "${folder.folderName}"? '
          'This will also permanently delete all ${_cardCounts[folder.id!] ?? 0} '
          'cards inside it. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _folderRepository.deleteFolder(folder.id!);
        _loadFolders();
        _showSnackBar('Folder "${folder.folderName}" deleted');
      } catch (e) {
        _showSnackBar('Failed to delete folder: $e', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Organizer'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _folders.isEmpty
              ? const Center(child: Text('No folders found.'))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: _folders.length,
                  itemBuilder: (context, index) {
                    final folder = _folders[index];
                    final cardCount = _cardCounts[folder.id!] ?? 0;
                    return _FolderCard(
                      folder: folder,
                      cardCount: cardCount,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CardsScreen(folder: folder),
                          ),
                        );
                        _loadFolders();
                      },
                      onDelete: () => _deleteFolder(folder),
                    );
                  },
                ),
    );
  }
}

class _FolderCard extends StatelessWidget {
  final Folder folder;
  final int cardCount;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _FolderCard({
    required this.folder,
    required this.cardCount,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getSuitIcon(folder.folderName),
                size: 52,
                color: _getSuitColor(folder.folderName),
              ),
              const SizedBox(height: 6),
              Text(
                folder.folderName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$cardCount cards',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 36,
                width: 36,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.delete, color: Colors.red, size: 22),
                  onPressed: onDelete,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getSuitIcon(String name) {
    switch (name) {
      case 'Hearts':
        return Icons.favorite;
      case 'Diamonds':
        return Icons.change_history;
      case 'Clubs':
        return Icons.filter_vintage;
      case 'Spades':
        return Icons.eco;
      default:
        return Icons.help;
    }
  }

  Color _getSuitColor(String name) {
    return (name == 'Hearts' || name == 'Diamonds') ? Colors.red : Colors.black;
  }
}