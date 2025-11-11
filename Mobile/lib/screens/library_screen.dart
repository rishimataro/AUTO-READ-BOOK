
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<Map<String, dynamic>> _readBooks = [];
  bool _isSelectionMode = false;
  final Set<int> _selectedBooks = <int>{};

  @override
  void initState() {
    super.initState();
    _loadReadBooks();
  }

  Future<void> _loadReadBooks() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final readBooksJson = prefs.getStringList('read_books') ?? [];
    setState(() {
      _readBooks = readBooksJson
          .map((book) => json.decode(book) as Map<String, dynamic>)
          .toList()
          .reversed
          .toList(); // Show latest read books first
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedBooks.clear();
    });
  }

  void _onBookTap(int index) {
    if (_isSelectionMode) {
      setState(() {
        if (_selectedBooks.contains(index)) {
          _selectedBooks.remove(index);
        } else {
          _selectedBooks.add(index);
        }
      });
    } else {
      // Handle normal tap, e.g., open book details
    }
  }

  Future<void> _deleteSelectedBooks() async {
    if (_selectedBooks.isEmpty) return;

    final bool? confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xóa ${_selectedBooks.length} cuốn sách?'),
        content: const Text(
            'Bạn có chắc chắn muốn xóa vĩnh viễn các sách đã chọn không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      final prefs = await SharedPreferences.getInstance();
      final readBooksJson = prefs.getStringList('read_books') ?? [];

      // The display list is reversed, original indices must be calculated
      final originalIndicesToDelete = _selectedBooks
          .map((reversedIndex) => (readBooksJson.length - 1) - reversedIndex)
          .toSet();

      final updatedBooksJson = <String>[];
      for (int i = 0; i < readBooksJson.length; i++) {
        if (!originalIndicesToDelete.contains(i)) {
          updatedBooksJson.add(readBooksJson[i]);
        }
      }

      await prefs.setStringList('read_books', updatedBooksJson);
      await _loadReadBooks(); // Refresh the list

      // Exit selection mode after deleting
      _toggleSelectionMode();
    }
  }

  AppBar _buildAppBar() {
    if (_isSelectionMode) {
      return AppBar(
        backgroundColor: const Color(0xFFF6F6F6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: _toggleSelectionMode,
        ),
        title: Text(
          'Đã chọn: ${_selectedBooks.length}',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: _selectedBooks.isNotEmpty ? Colors.red : Colors.grey,
            ),
            onPressed: _deleteSelectedBooks,
          ),
        ],
      );
    } else {
      return AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Thư viện",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.black),
            onPressed: _toggleSelectionMode,
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {},
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _loadReadBooks,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm sách...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle("Sách đã đọc"),
              const SizedBox(height: 16),
              _buildReadBooksList(),
              const SizedBox(height: 24),
              _buildSectionTitle("Sách yêu thích"),
              const SizedBox(height: 16),
              _buildFavoriteBooksPlaceholder(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildReadBooksList() {
    if (_readBooks.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text(
            "Bạn chưa đọc cuốn sách nào.\nSách bạn đã đọc xong sẽ xuất hiện ở đây.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return SizedBox(
      height: 210,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _readBooks.length,
        itemBuilder: (context, index) {
          final book = _readBooks[index];
          final imagePath = book['imagePath'] as String?;
          final title = book['title'] as String? ?? 'Không có tên';
          final isSelected = _selectedBooks.contains(index);

          return GestureDetector(
            onTap: () => _onBookTap(index),
            child: Container(
              width: 130,
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: imagePath != null && imagePath.isNotEmpty
                            ? Image.file(
                                File(imagePath),
                                width: 130,
                                height: 170,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 130,
                                height: 170,
                                color: Colors.grey[300],
                                child: const Icon(Icons.book, size: 50, color: Colors.grey),
                              ),
                      ),
                      if (_isSelectionMode)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.black.withOpacity(0.5)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check_circle, color: Colors.white, size: 40)
                                : null,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFavoriteBooksPlaceholder() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.0),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: const Center(
        child: Text(
          "Sách bạn yêu thích sẽ xuất hiện ở đây.",
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
