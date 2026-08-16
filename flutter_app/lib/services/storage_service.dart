import 'dart:convert';
import '../models/window_item.dart';
import '../models/project_rates.dart';
import '../models/project_history.dart';
import '../models/calculation_result.dart';

class BackupValidationResult {
  final bool isValid;
  final String? error;
  final Map<String, dynamic>? data;
  final int projectCount;
  final int scrapCount;
  final bool hasCurrentProject;
  final String? backupDate;
  final String? version;

  const BackupValidationResult({
    required this.isValid,
    this.error,
    this.data,
    this.projectCount = 0,
    this.scrapCount = 0,
    this.hasCurrentProject = false,
    this.backupDate,
    this.version,
  });
}

class StorageService {
  static final List<SavedProject> _savedProjects = [];
  static final List<ScrapItem> _scrapItems = [];

  static List<SavedProject> getSavedProjects() {
    return List.unmodifiable(_savedProjects);
  }

  static void saveProject(SavedProject project) {
    int idx = _savedProjects.indexWhere((p) => p.id == project.id);
    if (idx != -1) {
      _savedProjects[idx] = project;
    } else {
      _savedProjects.insert(0, project);
    }
  }

  static void deleteProject(String id) {
    _savedProjects.removeWhere((p) => p.id == id);
  }

  static void clearProjects() {
    _savedProjects.clear();
  }

  static List<ScrapItem> getScrapItems() {
    return List.unmodifiable(_scrapItems);
  }

  static void addScrap(ScrapItem item) {
    _scrapItems.add(item);
  }

  static void removeScrap(String id) {
    _scrapItems.removeWhere((s) => s.id == id);
  }

  static void clearScrap() {
    _scrapItems.clear();
  }

  static String exportAllJson() {
    Map<String, dynamic> data = {
      'schema': 'WINDOW_SECTION_BACKUP_V3',
      'version': '3.1.0',
      'timestamp': DateTime.now().toIso8601String(),
      'projects': _savedProjects.map((p) => p.toJson()).toList(),
      'scrap': _scrapItems.map((s) => s.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Exports a complete portable backup JSON of all projects, active state, settings, and scrap inventory
  static String exportFullBackup({
    required String customerName,
    required String projectName,
    required String phone,
    required String coating,
    required String weightType,
    required double profit,
    required double transport,
    required double extra,
    required bool useGst,
    required String billingMode,
    required bool minBilling,
    required List<dynamic> cart,
    required List<ExtraItem> extraItems,
    required List<int> allowedPipes,
    required ProjectRates rates,
    required CalculationResult result,
  }) {
    final now = DateTime.now();
    final data = {
      'schema': 'WINDOW_SECTION_BACKUP_V3',
      'version': '3.1.0',
      'timestamp': now.toIso8601String(),
      'date_formatted': '${now.day}/${now.month}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      'current_project': {
        'customerName': customerName,
        'projectName': projectName,
        'phone': phone,
        'coating': coating,
        'weightType': weightType,
        'profit': profit,
        'transport': transport,
        'extra': extra,
        'useGst': useGst,
        'billingMode': billingMode,
        'minBilling': minBilling,
        'cart': cart.map((e) => e is WindowItem ? e.toJson() : (e as PartitionItem).toJson()).toList(),
        'extraItems': extraItems.map((e) => e.toJson()).toList(),
        'allowedPipes': allowedPipes,
        'rates': rates.toJson(),
        'grandTotal': result.grandTotal,
        'billingGrandTotal': result.billingGrandTotal,
        'totalSqft': result.totalSqft,
        'billingSqft': result.billingSqft,
      },
      'saved_projects': _savedProjects.map((p) => p.toJson()).toList(),
      'scrap_inventory': _scrapItems.map((s) => s.toJson()).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Validates backup JSON structure without modifying any current state
  static BackupValidationResult validateBackup(String jsonStr) {
    if (jsonStr.trim().isEmpty) {
      return const BackupValidationResult(
        isValid: false,
        error: 'Provided backup text is empty.',
      );
    }

    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is! Map) {
        return const BackupValidationResult(
          isValid: false,
          error: 'Invalid JSON root: Expected a JSON object.',
        );
      }

      final map = Map<String, dynamic>.from(decoded);

      // Support legacy 'projects' or new 'saved_projects'
      final rawProjects = map['saved_projects'] ?? map['projects'];
      final rawScrap = map['scrap_inventory'] ?? map['scrap'];
      final rawCurrent = map['current_project'];

      int projectCount = 0;
      if (rawProjects is List) {
        projectCount = rawProjects.length;
      }

      int scrapCount = 0;
      if (rawScrap is List) {
        scrapCount = rawScrap.length;
      }

      final bool hasCurrent = rawCurrent is Map;

      if (projectCount == 0 && scrapCount == 0 && !hasCurrent) {
        return const BackupValidationResult(
          isValid: false,
          error: 'No recognizable Window Section Pro backup data found in file.',
        );
      }

      return BackupValidationResult(
        isValid: true,
        data: map,
        projectCount: projectCount,
        scrapCount: scrapCount,
        hasCurrentProject: hasCurrent,
        backupDate: map['date_formatted']?.toString() ?? map['timestamp']?.toString(),
        version: map['version']?.toString() ?? '1.0.0',
      );
    } catch (e) {
      return BackupValidationResult(
        isValid: false,
        error: 'Malformed JSON format: $e',
      );
    }
  }

  /// Applies validated backup data cleanly to storage lists
  static void applyValidatedStorage(Map<String, dynamic> data) {
    final rawProjects = data['saved_projects'] ?? data['projects'];
    final rawScrap = data['scrap_inventory'] ?? data['scrap'];

    if (rawProjects is List) {
      _savedProjects.clear();
      for (var item in rawProjects) {
        if (item is Map) {
          try {
            _savedProjects.add(SavedProject.fromJson(Map<String, dynamic>.from(item)));
          } catch (_) {}
        }
      }
    }

    if (rawScrap is List) {
      _scrapItems.clear();
      for (var item in rawScrap) {
        if (item is Map) {
          try {
            _scrapItems.add(ScrapItem.fromJson(Map<String, dynamic>.from(item)));
          } catch (_) {}
        }
      }
    }
  }
}
