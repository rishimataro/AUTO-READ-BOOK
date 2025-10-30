
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

  Future<void> _deleteBook(int index) async {
    final bool? confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa sách?'),
        content: const Text(
            'Bạn có chắc chắn muốn xóa cuốn sách này khỏi danh sách đã đọc không?'),
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
      // The list is reversed for display, so we calculate the correct index for the original list.
      final originalIndex = (_readBooks.length - 1) - index;

      final prefs = await SharedPreferences.getInstance();
      final readBooksJson = prefs.getStringList('read_books') ?? [];

      if (originalIndex >= 0 && originalIndex < readBooksJson.length) {
        readBooksJson.removeAt(originalIndex);
        await prefs.setStringList('read_books', readBooksJson);
        // Reload books to reflect the change.
        await _loadReadBooks();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
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
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadReadBooks,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Search Bar
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
              // Read Books Section
              _buildSectionTitle("Sách đã đọc"),
              const SizedBox(height: 16),
              _buildReadBooksList(),
              const SizedBox(height: 24),
              // Favorite Books Section
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
      height: 230, // Increased height to fit delete button
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _readBooks.length,
        itemBuilder: (context, index) {
          final book = _readBooks[index];
          final imagePath = book['imagePath'] as String?;
          final title = book['title'] as String? ?? 'Không có tên';

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 130,
                margin: const EdgeInsets.only(right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                              child: const Icon(Icons.book,
                                  size: 50, color: Colors.grey),
                            ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Positioned(
                top: -8,
                right: 8,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 2.0,
                  child: InkWell(
                    onTap: () => _deleteBook(index),
                    customBorder: const CircleBorder(),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: const Icon(
                        Icons.close,
                        color: Colors.red,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              )
            ],
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
