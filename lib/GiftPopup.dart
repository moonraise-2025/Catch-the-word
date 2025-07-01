import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import 'audio_manager.dart'; // Giả định AudioManager đã được cung cấp

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

  Map<String, bool> _isPressedMap =
      {}; // Để quản lý trạng thái nhấn của từng nút

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
      // Sang ngày mới → reset các trạng thái đã nhận thưởng
      await prefs.setString('lastRewardDate', today);
      await prefs.remove('${today}_daily1');
      await prefs.remove('${today}_daily30');
      await prefs.remove('${today}_daily50');
      await prefs.remove('${today}_playthrough');
    }

    setState(() {}); // Cập nhật UI sau khi kiểm tra và reset (nếu cần)
  }

  Future<bool> _isReceived(String keyId) async {
    return prefs.getBool('${todayKey}_$keyId') ?? false;
  }

  Future<void> _handleTap(String keyId, int rewardAmount) async {
    final received = await _isReceived(keyId);
    if (received) return; // Nếu đã nhận rồi thì không làm gì

    await prefs.setBool('${todayKey}_$keyId', true);
    AudioManager().playGiftSound(); // Phát âm thanh nhận thưởng

    if (widget.onReward != null) {
      widget.onReward!(
          rewardAmount); // Gọi callback để thêm thưởng vào tiền của người chơi
    }

    setState(() {}); // Cập nhật UI để hiển thị icon đã nhận
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      backgroundColor: Colors.transparent,
      // Đảm bảo không có padding mặc định từ Dialog
      insetPadding: EdgeInsets.zero,
      // Sử dụng ConstrainedBox để đặt kích thước tối đa cho nội dung popup.
      // Điều này giúp popup không quá lớn trên màn hình rộng.
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: screenWidth * 0.9, // Chiều rộng tối đa 90% màn hình
          maxHeight: screenHeight * 0.6, // Chiều cao tối đa 80% màn hình
        ),
        child: Stack(
          // Clip.none để cho phép logo và nút đóng nằm ngoài container chính nếu cần
          clipBehavior: Clip.none,
          children: [
            Container(
              // Điều chỉnh chiều cao và chiều rộng dựa trên kích thước màn hình
              height: screenHeight * 0.7,
              // Chiếm 70% chiều cao màn hình
              width: screenWidth * 0.85,
              // Chiếm 85% chiều rộng màn hình
              // Margin động để chừa chỗ cho tiêu đề/logo
              margin: EdgeInsets.only(top: screenHeight * 0.1),
              padding: EdgeInsets.symmetric(
                // Padding cân đối dựa trên kích thước màn hình
                horizontal: screenWidth * 0.05,
                // 5% chiều rộng màn hình cho padding ngang
                vertical: screenHeight *
                    0.03, // 3% chiều cao màn hình cho padding dọc
              ),
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
                      SizedBox(height: screenHeight * 0.02),
                      // Khoảng trống động cho logo
                      Text(
                        'PHẦN THƯỞNG',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: screenWidth * 0.08, // Kích thước chữ động
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF8E61DC),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      // Khoảng trống nhỏ động
                      _buildMissionRow(
                        context: context,
                        // Truyền context
                        keyId: 'daily1',
                        title: 'Đoán 1 từ',
                        reward: '5',
                        current: widget.dailyCount,
                        total: 1,
                        amount: 5,
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      // Khoảng trống nhỏ động

                      // FutureBuilder để xử lý hiển thị nhiệm vụ dựa trên trạng thái đã nhận
                      FutureBuilder<List<bool>>(
                        future: Future.wait([
                          _isReceived('daily30'),
                          _isReceived('daily50'),
                        ]),
                        builder: (context, snapshot) {
                          // Lấy trạng thái đã nhận của daily30 và daily50
                          final isDaily30Received = snapshot.data?[0] ?? false;
                          final isDaily50Received = snapshot.data?[1] ?? false;

                          return Column(
                            children: [
                              // Nếu daily30 chưa nhận, hiển thị nó
                              if (!isDaily30Received)
                                _buildMissionRow(
                                  context: context,
                                  // Truyền context
                                  keyId: 'daily30',
                                  title: 'Đoán 30 từ',
                                  reward: '30',
                                  current: widget.daily30Count,
                                  total: 30,
                                  amount: 30,
                                ),
                              // Nếu daily30 đã nhận, hiển thị daily50 (nếu chưa nhận)
                              if (isDaily30Received && !isDaily50Received)
                                _buildMissionRow(
                                  context: context,
                                  // Truyền context
                                  keyId: 'daily50',
                                  title: 'Đoán 50 từ',
                                  reward: '50',
                                  current: widget.daily50Count,
                                  total: 50,
                                  amount: 50,
                                ),
                              // Luôn hiển thị nhiệm vụ không có tiến độ
                              SizedBox(height: screenHeight * 0.01),
                              _buildMissionNoProgress(
                                context: context,
                                // Truyền context
                                keyId: 'playthrough',
                                title: 'Phần thưởng ngày mới',
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
            // Định vị logo tương đối với kích thước màn hình
            Positioned(
              top: screenHeight * 0.02, // Điều chỉnh giá trị này cẩn thận
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/images/logo.png',
                  width: screenWidth *
                      0.7, // Chiều rộng logo theo chiều rộng màn hình
                ),
              ),
            ),
            // Nút đóng ở góc phải trên
            Positioned(
              top: screenHeight * 0.05, // Vị trí theo chiều cao màn hình
              right: screenWidth * 0.02, // Vị trí theo chiều rộng màn hình
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Image.asset(
                  'assets/images/icon_close.png',
                  width: screenWidth * 0.06,
                  // Kích thước theo chiều rộng màn hình
                  height:
                      screenWidth * 0.06, // Kích thước theo chiều rộng màn hình
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget để xây dựng hàng nhiệm vụ có tiến độ
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

        // Xác định màu nền, viền, màu chữ title dựa theo trạng thái
        Color containerBg;
        Border? containerBorder;
        Color titleColor;

        if (received) {
          containerBg =  Color(0xff0fd89f);
          containerBorder =
              Border.all(color: Colors.white70, width: screenWidth * 0.003);
          titleColor = Colors.white70;
        } else if (canClaim) {
          containerBg = Colors.white; // Đủ điều kiện nhận
          containerBorder = null; // Không có viền
          titleColor = const Color(0xFF8E61DC);
        } else {
          containerBg = const Color(0xFFB1B7BB); // Chưa đủ điều kiện nhận
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
              boxShadow: [
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
                  // Bên trái: Tiêu đề nhiệm vụ
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
                                'images/true.png',
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

  // Widget để xây dựng hàng nhiệm vụ không có tiến độ
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

        // Xác định màu nền, viền, màu chữ title dựa theo trạng thái
        Color containerBg;
        Border? containerBorder;
        Color titleColor;

        if (received) {
          containerBg = const Color(0xff6bac5f);
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
              boxShadow: [
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
                                'images/true.png',
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
