
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'edit_book_screen.dart';
import 'read_book_screen.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  String _title = "Tên của sách";
  String _author = "Tác giả";
  String _category = "Thể loại";
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _loadBookData();
  }

  Future<void> _loadBookData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _title = prefs.getString('book_title') ?? "Tên của sách";
      _author = prefs.getString('book_author') ?? "Tác giả";
      _category = prefs.getString('book_category') ?? "Thể loại";
      _imagePath = prefs.getString('book_imagePath');
    });
  }

  Future<void> _saveBookData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('book_title', _title);
    await prefs.setString('book_author', _author);
    await prefs.setString('book_category', _category);
    if (_imagePath != null) {
      await prefs.setString('book_imagePath', _imagePath!);
    } else {
      await prefs.remove('book_imagePath');
    }
  }

  Future<void> _addBookToLibraryAndReset() async {
    // Don't save the default placeholder book
    if (_title == "Tên của sách" && _author == "Tác giả") {
      await _resetBookData();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final List<String> readBooksJson = prefs.getStringList('read_books') ?? [];

    final bookData = {
      'title': _title,
      'author': _author,
      'imagePath': _imagePath,
    };

    readBooksJson.add(json.encode(bookData));
    await prefs.setStringList('read_books', readBooksJson);

    await _resetBookData();
  }

  Future<void> _resetBookData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('book_title');
    await prefs.remove('book_author');
    await prefs.remove('book_category');
    await prefs.remove('book_imagePath');

    if (!mounted) return;
    setState(() {
      _title = "Tên của sách";
      _author = "Tác giả";
      _category = "Thể loại";
      _imagePath = null;
    });
  }

    Future<void> _showClearDataConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Bạn có chắc chắn muốn xóa toàn bộ thông tin sách hiện tại?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Xóa'),
              onPressed: () {
                _resetBookData();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _navigateToEditScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditBookScreen()),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _title = result['title'] ?? _title;
        _author = result['author'] ?? _author;
        _category = result['category'] ?? _category;
        _imagePath = result['imagePath'];
      });
      await _saveBookData();
    }
  }

  Future<void> _navigateToReadScreen() async {
    final bool? hasFinishedReading = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReadBookScreen(
          title: _title,
          author: _author,
        ),
      ),
    );

    if (hasFinishedReading == true) {
      await _addBookToLibraryAndReset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenSize.height * 0.3,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF426A80),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
              onPressed: _showClearDataConfirmationDialog,
            ),
          ),
          const Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Text(
              "Thêm mới",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned.fill(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    SizedBox(height: screenSize.height * 0.15),
                    Container(
                      width: 160,
                      height: 220,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        image: _imagePath != null
                            ? DecorationImage(
                                image: FileImage(File(_imagePath!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _imagePath == null
                          ? Center(
                              child: Icon(Icons.add, size: 60, color: const Color(0xFF426A80).withOpacity(0.7)),
                            )
                          : null,
                    ),
                    const SizedBox(height: 30),
                    Text(
                      _title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _author,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _category,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _navigateToEditScreen,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF9C7350),
                        side: const BorderSide(color: Color(0xFF9C7350), width: 1.5),
                        padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        "Chỉnh sửa",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _navigateToReadScreen, // Updated onPressed
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF426A80),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        "Đọc sách",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
