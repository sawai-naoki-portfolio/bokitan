import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sorting_problem.dart';

final journalEntryProblemsProvider =
    FutureProvider<List<SortingProblem>>((ref) async {
  final data = await rootBundle.loadString('assets/siwake.json');
  final List<dynamic> jsonResult = jsonDecode(data);
  return jsonResult.map((json) => SortingProblem.fromJson(json)).toList();
});
