// *****************************************************************************
// Flutter アプリ全体で利用するユーティリティやウィジェット、プロバイダーの定義
// *****************************************************************************

import 'dart:async';
import 'dart:convert';

import 'package:bookkeeping_vocabulary_notebook/provider/themeProvider.dart';
import 'package:bookkeeping_vocabulary_notebook/provider/useMaterial3Provider.dart';
import 'package:bookkeeping_vocabulary_notebook/utility/SwipeToDeleteCard.dart';
import 'package:bookkeeping_vocabulary_notebook/view/SearchPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

class ScheduleItem {
  final String id;
  final String title;
  final String subject; // 科目・コース名
  final DateTime startTime;
  final DateTime endTime;
  final String description;
  final List<String> tasks; // タスクやマイルストーン
  bool isCompleted;
  final bool isExamDate; // 追加：受験日設定なら true

  ScheduleItem({
    required this.id,
    required this.title,
    required this.subject,
    required this.startTime,
    required this.endTime,
    required this.description,
    this.tasks = const [],
    this.isCompleted = false,
    this.isExamDate = false, // デフォルトは false
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      id: json['id'],
      title: json['title'],
      subject: json['subject'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      description: json['description'],
      tasks: List<String>.from(json['tasks'] ?? []),
      isCompleted: json['isCompleted'] ?? false,
      isExamDate: json['isExamDate'] ?? false, // JSONに存在しなければ false
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subject': subject,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'description': description,
        'tasks': tasks,
        'isCompleted': isCompleted,
        'isExamDate': isExamDate, // 追加
      };
}

/// ScheduleNotifier: スケジュール一覧を SharedPreferences 経由で管理
final scheduleProvider =
    StateNotifierProvider<ScheduleNotifier, List<ScheduleItem>>(
  (ref) => ScheduleNotifier(),
);

class ScheduleNotifier extends StateNotifier<List<ScheduleItem>> {
  ScheduleNotifier() : super([]) {
    _loadScheduleItems();
  }

  Future<void> _loadScheduleItems() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('schedule_items') ?? [];
    state = data.map((e) => ScheduleItem.fromJson(jsonDecode(e))).toList();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> data = state.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList('schedule_items', data);
  }

  Future<void> addSchedule(ScheduleItem item) async {
    state = [...state, item];
    await _save();
  }

  Future<void> updateSchedule(ScheduleItem item) async {
    state = state.map((e) => e.id == item.id ? item : e).toList();
    await _save();
  }

  Future<void> removeSchedule(String id) async {
    state = state.where((e) => e.id != id).toList();
    await _save();
  }
}

class ScheduleManagementPage extends ConsumerStatefulWidget {
  const ScheduleManagementPage({super.key});

  @override
  ConsumerState<ScheduleManagementPage> createState() =>
      _ScheduleManagementPageState();
}

class _ScheduleManagementPageState
    extends ConsumerState<ScheduleManagementPage> {
  // 現在カレンダーでフォーカスしている日付（初期値は今日）
  DateTime _focusedDay = DateTime.now();

  // 選択された日付
  DateTime? _selectedDay;

  // scheduleProvider に登録されたスケジュールを、日付単位でグループ化する
  Map<DateTime, List<ScheduleItem>> _groupEvents(
      List<ScheduleItem> scheduleList) {
    final Map<DateTime, List<ScheduleItem>> data = {};
    for (var event in scheduleList) {
      // 日付のみ取り出す（時刻は切り捨て）
      final day = DateTime(
          event.startTime.year, event.startTime.month, event.startTime.day);
      if (data[day] == null) {
        data[day] = [event];
      } else {
        data[day]!.add(event);
      }
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    // providerからスケジュール一覧を取得
    final scheduleList = ref.watch(scheduleProvider);
    final groupedEvents = _groupEvents(scheduleList);

    final now = DateTime.now();
    // 受験日として設定され、未来の日付の予定を抽出
    final upcomingExamEvents = scheduleList
        .where((e) => e.isExamDate && e.startTime.isAfter(now))
        .toList();
    upcomingExamEvents.sort((a, b) => a.startTime.compareTo(b.startTime));
    final examCountdownWidgets = upcomingExamEvents.take(3).map((event) {
      final daysRemaining = event.startTime.difference(now).inDays;
      return Expanded(
        child: InkWell(
          onTap: () {
            // 受験日のカードがタップされたとき、編集画面に遷移する
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddEditSchedulePage(scheduleItem: event),
              ),
            );
          },
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Colors.grey),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.event_note,
                    color: Colors.black54,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "受験日まで残り\n${daysRemaining >= 0 ? daysRemaining : 0} 日",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();

    // 選択した日のイベントを返す関数
    List<ScheduleItem> getEventsForDay(DateTime day) {
      return groupedEvents[DateTime(day.year, day.month, day.day)] ?? [];
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("スケジュール管理"),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 受験日ウィジェット（設定があれば表示）
          if (examCountdownWidgets.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              // シンプルな背景色（必要に応じて変更可能）
              color: Colors.grey.shade200,
              child: Row(
                children: examCountdownWidgets,
              ),
            ),
          // カレンダーウィジェット
          TableCalendar<ScheduleItem>(
            firstDay: DateTime.utc(2000, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: CalendarFormat.month,
            headerStyle: HeaderStyle(
              titleCentered: true,
              titleTextFormatter: (date, locale) =>
                  DateFormat('yyyy/MM', locale).format(date),
            ),
            // 初期フォーマットを月表示に設定
            // availableCalendarFormats で、2週間表示や週表示を除外し、月表示のみを表示
            availableCalendarFormats: const {
              CalendarFormat.month: 'Month',
            },
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blueAccent,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.orangeAccent,
                shape: BoxShape.circle,
              ),
            ),
            eventLoader: getEventsForDay,
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return const SizedBox.shrink();
                return Positioned(
                  bottom: 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: events.map((event) {
                      return Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: event.isExamDate ? Colors.red : Colors.blue,
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),

          const Divider(),
          Expanded(
              child: _selectedDay == null
                  ? (scheduleList.isEmpty
                      ? const Center(
                          child: Text(
                            "スケジュールが設定されていません",
                            style: TextStyle(fontSize: 18),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // カレンダーで日付が選択されていない場合のみヘッダーを表示
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Text(
                                "スケジュール一覧",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // カレンダーで日付が選択されていない場合
                            Expanded(
                              child: ListView.builder(
                                itemCount: scheduleList.length,
                                itemBuilder: (context, index) {
                                  final event = scheduleList[index];
                                  return SwipeToDeleteCard(
                                    keyValue: ValueKey(event.id),
                                    onConfirm: () async {
                                      return await showDialog<bool>(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title: const Text("削除の確認"),
                                                content: const Text(
                                                    "このスケジュールを削除しますか？"),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, false),
                                                    child: const Text("キャンセル"),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                            context, true),
                                                    child: const Text("削除"),
                                                  ),
                                                ],
                                              );
                                            },
                                          ) ??
                                          false;
                                    },
                                    onDismissed: () async {
                                      await ref
                                          .read(scheduleProvider.notifier)
                                          .removeSchedule(event.id);
                                    },
                                    child: Card(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 4, horizontal: 8),
                                      child: ListTile(
                                        title: Text(event.title),
                                        subtitle: event.isExamDate
                                            ? Text(
                                                "${DateFormat('yyyy/MM/dd').format(event.startTime)}\n${event.description}",
                                              )
                                            : Text(
                                                "${DateFormat('yyyy/MM/dd HH:mm').format(event.startTime)} ～ "
                                                "${DateFormat('yyyy/MM/dd HH:mm').format(event.endTime)}\n${event.description}",
                                              ),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  AddEditSchedulePage(
                                                      scheduleItem: event),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ))
                  : (getEventsForDay(_selectedDay!).isEmpty
                      ? const Center(
                          child: Text(
                          "この日は何も設定されていません",
                          style: TextStyle(fontSize: 18),
                        ))
                      : Expanded(
                          child: ListView.builder(
                            // ヘッダーは表示せず、直接イベント一覧のListViewをレンダリング
                            itemCount: getEventsForDay(_selectedDay!).length,
                            itemBuilder: (context, index) {
                              final event =
                                  getEventsForDay(_selectedDay!)[index];
                              return SwipeToDeleteCard(
                                keyValue: ValueKey(event.id),
                                onConfirm: () async {
                                  return await showDialog<bool>(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            title: const Text("削除の確認"),
                                            content:
                                                const Text("このスケジュールを削除しますか？"),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, false),
                                                child: const Text("キャンセル"),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(
                                                    context, true),
                                                child: const Text("削除"),
                                              ),
                                            ],
                                          );
                                        },
                                      ) ??
                                      false;
                                },
                                onDismissed: () async {
                                  await ref
                                      .read(scheduleProvider.notifier)
                                      .removeSchedule(event.id);
                                },
                                child: Card(
                                  margin: const EdgeInsets.symmetric(
                                      vertical: 4, horizontal: 8),
                                  child: ListTile(
                                    title: Text(event.title),
                                    subtitle: event.isExamDate
                                        ? Text(
                                            "${DateFormat('yyyy/MM/dd').format(event.startTime)}\n${event.description}",
                                          )
                                        : Text(
                                            "${DateFormat('yyyy/MM/dd').add_jm().format(event.startTime)} ～ "
                                            "${DateFormat('yyyy/MM/dd').add_jm().format(event.endTime)}\n${event.description}",
                                          ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AddEditSchedulePage(
                                              scheduleItem: event),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ))),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // カレンダーで選択されていればその日付、なければ現在日時を利用
          final initialDate = _selectedDay ?? DateTime.now();
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => AddEditSchedulePage(initialDate: initialDate)),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// まず、2択のモードを区別するための列挙型を定義
enum ScheduleMode { exam, study }

class AddEditSchedulePage extends ConsumerStatefulWidget {
  final ScheduleItem? scheduleItem;

  /// 新規作成時の初期日付。もしセットされていれば、開始日時はその日付、修了日時はその7日後になります。
  final DateTime? initialDate;

  const AddEditSchedulePage({super.key, this.scheduleItem, this.initialDate});

  @override
  ConsumerState<AddEditSchedulePage> createState() =>
      _AddEditSchedulePageState();
}

class _AddEditSchedulePageState extends ConsumerState<AddEditSchedulePage> {
  final _titleController = TextEditingController();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _startTime;
  DateTime? _endTime;
  final _tasksController = TextEditingController();

  ScheduleMode _selectedMode = ScheduleMode.study;

  @override
  @override
  void initState() {
    super.initState();
    if (widget.scheduleItem != null) {
      // 既存スケジュール（編集モード）の場合は、保存されている内容をそのまま利用
      _titleController.text = widget.scheduleItem!.title;
      _subjectController.text = widget.scheduleItem!.subject;
      _descriptionController.text = widget.scheduleItem!.description;
      _startTime = widget.scheduleItem!.startTime;
      _endTime = widget.scheduleItem!.endTime;
      _tasksController.text = widget.scheduleItem!.tasks.join(", ");
      _selectedMode = widget.scheduleItem!.isExamDate
          ? ScheduleMode.exam
          : ScheduleMode.study;
    } else {
      // 新規追加の場合、常に「勉強タスクを設定する」を選択する
      _selectedMode = ScheduleMode.study;
      // もしカレンダーから初期日付が渡されていれば、それを開始日時にし、終了日時は1時間後に設定
      _startTime = widget.initialDate ?? DateTime.now();
      _endTime = (_startTime ?? DateTime.now()).add(const Duration(hours: 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.scheduleItem == null ? "スケジュール追加" : "スケジュール編集"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 基本情報入力欄
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "タイトル"),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: "詳細"),
            ),
            const SizedBox(height: 16),
            // ここで新たに2つのラジオボタンを表示
            Row(
              children: [
                Expanded(
                  child: RadioListTile<ScheduleMode>(
                    title: const Text("勉強タスクを設定する"),
                    value: ScheduleMode.study,
                    groupValue: _selectedMode,
                    onChanged: (value) {
                      setState(() {
                        _selectedMode = value!;
                      });
                    },
                  ),
                ),
                // AddEditSchedulePage 内の "受験日として設定する" のラジオボタン部分
                Expanded(
                  child: RadioListTile<ScheduleMode>(
                    title: const Text("受験日として設定する"),
                    value: ScheduleMode.exam,
                    groupValue: _selectedMode,
                    onChanged: (value) async {
                      if (value == ScheduleMode.exam) {
                        // 現在のスケジュール一覧を取得
                        final schedules = ref.read(scheduleProvider);
                        final now = DateTime.now();
                        // ※ここで、未来（今以降）の受験日スケジュールのみをカウント
                        int examCount = schedules
                            .where(
                                (e) => e.isExamDate && e.startTime.isAfter(now))
                            .length;
                        // 新規作成の場合：すでに未来の受験日スケジュールが3件以上なら、追加不可
                        if (widget.scheduleItem == null && examCount >= 3) {
                          await showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("受験日の設定制限"),
                              content: const Text("カレンダー上の受験日は3件まで設定可能です。"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("OK"),
                                ),
                              ],
                            ),
                          );
                          return;
                        }
                        // 編集の場合：
                        // 既存のスケジュールが受験日ではない状態から変更しようとする場合、
                        // 他の未来の受験日スケジュールの件数が既に3件以上なら変更不可
                        if (widget.scheduleItem != null &&
                            !widget.scheduleItem!.isExamDate &&
                            examCount >= 3) {
                          await showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("受験日の設定制限"),
                              content: const Text("カレンダー上の受験日は3件まで設定可能です。"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("OK"),
                                ),
                              ],
                            ),
                          );
                          return;
                        }
                      }
                      // チェックを問題なく通過した場合のみモードを切り替える
                      setState(() {
                        _selectedMode = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // _selectedMode によって入力フィールドを切り替え
            if (_selectedMode == ScheduleMode.exam)
              // 受験日モードの場合：受験日として１つの日付のみ選択（ここでは_startTimeを使用）
              ListTile(
                title: Text(
                    "受験日: ${DateFormat('yyyy/MM/dd').format(_startTime!)}"),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _startTime!,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        _startTime = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                          _startTime!.hour,
                          _startTime!.minute,
                        );
                      });
                    }
                  },
                ),
              )
            else ...[
              // 勉強タスクモードの場合：開始日時／終了日時／タスク入力欄をそのまま使用
              ListTile(
                title: Text(
                    "開始日時: ${DateFormat('yyyy/MM/dd').add_jm().format(_startTime!)}"),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _startTime!,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      TimeOfDay? time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(_startTime!),
                      );
                      if (time != null) {
                        setState(() {
                          _startTime = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                ),
              ),
              ListTile(
                title: Text(
                    "終了日時: ${DateFormat('yyyy/MM/dd').add_jm().format(_endTime!)}"),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _endTime!,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      TimeOfDay? time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(_endTime!),
                      );
                      if (time != null) {
                        setState(() {
                          _endTime = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            // 既存の保存ボタン部分を以下のように置き換えます
            widget.scheduleItem == null
                ? ElevatedButton(
                    onPressed: () {
                      final title = _titleController.text.trim();
                      final subject = _subjectController.text.trim();
                      final description = _descriptionController.text.trim();
                      if (title.isEmpty ||
                          _startTime == null ||
                          (_selectedMode == ScheduleMode.study &&
                              _endTime == null)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("すべての項目を入力してください")),
                        );
                        return;
                      }
                      final tasks = _tasksController.text
                          .split(",")
                          .map((e) => e.trim())
                          .where((element) => element.isNotEmpty)
                          .toList();
                      final newItem = ScheduleItem(
                        id: widget.scheduleItem?.id ?? UniqueKey().toString(),
                        title: title,
                        subject: subject,
                        startTime: _startTime!,
                        endTime: _selectedMode == ScheduleMode.study
                            ? _endTime!
                            : _startTime!.add(const Duration(days: 7)),
                        description: description,
                        tasks: _selectedMode == ScheduleMode.study ? tasks : [],
                        isExamDate: _selectedMode == ScheduleMode.exam,
                      );
                      ref.read(scheduleProvider.notifier).addSchedule(newItem);
                      Navigator.pop(context);
                    },
                    child: const Text("保存"),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                          onPressed: () async {
                            // 削除前の確認ダイアログ
                            bool confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text("削除の確認"),
                                      content:
                                          const Text("本当にこのスケジュールを削除しますか？"),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text("キャンセル"),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text("削除"),
                                        ),
                                      ],
                                    );
                                  },
                                ) ??
                                false;
                            if (confirmed) {
                              await ref
                                  .read(scheduleProvider.notifier)
                                  .removeSchedule(widget.scheduleItem!.id);
                              Navigator.pop(context);
                            }
                          },
                          child: const Text("削除"),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final title = _titleController.text.trim();
                            final subject = _subjectController.text.trim();
                            final description =
                                _descriptionController.text.trim();
                            if (title.isEmpty ||
                                _startTime == null ||
                                (_selectedMode == ScheduleMode.study &&
                                    _endTime == null)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("すべての項目を入力してください")),
                              );
                              return;
                            }
                            final tasks = _tasksController.text
                                .split(",")
                                .map((e) => e.trim())
                                .where((element) => element.isNotEmpty)
                                .toList();
                            final newItem = ScheduleItem(
                              id: widget.scheduleItem!.id,
                              title: title,
                              subject: subject,
                              startTime: _startTime!,
                              endTime: _selectedMode == ScheduleMode.study
                                  ? _endTime!
                                  : _startTime!.add(const Duration(days: 7)),
                              description: description,
                              tasks: _selectedMode == ScheduleMode.study
                                  ? tasks
                                  : [],
                              isExamDate: _selectedMode == ScheduleMode.exam,
                            );
                            ref
                                .read(scheduleProvider.notifier)
                                .updateSchedule(newItem);
                            Navigator.pop(context);
                          },
                          child: const Text("保存"),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// アプリエントリーポイント：main() と MyApp
/// ─────────────────────────────────────────────────────────
/// Flutterの初期化とRiverpodのProviderScopeでアプリ全体をラップし、
/// MyAppウィジェットを起動します。
/// ---------------------------------------------------------------------------
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    Phoenix(
      child: const ProviderScope(
        child: MyApp(),
      ),
    ),
  );
}

/// [MyApp]
/// ─────────────────────────────────────────────────────────
/// アプリ全体のテーマ設定やホーム画面(SearchPage)を設定するルートウィジェットです。
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final useMaterial3 = ref.watch(useMaterial3Provider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '単語検索＆保存アプリ',
      theme: ThemeData(
        fontFamily: 'Murecho',
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        useMaterial3: useMaterial3,
      ),
      darkTheme: ThemeData(
        fontFamily: 'Murecho',
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        useMaterial3: useMaterial3,
      ),
      themeMode: themeMode,
      home: const SearchPage(),
    );
  }
}
