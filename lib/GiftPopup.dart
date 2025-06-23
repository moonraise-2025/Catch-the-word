import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

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
    this.onReward,
  });

  @override
  State<Giftpopup> createState() => _GiftpopupState();
}

class _GiftpopupState extends State<Giftpopup> {
  late SharedPreferences prefs;
  final String todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _initPrefsAndCheckNewDay();
  }

  Future<void> _initPrefsAndCheckNewDay() async {
    prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString('lastRewardDate');
    final today = todayKey;

    if (lastDate != today) {
      // ✅ Sang ngày mới → reset
      await prefs.setString('lastRewardDate', today);
      await prefs.remove('${today}_daily1');
      await prefs.remove('${today}_daily30');
      await prefs.remove('${today}_daily50');
      await prefs.remove('${today}_playthrough');
    }

    setState(() {}); // cập nhật UI
  }

  Future<bool> _isReceived(String keyId) async {
    return prefs.getBool('${todayKey}_$keyId') ?? false;
  }

  Future<void> _handleTap(String keyId, int rewardAmount) async {
    final received = await _isReceived(keyId);
    if (received) return;

    await prefs.setBool('${todayKey}_$keyId', true);

    if (widget.onReward != null) {
      widget.onReward!(rewardAmount);
    }

    setState(() {}); // Cập nhật icon sau khi nhận
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
                  _buildMissionRow(
                    keyId: 'daily1',
                    title: 'Trả lời câu hỏi',
                    reward: '+5',
                    current: widget.dailyCount,
                    total: 1,
                    amount: 5,
                  ),
                  const SizedBox(height: 20),
                  _buildMissionRow(
                    keyId: 'daily30',
                    title: 'Trả lời 30 câu hỏi',
                    reward: '+10',
                    current: widget.daily30Count,
                    total: 30,
                    amount: 10,
                  ),
                  const SizedBox(height: 10),
                  _buildMissionRow(
                    keyId: 'daily50',
                    title: 'Trả lời 50 câu hỏi',
                    reward: '+15',
                    current: widget.daily50Count,
                    total: 50,
                    amount: 15,
                  ),
                  const SizedBox(height: 10),
                  _buildMissionNoProgress(
                    keyId: 'playthrough',
                    title: 'Sử dụng qua màn',
                    reward: '+20',
                    amount: 20,
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

  Widget _buildMissionRow({
    required String keyId,
    required String title,
    required String reward,
    required int current,
    required int total,
    required int amount,
  }) {
    final bool isComplete = current >= total;

    return FutureBuilder<bool>(
      future: _isReceived(keyId),
      builder: (context, snapshot) {
        final received = snapshot.data ?? false;

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
                    ? () => _handleTap(keyId, amount)
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
      },
    );
  }

  Widget _buildMissionNoProgress({
    required String keyId,
    required String title,
    required String reward,
    required int amount,
  }) {
    return FutureBuilder<bool>(
      future: _isReceived(keyId),
      builder: (context, snapshot) {
        final received = snapshot.data ?? false;

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
                onTap: received ? null : () => _handleTap(keyId, amount),
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
      },
    );
  }
}
