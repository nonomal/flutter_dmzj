import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dmzj/app/app_style.dart';
import 'package:flutter_dmzj/app/log.dart';
import 'package:flutter_dmzj/requests/common_request.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher_string.dart';

class Utils {
  static late PackageInfo packageInfo;
  static DateFormat dateFormat = DateFormat("yyyy-MM-dd");
  static DateFormat dateTimeFormat = DateFormat("MM-dd HH:mm");
  static DateFormat dateTimeFormatWithYear = DateFormat("yyyy-MM-dd HH:mm");

  /// 版本号解析
  static int parseVersion(String version) {
    var sp = version.split('.');
    var num = "";
    for (var item in sp) {
      num = num + item.padLeft(2, '0');
    }
    return int.parse(num);
  }

  /// 时间戳格式化-秒
  static String formatTimestamp(int ts) {
    return formatTimestampMS(ts * 1000);
  }

  static String formatTimestampToDate(int ts) {
    var dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return dateFormat.format(dt);
  }

  /// 时间戳格式化-毫秒
  static String formatTimestampMS(int ts) {
    var dt = DateTime.fromMillisecondsSinceEpoch(ts);

    var dtNow = DateTime.now();
    if (dt.year == dtNow.year &&
        dt.month == dtNow.month &&
        dt.day == dtNow.day) {
      return "今天${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    }
    if (dt.year == dtNow.year &&
        dt.month == dtNow.month &&
        dt.day == dtNow.day - 1) {
      return "昨天${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    }

    if (dt.year == dtNow.year) {
      return dateTimeFormat.format(dt);
    }

    return dateTimeFormatWithYear.format(dt);
  }

  /// 检查相册权限
  static Future<bool> checkPhotoPermission() async {
    try {
      var status = await Permission.photos.status;
      if (status == PermissionStatus.granted) {
        return true;
      }
      status = await Permission.photos.request();
      if (status.isGranted) {
        return true;
      } else {
        SmartDialog.showToast("请授予相册权限");
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// 保存图片
  static void saveImage(String url) async {
    //TODO Windows\MacOS\Linux另外处理
    if (Platform.isIOS && !await Utils.checkPhotoPermission()) {
      return;
    }
    try {
      var provider = ExtendedNetworkImageProvider(url, cache: true);
      var data = await provider.getNetworkImageData();
      if (data == null) {
        SmartDialog.showToast("图片保存失败");
        return;
      }
      var cacheDir = await getTemporaryDirectory();
      var file = File(p.join(cacheDir.path, p.basename(url)));
      await file.writeAsBytes(data);
      final result = await ImageGallerySaver.saveFile(
        file.path,
        name: p.basename(url),
        isReturnPathOfIOS: true,
      );
      Log.d(result.toString());
      SmartDialog.showToast("保存成功");
    } catch (e) {
      SmartDialog.showToast("保存失败");
    }
  }

  /// 分享
  static void share(String url, {String content = ""}) {
    //TODO 分享处理

    Share.share(content.isEmpty ? url : "$content\n$url");
  }

  static void checkUpdate({bool showMsg = false}) async {
    try {
      int currentVer = Utils.parseVersion(packageInfo.version);
      CommonRequest request = CommonRequest();
      var versionInfo = await request.checkUpdate();
      if (versionInfo.versionNum > currentVer) {
        Get.dialog(
          AlertDialog(
            title: Text(
              "发现新版本 ${versionInfo.version}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            content: Text(
              versionInfo.versionDesc,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
            actionsPadding: AppStyle.edgeInsetsH12,
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Get.back();
                      },
                      child: const Text("取消"),
                    ),
                  ),
                  AppStyle.hGap12,
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                      ),
                      onPressed: () {
                        launchUrlString(
                          versionInfo.downloadUrl,
                          mode: LaunchMode.externalApplication,
                        );
                      },
                      child: const Text("更新"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      } else {
        if (showMsg) {
          SmartDialog.showToast("当前已经是最新版本了");
        }
      }
    } catch (e) {
      Log.logPrint(e);
      if (showMsg) {
        SmartDialog.showToast("检查更新失败");
      }
    }
  }
}
