import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

enum Method {
  POST,
  GET,
  PUT,
  DELETE,
  UPDATE,
}

extension CachedDio on Dio {
  _saveCache({
    required String url,
    required String data,
    required Duration duration,
  }) async {
    var box = await Hive.openBox('cached_dio');
    var obj = {
      'date': DateTime.now().millisecondsSinceEpoch,
      'data': data,
      'duration': duration.inMilliseconds,
    };
    box.put(url, obj);
  }

  Future<String?> _getFromCache({required String url}) async {
    var box = await Hive.openBox('cached_dio');

    var data = box.get(url);
    if (data != null) {
      int eventTimeStamp = data['date'];
      int maxTimeStamp = data['duration'] + eventTimeStamp;
      int now = DateTime.now().millisecondsSinceEpoch;

      if (maxTimeStamp >= now) {
        return data['data'];
      }
    }
    return null;
  }

  Future<String?> postCached({
    required String url,
    required Duration duration,
    Map<String, dynamic>? headers,
  }) async {
    return _getQuery(
        url: url, duration: duration, headers: headers, method: Method.POST);
  }

  Future<String?> getCached({
    required String url,
    required Duration duration,
    Map<String, dynamic>? headers,
  }) async {
    return await _getQuery(
        url: url, duration: duration, headers: headers, method: Method.GET);
  }

  Future<String?> _getQuery({
    required String url,
    required Duration duration,
    required Method method,
    Map<String, dynamic>? headers,
  }) async {
    final documentDirectory = await getApplicationDocumentsDirectory();
    Hive.init(documentDirectory.path);
    var dio = headers == null ? Dio() : Dio(BaseOptions(headers: headers));

    String? res = await _getFromCache(url: url);
    if (res == null) {
      if (kDebugMode) {
        print('${method.name} $url');
      }
      Response<String>? resp = await switch (method.name) {
        'GET' => dio.get(url),
        'POST' => dio.post(url),
        'PUT' => dio.put(url),
        'DELETE' => dio.delete(url),
        _ => null,
      };

      res = resp?.data.toString();
      _saveCache(
        url: url,
        data: res ?? '',
        duration: duration,
      );
    } else {
      if (kDebugMode) {
        print('geting from cache');
      }
    }
    return res;
  }
}
