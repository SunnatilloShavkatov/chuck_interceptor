import 'package:chuck_interceptor/src/core/chuck_core.dart';
import 'package:chuck_interceptor/src/model/chuck_menu_item.dart';
import 'package:chuck_interceptor/src/helper/chuck_alert_helper.dart';
import 'package:chuck_interceptor/src/model/chuck_sort_option.dart';
import 'package:chuck_interceptor/src/ui/page/chuck_call_details_screen.dart';
import 'package:chuck_interceptor/src/model/chuck_http_call.dart';
import 'package:chuck_interceptor/src/utils/chuck_constants.dart';
import 'package:chuck_interceptor/src/ui/widget/chuck_call_list_item_widget.dart';
import 'package:flutter/material.dart';

import 'chuck_stats_screen.dart';

class ChuckCallsListScreen extends StatefulWidget {
  final ChuckCore _chuckCore;

  const ChuckCallsListScreen(this._chuckCore, {super.key});

  @override
  State<ChuckCallsListScreen> createState() => _ChuckCallsListScreenState();
}

class _ChuckCallsListScreenState extends State<ChuckCallsListScreen> {
  ChuckCore get chuckCore => widget._chuckCore;
  bool _searchEnabled = false;
  final TextEditingController _queryTextEditingController = TextEditingController();
  final List<ChuckMenuItem> _menuItems = [];
  ChuckSortOption? _sortOption = ChuckSortOption.time;
  bool _sortAscending = false;

  _ChuckCallsListScreenState() {
    _menuItems.add(ChuckMenuItem("Sort", Icons.sort));
    _menuItems.add(ChuckMenuItem("Delete", Icons.delete));
    _menuItems.add(ChuckMenuItem("Stats", Icons.insert_chart));
    _menuItems.add(ChuckMenuItem("Save", Icons.save));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _searchEnabled ? _buildSearchField() : _buildTitleWidget(),
        actions: [_buildSearchButton(), _buildMenuButton()],
      ),
      body: StreamBuilder<List<ChuckHttpCall>>(
        stream: chuckCore.callsSubject,
        builder: (context, snapshot) {
          List<ChuckHttpCall> calls = snapshot.data ?? [];
          final String query = _queryTextEditingController.text.trim();
          if (query.isNotEmpty) {
            // Use case-insensitive search with better performance
            final String lowerQuery = query.toLowerCase();
            calls = calls
                .where(
                  (call) =>
                      call.endpoint.toLowerCase().contains(lowerQuery) ||
                      call.method.toLowerCase().contains(lowerQuery) ||
                      call.server.toLowerCase().contains(lowerQuery),
                )
                .toList();
          }
          if (calls.isNotEmpty) {
            return _buildCallsListWidget(calls);
          } else {
            return _buildEmptyWidget();
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _queryTextEditingController.dispose();
  }

  Widget _buildSearchButton() {
    return IconButton(icon: const Icon(Icons.search), onPressed: _onSearchClicked);
  }

  void _onSearchClicked() {
    setState(() {
      _searchEnabled = !_searchEnabled;
      if (!_searchEnabled) {
        _queryTextEditingController.text = "";
      }
    });
  }

  Widget _buildMenuButton() {
    return PopupMenuButton<ChuckMenuItem>(
      onSelected: (ChuckMenuItem item) => _onMenuItemSelected(item),
      itemBuilder: (BuildContext context) {
        return _menuItems.map((ChuckMenuItem item) {
          return PopupMenuItem<ChuckMenuItem>(
            value: item,
            child: Row(
              children: [
                Icon(item.iconData, color: ChuckConstants.lightRed),
                const Padding(padding: EdgeInsets.only(left: 10)),
                Text(item.title),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  Widget _buildTitleWidget() {
    return const Text("Chuck");
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _queryTextEditingController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: "Search http request...",
        hintStyle: TextStyle(fontSize: 16.0, color: ChuckConstants.grey),
        border: InputBorder.none,
      ),
      style: const TextStyle(fontSize: 16.0),
      onChanged: _updateSearchQuery,
    );
  }

  void _onMenuItemSelected(ChuckMenuItem menuItem) {
    if (menuItem.title == "Sort") {
      _showSortDialog();
    }
    if (menuItem.title == "Delete") {
      _showRemoveDialog();
    }
    if (menuItem.title == "Stats") {
      _showStatsScreen();
    }
    if (menuItem.title == "Save") {
      _saveToFile();
    }
  }

  Widget _buildEmptyWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: ChuckConstants.orange),
            const SizedBox(height: 6),
            const Text("There are no calls to show", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "• Check if you send any http request",
                  style: TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                Text(
                  "• Check your ChuckInterceptor configuration",
                  style: TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                Text("• Check search filters", style: TextStyle(fontSize: 12), textAlign: TextAlign.center),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallsListWidget(List<ChuckHttpCall> calls) {
    // Create a copy only once for sorting to avoid multiple allocations
    final List<ChuckHttpCall> callsSorted = [...calls];

    switch (_sortOption) {
      case ChuckSortOption.time:
        if (_sortAscending) {
          callsSorted.sort((call1, call2) => call1.createdTime.compareTo(call2.createdTime));
        } else {
          callsSorted.sort((call1, call2) => call2.createdTime.compareTo(call1.createdTime));
        }
        break;
      case ChuckSortOption.responseTime:
        if (_sortAscending) {
          callsSorted.sort((call1, call2) {
            final time1 = call1.response?.time;
            final time2 = call2.response?.time;
            if (time1 == null && time2 == null) return 0;
            if (time1 == null) return -1;
            if (time2 == null) return 1;
            return time1.compareTo(time2);
          });
        } else {
          callsSorted.sort((call1, call2) {
            final time1 = call1.response?.time;
            final time2 = call2.response?.time;
            if (time1 == null && time2 == null) return 0;
            if (time1 == null) return 1;
            if (time2 == null) return -1;
            return time2.compareTo(time1);
          });
        }
        break;
      case ChuckSortOption.responseCode:
        if (_sortAscending) {
          callsSorted.sort((call1, call2) {
            final status1 = call1.response?.status;
            final status2 = call2.response?.status;
            if (status1 == null && status2 == null) return 0;
            if (status1 == null) return -1;
            if (status2 == null) return 1;
            return status1.compareTo(status2);
          });
        } else {
          callsSorted.sort((call1, call2) {
            final status1 = call1.response?.status;
            final status2 = call2.response?.status;
            if (status1 == null && status2 == null) return 0;
            if (status1 == null) return 1;
            if (status2 == null) return -1;
            return status2.compareTo(status1);
          });
        }
        break;
      case ChuckSortOption.responseSize:
        if (_sortAscending) {
          callsSorted.sort((call1, call2) {
            final size1 = call1.response?.size;
            final size2 = call2.response?.size;
            if (size1 == null && size2 == null) return 0;
            if (size1 == null) return -1;
            if (size2 == null) return 1;
            return size1.compareTo(size2);
          });
        } else {
          callsSorted.sort((call1, call2) {
            final size1 = call1.response?.size;
            final size2 = call2.response?.size;
            if (size1 == null && size2 == null) return 0;
            if (size1 == null) return 1;
            if (size2 == null) return -1;
            return size2.compareTo(size1);
          });
        }
        break;
      case ChuckSortOption.endpoint:
        if (_sortAscending) {
          callsSorted.sort((call1, call2) => call1.endpoint.compareTo(call2.endpoint));
        } else {
          callsSorted.sort((call1, call2) => call2.endpoint.compareTo(call1.endpoint));
        }
        break;
      default:
        break;
    }
    return ListView.separated(
      itemCount: callsSorted.length,
      // Use const constructors where possible for better performance
      itemBuilder: (context, index) => ChuckCallListItemWidget(callsSorted[index], _onListItemClicked),
      separatorBuilder: (context, index) => const Divider(height: 1, thickness: 1, color: ChuckConstants.grey),
      // Add cacheExtent for better performance with long lists
      cacheExtent: 20.0,
    );
  }

  void _onListItemClicked(ChuckHttpCall call) {
    Navigator.push<void>(
      widget._chuckCore.getContext()!,
      MaterialPageRoute(builder: (context) => ChuckCallDetailsScreen(call, widget._chuckCore)),
    );
  }

  void _showRemoveDialog() {
    ChuckAlertHelper.showAlert(
      context,
      "Delete calls",
      "Do you want to delete http calls?",
      firstButtonTitle: "No",
      firstButtonAction: () => <String, dynamic>{},
      secondButtonTitle: "Yes",
      secondButtonAction: () => _removeCalls(),
    );
  }

  void _removeCalls() {
    chuckCore.removeCalls();
  }

  void _showStatsScreen() {
    Navigator.push<void>(
      chuckCore.getContext()!,
      MaterialPageRoute(builder: (context) => ChuckStatsScreen(widget._chuckCore)),
    );
  }

  void _saveToFile() async {
    chuckCore.saveHttpRequests(context);
  }

  void _updateSearchQuery(String query) {
    setState(() {});
  }

  void _showSortDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext buildContext) {
        return Theme(
          data: ThemeData(brightness: Brightness.light),
          child: AlertDialog(
            title: const Text("Select filter"),
            content: StatefulBuilder(
              builder: (context, setState) {
                return Wrap(
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
                        const Text("Descending"),
                        Switch(
                          value: _sortAscending,
                          onChanged: (value) {
                            setState(() {
                              _sortAscending = value;
                            });
                          },
                          activeTrackColor: Colors.grey,
                          activeColor: Colors.white,
                        ),
                        const Text("Ascending"),
                      ],
                    ),
                  ],
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  sortCalls();
                },
                child: const Text("Use filter"),
              ),
            ],
          ),
        );
      },
    );
  }

  void sortCalls() {
    setState(() {});
  }
}
