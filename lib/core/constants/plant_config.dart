class PlantConfig {
  final String id;
  final String name;
  final int growthTimeHours;  // Thời gian để grow từ 0 → 100%
  final int harvestReward;    // Số điểm khi thu hoạch
  final int seedsFromHarvest; // Số hạt thu được khi harvest

  const PlantConfig({
    required this.id,
    required this.name,
    required this.growthTimeHours,
    required this.harvestReward,
    required this.seedsFromHarvest,
  });
}

class PlantConfigs {
  // Growth time theo ngày (chậm để người chơi phải chăm sóc lâu dài)
  static const Map<String, PlantConfig> plants = {
    'carrot': PlantConfig(
      id: 'carrot',
      name: 'Carrot',
      growthTimeHours: 40,   // 2 ngày
      harvestReward: 10,
      seedsFromHarvest: 2,
    ),
    'tomato': PlantConfig(
      id: 'tomato',
      name: 'Tomato',
      growthTimeHours: 60,   // 3 ngày
      harvestReward: 15,
      seedsFromHarvest: 3,
    ),
    'corn': PlantConfig(
      id: 'corn',
      name: 'Corn',
      growthTimeHours: 80,   // 4 ngày
      harvestReward: 20,
      seedsFromHarvest: 2,
    ),
    'sunflower': PlantConfig(
      id: 'sunflower',
      name: 'Sunflower',
      growthTimeHours: 100,  // 5 ngày
      harvestReward: 25,
      seedsFromHarvest: 4,
    ),
    'rose': PlantConfig(
      id: 'rose',
      name: 'Rose',
      growthTimeHours: 120,  // 6 ngày
      harvestReward: 30,
      seedsFromHarvest: 3,
    ),
    'tulip': PlantConfig(
      id: 'tulip',
      name: 'Tulip',
      growthTimeHours: 80,   // 4 ngày
      harvestReward: 22,
      seedsFromHarvest: 2,
    ),
    'wheat': PlantConfig(
      id: 'wheat',
      name: 'Wheat',
      growthTimeHours: 60,   // 3 ngày
      harvestReward: 12,
      seedsFromHarvest: 3,
    ),
    'pumpkin': PlantConfig(
      id: 'pumpkin',
      name: 'Pumpkin',
      growthTimeHours: 140,  // 7 ngày
      harvestReward: 35,
      seedsFromHarvest: 2,
    ),
    'strawberry': PlantConfig(
      id: 'strawberry',
      name: 'Strawberry',
      growthTimeHours: 100,  // 5 ngày
      harvestReward: 28,
      seedsFromHarvest: 3,
    ),
    'lettuce': PlantConfig(
      id: 'lettuce',
      name: 'Lettuce',
      growthTimeHours: 50,   // 2.5 ngày
      harvestReward: 14,
      seedsFromHarvest: 2,
    ),
  };

  static PlantConfig? getConfig(String plantType) {
    return plants[plantType];
  }
}
