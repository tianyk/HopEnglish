import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hopenglish/src/models/category.dart';

/// 分类数据服务
class CategoryService {
  static const String _dataPath = 'assets/data/categories.json';

  CategoryService._();

  /// 加载所有分类数据
  static Future<List<Category>> loadCategories() async {
    final jsonString = await rootBundle.loadString(_dataPath);
    final jsonList = json.decode(jsonString) as List<dynamic>;
    return jsonList.map((item) => Category.fromJson(item as Map<String, dynamic>)).toList();
  }
}
