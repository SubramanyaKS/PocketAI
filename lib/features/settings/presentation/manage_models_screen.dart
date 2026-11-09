import 'package:flutter/material.dart';
import 'package:arivu_ai/features/chat/service/local_ai_service.dart';
import 'package:arivu_ai/features/model/models/model_catalog.dart';
import 'package:arivu_ai/features/model/models/model_spec.dart';

/// Screen allowing users to browse, download, hot-swap, and delete on-device AI models.
class ManageModelsScreen extends StatefulWidget {
  final LocalAiService aiService;

  const ManageModelsScreen({super.key, required this.aiService});

  @override
  State<ManageModelsScreen> createState() => _ManageModelsScreenState();
}

class _ManageModelsScreenState extends State<ManageModelsScreen> {
  final Map<String, bool> _downloadedMap = {};
  int _totalSizeBytes = 0;
  bool _isLoading = false;

  // Track active download progress by model ID
  String? _downloadingModelId;
  double _downloadProgress = 0.0;
  String _downloadStatusText = '';

  @override
  void initState() {
    super.initState();
    _refreshModelStatus();
  }

  Future<void> _refreshModelStatus() async {
    try {
      await ModelCatalog.loadFromAsset();

      final futures = ModelCatalog.allModels.map((m) async {
        final downloaded = await widget.aiService.isModelDownloaded(m);
        return MapEntry(m.id, downloaded);
      });

      final entries = await Future.wait(futures);
      final totalSize = await widget.aiService.getTotalModelsSizeBytes();

      if (mounted) {
        setState(() {
          _downloadedMap.clear();
          _downloadedMap.addEntries(entries);
          _totalSizeBytes = totalSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[MODELS] Error refreshing status: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatBytes(int bytes) {
    final mb = bytes / (1024 * 1024);
    if (mb >= 1000) {
      return '${(mb / 1024).toStringAsFixed(2)} GB';
    }
    return '${mb.toStringAsFixed(1)} MB';
  }

  Future<void> _handleDeleteModel(ModelSpec spec) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            const SizedBox(width: 10),
            Expanded(child: Text('Delete ${spec.name}?')),
          ],
        ),
        content: Text(
          'This will remove the ${spec.sizeFormatted} model file from your device storage to free up space. You can re-download it anytime over Wi-Fi or mobile data.',
          style: TextStyle(
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await widget.aiService.deleteModel(spec);
        await _refreshModelStatus();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted ${spec.name}. Storage freed!'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting model: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleSwitchModel(ModelSpec spec) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.aiService.switchModel(spec);
      await _refreshModelStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched active model to ${spec.name}'),
            backgroundColor: const Color(0xFF6366F1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to switch model: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleDownloadAndSwitch(ModelSpec spec) async {
    setState(() {
      _downloadingModelId = spec.id;
      _downloadProgress = 0.0;
      _downloadStatusText = 'Starting download...';
    });

    try {
      await widget.aiService.switchModel(
        spec,
        onDownloadProgress: (received, total) {
          if (!mounted) return;
          setState(() {
            if (total > 0) {
              _downloadProgress = (received / total).clamp(0.0, 1.0);
              final pct = (_downloadProgress * 100).round();
              _downloadStatusText = 'Downloading: $pct%';
            } else {
              _downloadStatusText = 'Downloading...';
            }
          });
        },
      );

      await _refreshModelStatus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${spec.name} downloaded & activated!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _downloadingModelId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeModel = widget.aiService.activeModel;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage AI Models',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                // Top Storage Banner Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.pie_chart_rounded,
                          color: Color(0xFF6366F1),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Device Storage Used: ${_formatBytes(_totalSizeBytes)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Active model stays in RAM. Delete inactive models anytime to free up storage.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  'MODEL CATALOG',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),

                const SizedBox(height: 12),

                // Model Cards List
                ...ModelCatalog.allModels.map((spec) {
                  final isActive = spec.id == activeModel.id;
                  final isDownloaded = _downloadedMap[spec.id] ?? false;
                  final isDownloading = _downloadingModelId == spec.id;

                  return _buildModelCard(
                    spec: spec,
                    isActive: isActive,
                    isDownloaded: isDownloaded,
                    isDownloading: isDownloading,
                    isDark: isDark,
                  );
                }),
              ],
            ),
    );
  }

  Widget _buildModelCard({
    required ModelSpec spec,
    required bool isActive,
    required bool isDownloaded,
    required bool isDownloading,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? const Color(0xFF10B981)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE2E8F0)),
          width: isActive ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name + Category Tag
          Row(
            children: [
              Expanded(
                child: Text(
                  spec.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : (isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isActive ? 'Active in RAM' : spec.category,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isActive
                        ? const Color(0xFF10B981)
                        : (isDark
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFF475569)),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Description
          Text(
            spec.description,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 12),

          // Specs Row: Size & RAM
          Row(
            children: [
              Icon(
                Icons.storage_rounded,
                size: 15,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
              const SizedBox(width: 4),
              Text(
                spec.sizeFormatted,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.memory_rounded,
                size: 15,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
              const SizedBox(width: 4),
              Text(
                spec.recommendedRam,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Action Row / Progress Bar
          if (isDownloading) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: _downloadProgress > 0 ? _downloadProgress : null,
                  backgroundColor: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 6),
                Text(
                  _downloadStatusText,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ] else if (isActive) ...[
            // Active Model State
            Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Currently Loaded & Ready',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ] else if (isDownloaded) ...[
            // Downloaded & Inactive State: Switch or Delete
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6366F1),
                      side: const BorderSide(color: Color(0xFF6366F1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _handleSwitchModel(spec),
                    icon: const Icon(Icons.sync_rounded, size: 18),
                    label: const Text('Switch Model'),
                  ),
                ),
                const SizedBox(width: 10),
                // Delete Button
                IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.redAccent.withValues(alpha: 0.12),
                    foregroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  tooltip: 'Delete to free storage',
                  onPressed: () => _handleDeleteModel(spec),
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                ),
              ],
            ),
          ] else ...[
            // Not Downloaded State
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => _handleDownloadAndSwitch(spec),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: Text('Download (${spec.sizeFormatted})'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
