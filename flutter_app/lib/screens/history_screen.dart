import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/app_state.dart';
import '../models/project_history.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  final AppState appState;

  const HistoryScreen({super.key, required this.appState});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = widget.appState.isDarkMode;
    final savedProjects = StorageService.getSavedProjects();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Save Active Order Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.save_outlined, size: 18, color: AppTheme.accentCyan),
                          SizedBox(width: 8),
                          Text(
                            'SAVE ACTIVE PROJECT',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: widget.appState.cart.isEmpty
                            ? null
                            : () {
                                widget.appState.saveCurrentProject();
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Project saved successfully to History!'),
                                    duration: Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                        icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                        label: const Text('Save Order'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Active Customer: ${widget.appState.customerName.isNotEmpty ? widget.appState.customerName : "Walk-in"} | Items: ${widget.appState.cart.length} | Grand Total: ₹${(widget.appState.billingMode == 'actual' && !widget.appState.minBilling ? widget.appState.result.grandTotal : widget.appState.result.billingGrandTotal).toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Saved Projects History Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.history, size: 18, color: AppTheme.accentAmber),
                  const SizedBox(width: 8),
                  Text(
                    'SAVED PROJECTS (${savedProjects.length})',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Backup & Restore Action Bar
          Card(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _exportFullBackup(context),
                      icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                      label: const Text('Backup JSON', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentCyan,
                        foregroundColor: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRestoreDialog(context),
                      icon: const Icon(Icons.settings_backup_restore, size: 16),
                      label: const Text('Restore Backup', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.accentAmber,
                        side: const BorderSide(color: AppTheme.accentAmber, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          if (savedProjects.isEmpty)
            Card(
              child: Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                child: Column(
                  children: const [
                    Icon(Icons.folder_open, size: 40, color: Color(0xFF64748B)),
                    SizedBox(height: 10),
                    Text(
                      'No saved projects yet.',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Save your active quotations to access them here anytime.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          else
            ...savedProjects.map((proj) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  proj.customerName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.accentCyan,
                                  ),
                                ),
                                if (proj.projectName.isNotEmpty)
                                  Text(
                                    proj.projectName,
                                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${(proj.billingMode == 'actual' && !proj.minBilling ? proj.result.grandTotal : proj.result.billingGrandTotal).toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.accentAmber,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('Date: ${proj.date}', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                          const SizedBox(width: 12),
                          Text('Items: ${proj.cart.length}', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                          const SizedBox(width: 12),
                          Text('Area: ${proj.result.totalSqft.toStringAsFixed(1)} sqft', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                        ],
                      ),
                      const Divider(height: 16, color: Color(0xFF334155)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppTheme.accentRose, size: 20),
                            onPressed: () {
                              StorageService.deleteProject(proj.id);
                              setState(() {});
                            },
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              widget.appState.loadProject(proj);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Loaded project for ${proj.customerName}'),
                                  duration: const Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            icon: const Icon(Icons.file_open_outlined, size: 14),
                            label: const Text('Load Order', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _exportFullBackup(BuildContext context) {
    final jsonStr = widget.appState.exportFullBackupJson();
    Clipboard.setData(ClipboardData(text: jsonStr));

    final savedCount = StorageService.getSavedProjects().length;
    final scrapCount = StorageService.getScrapItems().length;
    final cartCount = widget.appState.cart.length;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: AppTheme.accentEmerald, size: 22),
            SizedBox(width: 8),
            Text('Backup Exported', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A complete JSON backup was copied to your clipboard.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Active Items: $cartCount', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                  Text('• Saved Projects: $savedCount', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                  Text('• Scrap Inventory: $scrapCount', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                  Text('• Master Material Rates: Included', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                  Text('• Commercial Settings: Included', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'You can paste and store this JSON text into any notes app, file, or backup storage.',
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showRestoreDialog(BuildContext context) {
    final TextEditingController textController = TextEditingController();
    String? validationError;
    BackupValidationResult? validationResult;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.settings_backup_restore, color: AppTheme.accentAmber, size: 22),
                SizedBox(width: 8),
                Text('Restore Backup', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Paste your Window Section Pro JSON backup text below:',
                      style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: textController,
                      maxLines: 6,
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        hintText: '{\n  "schema": "WINDOW_SECTION_BACKUP_V3",\n  ...\n}',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.all(10),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.paste, size: 18),
                          tooltip: 'Paste from clipboard',
                          onPressed: () async {
                            final data = await Clipboard.getData(Clipboard.kTextPlain);
                            if (data?.text != null) {
                              textController.text = data!.text!;
                              setModalState(() {
                                validationResult = StorageService.validateBackup(textController.text);
                                validationError = validationResult?.error;
                              });
                            }
                          },
                        ),
                      ),
                      onChanged: (val) {
                        setModalState(() {
                          if (val.trim().isNotEmpty) {
                            validationResult = StorageService.validateBackup(val);
                            validationError = validationResult?.error;
                          } else {
                            validationResult = null;
                            validationError = null;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Validation Status & Preview Card
                    if (validationError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.accentRose.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.accentRose.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppTheme.accentRose, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                validationError!,
                                style: const TextStyle(color: AppTheme.accentRose, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (validationResult != null && validationResult!.isValid) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.accentEmerald.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.accentEmerald.withOpacity(0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.check_circle_outline, color: AppTheme.accentEmerald, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'Valid Backup Detected',
                                  style: TextStyle(color: AppTheme.accentEmerald, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('• Saved Projects to Restore: ${validationResult!.projectCount}', style: const TextStyle(fontSize: 11)),
                            Text('• Scrap Records: ${validationResult!.scrapCount}', style: const TextStyle(fontSize: 11)),
                            Text('• Active Project State: ${validationResult!.hasCurrentProject ? "Included" : "None"}', style: const TextStyle(fontSize: 11)),
                            if (validationResult!.backupDate != null)
                              Text('• Backup Date: ${validationResult!.backupDate}', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: (validationResult != null && validationResult!.isValid)
                    ? () {
                        final data = validationResult!.data!;
                        widget.appState.restoreFullBackup(data);
                        Navigator.of(ctx).pop();
                        setState(() {});

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Backup restored successfully! All projects and rates updated.'),
                            duration: Duration(seconds: 3),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppTheme.accentEmerald,
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentAmber,
                  foregroundColor: const Color(0xFF0F172A),
                ),
                child: const Text('Restore & Apply'),
              ),
            ],
          );
        },
      ),
    );
  }
}
