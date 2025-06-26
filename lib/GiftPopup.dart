import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import 'audio_manager.dart';

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

  Map<String, bool> _isPressedMap = {};


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

    AudioManager().playGiftSound();


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
            height: 800,
            width: screenWidth * 0.80,
            margin: const EdgeInsets.only(top: 200), // để chừa chỗ cho tiêu đề
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30), // padding cân trái/phải
            decoration: BoxDecoration(
              image: const DecorationImage(
                image: AssetImage('assets/images/bg_popup.png'),
                fit: BoxFit.fill,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Text(
                      'PHẦN THƯỞNG',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 60, fontWeight: FontWeight.w900, color: Color(0xFF8E61DC)),
                    ),
                    const SizedBox(height: 10),
                    _buildMissionRow(
                      keyId: 'daily1',
                      title: 'Đoán 1 từ',
                      reward: '5',
                      current: widget.dailyCount,
                      total: 1,
                      amount: 5,
                    ),
                    const SizedBox(height: 10),

                    FutureBuilder<List<bool>>(
                      future: Future.wait([
                        _isReceived('daily30'),
                        _isReceived('daily50'),
                      ]),
                      builder: (context, snapshot) {
                        final isDaily30Received = snapshot.data?[0] ?? false;
                        final isDaily50Received = snapshot.data?[1] ?? false;

                        return Column(
                          children: [
                            if (!isDaily30Received)
                              _buildMissionRow(
                                keyId: 'daily30',
                                title: 'Đoán 30 từ',
                                reward: '30',
                                current: widget.daily30Count,
                                total: 30,
                                amount: 30,
                              ),
                            if (isDaily30Received)
                              _buildMissionRow(
                                keyId: 'daily50',
                                title: 'Đoán 50 từ',
                                reward: '50',
                                current: widget.daily50Count,
                                total: 50,
                                amount: 50,
                              ),
                            const SizedBox(height: 10),
                            _buildMissionNoProgress(
                              keyId: 'playthrough',
                              title: 'Sử dụng qua màn',
                              reward: '20',
                              amount: 20,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -600,
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              alignment: Alignment.center,
              child: Image.asset(
                'assets/images/logo.png',
                width: 500,
              ),
            ),
          ),
          // Nút đóng ở góc phải trên
          Positioned(
            top: 100,
            right: 10,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Image.asset(
                'assets/images/icon_close.png',
                width: 40,
                height: 40,
              ),
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
        final canClaim = isComplete && !received;

        return Builder(
          builder: (context) {
            final screenWidth = MediaQuery.of(context).size.width;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: SizedBox(
                width: screenWidth * 0.4,
                height: 110,
                child: AnimatedScale(
                  scale: _isPressedMap[keyId] == true ? 0.95 : 1.0,
                  duration: const Duration(milliseconds: 100),
                  child: GestureDetector(
                    onTapDown: (_) => setState(() => _isPressedMap[keyId] = true),
                    onTapUp: (_) => setState(() => _isPressedMap[keyId] = false),
                    onTapCancel: () => setState(() => _isPressedMap[keyId] = false),
                    child: ElevatedButton(
                      onPressed: canClaim ? () => _handleTap(keyId, amount) : null,
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                          if (states.contains(MaterialState.disabled)) {
                            return const Color(0xFF43ADED);
                          }
                          return Colors.white;
                        }),
                        elevation: MaterialStateProperty.all(4),
                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(color: Colors.white, width: 2),
                          ),
                        ),
                        padding: MaterialStateProperty.all(const EdgeInsets.all(5)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$title ($current/$total)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: canClaim ? Colors.grey : Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          received
                              ? const Icon(Icons.check_circle, color: Colors.green, size: 40)
                              : Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                reward,
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF8E61DC),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Image.asset(
                                'images/diamond.png',
                                width: 40,
                                height: 40,
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
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
        final canClaim = !received;

        return Builder(
          builder: (context) {
            final screenWidth = MediaQuery.of(context).size.width;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: SizedBox(
                width: screenWidth * 0.4,
                height: 110,
                child: AnimatedScale(
                  scale: _isPressedMap[keyId] == true ? 0.95 : 1.0,
                  duration: const Duration(milliseconds: 100),
                  child: GestureDetector(
                    onTapDown: (_) => setState(() => _isPressedMap[keyId] = true),
                    onTapUp: (_) => setState(() => _isPressedMap[keyId] = false),
                    onTapCancel: () => setState(() => _isPressedMap[keyId] = false),
                    child: ElevatedButton(
                      onPressed: received ? null : () => _handleTap(keyId, amount),
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                          if (states.contains(MaterialState.disabled)) {
                            return const Color(0xFF43ADED);
                          }
                          return Colors.white;
                        }),
                        elevation: MaterialStateProperty.all(4),
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(color: Colors.white, width: 2),
                          ),
                        ),
                        padding: MaterialStateProperty.all(const EdgeInsets.all(5)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: canClaim ? Colors.grey : Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          received
                              ? const Icon(Icons.check_circle, color: Colors.green, size: 36)
                              : Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                reward,
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF8E61DC),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Image.asset(
                                'images/diamond.png',
                                width: 40,
                                height: 40,
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
