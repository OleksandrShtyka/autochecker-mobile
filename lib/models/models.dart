class FitnessProfile {
  final double monthlyGymCost;
  final String fitnessGoal;
  final String fitnessBadge;

  const FitnessProfile({
    required this.monthlyGymCost,
    required this.fitnessGoal,
    required this.fitnessBadge,
  });

  factory FitnessProfile.fromJson(Map<String, dynamic> j) => FitnessProfile(
        monthlyGymCost: (j['monthlyGymCost'] as num?)?.toDouble() ?? 0,
        fitnessGoal: j['fitnessGoal'] as String? ?? 'general',
        fitnessBadge: j['fitnessBadge'] as String? ?? 'Beginner',
      );
}

class Supplement {
  final String id;
  final String name;
  final double totalWeightG;
  final double servingSizeG;
  final double servingsPerDay;
  final double price;
  final String purchaseDate;
  final String? notes;

  const Supplement({
    required this.id,
    required this.name,
    required this.totalWeightG,
    required this.servingSizeG,
    required this.servingsPerDay,
    required this.price,
    required this.purchaseDate,
    this.notes,
  });

  factory Supplement.fromJson(Map<String, dynamic> j) => Supplement(
        id: j['id'] as String,
        name: j['name'] as String,
        totalWeightG: (j['totalWeightG'] as num).toDouble(),
        servingSizeG: (j['servingSizeG'] as num).toDouble(),
        servingsPerDay: (j['servingsPerDay'] as num).toDouble(),
        price: (j['price'] as num?)?.toDouble() ?? 0,
        purchaseDate: j['purchaseDate'] as String,
        notes: j['notes'] as String?,
      );
}

class SupplementStatus {
  final String id;
  final String name;
  final double remainingPct;
  final double remainingG;
  final int daysLeft;
  final String depletionDate;
  final double costPerServing;

  const SupplementStatus({
    required this.id,
    required this.name,
    required this.remainingPct,
    required this.remainingG,
    required this.daysLeft,
    required this.depletionDate,
    required this.costPerServing,
  });

  factory SupplementStatus.fromJson(Map<String, dynamic> j) => SupplementStatus(
        id: j['id'] as String,
        name: j['name'] as String,
        remainingPct: (j['remainingPct'] as num).toDouble(),
        remainingG: (j['remainingG'] as num).toDouble(),
        daysLeft: (j['daysLeft'] as num).toInt(),
        depletionDate: j['depletionDate'] as String,
        costPerServing: (j['costPerServing'] as num).toDouble(),
      );
}

class GymSession {
  final String id;
  final String date;
  final int durationMin;
  final String workoutType;
  final double volumeKg;
  final List<dynamic> exercises;
  final String? notes;

  const GymSession({
    required this.id,
    required this.date,
    required this.durationMin,
    required this.workoutType,
    required this.volumeKg,
    required this.exercises,
    this.notes,
  });

  factory GymSession.fromJson(Map<String, dynamic> j) => GymSession(
        id: j['id'] as String,
        date: j['date'] as String,
        durationMin: (j['durationMin'] as num).toInt(),
        workoutType: j['workoutType'] as String,
        volumeKg: (j['volumeKg'] as num?)?.toDouble() ?? 0,
        exercises: j['exercises'] as List<dynamic>? ?? [],
        notes: j['notes'] as String?,
      );
}

class GymRoi {
  final int sessionsCount;
  final double monthlyCost;
  final double costPerSession;

  const GymRoi({
    required this.sessionsCount,
    required this.monthlyCost,
    required this.costPerSession,
  });

  factory GymRoi.fromJson(Map<String, dynamic> j) => GymRoi(
        sessionsCount: (j['sessionsCount'] as num).toInt(),
        monthlyCost: (j['monthlyCost'] as num).toDouble(),
        costPerSession: (j['costPerSession'] as num).toDouble(),
      );
}
