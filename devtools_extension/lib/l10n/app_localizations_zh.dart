// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Riverpod 狀態檢視器';

  @override
  String get connected => '已連接';

  @override
  String get disconnected => '未連接';

  @override
  String get clearHistory => '清除歷史';

  @override
  String get filterProviders => '篩選 Provider...';

  @override
  String get allHistory => '全部歷史';

  @override
  String get latestOnly => '僅最新';

  @override
  String get filterChangeTypes => '篩選變更類型';

  @override
  String get changeTypeAdd => '新增';

  @override
  String get changeTypeUpdate => '更新';

  @override
  String get changeTypeDispose => '銷毀';

  @override
  String get changeTypeError => '錯誤';

  @override
  String changesCount(int count) {
    return '$count 次變更';
  }

  @override
  String get connectingToApp => '正在連接應用程式...';

  @override
  String get makeSureAppRunning => '請確保您的應用程式正在運行並包含 RiverpodDevToolsObserver';

  @override
  String get noStateChangesYet => '尚無狀態變更';

  @override
  String get providerStateChangesWillAppearHere => 'Provider 狀態變更將顯示在此處';

  @override
  String get selectProviderToViewDetails => '選擇一個 provider 以查看詳細資訊';

  @override
  String get changeSource => '變更來源';

  @override
  String get callChain => '調用鏈';

  @override
  String get stackTrace => '堆疊追蹤';

  @override
  String get stateChange => '狀態變更';

  @override
  String get before => '變更前';

  @override
  String get after => '變更後';

  @override
  String get expand => '展開';

  @override
  String get collapse => '收起';

  @override
  String get copyLocation => '複製位置';

  @override
  String itemsCount(int count) {
    return '$count 個項目';
  }

  @override
  String get selectProviders => '選擇 Provider';

  @override
  String get clearAll => '全部清除';

  @override
  String get clearAllFilters => '清除所有篩選';

  @override
  String get showAutoComputed => '顯示自動計算';

  @override
  String get hideAutoComputed => '隱藏自動計算';

  @override
  String get derivedProviderUpdates => '衍生 Provider 更新';

  @override
  String get autoComputed => '自動計算';

  @override
  String get clickToExpandFullContent => '點擊展開完整內容...';
}
