import 'package:mongo_dart/mongo_dart.dart';

class WorkoutTemplate {
  final ObjectId id;
  final String name;
  final String description;
  final String difficulty;
  final String category;
  final bool isPreset;
  final ObjectId? createdBy;
  final List<WorkoutExerciseTemplate> exercises;

  WorkoutTemplate({
    ObjectId? id,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.category,
    required this.exercises,
    this.isPreset = false,
    this.createdBy,
  }) : id = id ?? ObjectId();

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'name': name,
      'description': description,
      'difficulty': difficulty,
      'category': category,
      'isPreset': isPreset,
      'createdBy': createdBy,
      'exercises': exercises.map((e) => e.toMap()).toList(),
    };
  }

  factory WorkoutTemplate.fromMap(Map<String, dynamic> map) {
    return WorkoutTemplate(
      id: map['_id'],
      name: map['name'],
      description: map['description'],
      difficulty: map['difficulty'],
      category: map['category'],
      isPreset: map['isPreset'],
      createdBy: map['createdBy'],
      exercises: (map['exercises'] as List)
          .map((e) => WorkoutExerciseTemplate.fromMap(e))
          .toList(),
    );
  }
}

class WorkoutExerciseTemplate {
  final ObjectId exerciseId;
  final int sets;
  final int reps;
  final int restTime;
  double? weight;
  final String? notes;
  List<ExerciseProgress> progressHistory;

  WorkoutExerciseTemplate({
    required this.exerciseId,
    required this.sets,
    required this.reps,
    required this.restTime,
    this.weight,
    this.notes,
    List<ExerciseProgress>? progressHistory,
  }) : progressHistory = progressHistory ?? [];

  Map<String, dynamic> toMap() {
    return {
      'exerciseId': exerciseId,
      'sets': sets,
      'reps': reps,
      'restTime': restTime,
      'weight': weight,
      'notes': notes,
      'progressHistory': progressHistory.map((p) => p.toMap()).toList(),
    };
  }

  factory WorkoutExerciseTemplate.fromMap(Map<String, dynamic> map) {
    return WorkoutExerciseTemplate(
      exerciseId: map['exerciseId'],
      sets: map['sets'],
      reps: map['reps'],
      restTime: map['restTime'],
      weight: map['weight'],
      notes: map['notes'],
      progressHistory: (map['progressHistory'] as List?)
          ?.map((p) => ExerciseProgress.fromMap(p))
          .toList(),
    );
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
    return ExerciseProgress(
      date: map['date'],
      weight: map['weight'],
      completedSets: map['completedSets'],
      completedReps: map['completedReps'],
    );
  }
} 