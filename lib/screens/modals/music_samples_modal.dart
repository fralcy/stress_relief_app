import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/widgets/app_button.dart';
import '../../core/utils/sfx_service.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/constants/music_samples.dart';
import '../../models/music_progress.dart';
import '../../core/utils/composing_service.dart';

/// Modal hiển thị các sample nhạc piano
class MusicSamplesModal extends StatefulWidget {
  final Function(MusicTrack) onSampleSelected;
  
  const MusicSamplesModal({
    super.key,
    required this.onSampleSelected,
  });

  @override
  State<MusicSamplesModal> createState() => _MusicSamplesModalState();

  /// Helper để show modal
  static Future<void> show(
    BuildContext context, {
    required Function(MusicTrack) onSampleSelected,
  }) {
    final l10n = AppLocalizations.of(context);
    return AppModal.show(
      context: context,
      title: l10n.samples,
      maxHeight: MediaQuery.of(context).size.height * 0.8,
      content: MusicSamplesModal(onSampleSelected: onSampleSelected),
    );
  }
}

class _MusicSamplesModalState extends State<MusicSamplesModal> {
  final ComposingService _composingService = ComposingService();
  int? _previewingIndex;

  @override
  void dispose() {
    _composingService.stopAll();
    super.dispose();
  }

  Future<void> _onPreview(int index) async {
    SfxService().buttonClick();
    
    if (_previewingIndex == index) {
      // Đang preview -> stop
      _composingService.stopAll();
      setState(() {
        _previewingIndex = null;
      });
      return;
    }
    
    // Stop previous preview
    _composingService.stopAll();
    
    setState(() {
      _previewingIndex = index;
    });
    
    // Get sample
    final sample = MusicSamples.samples[index];
    
    // Convert tracks to timeline format để play
    final timeline = _composingService.convertTracksToTimeline(
      sample.tracks,
      MusicSamples.totalBeats,
      MusicSamples.bpm,
    );
    
    // Play preview
    _playTimeline(timeline);
  }

  void _playTimeline(List<List<int?>> timeline) {
    int currentBeat = 0;
    final intervalMs = (60000 / MusicSamples.bpm).round();
    
    void playNextBeat() {
      if (!mounted || _previewingIndex == null) {
        return;
      }
      
      if (currentBeat >= timeline.length) {
        // End of preview
        setState(() {
          _previewingIndex = null;
        });
        return;
      }
      
      // Play current beat
      // Timeline có 5 tracks theo Instrument enum, nhưng samples chỉ dùng track 0 (Instrument.key = piano)
      if (currentBeat < timeline.length && timeline[currentBeat].isNotEmpty) {
        final note = timeline[currentBeat][0]; // Track 0 = piano (Instrument.key)
        if (note != null) {
          _composingService.playNote('piano', note);
        }
      }
      
      currentBeat++;
      Future.delayed(Duration(milliseconds: intervalMs), playNextBeat);
    }
    
    playNextBeat();
  }

  Future<void> _onLoad(int index) async {
    SfxService().buttonClick();
    
    // Stop preview if playing
    if (_previewingIndex != null) {
      _composingService.stopAll();
      setState(() {
        _previewingIndex = null;
      });
    }
    
    final l10n = AppLocalizations.of(context);
    final sample = MusicSamples.samples[index];
    
    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.useSample),
        content: Text(l10n.currentWillBeReplaced('music')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
    
    if (confirmed == true && mounted) {
      // Đóng modal và notify parent
      Navigator.of(context).pop();
      widget.onSampleSelected(sample);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.selectSample,
            style: AppTypography.bodyLarge(context,
              color: theme.text,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          // List của các samples
          ...MusicSamples.samples.asMap().entries.map((entry) {
            final index = entry.key;
            final sample = entry.value;
            final isPreviewing = _previewingIndex == index;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.background,
                border: Border.all(color: theme.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // Icon piano
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '🎹',
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Sample name
                  Expanded(
                    child: Text(
                      sample.name,
                      style: AppTypography.bodyLarge(context,
                        color: theme.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  
                  // Preview button
                  AppButton(
                    icon: isPreviewing ? Icons.pause : Icons.play_arrow,
                    onPressed: () => _onPreview(index),
                    width: 48,
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Load button
                  AppButton(
                    icon: Icons.download,
                    onPressed: () => _onLoad(index),
                    width: 48,
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
