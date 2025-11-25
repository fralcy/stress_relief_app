import '../../models/painting_progress.dart';
import '../l10n/app_localizations.dart';

/// Các template lineart cho mini game vẽ tranh
/// User sẽ dùng các outline này làm cơ sở để tô màu
class DrawingTemplates {
  // Get localized templates
  static List<Painting> getTemplates(AppLocalizations l10n) {
    return [
      Painting(
        name: l10n.templateHeart,
        createdAt: DateTime(2024, 1, 1),
        pixels: _heartTemplate,
      ),
      Painting(
        name: l10n.templateStar,
        createdAt: DateTime(2024, 1, 1),
        pixels: _starTemplate,
      ),
      Painting(
        name: l10n.templateFlower,
        createdAt: DateTime(2024, 1, 1),
        pixels: _flowerTemplate,
      ),
      Painting(
        name: l10n.templateApple,
        createdAt: DateTime(2024, 1, 1),
        pixels: _appleTemplate,
      ),
      Painting(
        name: l10n.templateTree,
        createdAt: DateTime(2024, 1, 1),
        pixels: _treeTemplate,
      ),
      Painting(
        name: l10n.templateCat,
        createdAt: DateTime(2024, 1, 1),
        pixels: _catTemplate,
      ),
    ];
  }

  // Empty cell constant
  static const int _empty = -1;
  
  // Colors from DrawingPalette (by index)
  static const int _black = 25; // '#181425'
  static const int _darkRed = 7; // '#a22633'
  static const int _darkYellow = 12; // '#feae34'
  static const int _darkGreen = 14; // '#265c42'
  static const int _darkBrown = 6; // '#733e39'

  // Template 1: Heart (Trái tim)
  // Outline màu đỏ sẫm, trong trống
  static final List<List<int>> _heartTemplate = List.generate(32, (row) {
    return List.generate(32, (col) {
      // Heart shape từ row 8-24, centered
      if (row >= 8 && row <= 24 && col >= 6 && col <= 25) {
        // Top bumps
        if (row == 8) {
          if ((col >= 9 && col <= 13) || (col >= 18 && col <= 22)) {
            return _darkRed;
          }
        }
        if (row == 9) {
          if (col == 8 || col == 14 || col == 17 || col == 23) {
            return _darkRed;
          }
        }
        if (row >= 10 && row <= 11) {
          if (col == 7 || col == 15 || col == 16 || col == 24) {
            return _darkRed;
          }
        }
        // Sides going down
        if (row >= 12 && row <= 18) {
          if (col == 6 || col == 25) {
            return _darkRed;
          }
        }
        // Bottom point
        if (row == 19) {
          if (col == 7 || col == 24) {
            return _darkRed;
          }
        }
        if (row == 20) {
          if (col == 9 || col == 22) {
            return _darkRed;
          }
        }
        if (row == 21) {
          if (col == 11 || col == 20) {
            return _darkRed;
          }
        }
        if (row == 22) {
          if (col == 13 || col == 18) {
            return _darkRed;
          }
        }
        if (row == 23) {
          if (col == 15 || col == 16) {
            return _darkRed;
          }
        }
        if (row == 24) {
          if (col == 15) {
            return _darkRed;
          }
        }
      }
      return _empty;
    });
  });

  // Template 2: Star (Ngôi sao 4 cánh)
  // Outline màu vàng đậm, trong trống
  static final List<List<int>> _starTemplate = List.generate(32, (row) {
    return List.generate(32, (col) {
      // Star centered at (16, 16) - 4-pointed star (cross shape)
      
      // Top point (vertical)
      if (col == 16 && row >= 6 && row <= 11) return _darkYellow;
      if (row == 7 && (col == 15 || col == 17)) return _darkYellow;
      if (row == 8 && (col == 14 || col == 18)) return _darkYellow;
      if (row == 9 && (col == 15 || col == 17)) return _darkYellow;
      
      // Bottom point (vertical)
      if (col == 16 && row >= 21 && row <= 26) return _darkYellow;
      if (row == 25 && (col == 15 || col == 17)) return _darkYellow;
      if (row == 24 && (col == 14 || col == 18)) return _darkYellow;
      if (row == 23 && (col == 15 || col == 17)) return _darkYellow;
      
      // Left point (horizontal)
      if (row == 16 && col >= 6 && col <= 11) return _darkYellow;
      if (col == 7 && (row == 15 || row == 17)) return _darkYellow;
      if (col == 8 && (row == 14 || row == 18)) return _darkYellow;
      if (col == 9 && (row == 15 || row == 17)) return _darkYellow;
      
      // Right point (horizontal)
      if (row == 16 && col >= 21 && col <= 26) return _darkYellow;
      if (col == 25 && (row == 15 || row == 17)) return _darkYellow;
      if (col == 24 && (row == 14 || row == 18)) return _darkYellow;
      if (col == 23 && (row == 15 || row == 17)) return _darkYellow;
      
      // Center square
      if (row >= 12 && row <= 20 && col >= 12 && col <= 20) {
        if ((row == 12 || row == 20) && col >= 12 && col <= 20) return _darkYellow;
        if ((col == 12 || col == 20) && row >= 12 && row <= 20) return _darkYellow;
      }
      
      return _empty;
    });
  });

  // Template 3: Flower (Hoa đơn giản)
  // Outline màu xanh lá đậm cho thân, trong trống
  static final List<List<int>> _flowerTemplate = List.generate(32, (row) {
    return List.generate(32, (col) {
      // Flower center at (16, 12)
      // Center circle
      if (row >= 10 && row <= 14 && col >= 14 && col <= 18) {
        if ((row == 10 || row == 14) && (col >= 15 && col <= 17)) return _darkYellow;
        if ((row == 11 || row == 13) && (col == 14 || col == 18)) return _darkYellow;
        if (row == 12 && (col == 14 || col == 18)) return _darkYellow;
      }
      
      // Top petal
      if (row >= 6 && row <= 9 && col >= 14 && col <= 18) {
        if (row == 6 && (col == 15 || col == 16 || col == 17)) return _darkYellow;
        if (row == 7 && (col == 14 || col == 18)) return _darkYellow;
        if (row == 8 && (col == 14 || col == 18)) return _darkYellow;
        if (row == 9 && (col == 15 || col == 17)) return _darkYellow;
      }
      
      // Bottom petal
      if (row >= 15 && row <= 18 && col >= 14 && col <= 18) {
        if (row == 15 && (col == 15 || col == 17)) return _darkYellow;
        if (row == 16 && (col == 14 || col == 18)) return _darkYellow;
        if (row == 17 && (col == 14 || col == 18)) return _darkYellow;
        if (row == 18 && (col == 15 || col == 16 || col == 17)) return _darkYellow;
      }
      
      // Left petal
      if (row >= 10 && row <= 14 && col >= 10 && col <= 13) {
        if (col == 10 && (row == 11 || row == 12 || row == 13)) return _darkYellow;
        if (col == 11 && (row == 10 || row == 14)) return _darkYellow;
        if (col == 12 && (row == 10 || row == 14)) return _darkYellow;
        if (col == 13 && (row == 11 || row == 13)) return _darkYellow;
      }
      
      // Right petal
      if (row >= 10 && row <= 14 && col >= 19 && col <= 22) {
        if (col == 22 && (row == 11 || row == 12 || row == 13)) return _darkYellow;
        if (col == 21 && (row == 10 || row == 14)) return _darkYellow;
        if (col == 20 && (row == 10 || row == 14)) return _darkYellow;
        if (col == 19 && (row == 11 || row == 13)) return _darkYellow;
      }
      
      // Stem
      if (col == 16 && row >= 19 && row <= 28) return _darkGreen;
      
      // Leaves
      if (row == 22 && (col >= 13 && col <= 15)) return _darkGreen;
      if (row == 23 && col == 12) return _darkGreen;
      if (row == 24 && col == 11) return _darkGreen;
      
      if (row == 24 && (col >= 17 && col <= 19)) return _darkGreen;
      if (row == 25 && col == 20) return _darkGreen;
      if (row == 26 && col == 21) return _darkGreen;
      
      return _empty;
    });
  });

  // Template 4: Apple (Quả táo)
  // Outline màu đỏ sẫm cho quả, nâu cho cuống, xanh cho lá
  static final List<List<int>> _appleTemplate = List.generate(32, (row) {
    return List.generate(32, (col) {
      // Apple body (rounded shape)
      if (row >= 10 && row <= 25 && col >= 8 && col <= 24) {
        // Top curves (indent at top center for stem)
        if (row == 10) {
          if ((col >= 10 && col <= 13) || (col >= 19 && col <= 22)) return _darkRed;
        }
        if (row == 11) {
          if (col == 9 || col == 14 || col == 18 || col == 23) return _darkRed;
        }
        if (row == 12) {
          if (col == 8 || col == 24) return _darkRed;
        }
        
        // Middle - widest part
        if (row >= 13 && row <= 19) {
          if (col == 8 || col == 24) return _darkRed;
        }
        
        // Bottom - narrowing
        if (row == 20) {
          if (col == 9 || col == 23) return _darkRed;
        }
        if (row == 21) {
          if (col == 10 || col == 22) return _darkRed;
        }
        if (row == 22) {
          if (col == 11 || col == 21) return _darkRed;
        }
        if (row == 23) {
          if (col == 13 || col == 19) return _darkRed;
        }
        if (row == 24) {
          if (col == 14 || col == 18) return _darkRed;
        }
        if (row == 25) {
          if (col >= 15 && col <= 17) return _darkRed;
        }
      }
      
      // Stem (cuống)
      if (col >= 15 && col <= 17) {
        if (row >= 6 && row <= 11) {
          if (col == 15 || col == 17) return _darkBrown;
          if (row == 6 || row == 11) return _darkBrown;
        }
      }
      
      // Leaf (lá)
      if (row >= 5 && row <= 9 && col >= 18 && col <= 23) {
        // Leaf outline
        if (row == 5 && (col == 20 || col == 21)) return _darkGreen;
        if (row == 6 && (col == 19 || col == 22)) return _darkGreen;
        if (row == 7 && (col == 18 || col == 23)) return _darkGreen;
        if (row == 8 && (col == 19 || col == 22)) return _darkGreen;
        if (row == 9 && (col == 20 || col == 21)) return _darkGreen;
      }
      
      return _empty;
    });
  });

  // Template 5: Tree (Cây)
  // Outline màu nâu cho thân, xanh cho tán
  static final List<List<int>> _treeTemplate = List.generate(32, (row) {
    return List.generate(32, (col) {
      // Tree trunk
      if (col >= 14 && col <= 18 && row >= 20 && row <= 28) {
        if (col == 14 || col == 18) return _darkBrown;
        if (row == 20 || row == 28) return _darkBrown;
      }
      
      // Tree crown (circular-ish)
      if (row >= 6 && row <= 20 && col >= 8 && col <= 24) {
        // Top layer
        if (row == 6 && (col >= 14 && col <= 18)) return _darkGreen;
        if (row == 7 && (col == 12 || col == 20)) return _darkGreen;
        if (row == 8 && (col == 10 || col == 22)) return _darkGreen;
        if (row == 9 && (col == 9 || col == 23)) return _darkGreen;
        if (row == 10 && (col == 8 || col == 24)) return _darkGreen;
        
        // Middle layers
        if ((row >= 11 && row <= 16) && (col == 8 || col == 24)) return _darkGreen;
        
        // Bottom layer
        if (row == 17 && (col == 9 || col == 23)) return _darkGreen;
        if (row == 18 && (col == 10 || col == 22)) return _darkGreen;
        if (row == 19 && (col == 12 || col == 20)) return _darkGreen;
        if (row == 20 && (col >= 13 && col <= 19)) return _darkGreen;
      }
      
      return _empty;
    });
  });

  // Template 6: Cat (Con mèo)
  // Outline màu đen, trong trống
  static final List<List<int>> _catTemplate = List.generate(32, (row) {
    return List.generate(32, (col) {
      // Head outline (circular)
      if (row >= 10 && row <= 20 && col >= 10 && col <= 22) {
        // Top of head
        if (row == 10 && (col >= 13 && col <= 19)) return _black;
        if (row == 11 && (col == 11 || col == 21)) return _black;
        if (row == 12 && (col == 10 || col == 22)) return _black;
        
        // Sides
        if ((row >= 13 && row <= 18) && (col == 10 || col == 22)) return _black;
        
        // Bottom (chin)
        if (row == 19 && (col == 11 || col == 21)) return _black;
        if (row == 20 && (col >= 13 && col <= 19)) return _black;
      }
      
      // Left ear
      if (row >= 6 && row <= 10 && col >= 11 && col <= 14) {
        if (row == 6 && col == 12) return _black;
        if (row == 7 && (col == 11 || col == 13)) return _black;
        if (row == 8 && (col == 11 || col == 14)) return _black;
        if (row == 9 && (col == 11 || col == 14)) return _black;
        if (row == 10 && (col >= 11 && col <= 14)) return _black;
      }
      
      // Right ear
      if (row >= 6 && row <= 10 && col >= 18 && col <= 21) {
        if (row == 6 && col == 20) return _black;
        if (row == 7 && (col == 19 || col == 21)) return _black;
        if (row == 8 && (col == 18 || col == 21)) return _black;
        if (row == 9 && (col == 18 || col == 21)) return _black;
        if (row == 10 && (col >= 18 && col <= 21)) return _black;
      }
      
      // Left eye
      if (row >= 13 && row <= 15 && col >= 13 && col <= 15) {
        if (row == 13 && col == 14) return _black;
        if (row == 14 && (col == 13 || col == 15)) return _black;
        if (row == 15 && col == 14) return _black;
      }
      
      // Right eye
      if (row >= 13 && row <= 15 && col >= 17 && col <= 19) {
        if (row == 13 && col == 18) return _black;
        if (row == 14 && (col == 17 || col == 19)) return _black;
        if (row == 15 && col == 18) return _black;
      }
      
      // Nose
      if (row == 16 && col == 16) return _black;
      
      // Mouth
      if (row == 17) {
        if (col == 16) return _black;
      }
      if (row == 18) {
        if (col == 14 || col == 18) return _black;
      }
      
      // Whiskers
      if (row == 15) {
        if (col >= 6 && col <= 9) return _black;
        if (col >= 23 && col <= 26) return _black;
      }
      if (row == 17) {
        if (col >= 6 && col <= 9) return _black;
        if (col >= 23 && col <= 26) return _black;
      }
      
      return _empty;
    });
  });
}
