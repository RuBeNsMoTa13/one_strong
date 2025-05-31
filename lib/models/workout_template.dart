import 'package:mongo_dart/mongo_dart.dart' as mongo;

class WorkoutTemplate {
  final mongo.ObjectId id;
  final String name;
  final String description;
  final String difficulty;
  final String category;
  final bool isPreset;
  final mongo.ObjectId? createdBy;
  final List<WorkoutExerciseTemplate> exercises;
  final bool isFavorite;
  final WorkoutSession? lastWorkout;

  WorkoutTemplate({
    mongo.ObjectId? id,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.category,
    required this.exercises,
    this.isPreset = false,
    this.createdBy,
    this.isFavorite = false,
    this.lastWorkout,
  }) : id = id ?? mongo.ObjectId();

  Map<String, dynamic> toMap() {
    try {
      print('\n[WorkoutTemplate] Convertendo para Map:');
      print('  id: $id');
      print('  name: $name');
      print('  createdBy: $createdBy');
      print('  isPreset: $isPreset');
      print('  exercises: ${exercises.length} exercícios');

      final map = {
        '_id': id,
        'name': name,
        'description': description,
        'difficulty': difficulty,
        'category': category,
        'isPreset': isPreset,
        'createdBy': createdBy,
        'exercises': exercises.map((e) => e.toMap()).toList(),
        'isFavorite': isFavorite,
        'lastWorkout': lastWorkout?.toMap(),
      };

      print('[WorkoutTemplate] Map criado com sucesso');
      return map;
    } catch (e, stackTrace) {
      print('[WorkoutTemplate] ERRO ao converter para Map:');
      print('Erro: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  factory WorkoutTemplate.fromMap(Map<String, dynamic> map) {
    try {
      print('\n[WorkoutTemplate] Convertendo Map para objeto:');
      print('  _id: ${map['_id']}');
      print('  name: ${map['name']}');
      print('  createdBy: ${map['createdBy']}');
      print('  isPreset: ${map['isPreset']}');
      print('  exercises: ${map['exercises']?.length ?? 0} exercícios');
      
      return WorkoutTemplate(
        id: map['_id'] as mongo.ObjectId,
        name: map['name'] as String,
        description: map['description'] as String,
        difficulty: map['difficulty'] as String,
        category: map['category'] as String,
        isPreset: map['isPreset'] as bool? ?? false,
        createdBy: map['createdBy'] as mongo.ObjectId?,
        exercises: (map['exercises'] as List)
            .map((e) => WorkoutExerciseTemplate.fromMap(e as Map<String, dynamic>))
            .toList(),
        isFavorite: map['isFavorite'] as bool? ?? false,
        lastWorkout: map['lastWorkout'] != null
            ? WorkoutSession.fromMap(map['lastWorkout'] as Map<String, dynamic>)
            : null,
      );
    } catch (e, stackTrace) {
      print('[WorkoutTemplate] ERRO ao converter Map:');
      print('Erro: $e');
      print('Stack trace: $stackTrace');
      print('Mapa recebido: $map');
      rethrow;
    }
  }

  @override
  String toString() {
    return 'WorkoutTemplate(id: $id, name: $name, createdBy: $createdBy, isPreset: $isPreset)';
  }
}

class WorkoutExerciseTemplate {
  final mongo.ObjectId exerciseId;
  final String name;
  final int sets;
  final String reps;
  int restTime;
  double? weight;
  final String? notes;
  bool isCompleted;
  List<ExerciseProgress> progressHistory;
  final String? imageUrl;

  WorkoutExerciseTemplate({
    required this.exerciseId,
    required this.name,
    required this.sets,
    required this.reps,
    required this.restTime,
    this.weight,
    this.notes,
    this.isCompleted = false,
    List<ExerciseProgress>? progressHistory,
    this.imageUrl,
  }) : progressHistory = progressHistory ?? [];

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'name': name,
      'sets': sets,
      'reps': reps,
      'restTime': restTime,
      'weight': weight,
      'notes': notes,
      'isCompleted': isCompleted,
      'progressHistory': progressHistory.map((p) => p.toMap()).toList(),
      'imageUrl': imageUrl,
    };
  }

  factory WorkoutExerciseTemplate.fromMap(Map<String, dynamic> map) {
    try {
      print('[WorkoutExerciseTemplate] Convertendo mapa para objeto:');
      print('  exerciseId: ${map['exerciseId']}');
      print('  name: ${map['name']}');
      
      return WorkoutExerciseTemplate(
        exerciseId: map['exerciseId'] as mongo.ObjectId,
        name: map['name'] as String,
        sets: map['sets'] as int,
        reps: map['reps'] as String,
        restTime: map['restTime'] as int,
        weight: map['weight'] as double?,
        notes: map['notes'] as String?,
        isCompleted: map['isCompleted'] as bool? ?? false,
        progressHistory: (map['progressHistory'] as List?)
            ?.map((p) => ExerciseProgress.fromMap(p as Map<String, dynamic>))
            .toList(),
        imageUrl: map['imageUrl'] as String?,
      );
    } catch (e, stackTrace) {
      print('[WorkoutExerciseTemplate] ERRO ao converter mapa:');
      print('Erro: $e');
      print('Stack trace: $stackTrace');
      print('Mapa recebido: $map');
      rethrow;
    }
  }

  @override
  String toString() {
    return 'WorkoutExerciseTemplate(name: $name, sets: $sets, reps: $reps)';
  }
}

class ExerciseProgress {
  final DateTime date;
  final double weight;
  final int completedSets;
  final int completedReps;

  ExerciseProgress({
    required this.date,
    required this.weight,
    required this.completedSets,
    required this.completedReps,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'weight': weight,
      'completedSets': completedSets,
      'completedReps': completedReps,
    };
  }

  factory ExerciseProgress.fromMap(Map<String, dynamic> map) {
    try {
      return ExerciseProgress(
        date: map['date'] as DateTime,
        weight: map['weight'] as double,
        completedSets: map['completedSets'] as int,
        completedReps: map['completedReps'] as int,
      );
    } catch (e, stackTrace) {
      print('[ExerciseProgress] ERRO ao converter mapa:');
      print('Erro: $e');
      print('Stack trace: $stackTrace');
      print('Mapa recebido: $map');
      rethrow;
    }
  }

  @override
  String toString() {
    return 'ExerciseProgress(date: $date, weight: $weight, sets: $completedSets, reps: $completedReps)';
  }
}

class WorkoutSession {
  final DateTime startTime;
  final DateTime? endTime;
  final bool isCompleted;
  final List<WorkoutExerciseProgress> exerciseProgress;

  WorkoutSession({
    required this.startTime,
    this.endTime,
    this.isCompleted = false,
    List<WorkoutExerciseProgress>? exerciseProgress,
  }) : exerciseProgress = exerciseProgress ?? [];

  Map<String, dynamic> toMap() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'isCompleted': isCompleted,
      'exerciseProgress': exerciseProgress.map((e) => e.toMap()).toList(),
    };
  }

  factory WorkoutSession.fromMap(Map<String, dynamic> map) {
    return WorkoutSession(
      startTime: map['startTime'] as DateTime,
      endTime: map['endTime'] as DateTime?,
      isCompleted: map['isCompleted'] as bool,
      exerciseProgress: (map['exerciseProgress'] as List?)
          ?.map((e) => WorkoutExerciseProgress.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }

  int getDurationInSeconds() {
    if (endTime == null) return 0;
    return endTime!.difference(startTime).inSeconds;
  }
}

class WorkoutExerciseProgress {
  final mongo.ObjectId exerciseId;
  final List<SetProgress> sets;
  final DateTime timestamp;

  WorkoutExerciseProgress({
    required this.exerciseId,
    required this.timestamp,
    List<SetProgress>? sets,
  }) : sets = sets ?? [];

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'timestamp': timestamp,
      'sets': sets.map((s) => s.toMap()).toList(),
    };
  }

  factory WorkoutExerciseProgress.fromMap(Map<String, dynamic> map) {
    try {
      return WorkoutExerciseProgress(
        exerciseId: map['exerciseId'] as mongo.ObjectId,
        timestamp: map['timestamp'] as DateTime,
        sets: (map['sets'] as List?)
            ?.map((s) => SetProgress.fromMap(s as Map<String, dynamic>))
            .toList(),
      );
    } catch (e, stackTrace) {
      print('[WorkoutExerciseProgress] ERRO ao converter mapa:');
      print('Erro: $e');
      print('Stack trace: $stackTrace');
      print('Mapa recebido: $map');
      rethrow;
    }
  }
}

class SetProgress {
  final int reps;
  final double weight;
  final bool isCompleted;

  SetProgress({
    required this.reps,
    required this.weight,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'reps': reps,
      'weight': weight,
      'isCompleted': isCompleted,
    };
  }

  factory SetProgress.fromMap(Map<String, dynamic> map) {
    try {
      return SetProgress(
        reps: map['reps'] as int,
        weight: map['weight'] as double,
        isCompleted: map['isCompleted'] as bool? ?? false,
      );
    } catch (e, stackTrace) {
      print('[SetProgress] ERRO ao converter mapa:');
      print('Erro: $e');
      print('Stack trace: $stackTrace');
      print('Mapa recebido: $map');
      rethrow;
    }
  }
} 