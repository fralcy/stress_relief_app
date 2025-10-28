class DrawingPalette {
  // Bộ màu cho mini game vẽ tranh, sắp xếp theo gradient grid
  static const List<List<String>> colors = [
    ['#be4a2f', '#d77643', '#e4a672', '#ead4aa'],
    ['#b86f50', '#f77622', '#feae34', '#fee761'],
    ['#63c74d', '#3e8948', '#265c42', '#193c3e'],
    ['#124e89', '#0099db', '#2ce8f5', '#c0cbdc'],
    ['#8b9bb4', '#5a6988', '#3a4466', '#262b44'],
    ['#181425', '#68386c', '#b55088', '#3e2731'],
    ['#a22633', '#e43b44', '#f6757a', '#e8b796'],
    ['#c28569', '#733e39', '#ff0044', '#ffffff'],
  ];
  
  // Flatten palette để dễ access bằng index
  static final List<String> flatColors = colors.expand((row) => row).toList();
  
  // Tổng số màu trong palette
  static const int totalColors = 32;
  
  // Index cho empty cell
  static const int emptyIndex = -1;
  
  // Convert hex string to Color
  static int hexToInt(String hex) {
    return int.parse(hex.substring(1), radix: 16) + 0xFF000000;
  }
  
  // Lấy màu theo index
  static String getColorByIndex(int index) {
    if (index < 0 || index >= flatColors.length) {
      return ''; // Empty
    }
    return flatColors[index];
  }
  
  // Lấy index của màu
  static int getIndexByColor(String hex) {
    return flatColors.indexOf(hex);
  }
}