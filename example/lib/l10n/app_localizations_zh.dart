// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Riverpod DevTools Tracker 示範';

  @override
  String get homeTitle => 'Riverpod DevTools Tracker 範例';

  @override
  String get usageInstructions => '🔍 使用說明';

  @override
  String get instruction1 => '1. 點擊下方的範例卡片進入各個示範頁面';

  @override
  String get instruction2 => '2. 操作 UI 元件觸發狀態變化';

  @override
  String get instruction3 => '3. 打開 DevTools 擴展查看詳細的狀態變化追蹤';

  @override
  String get instruction4 => '4. 可以看到觸發變化的確切代碼位置和調用堆疊';

  @override
  String get counterExampleTitle => '計數器範例';

  @override
  String get counterExampleDesc => '展示基本的狀態變化追蹤\n包含計數器及其衍生狀態';

  @override
  String get userExampleTitle => '使用者資料範例';

  @override
  String get userExampleDesc => '展示複雜物件的狀態變化\n追蹤登入狀態和個人資料更新';

  @override
  String get asyncExampleTitle => '非同步資料範例';

  @override
  String get asyncExampleDesc => '展示 AsyncValue 的狀態追蹤\n包含載入、成功、錯誤狀態';

  @override
  String get todoExampleTitle => '待辦事項範例';

  @override
  String get todoExampleDesc => '展示列表的增刪改操作追蹤\n完整的 CRUD 操作示範';

  @override
  String get counterScreenTitle => '計數器範例';

  @override
  String get currentCount => '當前計數:';

  @override
  String get doubleValue => '倍數值';

  @override
  String get isEven => '是否為偶數';

  @override
  String get yes => '是';

  @override
  String get no => '否';

  @override
  String get decrease => '減少';

  @override
  String get increase => '增加';

  @override
  String get reset => '重置';

  @override
  String get userScreenTitle => '使用者資料範例';

  @override
  String get loggedIn => '已登入';

  @override
  String get notLoggedIn => '未登入';

  @override
  String get name => '姓名';

  @override
  String get age => '年齡';

  @override
  String get email => 'Email';

  @override
  String get login => '登入';

  @override
  String get changeName => '更改姓名';

  @override
  String get increaseAge => '增加年齡';

  @override
  String get logout => '登出';

  @override
  String get changeNameDialogTitle => '更改姓名';

  @override
  String get newName => '新姓名';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '確定';

  @override
  String get asyncScreenTitle => '非同步資料範例';

  @override
  String get futureProviderExample => 'FutureProvider 範例';

  @override
  String get loadingSuccess => '載入成功';

  @override
  String get loading => '載入中...';

  @override
  String get loadingFailed => '載入失敗';

  @override
  String get reloadInvalidate => '重新載入 (invalidate)';

  @override
  String get stateNotifierAsyncExample => 'StateNotifier + AsyncValue 範例';

  @override
  String get refreshData => '刷新資料';

  @override
  String get todoScreenTitle => '待辦事項範例';

  @override
  String get noTodosMessage => '目前沒有待辦事項\n點擊下方按鈕新增';

  @override
  String get clearCompleted => '清除已完成';

  @override
  String get addTodo => '新增待辦事項';

  @override
  String get pending => '待完成';

  @override
  String get completed => '已完成';

  @override
  String get addTodoDialogTitle => '新增待辦事項';

  @override
  String get todoContent => '事項內容';

  @override
  String get add => '新增';

  @override
  String get defaultUserName => '張小明';

  @override
  String get languageSelector => '語言';

  @override
  String get languageEnglish => '英文';

  @override
  String get languageTraditionalChinese => '繁體中文';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get appTitle => 'Riverpod DevTools Tracker 示範';

  @override
  String get homeTitle => 'Riverpod DevTools Tracker 範例';

  @override
  String get usageInstructions => '🔍 使用說明';

  @override
  String get instruction1 => '1. 點擊下方的範例卡片進入各個示範頁面';

  @override
  String get instruction2 => '2. 操作 UI 元件觸發狀態變化';

  @override
  String get instruction3 => '3. 打開 DevTools 擴展查看詳細的狀態變化追蹤';

  @override
  String get instruction4 => '4. 可以看到觸發變化的確切代碼位置和調用堆疊';

  @override
  String get counterExampleTitle => '計數器範例';

  @override
  String get counterExampleDesc => '展示基本的狀態變化追蹤\n包含計數器及其衍生狀態';

  @override
  String get userExampleTitle => '使用者資料範例';

  @override
  String get userExampleDesc => '展示複雜物件的狀態變化\n追蹤登入狀態和個人資料更新';

  @override
  String get asyncExampleTitle => '非同步資料範例';

  @override
  String get asyncExampleDesc => '展示 AsyncValue 的狀態追蹤\n包含載入、成功、錯誤狀態';

  @override
  String get todoExampleTitle => '待辦事項範例';

  @override
  String get todoExampleDesc => '展示列表的增刪改操作追蹤\n完整的 CRUD 操作示範';

  @override
  String get counterScreenTitle => '計數器範例';

  @override
  String get currentCount => '當前計數:';

  @override
  String get doubleValue => '倍數值';

  @override
  String get isEven => '是否為偶數';

  @override
  String get yes => '是';

  @override
  String get no => '否';

  @override
  String get decrease => '減少';

  @override
  String get increase => '增加';

  @override
  String get reset => '重置';

  @override
  String get userScreenTitle => '使用者資料範例';

  @override
  String get loggedIn => '已登入';

  @override
  String get notLoggedIn => '未登入';

  @override
  String get name => '姓名';

  @override
  String get age => '年齡';

  @override
  String get email => 'Email';

  @override
  String get login => '登入';

  @override
  String get changeName => '更改姓名';

  @override
  String get increaseAge => '增加年齡';

  @override
  String get logout => '登出';

  @override
  String get changeNameDialogTitle => '更改姓名';

  @override
  String get newName => '新姓名';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '確定';

  @override
  String get asyncScreenTitle => '非同步資料範例';

  @override
  String get futureProviderExample => 'FutureProvider 範例';

  @override
  String get loadingSuccess => '載入成功';

  @override
  String get loading => '載入中...';

  @override
  String get loadingFailed => '載入失敗';

  @override
  String get reloadInvalidate => '重新載入 (invalidate)';

  @override
  String get stateNotifierAsyncExample => 'StateNotifier + AsyncValue 範例';

  @override
  String get refreshData => '刷新資料';

  @override
  String get todoScreenTitle => '待辦事項範例';

  @override
  String get noTodosMessage => '目前沒有待辦事項\n點擊下方按鈕新增';

  @override
  String get clearCompleted => '清除已完成';

  @override
  String get addTodo => '新增待辦事項';

  @override
  String get pending => '待完成';

  @override
  String get completed => '已完成';

  @override
  String get addTodoDialogTitle => '新增待辦事項';

  @override
  String get todoContent => '事項內容';

  @override
  String get add => '新增';

  @override
  String get defaultUserName => '張小明';

  @override
  String get languageSelector => '語言';

  @override
  String get languageEnglish => '英文';

  @override
  String get languageTraditionalChinese => '繁體中文';
}
