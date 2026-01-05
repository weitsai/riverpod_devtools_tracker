import 'dart:async';

import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';
import 'package:vm_service/vm_service.dart' hide Stack;

import 'models/provider_state_info.dart';
import 'widgets/provider_list_tile.dart';
import 'widgets/state_detail_panel.dart';
import 'theme/extension_theme.dart';

class RiverpodDevToolsExtension extends StatefulWidget {
  const RiverpodDevToolsExtension({super.key});

  @override
  State<RiverpodDevToolsExtension> createState() =>
      _RiverpodDevToolsExtensionState();
}

class _RiverpodDevToolsExtensionState extends State<RiverpodDevToolsExtension> {
  final List<ProviderStateInfo> _providerStates = [];
  final Map<String, ProviderStateInfo> _latestStates = {};
  ProviderStateInfo? _selectedProvider;
  StreamSubscription<Event>? _extensionEventSubscription;
  bool _isConnected = false;
  String _searchText = ''; // 搜尋框輸入文字
  final Set<String> _selectedProviders = {}; // 已選中的 providers（複選）
  bool _showAllHistory = true;
  VoidCallback? _connectionListener;

  // 狀態類型篩選
  final Set<String> _selectedChangeTypes = {
    'add',
    'update',
    'dispose',
    'error',
  };

  // 隱藏自動計算的更新（預設隱藏）
  bool _hideAutoComputed = true;

  // 搜尋建議
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  final LayerLink _searchLayerLink = LayerLink();
  OverlayEntry? _searchOverlay;

  // 篩選器 overlay
  final LayerLink _filterLayerLink = LayerLink();
  OverlayEntry? _filterOverlay;

  @override
  void initState() {
    super.initState();
    _setupConnectionListener();
    _searchFocusNode.addListener(_onSearchFocusChanged);
  }

  void _onSearchFocusChanged() {
    if (_searchFocusNode.hasFocus) {
      _showSearchSuggestionsOverlay();
    }
    // 不自動關閉 overlay，讓用戶可以複選
  }

  void _setupConnectionListener() {
    _connectionListener = () {
      final manager = serviceManager;
      if (manager.connectedState.value.connected) {
        _onServiceConnected();
      } else {
        if (mounted) {
          setState(() {
            _isConnected = false;
          });
        }
      }
    };

    serviceManager.connectedState.addListener(_connectionListener!);

    if (serviceManager.connectedState.value.connected) {
      _onServiceConnected();
    }
  }

  Future<void> _onServiceConnected() async {
    try {
      final manager = serviceManager;
      final service = manager.service;

      if (service == null) {
        debugPrint('Service is null even though connected');
        return;
      }

      _extensionEventSubscription?.cancel();

      _extensionEventSubscription = service.onExtensionEvent.listen((event) {
        debugPrint('Received extension event: ${event.extensionKind}');
        if (event.extensionKind == 'riverpod_state_change') {
          _handleStateChange(event);
        }
      });

      try {
        await service.streamListen(EventStreams.kExtension);
        debugPrint('Extension stream listening enabled');
      } catch (e) {
        debugPrint('streamListen error (may already be listening): $e');
      }

      if (mounted) {
        setState(() {
          _isConnected = true;
        });
      }
    } catch (e) {
      debugPrint('Error during service connection: $e');
    }
  }

  void _handleStateChange(Event event) {
    final data = event.extensionData?.data;
    if (data == null) return;

    try {
      final stateInfo = ProviderStateInfo.fromJson(data);
      setState(() {
        _providerStates.insert(0, stateInfo);
        _latestStates[stateInfo.providerName] = stateInfo;

        if (_providerStates.length > 500) {
          _providerStates.removeLast();
        }
      });
    } catch (e) {
      debugPrint('Error parsing state change: $e');
    }
  }

  List<ProviderStateInfo> get _filteredProviders {
    var states =
        _showAllHistory ? _providerStates : _latestStates.values.toList();

    // 篩選狀態類型
    states =
        states
            .where((s) => _selectedChangeTypes.contains(s.changeType))
            .toList();

    // 隱藏自動計算的更新（沒有 location 的 update）
    if (_hideAutoComputed) {
      states =
          states.where((s) {
            // 非 update 類型都保留
            if (s.changeType != 'update') return true;
            // 有 location 的 update 都保留
            if (s.hasLocation) {
              return true;
            }
            // 異步 Provider 的完成更新也保留（即使沒有 location）
            // 檢查值是否為 AsyncValue 類型
            if (_isAsyncValueUpdate(s)) {
              return true;
            }
            // 其他沒有 location 的 update（如 derived provider 自動計算）過濾掉
            return false;
          }).toList();
    }

    // 篩選已選中的 providers（複選）
    if (_selectedProviders.isNotEmpty) {
      states =
          states
              .where((s) => _selectedProviders.contains(s.providerName))
              .toList();
    }

    return states.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// 檢查是否為異步值的更新（FutureProvider/StreamProvider/AsyncNotifierProvider）
  bool _isAsyncValueUpdate(ProviderStateInfo s) {
    // 檢查 previousValue 或 currentValue 是否包含 AsyncValue 模式
    final asyncPattern = RegExp(r'Async(Loading|Data|Error)<');

    String? getValueString(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      if (value is Map) {
        // 檢查 {type, value} 格式
        final type = value['type'];
        final val = value['value'];
        if (type is String && asyncPattern.hasMatch(type)) return type;
        if (val is String && asyncPattern.hasMatch(val)) return val;
      }
      return value.toString();
    }

    final prevStr = getValueString(s.previousValue);
    final currStr = getValueString(s.currentValue);

    return (prevStr != null && asyncPattern.hasMatch(prevStr)) ||
        (currStr != null && asyncPattern.hasMatch(currStr));
  }

  /// 取得所有不重複的 provider 名稱
  List<String> get _allProviderNames {
    final names = <String>{};
    for (final state in _providerStates) {
      names.add(state.providerName);
    }
    return names.toList()..sort();
  }

  /// 取得符合搜尋條件的 provider 建議
  List<String> get _searchSuggestions {
    final allNames = _allProviderNames;
    if (_searchText.isEmpty) {
      return allNames;
    }
    return allNames
        .where((name) => name.toLowerCase().contains(_searchText.toLowerCase()))
        .toList();
  }

  int get _totalChanges => _providerStates.length;

  @override
  void dispose() {
    if (_connectionListener != null) {
      serviceManager.connectedState.removeListener(_connectionListener!);
    }
    _extensionEventSubscription?.cancel();
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchFocusNode.dispose();
    _searchController.dispose();
    _hideSearchSuggestionsOverlay();
    _hideFilterOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ExtensionTheme.darkTheme,
      home: Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isConnected ? _buildContent() : _buildConnectionStatus(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF161B22),
        border: Border(bottom: BorderSide(color: Color(0xFF30363D), width: 1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.data_object,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Riverpod State Inspector',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              _buildStatusIndicator(),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFF8B949E),
                ),
                onPressed: _clearHistory,
                tooltip: 'Clear History',
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 已選中的 provider chips
          if (_selectedProviders.isNotEmpty)
            Container(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children:
                    _selectedProviders.map((provider) {
                      return Chip(
                        label: Text(provider),
                        labelStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        backgroundColor: const Color(
                          0xFF6366F1,
                        ).withValues(alpha: 0.3),
                        deleteIconColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF6366F1)),
                        onDeleted: () {
                          setState(() {
                            _selectedProviders.remove(provider);
                          });
                        },
                      );
                    }).toList(),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: CompositedTransformTarget(
                  link: _searchLayerLink,
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: (value) {
                      setState(() => _searchText = value);
                      _showSearchSuggestionsOverlay();
                    },
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Filter Providers...',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      prefixIcon: Icon(
                        Icons.filter_alt,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_searchText.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                setState(() {
                                  _searchText = '';
                                  _searchController.clear();
                                });
                                _showSearchSuggestionsOverlay();
                              },
                            ),
                          if (_selectedProviders.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              tooltip: 'Clear All Filters',
                              onPressed: () {
                                setState(() {
                                  _selectedProviders.clear();
                                });
                              },
                            ),
                        ],
                      ),
                      filled: true,
                      fillColor: const Color(0xFF0D1117),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF30363D)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF30363D)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF6366F1)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF238636).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_totalChanges changes',
                  style: const TextStyle(
                    color: Color(0xFF3FB950),
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text(_showAllHistory ? 'All History' : 'Latest Only'),
                selected: _showAllHistory,
                onSelected: (value) => setState(() => _showAllHistory = value),
                selectedColor: const Color(0xFF6366F1).withValues(alpha: 0.3),
                checkmarkColor: const Color(0xFF6366F1),
                labelStyle: TextStyle(
                  color:
                      _showAllHistory
                          ? const Color(0xFF6366F1)
                          : const Color(0xFF8B949E),
                ),
                side: BorderSide(
                  color:
                      _showAllHistory
                          ? const Color(0xFF6366F1)
                          : const Color(0xFF30363D),
                ),
              ),
              const SizedBox(width: 8),
              CompositedTransformTarget(
                link: _filterLayerLink,
                child: IconButton(
                  icon: Icon(
                    Icons.filter_list,
                    color:
                        _selectedChangeTypes.length < 4
                            ? const Color(0xFF6366F1)
                            : const Color(0xFF8B949E),
                  ),
                  tooltip: 'Filter Change Types',
                  onPressed: () {
                    if (_filterOverlay == null) {
                      _showFilterOverlay();
                    } else {
                      _hideFilterOverlay();
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                _isConnected
                    ? const Color(0xFF3FB950)
                    : const Color(0xFFF85149),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          _isConnected ? 'Connected' : 'Disconnected',
          style: TextStyle(
            color:
                _isConnected
                    ? const Color(0xFF3FB950)
                    : const Color(0xFFF85149),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionStatus() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF6366F1)),
          const SizedBox(height: 16),
          Text(
            'Connecting to application...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Make sure your app is running with RiverpodDevToolsObserver',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_providerStates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No state changes yet',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Provider state changes will appear here',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return SelectionArea(
      child: Row(
        children: [
          SizedBox(width: 400, child: _buildProviderList()),
          Container(width: 1, color: const Color(0xFF30363D)),
          Expanded(
            child:
                _selectedProvider != null
                    ? Align(
                      alignment: Alignment.topCenter,
                      child: StateDetailPanel(stateInfo: _selectedProvider!),
                    )
                    : Center(
                      child: Text(
                        'Select a provider to view details',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderList() {
    final providers = _filteredProviders;
    final totalCount = _providerStates.length;

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: providers.length,
      itemBuilder: (context, index) {
        final provider = providers[index];
        final isSelected = _selectedProvider?.id == provider.id;

        final changeIndex = _providerStates.indexOf(provider);
        final changeNumber = changeIndex >= 0 ? totalCount - changeIndex : null;

        return ProviderListTile(
          stateInfo: provider,
          isSelected: isSelected,
          changeNumber: changeNumber,
          onTap: () => setState(() => _selectedProvider = provider),
        );
      },
    );
  }

  void _clearHistory() {
    setState(() {
      _providerStates.clear();
      _latestStates.clear();
      _selectedProvider = null;
    });
  }

  /// 顯示篩選器 overlay
  void _showFilterOverlay() {
    final overlay = Overlay.of(context);
    _filterOverlay = OverlayEntry(
      builder:
          (context) => GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _hideFilterOverlay,
            child: Stack(
              children: [
                Positioned(
                  right: 16,
                  top: 130,
                  child: GestureDetector(
                    onTap: () {}, // 防止點擊菜單本身時關閉
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFF161B22),
                      child: Container(
                        width: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF30363D)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Color(0xFF30363D)),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.filter_list,
                                    color: Color(0xFF8B949E),
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Filter Change Types',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildFilterCheckbox('add', '➕ Add'),
                            _buildFilterCheckbox('update', '🔄 Update'),
                            _buildFilterCheckbox('dispose', '🗑️ Dispose'),
                            _buildFilterCheckbox('error', '❌ Error'),
                            const Divider(height: 1, color: Color(0xFF30363D)),
                            _buildAutoComputedToggle(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
    overlay.insert(_filterOverlay!);
  }

  /// 建立篩選器 checkbox
  Widget _buildFilterCheckbox(String type, String label) {
    final isSelected = _selectedChangeTypes.contains(type);
    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            // 至少要保留一個選項
            if (_selectedChangeTypes.length > 1) {
              _selectedChangeTypes.remove(type);
            }
          } else {
            _selectedChangeTypes.add(type);
          }
        });
        // 重新構建 overlay 以更新 UI
        _rebuildFilterOverlay();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_box : Icons.check_box_outline_blank,
              color:
                  isSelected
                      ? const Color(0xFF6366F1)
                      : const Color(0xFF8B949E),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF6366F1) : Colors.white,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 隱藏篩選器 overlay
  void _hideFilterOverlay() {
    _filterOverlay?.remove();
    _filterOverlay = null;
  }

  /// 重新構建篩選器 overlay
  void _rebuildFilterOverlay() {
    if (_filterOverlay != null) {
      _hideFilterOverlay();
      _showFilterOverlay();
    }
  }

  /// 建立自動計算切換選項
  Widget _buildAutoComputedToggle() {
    return InkWell(
      onTap: () {
        setState(() {
          _hideAutoComputed = !_hideAutoComputed;
        });
        // 重新構建 overlay 以更新 UI
        _rebuildFilterOverlay();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              _hideAutoComputed ? Icons.visibility_off : Icons.visibility,
              color:
                  _hideAutoComputed
                      ? const Color(0xFF8B949E)
                      : const Color(0xFF6366F1),
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _hideAutoComputed
                        ? 'Show auto-computed'
                        : 'Hide auto-computed',
                    style: TextStyle(
                      color:
                          _hideAutoComputed
                              ? Colors.white
                              : const Color(0xFF6366F1),
                      fontSize: 13,
                    ),
                  ),
                  const Text(
                    'Derived provider updates',
                    style: TextStyle(color: Color(0xFF6E7681), fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 顯示搜尋建議覆蓋層
  void _showSearchSuggestionsOverlay() {
    _hideSearchSuggestionsOverlay();

    final suggestions = _searchSuggestions;
    if (suggestions.isEmpty) return;

    final overlay = Overlay.of(context);
    _searchOverlay = OverlayEntry(
      builder:
          (context) => GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              _searchFocusNode.unfocus();
              _hideSearchSuggestionsOverlay();
            },
            child: Stack(
              children: [
                Positioned(
                  width: 400,
                  child: CompositedTransformFollower(
                    link: _searchLayerLink,
                    targetAnchor: Alignment.bottomLeft,
                    followerAnchor: Alignment.topLeft,
                    offset: const Offset(0, 8),
                    child: GestureDetector(
                      onTap: () {}, // 防止點擊列表時關閉
                      child: Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(8),
                        color: const Color(0xFF161B22),
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 300),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF30363D)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 標題列
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Color(0xFF30363D),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.filter_alt,
                                      color: Color(0xFF8B949E),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Select Providers',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (_selectedProviders.isNotEmpty)
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            _selectedProviders.clear();
                                          });
                                        },
                                        child: const Text(
                                          'Clear All',
                                          style: TextStyle(
                                            color: Color(0xFF6366F1),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // Provider 列表
                              Flexible(
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  shrinkWrap: true,
                                  itemCount: suggestions.length,
                                  itemBuilder: (context, index) {
                                    final suggestion = suggestions[index];
                                    final isSelected = _selectedProviders
                                        .contains(suggestion);
                                    final isHighlighted =
                                        _searchText.isNotEmpty &&
                                        suggestion.toLowerCase().contains(
                                          _searchText.toLowerCase(),
                                        );

                                    return InkWell(
                                      onTap: () {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedProviders.remove(
                                              suggestion,
                                            );
                                          } else {
                                            _selectedProviders.add(suggestion);
                                          }
                                        });
                                        // 重新構建 overlay 以更新選擇狀態
                                        _showSearchSuggestionsOverlay();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        color:
                                            isSelected
                                                ? const Color(
                                                  0xFF6366F1,
                                                ).withValues(alpha: 0.1)
                                                : null,
                                        child: Row(
                                          children: [
                                            Icon(
                                              isSelected
                                                  ? Icons.check_box
                                                  : Icons
                                                      .check_box_outline_blank,
                                              size: 20,
                                              color:
                                                  isSelected
                                                      ? const Color(0xFF6366F1)
                                                      : const Color(0xFF8B949E),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.data_object,
                                              size: 16,
                                              color: Color(0xFF8B949E),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                suggestion,
                                                style: TextStyle(
                                                  color:
                                                      isSelected
                                                          ? const Color(
                                                            0xFF6366F1,
                                                          )
                                                          : isHighlighted
                                                          ? Colors.white
                                                          : const Color(
                                                            0xFFE6EDF3,
                                                          ),
                                                  fontSize: 13,
                                                  fontWeight:
                                                      isSelected
                                                          ? FontWeight.w600
                                                          : FontWeight.normal,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );

    overlay.insert(_searchOverlay!);
  }

  /// 隱藏搜尋建議覆蓋層
  void _hideSearchSuggestionsOverlay() {
    _searchOverlay?.remove();
    _searchOverlay = null;
  }
}
