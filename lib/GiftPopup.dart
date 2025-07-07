import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import 'audio_manager.dart';


enum MissionStatus {
  canClaim,       // Có thể nhận
  notComplete,    // Chưa đủ điều kiện
  received,       // Đã nhận
}

class MissionData {
  final String keyId;
  final String title;
  final String reward;
  final int amount;
  final int? current;
  final int? total;
  MissionStatus status;
  final bool hasProgress; // Để phân biệt _buildMissionRow và _buildMissionNoProgress

  MissionData({
    required this.keyId,
    required this.title,
    required this.reward,
    required this.amount,
    this.current,
    this.total,
    required this.status,
    required this.hasProgress,
  });
}


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
  late Future<List<MissionData>> _missionsFuture;

  @override
  void initState() {
    super.initState();

    _missionsFuture = _initializeMissions();
  }

  // Hàm mới để xử lý khởi tạo SharedPreferences và lấy danh sách nhiệm vụ ban đầu
  Future<List<MissionData>> _initializeMissions() async {
    prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString('lastRewardDate');
    final today = todayKey;

    if (lastDate != today) {
      await prefs.setString('lastRewardDate', today);
      await prefs.remove('${lastDate}_daily1');
      await prefs.remove('${lastDate}_daily30');
      await prefs.remove('${lastDate}_daily50');
      await prefs.remove('${lastDate}_playthrough');
    }

    return _getSortedMissions(); // Trả về Future
  }


  // Hàm kiểm tra xem nhiệm vụ đã được nhận chưa
  Future<bool> _isReceived(String keyId) async {
    return prefs.getBool('${todayKey}_$keyId') ?? false;
  }

  // Hàm xử lý khi người dùng nhấn nút nhận thưởng
  Future<void> _handleTap(String keyId, int rewardAmount) async {
    final received = await _isReceived(keyId);
    if (received) return;

    await prefs.setBool('${todayKey}_$keyId', true);
    AudioManager().playGiftSound();

    if (widget.onReward != null) {
      widget.onReward!(rewardAmount);
    }

    setState(() {
      _missionsFuture = _getSortedMissions(); // Quan trọng: Rebuild Future
    });
  }

  // Hàm để lấy và sắp xếp danh sách nhiệm vụ dựa trên trạng thái
  // Hàm này không cần biết về khởi tạo prefs nữa vì nó được gọi sau prefs đã sẵn sàng
  Future<List<MissionData>> _getSortedMissions() async {
    final daily1Received = await _isReceived('daily1');
    final daily30Received = await _isReceived('daily30');
    final daily50Received = await _isReceived('daily50');
    final playthroughReceived = await _isReceived('playthrough');

    List<MissionData> missions = [
      MissionData(
        keyId: 'daily1',
        title: 'Đoán 1 từ',
        reward: '5',
        amount: 5,
        current: widget.dailyCount,
        total: 1,
        status: _getMissionStatus(widget.dailyCount >= 1, daily1Received),
        hasProgress: true,
      ),
      MissionData(
        keyId: 'daily30',
        title: 'Đoán 30 từ',
        reward: '30',
        amount: 30,
        current: widget.daily30Count,
        total: 30,
        status: _getMissionStatus(widget.daily30Count >= 30, daily30Received),
        hasProgress: true,
      ),
      MissionData(
        keyId: 'daily50',
        title: 'Đoán 50 từ',
        reward: '50',
        amount: 50,
        current: widget.daily50Count,
        total: 50,
        status: _getMissionStatus(widget.daily50Count >= 50, daily50Received),
        hasProgress: true,
      ),
      MissionData(
        keyId: 'playthrough',
        title: 'Phần thưởng ngày mới',
        reward: '20',
        amount: 20,
        current: null,
        total: null,
        status: _getMissionStatus(true, playthroughReceived),
        hasProgress: false,
      ),
    ];

    missions.sort((a, b) => a.status.index.compareTo(b.status.index));

    return missions;
  }

  MissionStatus _getMissionStatus(bool isComplete, bool received) {
    if (received) {
      return MissionStatus.received;
    } else if (isComplete) {
      return MissionStatus.canClaim;
    } else {
      return MissionStatus.notComplete;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Center(
      child: Stack(
        children: [
          Container(
            width: screenWidth * 0.90,
            height: screenHeight * 0.50,
            margin: EdgeInsets.only(top: screenHeight * 0.1), // Margin động để chừa chỗ cho tiêu đề/logo
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.03,
              vertical: screenHeight * 0.025,
            ),
            decoration: BoxDecoration(
              image: const DecorationImage(
                image: AssetImage('assets/images/bg_popup.png'),
                fit: BoxFit.fill,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: screenHeight * 0.08),
                Text(
                  'PHẦN THƯỞNG',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: screenWidth * 0.09,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF8E61DC),
                      decoration: TextDecoration.none,
                      fontFamily: 'Roboto'
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),

                // Expanded bọc SingleChildScrollView để nó chiếm hết không gian còn lại và có thể cuộn
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        FutureBuilder<List<MissionData>>(
                          future: _missionsFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            } else if (snapshot.hasError) {
                              return Text('Lỗi: ${snapshot.error}');
                            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Text('Không có nhiệm vụ nào.');
                            } else {
                              return Column(
                                children: snapshot.data!.map((mission) {
                                  return Column(
                                    children: [
                                      if (mission.hasProgress)
                                        _buildMissionRow(
                                          context: context,
                                          keyId: mission.keyId,
                                          title: mission.title,
                                          reward: mission.reward,
                                          current: mission.current!,
                                          total: mission.total!,
                                          amount: mission.amount,
                                        )
                                      else
                                        _buildMissionNoProgress(
                                          context: context,
                                          keyId: mission.keyId,
                                          title: mission.title,
                                          reward: mission.reward,
                                          amount: mission.amount,
                                        ),
                                      SizedBox(height: screenHeight * 0.01),
                                    ],
                                  );
                                }).toList(),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: screenHeight * 0.02,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.center,
              child: Image.asset(
                'assets/images/logo.png',
                width: screenWidth * 0.7,
              ),
            ),
          ),
          Positioned(
            top: screenHeight * 0.05,
            right: screenWidth * 0.02,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Image.asset(
                'assets/images/icon_close.png',
                width: screenWidth * 0.08,
                height: screenWidth * 0.08,
              ),
            ),
          ),
          SizedBox(height: screenHeight * 0.65),

        ],
      ),
    ); // Only one closing parenthesis for the Center widget
  }
  Widget _buildMissionRow({
    required BuildContext context,
    required String keyId,
    required String title,
    required String reward,
    required int current,
    required int total,
    required int amount,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final bool isComplete = current >= total;

    return FutureBuilder<bool>(
      future: _isReceived(keyId),
      builder: (context, snapshot) {
        final received = snapshot.data ?? false;
        final canClaim = isComplete && !received;

        Color containerBg;
        Border? containerBorder;
        Color titleColor;

        if (received) {
          containerBg = const Color(0xff0fd89f);
          containerBorder =
              Border.all(color: Colors.white70, width: screenWidth * 0.003);
          titleColor = Colors.white70;
        } else if (canClaim) {
          containerBg = Colors.white;
          containerBorder = null;
          titleColor = const Color(0xFF8E61DC);
        } else {
          containerBg = const Color(0xFFB1B7BB);
          containerBorder =
              Border.all(color: Colors.black45, width: screenWidth * 0.003);
          titleColor = Colors.black45;
        }

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.02,
            vertical: screenWidth * 0.01,
          ),
          child: Container(
            height: screenHeight * 0.065,
            decoration: BoxDecoration(
              color: containerBg,
              borderRadius: BorderRadius.circular(screenWidth * 0.1),
              border: containerBorder,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding:
                      EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
                      child: Text(
                        '$title ($current/$total)',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                            decoration: TextDecoration.none,
                            fontFamily: 'Roboto'
                        ),
                      ),
                    ),
                  ),
                  AnimatedScale(
                    scale: _isPressedMap[keyId] == true ? 0.95 : 1.0,
                    duration: const Duration(milliseconds: 100),
                    child: GestureDetector(
                      onTapDown: (_) =>
                          setState(() => _isPressedMap[keyId] = true),
                      onTapUp: (_) {
                        setState(() => _isPressedMap[keyId] = false);
                        if (canClaim) _handleTap(keyId, amount);
                      },
                      onTapCancel: () =>
                          setState(() => _isPressedMap[keyId] = false),
                      child: Container(
                        width: screenWidth * 0.17,
                        height: screenWidth * 0.1,
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.025,
                          vertical: screenHeight * 0.008,
                        ),
                        margin: EdgeInsets.only(right: screenWidth * 0.02),
                        decoration: BoxDecoration(
                          color: received
                              ? const Color(0xFF5ce1e6)
                              : (canClaim
                              ? const Color(0xffec9035)
                              : const Color(0xFFebecec)),
                          borderRadius:
                          BorderRadius.circular(screenWidth * 0.1),
                        ),
                        child: received
                            ? Image.asset(
                          'assets/images/true.png',
                          width: screenWidth * 0.05,
                          height: screenWidth * 0.05,
                        )
                            : Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              reward,
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.bold,
                                color: Colors.black45,
                                  decoration: TextDecoration.none,
                                  fontFamily: 'Roboto'

                              ),
                            ),
                            SizedBox(width: screenWidth * 0.01),
                            Image.asset(
                              'assets/images/diamond.png',
                              width: screenWidth * 0.045,
                              height: screenWidth * 0.045,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMissionNoProgress({
    required BuildContext context,
    required String keyId,
    required String title,
    required String reward,
    required int amount,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return FutureBuilder<bool>(
      future: _isReceived(keyId),
      builder: (context, snapshot) {
        final received = snapshot.data ?? false;
        final canClaim = !received;

        Color containerBg;
        Border? containerBorder;
        Color titleColor;

        if (received) {
          containerBg = const Color(0xff0fd89f);
          containerBorder =
              Border.all(color: Colors.white70, width: screenWidth * 0.003);
          titleColor = Colors.white70;
        } else if (canClaim) {
          containerBg = Colors.white;
          containerBorder = null;
          titleColor = const Color(0xFF8E61DC);
        } else {
          containerBg = const Color(0xFFB1B7BB);
          containerBorder =
              Border.all(color: Colors.black45, width: screenWidth * 0.003);
          titleColor = Colors.black45;
        }

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.02,
            vertical: screenWidth * 0.01,
          ),
          child: Container(
            height: screenHeight * 0.065,
            decoration: BoxDecoration(
              color: containerBg,
              borderRadius: BorderRadius.circular(screenWidth * 0.1),
              border: containerBorder,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding:
                      EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                            decoration: TextDecoration.none,
                            fontFamily: 'Roboto'
                        ),
                      ),
                    ),
                  ),
                  AnimatedScale(
                    scale: _isPressedMap[keyId] == true ? 0.95 : 1.0,
                    duration: const Duration(milliseconds: 100),
                    child: GestureDetector(
                      onTapDown: (_) =>
                          setState(() => _isPressedMap[keyId] = true),
                      onTapUp: (_) {
                        setState(() => _isPressedMap[keyId] = false);
                        if (canClaim) _handleTap(keyId, amount);
                      },
                      onTapCancel: () =>
                          setState(() => _isPressedMap[keyId] = false),
                      child: Container(
                        width: screenWidth * 0.17,
                        height: screenWidth * 0.1,
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.025,
                          vertical: screenHeight * 0.008,
                        ),
                        margin: EdgeInsets.only(right: screenWidth * 0.02),
                        decoration: BoxDecoration(
                          color: received
                              ? const Color(0xFF5ce1e6)
                              : (canClaim
                              ? const Color(0xffec9035)
                              : const Color(0xFFebecec)),
                          borderRadius:
                          BorderRadius.circular(screenWidth * 0.1),
                        ),
                        child: received
                            ? Image.asset(
                          'assets/images/true.png',
                          width: screenWidth * 0.05,
                          height: screenWidth * 0.05,
                        )
                            : Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              reward,
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.bold,
                                color: Colors.black45,
                                  decoration: TextDecoration.none,
                                  fontFamily: 'Roboto'
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.01),
                            Image.asset(
                              'assets/images/diamond.png',
                              width: screenWidth * 0.045,
                              height: screenWidth * 0.045,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}