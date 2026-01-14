import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';
import 'package:vm_service/vm_service.dart' hide Stack;

import '../l10n/app_localizations.dart';
import 'locale_manager.dart';
import 'models/provider_state_info.dart';
import 'models/provider_network.dart';
import 'widgets/provider_list_tile.dart';
import 'widgets/state_detail_panel.dart';
import 'widgets/timeline_view.dart';
import 'widgets/performance_panel.dart';
import 'widgets/provider_graph_view.dart';
import 'theme/extension_theme.dart';

/// View mode for the extension
enum ViewMode { list, timeline }

class RiverpodDevToolsExtension extends StatefulWidget {
  final LocaleManager localeManager;

  const RiverpodDevToolsExtension({super.key, required this.localeManager});

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
  String _searchText = ''; // Search input text
  final Set<String> _selectedProviders =
      {}; // Selected providers (multi-select)
  bool _showAllHistory = true;
  VoidCallback? _connectionListener;

  // Cache filtered providers to avoid recomputation
  List<ProviderStateInfo>? _cachedFilteredProviders;
  bool _filterCacheInvalid = true;

  // Filter by change type
  final Set<String> _selectedChangeTypes = {
    'add',
    'update',
    'dispose',
    'error',
  };

  // Hide auto-computed updates (hidden by default)
  bool _hideAutoComputed = true;

  // View mode (list or timeline)
  ViewMode _viewMode = ViewMode.list;

  // Search suggestions
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  final LayerLink _searchLayerLink = LayerLink();
  OverlayEntry? _searchOverlay;

  // Filter overlay
  final LayerLink _filterLayerLink = LayerLink();
  OverlayEntry? _filterOverlay;

  // Performance statistics (from latest event)
  Map<String, dynamic>? _performanceStats;

  // Provider network for dependency graph
  final ProviderNetwork _providerNetwork = ProviderNetwork();

  // Current tab index (0: State Inspector, 1: Performance, 2: Graph)
  int _currentTabIndex = 0;

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
    // Don't auto-close overlay, allow multiple selections
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

        // Update performance statistics if available
        if (data['performanceStats'] != null) {
          _performanceStats = Map<String, dynamic>.from(
            data['performanceStats'] as Map<dynamic, dynamic>,
          );
        }

        // Update provider network for dependency graph
        _providerNetwork.recordProviderUpdate(
          stateInfo.providerName,
          stateInfo.providerType,
        );

        // Invalidate cache since data changed
        _invalidateFilterCache();
      });
    } catch (e) {
      debugPrint('Error parsing state change: $e');
    }
  }

  List<ProviderStateInfo> get _filteredProviders {
    // Return cached result if valid
    if (!_filterCacheInvalid && _cachedFilteredProviders != null) {
      return _cachedFilteredProviders!;
    }

    var states =
        _showAllHistory ? _providerStates : _latestStates.values.toList();

    // Filter by change type
    states =
        states
            .where((s) => _selectedChangeTypes.contains(s.changeType))
            .toList();

    // Hide auto-computed updates (updates without location)
    if (_hideAutoComputed) {
      states =
          states.where((s) {
            // Keep all non-update types
            if (s.changeType != 'update') return true;
            // Keep all updates with location
            if (s.hasLocation) {
              return true;
            }
            // Also keep async provider completion updates (even without location)
            // Check if value is AsyncValue type
            if (_isAsyncValueUpdate(s)) {
              return true;
            }
            // Filter out other updates without location (e.g., derived provider auto-computed)
            return false;
          }).toList();
    }

    // Filter by selected providers (multi-select)
    if (_selectedProviders.isNotEmpty) {
      states =
          states
              .where((s) => _selectedProviders.contains(s.providerName))
              .toList();
    }

    final result =
        states.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Cache the result
    _cachedFilteredProviders = result;
    _filterCacheInvalid = false;

    return result;
  }

  /// Invalidate filter cache
  void _invalidateFilterCache() {
    _filterCacheInvalid = true;
  }

  /// Check if this is an async value update (FutureProvider/StreamProvider/AsyncNotifierProvider)
  bool _isAsyncValueUpdate(ProviderStateInfo s) {
    // Check if previousValue or currentValue contains AsyncValue pattern
    final asyncPattern = RegExp(r'Async(Loading|Data|Error)<');

    String? getValueString(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      if (value is Map) {
        // Check {type, value} format
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

  /// Get all unique provider names
  List<String> get _allProviderNames {
    final names = <String>{};
    for (final state in _providerStates) {
      names.add(state.providerName);
    }
    return names.toList()..sort();
  }

  /// Get provider suggestions matching the search criteria
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
    final l10n = AppLocalizations.of(context)!;
    return Theme(
      data: ExtensionTheme.darkTheme,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        body: Column(
          children: [
            _buildHeader(l10n),
            Expanded(
              child:
                  _isConnected
                      ? _buildContent(l10n)
                      : _buildConnectionStatus(l10n),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
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
              Text(
                l10n.appTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              // Tab buttons
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1117),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF30363D)),
                ),
                child: Row(
                  children: [
                    _buildTabButton(
                      label: 'State Inspector',
                      icon: Icons.view_list,
                      isSelected: _currentTabIndex == 0,
                      onTap: () => setState(() => _currentTabIndex = 0),
                    ),
                    Container(
                      width: 1,
                      height: 24,
                      color: const Color(0xFF30363D),
                    ),
                    _buildTabButton(
                      label: 'Performance',
                      icon: Icons.speed,
                      isSelected: _currentTabIndex == 1,
                      onTap: () => setState(() => _currentTabIndex = 1),
                    ),
                    Container(
                      width: 1,
                      height: 24,
                      color: const Color(0xFF30363D),
                    ),
                    _buildTabButton(
                      label: 'Graph',
                      icon: Icons.hub,
                      isSelected: _currentTabIndex == 2,
                      onTap: () => setState(() => _currentTabIndex = 2),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _buildStatusIndicator(l10n),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.language, color: Color(0xFF8B949E)),
                onPressed: () {
                  widget.localeManager.toggleLocale();
                },
                tooltip: 'Toggle Language',
              ),
              const SizedBox(width: 8),
              if (_currentTabIndex == 0)
                SegmentedButton<ViewMode>(
                  segments: const [
                    ButtonSegment(
                      value: ViewMode.list,
                      icon: Icon(Icons.list, size: 18),
                      tooltip: 'List View',
                    ),
                    ButtonSegment(
                      value: ViewMode.timeline,
                      icon: Icon(Icons.timeline, size: 18),
                      tooltip: 'Timeline View',
                    ),
                  ],
                  selected: {_viewMode},
                  onSelectionChanged: (Set<ViewMode> newSelection) {
                    setState(() => _viewMode = newSelection.first);
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return const Color(0xFF6366F1).withValues(alpha: 0.3);
                      }
                      return const Color(0xFF161B22);
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return const Color(0xFF6366F1);
                      }
                      return const Color(0xFF8B949E);
                    }),
                    side: WidgetStateProperty.all(
                      const BorderSide(color: Color(0xFF30363D)),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.download, color: Color(0xFF8B949E)),
                onPressed: _providerStates.isEmpty ? null : _showExportDialog,
                tooltip: 'Export Events',
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFF8B949E),
                ),
                onPressed: _clearHistory,
                tooltip: l10n.clearHistory,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Selected provider chips
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
                            _invalidateFilterCache();
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
                      hintText: l10n.filterProviders,
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
                              tooltip: l10n.clearAllFilters,
                              onPressed: () {
                                setState(() {
                                  _selectedProviders.clear();
                                  _invalidateFilterCache();
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
                  l10n.changesCount(_totalChanges),
                  style: const TextStyle(
                    color: Color(0xFF3FB950),
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text(
                  _showAllHistory ? l10n.allHistory : l10n.latestOnly,
                ),
                selected: _showAllHistory,
                onSelected:
                    (value) => setState(() {
                      _showAllHistory = value;
                      _invalidateFilterCache();
                    }),
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
                  tooltip: l10n.filterChangeTypes,
                  onPressed: () {
                    if (_filterOverlay == null) {
                      _showFilterOverlay(l10n);
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

  Widget _buildStatusIndicator(AppLocalizations l10n) {
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
          _isConnected ? l10n.connected : l10n.disconnected,
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

  Widget _buildConnectionStatus(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFF6366F1)),
          const SizedBox(height: 16),
          Text(
            l10n.connectingToApp,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.makeSureAppRunning,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    // Show performance panel when Performance tab is selected
    if (_currentTabIndex == 1) {
      return PerformancePanel(performanceStats: _performanceStats);
    }

    // Show graph view when Graph tab is selected
    if (_currentTabIndex == 2) {
      return ProviderGraphView(network: _providerNetwork);
    }

    // Show state inspector when State tab is selected
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
              l10n.noStateChangesYet,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.providerStateChangesWillAppearHere,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    // Switch between list and timeline view
    if (_viewMode == ViewMode.timeline) {
      return _buildTimelineView();
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
                        l10n.selectProviderToViewDetails,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineView() {
    return Row(
      children: [
        Expanded(
          child: TimelineView(
            events: _filteredProviders,
            selectedEvent: _selectedProvider,
            onEventSelected:
                (event) => setState(() => _selectedProvider = event),
          ),
        ),
        if (_selectedProvider != null) ...[
          Container(width: 1, color: const Color(0xFF30363D)),
          SizedBox(
            width: 400,
            child: Align(
              alignment: Alignment.topCenter,
              child: StateDetailPanel(stateInfo: _selectedProvider!),
            ),
          ),
        ],
      ],
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
      _performanceStats = null; // Clear performance statistics
    });
  }

  /// Show filter overlay
  void _showFilterOverlay(AppLocalizations l10n) {
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
                    onTap: () {}, // Prevent closing when clicking menu itself
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
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.filter_list,
                                    color: Color(0xFF8B949E),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.filterChangeTypes,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildFilterCheckbox(
                              l10n,
                              'add',
                              '➕ ${l10n.changeTypeAdd}',
                            ),
                            _buildFilterCheckbox(
                              l10n,
                              'update',
                              '🔄 ${l10n.changeTypeUpdate}',
                            ),
                            _buildFilterCheckbox(
                              l10n,
                              'dispose',
                              '🗑️ ${l10n.changeTypeDispose}',
                            ),
                            _buildFilterCheckbox(
                              l10n,
                              'error',
                              '❌ ${l10n.changeTypeError}',
                            ),
                            const Divider(height: 1, color: Color(0xFF30363D)),
                            _buildAutoComputedToggle(l10n),
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

  /// Build filter checkbox
  Widget _buildFilterCheckbox(
    AppLocalizations l10n,
    String type,
    String label,
  ) {
    final isSelected = _selectedChangeTypes.contains(type);
    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            // Keep at least one option selected
            if (_selectedChangeTypes.length > 1) {
              _selectedChangeTypes.remove(type);
            }
          } else {
            _selectedChangeTypes.add(type);
          }
          _invalidateFilterCache();
        });
        // Rebuild overlay to update UI
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

  /// Hide filter overlay
  void _hideFilterOverlay() {
    _filterOverlay?.remove();
    _filterOverlay = null;
  }

  /// Rebuild filter overlay
  void _rebuildFilterOverlay() {
    if (_filterOverlay != null) {
      _hideFilterOverlay();
      final l10n = AppLocalizations.of(context)!;
      _showFilterOverlay(l10n);
    }
  }

  /// Build auto-computed toggle option
  Widget _buildAutoComputedToggle(AppLocalizations l10n) {
    return InkWell(
      onTap: () {
        setState(() {
          _hideAutoComputed = !_hideAutoComputed;
          _invalidateFilterCache();
        });
        // Rebuild overlay to update UI
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
                        ? l10n.showAutoComputed
                        : l10n.hideAutoComputed,
                    style: TextStyle(
                      color:
                          _hideAutoComputed
                              ? Colors.white
                              : const Color(0xFF6366F1),
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    l10n.derivedProviderUpdates,
                    style: const TextStyle(
                      color: Color(0xFF6E7681),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show search suggestions overlay
  void _showSearchSuggestionsOverlay() {
    _hideSearchSuggestionsOverlay();

    final suggestions = _searchSuggestions;
    if (suggestions.isEmpty) return;

    final overlay = Overlay.of(context);
    final l10n = AppLocalizations.of(context)!;
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
                      onTap: () {}, // Prevent closing when clicking list
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
                              // Title row
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
                                    Text(
                                      l10n.selectProviders,
                                      style: const TextStyle(
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
                                            _invalidateFilterCache();
                                          });
                                        },
                                        child: Text(
                                          l10n.clearAll,
                                          style: const TextStyle(
                                            color: Color(0xFF6366F1),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // Provider list
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
                                          _invalidateFilterCache();
                                        });
                                        // Rebuild overlay to update selection state
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

  /// Hide search suggestions overlay
  void _hideSearchSuggestionsOverlay() {
    _searchOverlay?.remove();
    _searchOverlay = null;
  }

  /// Show export dialog
  void _showExportDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF161B22),
            title: const Text(
              'Export Events',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.code, color: Color(0xFF6366F1)),
                  title: const Text(
                    'JSON Format',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'Complete event data with metadata',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _exportAsJson();
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(
                    Icons.table_chart,
                    color: Color(0xFF6366F1),
                  ),
                  title: const Text(
                    'CSV Format',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'Timeline format for spreadsheet analysis',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _exportAsCsv();
                  },
                ),
              ],
            ),
          ),
    );
  }

  /// Export as JSON format
  void _exportAsJson() {
    final data = {
      'exportedAt': DateTime.now().toIso8601String(),
      'totalEvents': _providerStates.length,
      'events': _providerStates.map((state) => state.toJson()).toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    _downloadFile('riverpod_events_$timestamp.json', jsonString);
  }

  /// Export as CSV format (timeline)
  void _exportAsCsv() {
    final buffer = StringBuffer();
    buffer.writeln('Timestamp,Change Type,Provider,Value,Location');

    for (final state in _providerStates) {
      final formattedValue = _formatValueForCsv(state.currentValue);
      buffer.writeln(
        [
          state.timestamp.toIso8601String(),
          state.changeType,
          state.providerName,
          formattedValue.replaceAll(',', ';'), // Escape commas
          state.location ?? 'N/A',
        ].join(','),
      );
    }

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    _downloadFile('riverpod_events_$timestamp.csv', buffer.toString());
  }

  /// Format value for CSV export
  String _formatValueForCsv(dynamic value) {
    if (value == null) return 'null';
    if (value is String) return value;
    if (value is Map) {
      return json.encode(value);
    }
    return value.toString();
  }

  /// Trigger browser download
  void _downloadFile(String filename, String content) {
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor =
        html.AnchorElement(href: url)
          ..setAttribute('download', filename)
          ..click();
    html.Url.revokeObjectUrl(url);
  }

  /// Build tab button
  Widget _buildTabButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? const Color(0xFF6366F1).withValues(alpha: 0.2)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color:
                  isSelected
                      ? const Color(0xFF6366F1)
                      : const Color(0xFF8B949E),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected
                        ? const Color(0xFF6366F1)
                        : const Color(0xFF8B949E),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
