
import 'package:flutter/material.dart';

class ReadBookScreen extends StatefulWidget {
  final String title;
  final String author;

  const ReadBookScreen({
    super.key,
    required this.title,
    required this.author,
  });

  @override
  State<ReadBookScreen> createState() => _ReadBookScreenState();
}

class _ReadBookScreenState extends State<ReadBookScreen> {
  bool _isPlaying = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xFF426A80),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                // Placeholder for book content
                child: SingleChildScrollView(
                  child: Text(
                    'Nội dung sách "${widget.title}" của tác giả ${widget.author} sẽ được hiển thị ở đây. Hiện tại đây chỉ là văn bản giữ chỗ.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, height: 1.5),
                  ),
                ),
              ),
            ),
          ),
          _buildControlPanel(),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                onPressed: () {
                  // Placeholder for changing voice
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chức năng đổi giọng đọc chưa được cài đặt.')),
                  );
                },
                icon: const Icon(Icons.record_voice_over, size: 30),
                tooltip: 'Đổi giọng đọc',
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _isPlaying = !_isPlaying;
                  });
                },
                icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 50, color: const Color(0xFF426A80)),
                tooltip: _isPlaying ? 'Tạm dừng' : 'Phát',
              ),
              IconButton(
                onPressed: () {
                  // Placeholder for next page
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chức năng lật trang chưa được cài đặt.')),
                  );
                },
                icon: const Icon(Icons.skip_next, size: 30),
                tooltip: 'Trang tiếp theo',
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Pop with a 'true' result to signal completion
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9C7350),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text('Đã đọc xong', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
