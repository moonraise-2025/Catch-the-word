import 'package:flutter/material.dart';

class Giftpopup extends StatefulWidget {
  final int dailyCount;
  final int daily30Count;
  final int daily50Count;
  final void Function(int amount)? onReward;


  const Giftpopup({
    super.key,
    required this.dailyCount,
    required this.daily30Count,
    required this.daily50Count,
    this.onReward
  });

  @override
  State<Giftpopup> createState() => _GiftpopupState();
}

class _GiftpopupState extends State<Giftpopup> {
  final Map<String, bool> _received = {
    'daily1': false,
    'weekly30': false,
    'weekly50': false,
    'playthrough': false,
  };

  void _handleTap(String key) {
    setState(() {
      _received[key] = true;
    });
    if (widget.onReward != null) {
      if (key == 'daily1') widget.onReward!(5);
      if (key == 'daily30') widget.onReward!(10);
      if (key == 'daily50') widget.onReward!(15);
      if (key == 'playthrough') widget.onReward!(20);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          Container(
            width: screenWidth * 0.95,
            margin: const EdgeInsets.only(top: 80),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  // const Text(
                  //   'Nhiệm vụ hằng ngày',
                  //   style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                  // ),
                  const SizedBox(height: 20),
                  _buildMissionRow(
                    keyId: 'daily1',
                    title: 'Trả lời câu hỏi',
                    reward: '+5',
                    current: widget.dailyCount,
                    total: 1,
                  ),
                  // const SizedBox(height: 40),
                  // const Text(
                  //   'Nhiệm vụ hằng tuần',
                  //   style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                  // ),
                  const SizedBox(height: 20),
                  _buildMissionRow(
                    keyId: 'daily30',
                    title: 'Trả lời 30 câu hỏi',
                    reward: '+10',
                    current: widget.daily30Count,
                    total: 30,
                  ),
                  const SizedBox(height: 10),
                  _buildMissionRow(
                    keyId: 'daily50',
                    title: 'Trả lời 50 câu hỏi',
                    reward: '+15',
                    current: widget.daily50Count,
                    total: 50,
                  ),
                  const SizedBox(height: 10),
                  _buildMissionNoProgress(
                    keyId: 'playthrough',
                    title: 'Sử dụng qua màn',
                    reward: '+20',
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 80,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.pinkAccent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
                border: Border.all(color: Colors.pink, width: 2),
              ),
              child: const Text(
                'Nhiệm Vụ Hằng Ngày',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: IconButton(
              icon: const Icon(Icons.close, size: 30, color: Colors.blueAccent),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionRow({ //nhiệm vụ nhận qua
    required String keyId,
    required String title,
    required String reward,
    required int current,
    required int total,
  }) {
    final bool received = _received[keyId] ?? false;
    final bool isComplete = current >= total;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$title ($current/$total)',
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
          ),
          GestureDetector(
            onTap: (!received && isComplete)
                ? () => _handleTap(keyId)
                : null,
            child: received
                ? const Icon(Icons.check_circle, color: Colors.green, size: 50)
                : Row(
              children: [
                Text(
                  reward,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.diamond,
                  color: Colors.blueAccent,
                  size: 50,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //Nhiệm vụ qua màn
  Widget _buildMissionNoProgress({
    required String keyId,
    required String title,
    required String reward,
  }) {
    final bool received = _received[keyId] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
          ),
          GestureDetector(
            onTap: received
                ? null
                : () => _handleTap(keyId), // click để nhận
            child: received
                ? const Icon(Icons.check_circle,
                color: Colors.green, size: 50)
                : Row(
              children: [
                Text(
                  reward,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.diamond,
                  color: Colors.blueAccent,
                  size: 50,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

