import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_modal.dart';
import '../../core/widgets/app_button.dart';
import '../../core/utils/composing_service.dart';
import '../../core/l10n/app_localizations.dart';
import 'dart:async';
import '../../core/utils/bgm_service.dart';
import 'library_modal.dart';
import 'music_samples_modal.dart';
import '../../models/music_progress.dart';

/// Modal sáng tác nhạc
class ComposingModal extends StatefulWidget {
  const ComposingModal({super.key});

  @override
  State<ComposingModal> createState() => _ComposingModalState();

  /// Helper để show modal
  static Future<void> show(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    
    // Init default tracks nếu chưa có
    await ComposingService().initializeDefaultTracks();
    
    if (!context.mounted) return;

    // Pause BGM khi mở modal
    await BgmService().pause();
    
    await AppModal.show(
      context: context,
      title: l10n.music,
      maxHeight: MediaQuery.of(context).size.height * 0.92,
      content: const ComposingModal(),
    );
    
    // Resume BGM khi đóng modal
    await BgmService().resume();
  }
}

class _ComposingModalState extends State<ComposingModal> {
  final TextEditingController _nameController = TextEditingController();
  final ComposingService _composingService = ComposingService();
  
  String _songName = 'My Song';
  bool _isEditingName = false;
  bool _isLoading = true;
  Timer? _playbackTimer;
  
  // Music settings
  static const int _bpm = 120;
  static const int _durationSeconds = 12;
  static const int _beatsPerBar = 4;
  static const int _totalBeats = (_durationSeconds * _bpm) ~/ 60;
  
  // Selected instrument and note
  InstrumentType _selectedInstrument = InstrumentType.piano;
  int? _selectedNote;
  
  // Timeline: [beat][track] = note (1-8) or null
  final List<List<int?>> _timeline = List.generate(
    _totalBeats,
    (_) => List.filled(InstrumentType.values.length, null),
  );
  
  // Playback
  bool _isPlaying = false;
  int _playbackPosition = 0;

  @override
  void initState() {
    super.initState();
    _composingService.initialize();
    _loadTrack();
  }

  void _loadTrack() {
    final currentTrack = _composingService.getCurrentTrack();
    
    if (currentTrack != null) {
      setState(() {
        _songName = currentTrack.name;
        _nameController.text = currentTrack.name;
        
        // Convert tracks thành timeline
        final convertedTimeline = _composingService.convertTracksToTimeline(
          currentTrack.tracks,
          _totalBeats,
          _bpm,
        );
        
        // Update timeline
        for (int beat = 0; beat < _totalBeats && beat < convertedTimeline.length; beat++) {
          for (int track = 0; track < InstrumentType.values.length && track < convertedTimeline[beat].length; track++) {
            _timeline[beat][track] = convertedTimeline[beat][track];
          }
        }
        
        _isLoading = false;
      });
    } else {
      setState(() {
        _nameController.text = _songName;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _playbackTimer?.cancel();
    _composingService.stopAll();
    super.dispose();
  }

  void _onInstrumentSelected(InstrumentType instrument) {
    setState(() {
      _selectedInstrument = instrument;
      _selectedNote = null;
    });
  }

  void _onNoteSelected(int note) {
    _composingService.playNote(_getInstrumentPath(_selectedInstrument), note);
    setState(() {
      _selectedNote = note;
    });
  }

  void _onTimelineClick(int beatIndex) {
    if (_selectedNote == null) return;
    
    final trackIndex = InstrumentType.values.indexOf(_selectedInstrument);
    
    setState(() {
      if (_timeline[beatIndex][trackIndex] == _selectedNote) {
        _timeline[beatIndex][trackIndex] = null;
      } else {
        _timeline[beatIndex][trackIndex] = _selectedNote;
      }
    });
    
    // Auto-save
    _saveTrack();
  }

  Future<void> _saveTrack() async {
    // Convert timeline thành tracks format
    final tracks = _composingService.convertTimelineToTracks(_timeline, _bpm);
    
    // Save
    await _composingService.saveTrack(tracks, name: _songName);
  }

  String _getInstrumentPath(InstrumentType instrument) {
    switch (instrument) {
      case InstrumentType.piano:
        return 'piano';
      case InstrumentType.guitar:
        return 'guitar';
      case InstrumentType.synth:
        return 'synth';
      case InstrumentType.bass:
        return 'bass';
      case InstrumentType.drum:
        return 'drum';
    }
  }

  void _onPlay() {
    if (_isPlaying) {
      // Đang play -> pause
      _pausePlayback();
    } else {
      // Start hoặc resume
      _startPlayback();
    }
  }

  void _onPause() {
    _pausePlayback();
  }

  void _onStop() {
    _stopPlayback();
  }

  void _startPlayback() {
    setState(() {
      _isPlaying = true;
    });
    
    // Tính interval giữa các beat: 60000ms / BPM
    final intervalMs = (60000 / _bpm).round();
    
    _playbackTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      // Phát notes ở beat hiện tại
      _playCurrentBeat();
      
      // Di chuyển sang beat tiếp theo
      setState(() {
        _playbackPosition++;
        
        // Loop lại khi hết
        if (_playbackPosition >= _totalBeats) {
          _playbackPosition = 0;
        }
      });
    });
  }

  void _pausePlayback() {
    _playbackTimer?.cancel();
    _composingService.stopAll();
    setState(() {
      _isPlaying = false;
    });
  }

  void _stopPlayback() {
    _playbackTimer?.cancel();
    _composingService.stopAll();
    setState(() {
      _isPlaying = false;
      _playbackPosition = 0;
    });
  }

  void _playCurrentBeat() {
    // Thu thập tất cả notes ở beat hiện tại
    final notesToPlay = <String, int>{};
    
    for (int trackIndex = 0; trackIndex < InstrumentType.values.length; trackIndex++) {
      final note = _timeline[_playbackPosition][trackIndex];
      if (note != null) {
        final instrument = InstrumentType.values[trackIndex];
        final instrumentPath = _getInstrumentPath(instrument);
        notesToPlay[instrumentPath] = note;
      }
    }
    
    // Phát tất cả notes cùng lúc
    if (notesToPlay.isNotEmpty) {
      _composingService.playChord(notesToPlay);
    }
  }

  Future<void> _onOpen() async {
    // Show library modal
    await LibraryModal.show(
      context,
      onTrackSelected: () {
        // Reload track khi chọn track mới
        setState(() {
          _isLoading = true;
        });
        _loadTrack();
      },
    );
  }

  Future<void> _onSaveName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      _nameController.text = _songName;
      setState(() {
        _isEditingName = false;
      });
      return;
    }
    
    setState(() {
      _songName = newName;
      _isEditingName = false;
    });
    
    // Save name
    await _composingService.updateCurrentTrackName(newName);
    
    // Re-save track with new name
    _saveTrack();
  }

  void _onCancelEdit() {
    _nameController.text = _songName;
    setState(() {
      _isEditingName = false;
    });
  }

  void _onEditName() {
    setState(() {
      _isEditingName = true;
    });
  }

  Future<void> _onSamples() async {
    // Stop playback if playing
    if (_isPlaying) {
      _stopPlayback();
    }
    
    // Show samples modal
    await MusicSamplesModal.show(
      context,
      onSampleSelected: (MusicTrack sample) {
        // Load sample vào timeline
        setState(() {
          _isLoading = true;
        });
        
        // Clear current timeline
        for (int beat = 0; beat < _timeline.length; beat++) {
          for (int track = 0; track < InstrumentType.values.length; track++) {
            _timeline[beat][track] = null;
          }
        }
        
        // Convert sample tracks to timeline
        final convertedTimeline = _composingService.convertTracksToTimeline(
          sample.tracks,
          _totalBeats,
          _bpm,
        );
        
        // Load vào timeline (chỉ piano track - index 0)
        for (int beat = 0; beat < _totalBeats && beat < convertedTimeline.length; beat++) {
          if (beat < convertedTimeline.length && convertedTimeline[beat].isNotEmpty) {
            _timeline[beat][0] = convertedTimeline[beat][0]; // Piano only
          }
        }
        
        setState(() {
          _isLoading = false;
        });
        
        // Auto-save
        _saveTrack();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildToolbar(l10n, theme),
          const SizedBox(height: 16),
          _buildTimeline(theme),
          const SizedBox(height: 16),
          _buildPlaybackControls(l10n),
          const SizedBox(height: 24),
          _buildInstrumentSection(l10n, theme),
          const SizedBox(height: 16),
          _buildNoteSection(l10n, theme),
        ],
      ),
    );
  }

  Widget _buildToolbar(AppLocalizations l10n, dynamic theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Song name với edit functionality
        Row(
          children: [
            Text(
              '${l10n.songName}: ',
              style: TextStyle(
                color: theme.text,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            if (_isEditingName) ...[
              // Text field để edit
              Expanded(
                child: TextField(
                  controller: _nameController,
                  autofocus: true,
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: theme.primary),
                    ),
                  ),
                  onSubmitted: (_) => _onSaveName(),
                ),
              ),
              const SizedBox(width: 8),
              // Save button
              GestureDetector(
                onTap: _onSaveName,
                child: const Icon(Icons.check, color: Colors.green, size: 20),
              ),
              const SizedBox(width: 8),
              // Cancel button
              GestureDetector(
                onTap: _onCancelEdit,
                child: const Icon(Icons.close, color: Colors.red, size: 20),
              ),
            ] else ...[
              // Display name
              Text(
                _songName,
                style: TextStyle(
                  color: theme.text,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              // Edit button
              GestureDetector(
                onTap: _onEditName,
                child: Icon(Icons.edit, color: theme.primary, size: 16),
              ),
            ],
          ],
        ),
        
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildTimeline(theme) {
    return Column(
      children: [
        Container(
          height: 280,
          decoration: BoxDecoration(
            color: theme.background,
            border: Border.all(color: theme.border, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Container(
                  width: 80,
                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: theme.border, width: 2)),
                  ),
                  child: Column(
                    children: InstrumentType.values.map((instrument) {
                      return Container(
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: theme.border, width: 1)),
                        ),
                        child: Text(
                          _getInstrumentEmoji(instrument),
                          style: const TextStyle(fontSize: 24),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                ...List.generate(_totalBeats, (beatIndex) {
                  final isBarStart = beatIndex % _beatsPerBar == 0;
                  final isCurrentBeat = _isPlaying && _playbackPosition == beatIndex;
                  
                  return Container(
                    width: 48,
                    decoration: BoxDecoration(
                      color: isCurrentBeat ? theme.secondary.withOpacity(0.2) : null,
                      border: Border(
                        left: isBarStart
                            ? BorderSide(color: theme.border, width: 2)
                            : BorderSide.none,
                      ),
                    ),
                    child: Column(
                      children: List.generate(InstrumentType.values.length, (trackIndex) {
                        final note = _timeline[beatIndex][trackIndex];
                        final hasNote = note != null;
                        
                        return GestureDetector(
                          onTap: () => _onTimelineClick(beatIndex),
                          child: Container(
                            height: 56,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isCurrentBeat && hasNote
                                  ? theme.primary
                                  : hasNote
                                      ? theme.secondary
                                      : theme.background,
                              border: Border(
                                bottom: BorderSide(color: theme.border, width: 1),
                              ),
                            ),
                            child: hasNote
                                ? Text(
                                    note.toString(),
                                    style: TextStyle(
                                      color: theme.background,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : null,
                          ),
                        );
                      }),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: LinearProgressIndicator(
            value: _isPlaying ? _playbackPosition / _totalBeats : 0,
            backgroundColor: theme.border,
            valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildPlaybackControls(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppButton(
          icon: _isPlaying ? Icons.pause : Icons.play_arrow,
          onPressed: _isPlaying ? _onPause : _onPlay,
          width: 56,
        ),
        const SizedBox(width: 12),
        AppButton(
          icon: Icons.stop,
          onPressed: _onStop,
          width: 56,
        ),
        const SizedBox(width: 12),
        AppButton(
          icon: Icons.folder_open, 
          onPressed: _onOpen,
          width: 56,
        ),
        const SizedBox(width: 12),
        AppButton(
          icon: Icons.library_music,
          onPressed: _onSamples,
          width: 56,
        ),
      ],
    );
  }

  Widget _buildInstrumentSection(AppLocalizations l10n, theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.selectInstrument,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.text,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: InstrumentType.values.map((instrument) {
              final isSelected = instrument == _selectedInstrument;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => _onInstrumentSelected(instrument),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? theme.secondary : theme.primary,
                      border: Border.all(
                        color: isSelected ? theme.text : theme.border,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getInstrumentEmoji(instrument),
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getInstrumentName(instrument, l10n),
                          style: TextStyle(
                            color: theme.background,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteSection(AppLocalizations l10n, theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.notes,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.text,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...List.generate(8, (index) {
              final note = index + 1;
              final isSelected = _selectedNote == note;
              
              return GestureDetector(
                onTap: () => _onNoteSelected(note),
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? theme.secondary : theme.primary,
                    border: Border.all(
                      color: isSelected ? theme.text : theme.border,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    note.toString(),
                    style: TextStyle(
                      color: theme.background,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 12),
        if (_selectedNote != null)
          Row(
            children: [
              Text(
                '${l10n.selected}: ',
                style: TextStyle(color: theme.text, fontSize: 14),
              ),
              Text(
                '${_getInstrumentEmoji(_selectedInstrument)} • ${l10n.note}: $_selectedNote',
                style: TextStyle(
                  color: theme.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
      ],
    );
  }

  String _getInstrumentEmoji(InstrumentType instrument) {
    switch (instrument) {
      case InstrumentType.piano:
        return '🎹';
      case InstrumentType.guitar:
        return '🎸';
      case InstrumentType.synth:
        return '🎛️';
      case InstrumentType.bass:
        return '🎸';
      case InstrumentType.drum:
        return '🥁';
    }
  }

  String _getInstrumentName(InstrumentType instrument, AppLocalizations l10n) {
    switch (instrument) {
      case InstrumentType.piano:
        return l10n.piano;
      case InstrumentType.guitar:
        return l10n.guitar;
      case InstrumentType.synth:
        return l10n.synth;
      case InstrumentType.bass:
        return l10n.bass;
      case InstrumentType.drum:
        return l10n.drum;
    }
  }
}

enum InstrumentType {
  piano,
  guitar,
  synth,
  bass,
  drum,
}