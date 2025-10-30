class FishConfig {
  final String id;
  final String name;
  final int pointsPerHour;   // Điểm sinh ra mỗi giờ
  final int price;           // Giá mua/bán cá

  const FishConfig({
    required this.id,
    required this.name,
    required this.pointsPerHour,
    required this.price,
  });
}

class FishConfigs {
  static const int cycleHours = 20;
  
  static const Map<String, FishConfig> fishes = {
    'betta': FishConfig(
      id: 'betta',
      name: 'Betta',
      pointsPerHour: 2,
      price: 100,
    ),
    'guppy': FishConfig(
      id: 'guppy',
      name: 'Guppy',
      pointsPerHour: 1,
      price: 80,
    ),
    'neon': FishConfig(
      id: 'neon',
      name: 'Neon Tetra',
      pointsPerHour: 2,
      price: 90,
    ),
    'molly': FishConfig(
      id: 'molly',
      name: 'Molly',
      pointsPerHour: 1,
      price: 75,
    ),
    'cory': FishConfig(
      id: 'cory',
      name: 'Cory',
      pointsPerHour: 2,
      price: 85,
    ),
    'platy': FishConfig(
      id: 'platy',
      name: 'Platy',
      pointsPerHour: 1,
      price: 70,
    ),
  };

  static FishConfig? getConfig(String fishType) {
    return fishes[fishType];
  }
}