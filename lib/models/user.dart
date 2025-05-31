import 'package:mongo_dart/mongo_dart.dart' as mongo;

class User {
  final mongo.ObjectId id;
  final String name;
  final String email;
  final String password;
  final DateTime birthDate;
  final String gender;
  double height;
  double weight;
  String goal;
  final DateTime joinedDate;
  List<WeightHistory> weightHistory;
  int workoutsCompleted;
  int daysStreak;
  int totalWorkoutMinutes;
  DateTime? lastWorkoutDate;
  List<WorkoutHistory> workoutHistory;

  User({
    mongo.ObjectId? id,
    required this.name,
    required this.email,
    required this.password,
    required this.birthDate,
    required this.gender,
    required this.height,
    required this.weight,
    required this.goal,
    DateTime? joinedDate,
    List<WeightHistory>? weightHistory,
    this.workoutsCompleted = 0,
    this.daysStreak = 0,
    this.totalWorkoutMinutes = 0,
    this.lastWorkoutDate,
    List<WorkoutHistory>? workoutHistory,
  })  : id = id ?? mongo.ObjectId(),
        joinedDate = joinedDate ?? DateTime.now(),
        weightHistory = weightHistory ?? [],
        workoutHistory = workoutHistory ?? [];

  Map<String, dynamic> toMap() {
    try {
      final map = {
        '_id': id,
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'birthDate': birthDate,
        'gender': gender,
        'height': height,
        'weight': weight,
        'goal': goal,
        'joinedDate': joinedDate,
        'weightHistory': weightHistory.map((w) => w.toMap()).toList(),
        'workoutsCompleted': workoutsCompleted,
        'daysStreak': daysStreak,
        'totalWorkoutMinutes': totalWorkoutMinutes,
        'lastWorkoutDate': lastWorkoutDate,
        'workoutHistory': workoutHistory.map((w) => w.toMap()).toList(),
      };
      print('[User] Mapa do usuário gerado com sucesso');
      return map;
    } catch (e) {
      print('[User] Erro ao converter usuário para Map: $e');
      rethrow;
    }
  }

  factory User.fromMap(Map<String, dynamic> map) {
    try {
      print('[User] Convertendo Map para User...');
      return User(
        id: map['_id'] as mongo.ObjectId,
        name: (map['name'] as String).trim(),
        email: (map['email'] as String).trim().toLowerCase(),
        password: map['password'] as String,
        birthDate: map['birthDate'] as DateTime,
        gender: map['gender'] as String,
        height: (map['height'] as num).toDouble(),
        weight: (map['weight'] as num).toDouble(),
        goal: map['goal'] as String,
        joinedDate: map['joinedDate'] as DateTime,
        weightHistory: (map['weightHistory'] as List? ?? [])
            .map((w) => WeightHistory.fromMap(w as Map<String, dynamic>))
            .toList(),
        workoutsCompleted: (map['workoutsCompleted'] as num?)?.toInt() ?? 0,
        daysStreak: (map['daysStreak'] as num?)?.toInt() ?? 0,
        totalWorkoutMinutes: (map['totalWorkoutMinutes'] as num?)?.toInt() ?? 0,
        lastWorkoutDate: map['lastWorkoutDate'] as DateTime?,
        workoutHistory: (map['workoutHistory'] as List? ?? [])
            .map((w) => WorkoutHistory.fromMap(w as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date)),
      );
    } catch (e, stackTrace) {
      print('[User] Erro ao converter Map para User:');
      print('Erro: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, birthDate: $birthDate, gender: $gender, height: $height, weight: $weight, goal: $goal)';
  }
}

class WeightHistory {
  final DateTime date;
  final double weight;

  WeightHistory({
    required this.date,
    required this.weight,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'weight': weight,
    };
  }

  factory WeightHistory.fromMap(Map<String, dynamic> map) {
    return WeightHistory(
      date: map['date'] as DateTime,
      weight: map['weight'] as double,
    );
  }

  @override
  String toString() {
    return 'WeightHistory(date: $date, weight: $weight)';
  }
}

class WorkoutHistory {
  final DateTime date;
  final String workoutName;
  final int durationSeconds;
  final List<ExerciseRecord> exercises;

  WorkoutHistory({
    required this.date,
    required this.workoutName,
    required this.durationSeconds,
    List<ExerciseRecord>? exercises,
  }) : exercises = exercises ?? [];

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'workoutName': workoutName,
      'durationSeconds': durationSeconds,
      'exercises': exercises.map((e) => e.toMap()).toList(),
    };
  }

  factory WorkoutHistory.fromMap(Map<String, dynamic> map) {
    return WorkoutHistory(
      date: map['date'] as DateTime,
      workoutName: map['workoutName'] as String,
      durationSeconds: (map['durationSeconds'] ?? map['durationMinutes'] * 60) as int,
      exercises: (map['exercises'] as List?)
          ?.map((e) => ExerciseRecord.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ExerciseRecord {
  final String name;
  final int sets;
  final int reps;
  final double weight;

  ExerciseRecord({
    required this.name,
    required this.sets,
    required this.reps,
    required this.weight,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'sets': sets,
      'reps': reps,
      'weight': weight,
    };
  }

  factory ExerciseRecord.fromMap(Map<String, dynamic> map) {
    return ExerciseRecord(
      name: map['name'] as String,
      sets: map['sets'] as int,
      reps: map['reps'] as int,
      weight: map['weight'] as double,
    );
  }
} 