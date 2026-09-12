// ignore_for_file: deprecated_member_use

import 'package:chuck_interceptor/src/core/chuck_core.dart';
import 'package:chuck_interceptor/src/helper/chuck_alert_helper.dart';
import 'package:chuck_interceptor/src/model/chuck_http_call.dart';
import 'package:chuck_interceptor/src/model/chuck_menu_item.dart';
import 'package:chuck_interceptor/src/model/chuck_sort_option.dart';
import 'package:chuck_interceptor/src/theme/chuck_theme.dart';
import 'package:chuck_interceptor/src/theme/chuck_theme_data.dart';
import 'package:chuck_interceptor/src/ui/page/chuck_call_details_screen.dart';
import 'package:chuck_interceptor/src/ui/page/chuck_stats_screen.dart';
import 'package:chuck_interceptor/src/ui/widget/chuck_call_list_item_widget.dart';
import 'package:flutter/material.dart';

class ChuckCallsListScreen extends StatefulWidget {
  const ChuckCallsListScreen(this._chuckCore, {super.key});

  final ChuckCore _chuckCore;

  @override
  State<ChuckCallsListScreen> createState() => _ChuckCallsListScreenState();
}

class _ChuckCallsListScreenState extends State<ChuckCallsListScreen> {
  _ChuckCallsListScreenState() {
    _menuItems
      ..add(const ChuckMenuItem('Sort', Icons.sort))
      ..add(const ChuckMenuItem('Delete', Icons.delete))
      ..add(const ChuckMenuItem('Stats', Icons.insert_chart))
      ..add(const ChuckMenuItem('Save', Icons.save));
  }

  ChuckCore get chuckCore => widget._chuckCore;
  bool _searchEnabled = false;
  final TextEditingController _queryTextEditingController = TextEditingController();
  final List<ChuckMenuItem> _menuItems = [];
  final GlobalKey<TooltipState> _tooltipKey = GlobalKey<TooltipState>();
  ChuckSortOption? _sortOption = ChuckSortOption.time;
  bool _sortAscending = false;

  @override
  Widget build(BuildContext context) => Theme(
    data: ChuckThemeData.attach(Theme.of(context)),
    child: Builder(
      builder: (context) => ScaffoldMessenger(
        child: Scaffold(
          backgroundColor: context.chuckTheme.background,
          appBar: AppBar(
            backgroundColor: context.chuckTheme.background,
            surfaceTintColor: context.chuckTheme.background,
            title: _searchEnabled ? _buildSearchField(context) : _buildTitleWidget(context),
            actions: [_buildSearchButton(), _buildMenuButton(context)],
          ),
          body: StreamBuilder<List<ChuckHttpCall>>(
            stream: chuckCore.callsSubject,
            builder: (context, snapshot) {
              List<ChuckHttpCall> calls = snapshot.data ?? [];
              final String query = _queryTextEditingController.text.trim();
              if (query.isNotEmpty) {
                calls = _filterCallsByQuery(calls, query);
              }
              if (calls.isNotEmpty) {
                return _buildCallsListWidget(context, calls);
              } else {
                return _buildEmptyWidget(context);
              }
            },
          ),
        ),
      ),
    ),
  );

  @override
  void dispose() {
    super.dispose();
    _queryTextEditingController.dispose();
  }

  Widget _buildSearchButton() => Tooltip(
    key: _tooltipKey,
    message:
        'Search tips:\n'
        '• Use commas to search multiple terms\n'
        '• Use ! to exclude terms (e.g., !error)\n'
        '• Search works on URL, method, and status',
    preferBelow: false,
    showDuration: const Duration(seconds: 3),
    triggerMode: TooltipTriggerMode.manual,
    child: IconButton(icon: const Icon(Icons.search), onPressed: _onSearchClicked),
  );

  void _onSearchClicked() {
    if (!_searchEnabled) {
      _tooltipKey.currentState?.ensureTooltipVisible();
    }

    setState(() {
      _searchEnabled = !_searchEnabled;
      if (!_searchEnabled) {
        _queryTextEditingController.text = '';
      }
    });
  }

  Widget _buildMenuButton(BuildContext context) => PopupMenuButton<ChuckMenuItem>(
    onSelected: _onMenuItemSelected,
    itemBuilder: (BuildContext context) => _menuItems
        .map(
          (item) => PopupMenuItem<ChuckMenuItem>(
            value: item,
            child: Row(
              children: [
                Icon(item.iconData, color: context.chuckTheme.accent),
                const Padding(padding: EdgeInsets.only(left: 10)),
                Text(item.title),
              ],
            ),
          ),
        )
        .toList(),
  );

  Widget _buildTitleWidget(BuildContext context) => Text(
    'Chuck Inspector',
    style: TextStyle(fontWeight: FontWeight.bold, color: context.chuckTheme.primaryText),
  );

  Widget _buildSearchField(BuildContext context) => TextField(
    controller: _queryTextEditingController,
    autofocus: true,
    decoration: InputDecoration(
      hintText: 'Search (path, method, host, !tag)...',
      hintStyle: TextStyle(fontSize: 14, color: context.chuckTheme.secondaryText),
      border: InputBorder.none,
      suffixIcon: IconButton(
        icon: const Icon(Icons.clear, size: 18),
        onPressed: () {
          _queryTextEditingController.clear();
          setState(() {});
        },
      ),
    ),
    style: TextStyle(fontSize: 14, color: context.chuckTheme.primaryText),
    onChanged: _updateSearchQuery,
  );

  void _onMenuItemSelected(ChuckMenuItem menuItem) {
    if (menuItem.title == 'Sort') {
      _showSortDialog();
    }
    if (menuItem.title == 'Delete') {
      _showRemoveDialog();
    }
    if (menuItem.title == 'Stats') {
      _showStatsScreen();
    }
    if (menuItem.title == 'Save') {
      _saveToFile().ignore();
    }
  }

  Widget _buildEmptyWidget(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(32, 0, 32, MediaQuery.paddingOf(context).bottom + 16),
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_tethering_off, size: 48, color: context.chuckTheme.neutral),
          const SizedBox(height: 12),
          Text(
            'No HTTP calls to display',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: context.chuckTheme.primaryText),
          ),
          const SizedBox(height: 8),
          Text(
            'Requests will appear here as they are intercepted.\nCheck your active filter or search query if calls are missing.',
            style: TextStyle(fontSize: 13, color: context.chuckTheme.secondaryText),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );

  Widget _buildCallsListWidget(BuildContext context, List<ChuckHttpCall> calls) {
    // Create a copy only once for sorting to avoid multiple allocations
    final List<ChuckHttpCall> callsSorted = [...calls];

    switch (_sortOption) {
      case ChuckSortOption.time:
        if (_sortAscending) {
          callsSorted.sort((call1, call2) => call1.createdTime.compareTo(call2.createdTime));
        } else {
          callsSorted.sort((call1, call2) => call2.createdTime.compareTo(call1.createdTime));
        }
      case ChuckSortOption.responseTime:
        if (_sortAscending) {
          callsSorted.sort((call1, call2) {
            final time1 = call1.response?.time;
            final time2 = call2.response?.time;
            if (time1 == null && time2 == null) {
              return 0;
            }
            if (time1 == null) {
              return -1;
            }
            if (time2 == null) {
              return 1;
            }
            return time1.compareTo(time2);
          });
        } else {
          callsSorted.sort((call1, call2) {
            final time1 = call1.response?.time;
            final time2 = call2.response?.time;
            if (time1 == null && time2 == null) {
              return 0;
            }
            if (time1 == null) {
              return 1;
            }
            if (time2 == null) {
              return -1;
            }
            return time2.compareTo(time1);
          });
        }
      case ChuckSortOption.responseCode:
        if (_sortAscending) {
          callsSorted.sort((call1, call2) {
            final status1 = call1.response?.status;
            final status2 = call2.response?.status;
            if (status1 == null && status2 == null) {
              return 0;
            }
            if (status1 == null) {
              return -1;
            }
            if (status2 == null) {
              return 1;
            }
            return status1.compareTo(status2);
          });
        } else {
          callsSorted.sort((call1, call2) {
            final status1 = call1.response?.status;
            final status2 = call2.response?.status;
            if (status1 == null && status2 == null) {
              return 0;
            }
            if (status1 == null) {
              return 1;
            }
            if (status2 == null) {
              return -1;
            }
            return status2.compareTo(status1);
          });
        }
      case ChuckSortOption.responseSize:
        if (_sortAscending) {
          callsSorted.sort((call1, call2) {
            final size1 = call1.response?.size;
            final size2 = call2.response?.size;
            if (size1 == null && size2 == null) {
              return 0;
            }
            if (size1 == null) {
              return -1;
            }
            if (size2 == null) {
              return 1;
            }
            return size1.compareTo(size2);
          });
        } else {
          callsSorted.sort((call1, call2) {
            final size1 = call1.response?.size;
            final size2 = call2.response?.size;
            if (size1 == null && size2 == null) {
              return 0;
            }
            if (size1 == null) {
              return 1;
            }
            if (size2 == null) {
              return -1;
            }
            return size2.compareTo(size1);
          });
        }
      case ChuckSortOption.endpoint:
        if (_sortAscending) {
          callsSorted.sort((call1, call2) => call1.endpoint.compareTo(call2.endpoint));
        } else {
          callsSorted.sort((call1, call2) => call2.endpoint.compareTo(call1.endpoint));
        }
      case null:
        break;
    }
    final double bottomPadding = MediaQuery.paddingOf(context).bottom + 16;
    return ListView.separated(
      padding: EdgeInsets.only(top: 6, bottom: bottomPadding),
      itemCount: callsSorted.length,
      itemBuilder: (context, index) => ChuckCallListItemWidget(callsSorted[index], _onListItemClicked),
      separatorBuilder: (context, index) => const SizedBox(height: 2),
      cacheExtent: 20,
    );
  }

  void _onListItemClicked(ChuckHttpCall call) {
    Navigator.push<void>(
      widget._chuckCore.getContext()!,
      MaterialPageRoute(builder: (context) => ChuckCallDetailsScreen(call, widget._chuckCore)),
    ).ignore();
  }

  void _showRemoveDialog() {
    ChuckAlertHelper.showAlert(
      context,
      'Delete calls',
      'Do you want to delete http calls?',
      firstButtonTitle: 'No',
      firstButtonAction: () => <String, dynamic>{},
      secondButtonTitle: 'Yes',
      secondButtonAction: _removeCalls,
    );
  }

  void _removeCalls() {
    chuckCore.removeCalls();
  }

  void _showStatsScreen() {
    Navigator.push<void>(
      chuckCore.getContext()!,
      MaterialPageRoute(builder: (context) => ChuckStatsScreen(widget._chuckCore)),
    ).ignore();
  }

  Future<void> _saveToFile() async {
    chuckCore.saveHttpRequests(context);
  }

  void _updateSearchQuery(String query) {
    setState(() {});
  }

  List<ChuckHttpCall> _filterCallsByQuery(List<ChuckHttpCall> calls, String query) {
    final List<String> allTerms = query.split(',').map((term) => term.trim()).where((term) => term.isNotEmpty).toList();

    if (allTerms.isEmpty) {
      return calls;
    }

    final List<String> includeTerms = [];
    final List<String> excludeTerms = [];

    for (final String term in allTerms) {
      if (term.startsWith('!') && term.length > 1) {
        excludeTerms.add(term.substring(1).toLowerCase());
      } else {
        includeTerms.add(term.toLowerCase());
      }
    }

    return calls.where((call) {
      final String endpoint = call.endpoint.toLowerCase();
      final String method = call.method.toLowerCase();
      final String server = call.server.toLowerCase();

      for (final String excludeTerm in excludeTerms) {
        if (endpoint.contains(excludeTerm) || method.contains(excludeTerm) || server.contains(excludeTerm)) {
          return false;
        }
      }

      if (includeTerms.isNotEmpty) {
        return includeTerms.any((term) => endpoint.contains(term) || method.contains(term) || server.contains(term));
      }

      return true;
    }).toList();
  }

  void _showSortDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext buildContext) => Theme(
        data: ChuckThemeData.attach(Theme.of(context)),
        child: AlertDialog(
          title: const Text('Select filter'),
          content: StatefulBuilder(
            builder: (context, setState) => Wrap(
              children: [
                ...ChuckSortOption.values.map(
                  (sortOption) => RadioListTile<ChuckSortOption>(
                    title: Text(sortOption.name),
                    value: sortOption,
                    groupValue: _sortOption,
                    onChanged: (value) {
                      setState(() {
                        _sortOption = value;
                      });
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Descending'),
                    Switch(
                      value: _sortAscending,
                      onChanged: (value) {
                        setState(() {
                          _sortAscending = value;
                        });
                      },
                      activeTrackColor: context.chuckTheme.neutral,
                      activeThumbColor: context.chuckTheme.onInverseSurface,
                    ),
                    const Text('Ascending'),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                sortCalls();
              },
              child: const Text('Use filter'),
            ),
          ],
        ),
      ),
    ).ignore();
  }

  void sortCalls() {
    setState(() {});
  }
}
