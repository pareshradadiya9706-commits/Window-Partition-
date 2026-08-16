class ProjectRates {
  final double aluRate;
  final double partDpRate;
  final double partDoorRate;
  final double partClipRate;
  final double partSheetRate;
  final double glassRateDefault;
  final double laborRateDefault;
  final double hardRateDefault;
  final double jaliRateDefault;
  final double louverRateDefault;
  final double partDoorHwRate;

  const ProjectRates({
    this.aluRate = 480.0,
    this.partDpRate = 460.0,
    this.partDoorRate = 460.0,
    this.partClipRate = 130.0,
    this.partSheetRate = 55.0,
    this.glassRateDefault = 58.0,
    this.laborRateDefault = 20.0,
    this.hardRateDefault = 15.0,
    this.jaliRateDefault = 16.0,
    this.louverRateDefault = 130.0,
    this.partDoorHwRate = 850.0,
  });

  Map<String, dynamic> toJson() => {
    'alu_rate': aluRate,
    'part_dp_rate': partDpRate,
    'part_door_rate': partDoorRate,
    'part_clip_rate': partClipRate,
    'part_sheet_rate': partSheetRate,
    'glass_rate_default': glassRateDefault,
    'labor_rate_default': laborRateDefault,
    'hard_rate_default': hardRateDefault,
    'jali_rate_default': jaliRateDefault,
    'louver_rate_default': louverRateDefault,
    'part_door_hw_rate': partDoorHwRate,
  };

  factory ProjectRates.fromJson(Map<String, dynamic> json) => ProjectRates(
    aluRate: (json['alu_rate'] as num?)?.toDouble() ?? 480.0,
    partDpRate: (json['part_dp_rate'] as num?)?.toDouble() ?? 460.0,
    partDoorRate: (json['part_door_rate'] as num?)?.toDouble() ?? 460.0,
    partClipRate: (json['part_clip_rate'] as num?)?.toDouble() ?? 130.0,
    partSheetRate: (json['part_sheet_rate'] as num?)?.toDouble() ?? 55.0,
    glassRateDefault: (json['glass_rate_default'] as num?)?.toDouble() ?? 58.0,
    laborRateDefault: (json['labor_rate_default'] as num?)?.toDouble() ?? 20.0,
    hardRateDefault: (json['hard_rate_default'] as num?)?.toDouble() ?? 15.0,
    jaliRateDefault: (json['jali_rate_default'] as num?)?.toDouble() ?? 16.0,
    louverRateDefault: (json['louver_rate_default'] as num?)?.toDouble() ?? 130.0,
    partDoorHwRate: (json['part_door_hw_rate'] as num?)?.toDouble() ?? 850.0,
  );

  ProjectRates copyWith({
    double? aluRate,
    double? partDpRate,
    double? partDoorRate,
    double? partClipRate,
    double? partSheetRate,
    double? glassRateDefault,
    double? laborRateDefault,
    double? hardRateDefault,
    double? jaliRateDefault,
    double? louverRateDefault,
    double? partDoorHwRate,
  }) {
    return ProjectRates(
      aluRate: aluRate ?? this.aluRate,
      partDpRate: partDpRate ?? this.partDpRate,
      partDoorRate: partDoorRate ?? this.partDoorRate,
      partClipRate: partClipRate ?? this.partClipRate,
      partSheetRate: partSheetRate ?? this.partSheetRate,
      glassRateDefault: glassRateDefault ?? this.glassRateDefault,
      laborRateDefault: laborRateDefault ?? this.laborRateDefault,
      hardRateDefault: hardRateDefault ?? this.hardRateDefault,
      jaliRateDefault: jaliRateDefault ?? this.jaliRateDefault,
      louverRateDefault: louverRateDefault ?? this.louverRateDefault,
      partDoorHwRate: partDoorHwRate ?? this.partDoorHwRate,
    );
  }
}
