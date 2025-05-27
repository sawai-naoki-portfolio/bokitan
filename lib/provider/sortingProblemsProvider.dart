// ============================================================================
// sortingProblemsProvider
// -----------------------------------------------------------------------------
// この FutureProvider は、assets/siwake.json から仕訳問題のリストを非同期
// で読み込み、SortingProblem インスタンスのリストとして返します。
// ============================================================================
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utility/SortingProblem.dart';

final sortingProblemsProvider =
    FutureProvider<List<SortingProblem>>((ref) async {
  final data = await rootBundle.loadString('assets/siwake.json');
  final List<dynamic> jsonResult = jsonDecode(data);
  return jsonResult.map((json) => SortingProblem.fromJson(json)).toList();
});
