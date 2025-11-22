import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/utils/sfx_service.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/utils/composing_service.dart';
import '../../models/music_progress.dart';

/// Modal hiển thị thư viện các đoạn nhạc
class LibraryModal extends StatefulWidget {
  final Function() onTrackSelected;
  
  const LibraryModal({
    super.key,
    required this.onTrackSelected,
  });

  @override
  State<LibraryModal> createState() => _LibraryModalState();

  /// Helper để show modal
  static Future<void> show(
    BuildContext context, {
    required Function() onTrackSelected,
  }) {
    final l10n = AppLocalizations.of(context);
    return AppModal.show(
      context: context,
      title: l10n.library,
      maxHeight: MediaQuery.of(context).size.height * 0.8,
      content: LibraryModal(onTrackSelected: onTrackSelected),
    );
  }
}

class _LibraryModalState extends State<LibraryModal> {
  final ComposingService _composingService = ComposingService();
  List<MusicTrack> _tracks = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  void _loadTracks() {
    final progress = _composingService.loadProgress();
    if (progress != null && progress.savedTracks.isNotEmpty) {
      setState(() {
        _tracks = progress.savedTracks;
        _selectedIndex = progress.selected; // Lấy index đang chọn từ progress
      });
    }
  }

  Future<void> _onSelectTrack(int index) async {
    SfxService().buttonClick();
    await _composingService.selectTrack(index);
    
    // Đóng modal và notify parent để reload
    if (mounted) {
      Navigator.of(context).pop();
      widget.onTrackSelected();
    }
  }





  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context);

    if (_tracks.isEmpty) {
      return Center(
        child: Text(
          'Không có đoạn nhạc nào',
          style: TextStyle(color: theme.text),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.myTracks,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.text,
            ),
          ),
          const SizedBox(height: 16),
          
          // List của các đoạn nhạc với preview và preview button
          ..._tracks.asMap().entries.map((entry) {
            final index = entry.key;
            final track = entry.value;
            final isSelected = index == _selectedIndex;
            
            return GestureDetector(
              onTap: () => _onSelectTrack(index),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? theme.primary.withOpacity(0.2)
                    : theme.background,
                  border: Border.all(
                    color: isSelected ? theme.primary : theme.border,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    // Tên track
                    Expanded(
                      child: Text(
                        track.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.text,
                        ),
                      ),
                    ),
                    
                    // Indicator nếu đang chọn
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: theme.primary,
                        size: 24,
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}