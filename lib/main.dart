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

// タイマーの状態を表すクラス
class PomodoroTimerState {
  final int totalDuration; // 設定された合計時間（秒）
  final int remainingTime; // 残り時間（秒）
  final bool isRunning; // 動作中かどうか

  PomodoroTimerState({
    required this.totalDuration,
    required this.remainingTime,
    required this.isRunning,
  });

  PomodoroTimerState copyWith({
    int? totalDuration,
    int? remainingTime,
    bool? isRunning,
  }) {
    return PomodoroTimerState(
      totalDuration: totalDuration ?? this.totalDuration,
      remainingTime: remainingTime ?? this.remainingTime,
      isRunning: isRunning ?? this.isRunning,
    );
  }
}

class PomodoroTimerNotifier extends StateNotifier<PomodoroTimerState> {
  Timer? _timer;

  PomodoroTimerNotifier()
      : super(PomodoroTimerState(
            totalDuration: 1800, remainingTime: 1800, isRunning: false));

  // タイマーを開始する
  void startTimer() {
    _timer?.cancel();
    state = state.copyWith(isRunning: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingTime <= 1) {
        timer.cancel();
        state = state.copyWith(remainingTime: 0, isRunning: false);
        // 必要であれば、タイムアップ時の通知処理等をここで追加
      } else {
        state = state.copyWith(remainingTime: state.remainingTime - 1);
      }
    });
  }

  // タイマーを一時停止する
  void pauseTimer() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  // タイマーをリセットする
  void resetTimer() {
    _timer?.cancel();
    state =
        state.copyWith(remainingTime: state.totalDuration, isRunning: false);
  }

  // タイマーの合計時間（秒）を変更する（カスタム設定など用）
  void setTotalDuration(int durationInSeconds) {
    _timer?.cancel();
    state = PomodoroTimerState(
        totalDuration: durationInSeconds,
        remainingTime: durationInSeconds,
        isRunning: false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final pomodoroTimerProvider =
    StateNotifierProvider<PomodoroTimerNotifier, PomodoroTimerState>(
  (ref) => PomodoroTimerNotifier(),
);

class PomodoroTimerWidget extends ConsumerWidget {
  const PomodoroTimerWidget({super.key});

  // 推奨設定オプション（秒単位）
  final List<Map<String, dynamic>> recommendedOptions = const [
    {'label': '30分', 'value': 1800},
    {'label': '1時間', 'value': 3600},
    {'label': '2時間', 'value': 7200},
  ];

  // 確認ダイアログを表示するヘルパーメソッド
  Future<bool> _showConfirmChangeDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("確認"),
              content: const Text("タイマーが動作中です。設定変更するとタイマーがリセットされます。\n変更しますか？"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("キャンセル"),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("変更する"),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(pomodoroTimerProvider);
    final timerNotifier = ref.read(pomodoroTimerProvider.notifier);

    // 進捗割合（残り時間の割合）
    final progress = (timerState.totalDuration - timerState.remainingTime) /
        timerState.totalDuration;

    // 残り時間を「分:秒」で表示
    String timerText() {
      final int minutes = timerState.remainingTime ~/ 60;
      final int seconds = timerState.remainingTime % 60;
      return "$minutes:${seconds.toString().padLeft(2, '0')}";
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // プログレスインジケーターと残り時間テキスト
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey.shade300,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                  ),
                ),
                Text(
                  timerText(),
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 推奨設定の ChoiceChip
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: recommendedOptions.map((option) {
                final int optionValue = option['value'];
                final String label = option['label'];
                final bool selected = timerState.totalDuration == optionValue;
                return ChoiceChip(
                  label: Text(label),
                  selected: selected,
                  selectedColor: Colors.blueAccent,
                  onSelected: (bool value) async {
                    // もしタイマーが動作中なら、変更確認ダイアログを表示する
                    if (timerState.isRunning) {
                      bool confirmed = await _showConfirmChangeDialog(context);
                      if (!confirmed) return;
                    }
                    // タイマーが動作中でも、ユーザーが確認した場合は設定変更（リセット）
                    timerNotifier.setTotalDuration(optionValue);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            // カスタム設定ボタン
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    // 同様に、もしタイマーが動作中なら確認ダイアログを表示
                    if (timerState.isRunning) {
                      bool confirmed = await _showConfirmChangeDialog(context);
                      if (!confirmed) return;
                    }
                    final controller = TextEditingController();
                    await showDialog<void>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text("カスタム設定 (分)"),
                          content: TextField(
                            controller: controller,
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(hintText: "例: 45"),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("キャンセル"),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                if (controller.text.trim().isNotEmpty) {
                                  final int? minutes =
                                      int.tryParse(controller.text.trim());
                                  if (minutes != null && minutes > 0) {
                                    timerNotifier
                                        .setTotalDuration(minutes * 60);
                                  }
                                }
                                Navigator.pop(context);
                              },
                              child: const Text("設定"),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: const Text("カスタム設定"),
                ),
              ],
            ),
            const Divider(height: 24),
            // タイマー操作ボタン
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: timerState.isRunning
                      ? timerNotifier.pauseTimer
                      : timerNotifier.startTimer,
                  child: Text(timerState.isRunning ? "一時停止" : "開始"),
                ),
                ElevatedButton(
                  onPressed: timerNotifier.resetTimer,
                  child: const Text("リセット"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

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
                                      subtitle: Text(
                                        "${DateFormat.yMd().add_jm().format(event.startTime)} ～ "
                                        "${DateFormat.yMd().add_jm().format(event.endTime)}\n${event.description}",
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
                          ),
                        ],
                      ))
                : (getEventsForDay(_selectedDay!).isEmpty
                    ? const Center(
                        child: Text(
                        "この日は何も設定されていません",
                        style: TextStyle(fontSize: 18),
                      ))
                    : ListView.builder(
                        // ヘッダーは表示せず、直接イベント一覧のListViewをレンダリング
                        itemCount: getEventsForDay(_selectedDay!).length,
                        itemBuilder: (context, index) {
                          final event = getEventsForDay(_selectedDay!)[index];
                          return SwipeToDeleteCard(
                            keyValue: ValueKey(event.id),
                            onConfirm: () async {
                              return await showDialog<bool>(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: const Text("削除の確認"),
                                        content: const Text("このスケジュールを削除しますか？"),
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
                                subtitle: Text(
                                  "${DateFormat.yMd().add_jm().format(event.startTime)} ～ "
                                  "${DateFormat.yMd().add_jm().format(event.endTime)}\n科目: ${event.subject}",
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
                      )),
          ),
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
                Expanded(
                  child: RadioListTile<ScheduleMode>(
                    title: const Text("受験日として設定する"),
                    value: ScheduleMode.exam,
                    groupValue: _selectedMode,
                    onChanged: (value) async {
                      if (value == ScheduleMode.exam) {
                        // まず現在のスケジュール一覧を取得
                        final schedules = ref.read(scheduleProvider);
                        // 受験日として設定されているスケジュール件数をカウント
                        int examCount =
                            schedules.where((e) => e.isExamDate).length;

                        // 新規作成の場合：既に3件以上設定されているなら追加不可
                        if (widget.scheduleItem == null && examCount >= 3) {
                          await showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("受験日の設定制限"),
                              content: const Text("受験日の設定は最大で3件までです。"),
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
                        // 編集の場合：既存スケジュールが受験日でなければ（つまりstudyから変更する場合）、
                        // 他の受験日スケジュールの件数が3件以上なら変更不可
                        if (widget.scheduleItem != null &&
                            !widget.scheduleItem!.isExamDate &&
                            examCount >= 3) {
                          await showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("受験日の設定制限"),
                              content: const Text("受験日の設定は最大で3件までです。"),
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
                      // 上記のチェックを問題なく通過した場合のみ、モードを切り替える
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
                title: Text("受験日: ${DateFormat.yMd().format(_startTime!)}"),
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
                    "開始日時: ${DateFormat.yMd().add_jm().format(_startTime!)}"),
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
                    "終了日時: ${DateFormat.yMd().add_jm().format(_endTime!)}"),
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
                          description.isEmpty ||
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
                          onPressed: () {
                            final title = _titleController.text.trim();
                            final subject = _subjectController.text.trim();
                            final description =
                                _descriptionController.text.trim();
                            if (title.isEmpty ||
                                description.isEmpty ||
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
                      const SizedBox(width: 16),
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
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

class PomodoroTimerPage extends StatefulWidget {
  const PomodoroTimerPage({super.key});

  @override
  State<PomodoroTimerPage> createState() => _PomodoroTimerPageState();
}

class _PomodoroTimerPageState extends State<PomodoroTimerPage> {
  static const int pomodoroDuration = 1500; // 25分 = 1500秒
  int remainingTime = pomodoroDuration;
  Timer? timer;
  bool isRunning = false;

  void startTimer() {
    timer?.cancel();
    setState(() {
      isRunning = true;
    });
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingTime <= 0) {
        timer.cancel();
        setState(() {
          isRunning = false;
        });
        // ここでリマインダーや通知機能と連携可能
        return;
      }
      setState(() {
        remainingTime--;
      });
    });
  }

  void pauseTimer() {
    timer?.cancel();
    setState(() {
      isRunning = false;
    });
  }

  void resetTimer() {
    timer?.cancel();
    setState(() {
      remainingTime = pomodoroDuration;
      isRunning = false;
    });
  }

  String get timerText {
    final minutes = remainingTime ~/ 60;
    final seconds = remainingTime % 60;
    return "$minutes:${seconds.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ポモドーロタイマー"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              timerText,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: isRunning ? pauseTimer : startTimer,
                  child: Text(isRunning ? "一時停止" : "開始"),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: resetTimer,
                  child: const Text("リセット"),
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
