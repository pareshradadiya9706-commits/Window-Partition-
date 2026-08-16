import 'package:flutter/material.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'widgets/app_header.dart';
import 'widgets/sticky_stats_bar.dart';
import 'screens/order_screen.dart';
import 'screens/bill_screen.dart';
import 'screens/cutting_screen.dart';
import 'screens/draw_screen.dart';
import 'screens/scrap_screen.dart';
import 'screens/rates_screen.dart';
import 'screens/history_screen.dart';
import 'screens/quotation_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WindowSectionApp());
}

class WindowSectionApp extends StatefulWidget {
  const WindowSectionApp({super.key});

  @override
  State<WindowSectionApp> createState() => _WindowSectionAppState();
}

class _WindowSectionAppState extends State<WindowSectionApp> {
  final AppState _appState = AppState();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _appState,
      builder: (context, _) {
        return MaterialApp(
          title: 'DW Ultimate Pro V3',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: MainNavigationScaffold(appState: _appState),
        );
      },
    );
  }
}

class MainNavigationScaffold extends StatefulWidget {
  final AppState appState;

  const MainNavigationScaffold({super.key, required this.appState});

  @override
  State<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends State<MainNavigationScaffold> {
  @override
  Widget build(BuildContext context) {
    final isDark = widget.appState.isDarkMode;
    final currentIdx = widget.appState.currentTabIndex;

    final List<Widget> screens = [
      OrderScreen(appState: widget.appState),
      BillScreen(appState: widget.appState),
      CuttingScreen(appState: widget.appState),
      DrawScreen(appState: widget.appState),
      QuotationScreen(appState: widget.appState),
      ScrapScreen(appState: widget.appState),
      RatesScreen(appState: widget.appState),
      HistoryScreen(appState: widget.appState),
    ];

    return Scaffold(
      appBar: AppHeader(appState: widget.appState),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: currentIdx < screens.length ? currentIdx : 0,
                children: screens,
              ),
            ),
            StickyStatsBar(appState: widget.appState),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIdx < screens.length ? currentIdx : 0,
        onDestinationSelected: (index) {
          widget.appState.setTabIndex(index);
        },
        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        indicatorColor: AppTheme.accentCyan.withOpacity(0.25),
        height: 62,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.add_shopping_cart, size: 20),
            selectedIcon: Icon(Icons.shopping_cart, color: AppTheme.accentCyan, size: 22),
            label: 'Order',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_outlined, size: 20),
            selectedIcon: Icon(Icons.receipt, color: AppTheme.accentCyan, size: 22),
            label: 'Bill',
          ),
          NavigationDestination(
            icon: Icon(Icons.content_cut_outlined, size: 20),
            selectedIcon: Icon(Icons.content_cut, color: AppTheme.accentCyan, size: 22),
            label: 'Cutting',
          ),
          NavigationDestination(
            icon: Icon(Icons.architecture_outlined, size: 20),
            selectedIcon: Icon(Icons.architecture, color: AppTheme.accentCyan, size: 22),
            label: 'Draw',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined, size: 20),
            selectedIcon: Icon(Icons.description, color: AppTheme.accentCyan, size: 22),
            label: 'Quote',
          ),
          NavigationDestination(
            icon: Icon(Icons.recycling_outlined, size: 20),
            selectedIcon: Icon(Icons.recycling, color: AppTheme.accentCyan, size: 22),
            label: 'Scrap',
          ),
          NavigationDestination(
            icon: Icon(Icons.currency_rupee_outlined, size: 20),
            selectedIcon: Icon(Icons.currency_rupee, color: AppTheme.accentCyan, size: 22),
            label: 'Rates',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined, size: 20),
            selectedIcon: Icon(Icons.history, color: AppTheme.accentCyan, size: 22),
            label: 'History',
          ),
        ],
      ),
    );
  }
}
