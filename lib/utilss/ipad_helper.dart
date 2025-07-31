import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class IpadHelper {
  static bool get isIPad {
    if (kIsWeb) return false;
    if (!Platform.isIOS) return false;
    
    // Kiểm tra kích thước màn hình để xác định iPad
    final mediaQuery = MediaQueryData.fromView(WidgetsBinding.instance.platformDispatcher.views.first);
    final size = mediaQuery.size;
    final diagonal = (size.width * size.width + size.height * size.height);
    
    // iPad thường có diagonal > 1000000 (khoảng 9.7 inch trở lên)
    return diagonal > 1000000;
  }

  static bool get isIPadPro {
    if (!isIPad) return false;
    
    final mediaQuery = MediaQueryData.fromView(WidgetsBinding.instance.platformDispatcher.views.first);
    final size = mediaQuery.size;
    final diagonal = (size.width * size.width + size.height * size.height);
    
    // iPad Pro thường có diagonal > 1500000 (khoảng 11 inch trở lên)
    return diagonal > 1500000;
  }

  static bool get isIPadAir {
    if (!isIPad) return false;
    
    final mediaQuery = MediaQueryData.fromView(WidgetsBinding.instance.platformDispatcher.views.first);
    final size = mediaQuery.size;
    final diagonal = (size.width * size.width + size.height * size.height);
    
    // iPad Air 11 inch có diagonal khoảng 1200000-1400000
    return diagonal >= 1200000 && diagonal <= 1400000;
  }

  // Điều chỉnh pixel ratio cho iPad để tránh lỗi memory
  static double get optimalPixelRatio {
    if (isIPad) {
      if (isIPadPro) return 1.0;
      if (isIPadAir) return 1.2; // Tối ưu cho iPad Air
      return 1.5;
    }
    return 2.0;
  }

  // Điều chỉnh delay cho iPad
  static int get captureDelay {
    if (isIPad) {
      if (isIPadPro) return 300;
      if (isIPadAir) return 250; // Tối ưu cho iPad Air
      return 250;
    }
    return 200;
  }

  // Kiểm tra xem có nên sử dụng fallback cho share
  static bool get shouldUseShareFallback {
    return isIPad;
  }

  // Kiểm tra xem có nên sử dụng fallback cho ads
  static bool get shouldUseAdsFallback {
    return isIPad;
  }

  // Delay cho touch events trên iPad
  static int get touchDelay {
    if (isIPad) {
      return isIPadAir ? 150 : 200;
    }
    return 100;
  }
} 