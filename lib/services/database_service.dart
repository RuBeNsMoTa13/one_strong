import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/workout_template.dart';
import '../config/mongodb_config.dart';

class DatabaseService {
  static late mongo.Db _db;
  static bool _isInitialized = false;
  static const String _userIdKey = 'userId';
  static const String _userEmailKey = 'userEmail';

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('\n[Database] Iniciando conexão com MongoDB...');
      print('[Database] String de conexão: ${MongoDBConfig.connectionString}');
      
      _db = await mongo.Db.create(MongoDBConfig.connectionString);
      
      print('[Database] Tentando abrir conexão...');
      await _db.open();
      print('[Database] Conexão aberta com sucesso');
      
      // Verifica se a conexão está realmente ativa
      try {
        print('[Database] Verificando status do servidor...');
        final serverStatus = await _db.serverStatus();
        print('[Database] Status do servidor: OK');
        print('[Database] Versão do MongoDB: ${serverStatus['version']}');
        
        // Verifica e cria a coleção de usuários se não existir
        print('[Database] Verificando coleção de usuários...');
        final collections = await _db.getCollectionNames();
        if (!collections.contains(MongoDBConfig.usersCollection)) {
          print('[Database] Coleção de usuários não encontrada. Criando...');
          await _db.createCollection(MongoDBConfig.usersCollection);
          print('[Database] Coleção de usuários criada com sucesso');
          
          // Cria índice único para email
          print('[Database] Criando índice único para email...');
          await _db.collection(MongoDBConfig.usersCollection).createIndex(
            key: 'email',
            unique: true,
          );
          print('[Database] Índice criado com sucesso');
        } else {
          print('[Database] Coleção de usuários já existe');
        }
      } catch (statusError) {
        print('[Database] Erro ao verificar status do servidor: $statusError');
        throw statusError;
      }
      
      _isInitialized = true;
      
      // Garantir que os índices existam
      await _createIndexes();
    } catch (e, stackTrace) {
      print('[Database] Erro ao conectar ao MongoDB:');
      print('Erro: $e');
      print('Stack trace: $stackTrace');
      _isInitialized = false;
      rethrow;
    }
  }

  static Future<void> _createIndexes() async {
    try {
      print('Criando índices no MongoDB Atlas...');
      // Índice único para email de usuários
      await _db.collection(MongoDBConfig.usersCollection).createIndex(
        keys: {'email': 1},
        unique: true,
      );

      // Índices para workout_templates
      await _db.collection(MongoDBConfig.workoutTemplatesCollection).createIndex(
        keys: {'createdBy': 1},
      );

      // Índices para exercise_progress
      await _db.collection(MongoDBConfig.exerciseProgressCollection).createIndex(
        keys: {
          'userId': 1,
          'workoutId': 1,
          'exerciseId': 1,
        },
      );
      print('Índices criados com sucesso no MongoDB Atlas');
    } catch (e, stackTrace) {
      print('Erro ao criar índices no MongoDB Atlas:');
      print('Erro: $e');
      print('Stack trace: $stackTrace');
      // Não lançar o erro aqui, pois os índices podem já existir
    }
  }

  static Future<String> checkConnectionStatus() async {
    try {
      print('\n==================== VERIFICAÇÃO DE CONEXÃO ====================');
      print('[checkConnection] Iniciando verificação de conexão...');
      
      if (!_isInitialized) {
        print('[checkConnection] Banco não inicializado. Tentando inicializar...');
        await initialize();
      }
      
      if (!_db.isConnected) {
        print('[checkConnection] ERRO: Banco de dados não está conectado');
        return 'Não conectado ao banco de dados. Estado: Desconectado';
      }

      // Testa a conexão tentando acessar o status do servidor
      try {
        print('[checkConnection] Verificando status do servidor...');
        final status = await _db.serverStatus();
        print('[checkConnection] Status do servidor OK');
        print('[checkConnection] Versão MongoDB: ${status['version']}');
        
        // Tenta listar as collections
        print('[checkConnection] Listando collections...');
        final collections = await _db.getCollectionNames();
        print('[checkConnection] Collections encontradas: ${collections.join(', ')}');
        
        // Tenta acessar a collection de usuários
        print('[checkConnection] Testando acesso à collection de usuários...');
        final userCollection = _db.collection(MongoDBConfig.usersCollection);
        final testQuery = await userCollection.find().toList();
        print('[checkConnection] Collection de usuários acessível');
        print('[checkConnection] Número de documentos: ${testQuery.length}');
        
        final result = '''
Conexão com MongoDB estabelecida com sucesso!

Status:
- Conectado: Sim
- Versão MongoDB: ${status['version']}
- Database: ${_db.databaseName}
- Collections disponíveis: ${collections.join(', ')}
- Collection de usuários: ${collections.contains(MongoDBConfig.usersCollection) ? 'Existe' : 'Não existe'}
- Documentos na collection de usuários: ${testQuery.length}
''';
        print('\nRESULTADO DA VERIFICAÇÃO:');
        print(result);
        print('==============================================================\n');
        return result;
      } catch (e) {
        final errorMsg = '''
Erro ao verificar status do banco:
$e

Por favor, verifique:
1. Se o MongoDB Atlas está acessível
2. Se as credenciais estão corretas
3. Se o IP está liberado no MongoDB Atlas
''';
        print('\nERRO NA VERIFICAÇÃO:');
        print(errorMsg);
        print('==============================================================\n');
        return errorMsg;
      }
    } catch (e) {
      final errorMsg = '''
Erro ao conectar ao banco de dados:
$e

Por favor, verifique:
1. Sua conexão com a internet
2. Se o arquivo .env existe e contém MONGODB_URI
3. Se a string de conexão está correta
''';
      print('\nERRO NA VERIFICAÇÃO:');
      print(errorMsg);
      print('==============================================================\n');
      return errorMsg;
    }
  }

  // Método para testar a conexão
  static Future<bool> testConnection() async {
    try {
      print('\n[testConnection] Iniciando teste de conexão...');
      
      if (!_isInitialized) {
        print('[testConnection] Banco não inicializado. Tentando inicializar...');
        await initialize();
      }
      
      if (!_db.isConnected) {
        print('[testConnection] Banco não está conectado. Tentando conectar...');
        await _db.open();
      }
      
      print('[testConnection] Verificando status do servidor...');
      final status = await _db.serverStatus();
      print('[testConnection] Conexão OK. Versão do MongoDB: ${status['version']}');
      
      print('[testConnection] Listando collections disponíveis...');
      final collections = await _db.getCollectionNames();
      print('[testConnection] Collections: $collections');
      
      return true;
    } catch (e, stackTrace) {
      print('[testConnection] Erro ao testar conexão:');
      print('Erro: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  // Gerenciamento de Sessão
  static Future<void> saveUserSession(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userIdKey, user.id.toHexString());
      await prefs.setString(_userEmailKey, user.email);
      print('Sessão do usuário salva com sucesso');
    } catch (e) {
      print('Erro ao salvar sessão do usuário: $e');
      rethrow;
    }
  }

  static Future<void> clearUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
  }

  static Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString(_userEmailKey);
    if (userEmail == null) return null;
    return await getUserByEmail(userEmail);
  }

  // Usuários
  static Future<User?> getUserByEmail(String email) async {
    try {
      if (!_isInitialized || !_db.isConnected) {
        print('Banco de dados não inicializado ou desconectado');
        await initialize();
      }

      final userCollection = _db.collection(MongoDBConfig.usersCollection);
      print('Buscando usuário com email: $email');
      
      final userData = await userCollection.findOne(mongo.where.eq('email', email));
      if (userData == null) {
        print('Usuário não encontrado');
        return null;
      }
      
      print('Usuário encontrado: ${userData.toString()}');
      return User.fromMap(userData);
    } catch (e, stackTrace) {
      print('Erro ao buscar usuário:');
      print('Erro: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  static Future<bool> createUser(User user) async {
    try {
      print('\n==================== CRIAÇÃO DE USUÁRIO ====================');
      if (!_isInitialized || !_db.isConnected) {
        print('[createUser] Banco não inicializado/conectado. Tentando reconectar...');
        await initialize();
      }

      print('[createUser] Verificando conexão com o banco...');
      if (!_db.isConnected) {
        print('[createUser] ERRO: Banco ainda não está conectado após inicialização');
        return false;
      }

      final userCollection = _db.collection(MongoDBConfig.usersCollection);
      
      // Verifica se a collection existe e está acessível
      print('[createUser] Verificando acesso à collection...');
      try {
        final testQuery = await userCollection.find().toList();
        print('[createUser] Collection está acessível. ${testQuery.length} documentos encontrados');
      } catch (e) {
        print('[createUser] ERRO ao acessar collection:');
        print(e);
        return false;
      }
      
      final userMap = user.toMap();
      print('[createUser] Dados do usuário para inserção:');
      userMap.forEach((key, value) {
        if (key != 'password') {
          print('  $key: $value');
        }
      });

      // Verifica se o e-mail já existe
      print('[createUser] Verificando se e-mail já existe: ${user.email}');
      final existingUser = await userCollection.findOne({'email': user.email});
      if (existingUser != null) {
        print('[createUser] ERRO: E-mail já está em uso: ${user.email}');
        return false;
      }

      // Tenta inserir o usuário
      try {
        print('[createUser] Iniciando inserção no banco...');
        final result = await userCollection.insertOne(userMap);
        print('[createUser] Resultado da inserção:');
        print('  isSuccess: ${result.isSuccess}');
        print('  id: ${result.id}');
        
        if (result.isSuccess) {
          // Verifica se o documento foi realmente inserido
          final inserted = await userCollection.findOne({'_id': result.id});
          if (inserted != null) {
            print('[createUser] Documento inserido com sucesso e verificado');
            print('==============================================================\n');
            return true;
          } else {
            print('[createUser] ERRO: Documento não encontrado após inserção');
            print('==============================================================\n');
            return false;
          }
        } else {
          if (result.writeError != null) {
            print('[createUser] ERRO na inserção:');
            print('  Mensagem: ${result.writeError?.errmsg}');
            print('  Código: ${result.writeError?.code}');
          }
          print('==============================================================\n');
          return false;
        }
      } catch (insertError, stackTrace) {
        print('[createUser] ERRO ao inserir usuário no banco:');
        print('Erro: $insertError');
        print('Stack trace: $stackTrace');
        print('==============================================================\n');
        return false;
      }
    } catch (e, stackTrace) {
      print('[createUser] ERRO geral ao criar usuário:');
      print('Erro: $e');
      print('Stack trace: $stackTrace');
      print('==============================================================\n');
      return false;
    }
  }

  static Future<bool> updateUser(User user) async {
    try {
      final userCollection = _db.collection(MongoDBConfig.usersCollection);
      await userCollection.update(
        mongo.where.eq('_id', user.id),
        user.toMap(),
      );
      return true;
    } catch (e) {
      print('Erro ao atualizar usuário: $e');
      return false;
    }
  }

  // Fichas de Treino
  static Future<List<WorkoutTemplate>> getWorkoutTemplates({
    bool presetsOnly = false,
    mongo.ObjectId? userId,
  }) async {
    try {
      print('\n[Database] Buscando templates de treino...');
      print('  presetsOnly: $presetsOnly');
      print('  userId: $userId');

      if (!_isInitialized || !_db.isConnected) {
        print('[Database] Banco não inicializado/conectado. Tentando reconectar...');
        await initialize();
      }

      final templateCollection = _db.collection(MongoDBConfig.workoutTemplatesCollection);
      
      // Constrói a query baseada nos parâmetros
      mongo.SelectorBuilder query;
      if (presetsOnly) {
        query = mongo.where.eq('isPreset', true);
      } else if (userId != null) {
        query = mongo.where.eq('createdBy', userId);
      } else {
        query = mongo.where.eq('isPreset', true);
      }

      print('[Database] Executando query:');
      print('  ${query.toString()}');

      final templates = await templateCollection.find(query).toList();
      print('[Database] Templates encontrados: ${templates.length}');
      
      // Log detalhado dos templates encontrados
      for (var t in templates) {
        print('\n[Database] Template encontrado:');
        print('  _id: ${t['_id']}');
        print('  name: ${t['name']}');
        print('  createdBy: ${t['createdBy']}');
        print('  isPreset: ${t['isPreset']}');
      }

      final result = templates.map((t) {
        try {
          print('\n[Database] Convertendo template:');
          print('  _id: ${t['_id']}');
          print('  name: ${t['name']}');
          print('  exercises: ${t['exercises']?.length ?? 0} exercícios');
          return WorkoutTemplate.fromMap(t);
        } catch (e, stackTrace) {
          print('[Database] ERRO ao converter template:');
          print('Erro: $e');
          print('Stack trace: $stackTrace');
          print('Template com erro: $t');
          rethrow;
        }
      }).toList();

      print('[Database] Templates convertidos com sucesso: ${result.length}');
      return result;
    } catch (e, stackTrace) {
      print('[Database] Erro ao buscar templates:');
      print('Erro: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  static Future<bool> saveWorkoutTemplate(WorkoutTemplate template) async {
    try {
      print('\n[Database] Salvando template de treino...');
      print('  name: ${template.name}');
      print('  createdBy: ${template.createdBy}');
      
      if (!_isInitialized || !_db.isConnected) {
        print('[Database] Banco não inicializado/conectado. Tentando reconectar...');
        await initialize();
      }

      final templateCollection = _db.collection(MongoDBConfig.workoutTemplatesCollection);
      final templateMap = template.toMap();
      
      print('[Database] Dados do template para inserção:');
      templateMap.forEach((key, value) {
        print('  $key: $value');
      });

      final result = await templateCollection.insertOne(templateMap);
      
      print('[Database] Resultado da inserção:');
      print('  isSuccess: ${result.isSuccess}');
      print('  id: ${result.id}');
      
      return result.isSuccess;
    } catch (e, stackTrace) {
      print('[Database] Erro ao salvar template:');
      print('Erro: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  static Future<bool> updateWorkoutTemplate(WorkoutTemplate template) async {
    try {
      final templateCollection = _db.collection(MongoDBConfig.workoutTemplatesCollection);
      await templateCollection.update(
        mongo.where.eq('_id', template.id),
        template.toMap(),
      );
      return true;
    } catch (e) {
      print('Erro ao atualizar template: $e');
      return false;
    }
  }

  // Progresso dos Exercícios
  static Future<bool> updateExerciseProgress(
    mongo.ObjectId userId,
    mongo.ObjectId workoutId,
    mongo.ObjectId exerciseId,
    ExerciseProgress progress,
  ) async {
    try {
      final progressCollection = _db.collection(MongoDBConfig.exerciseProgressCollection);
      await progressCollection.update(
        mongo.where.and([
          mongo.where.eq('userId', userId),
          mongo.where.eq('workoutId', workoutId),
          mongo.where.eq('exerciseId', exerciseId),
        ] as mongo.SelectorBuilder),
        {
          r'$push': {
            'progressHistory': progress.toMap(),
          },
        },
        upsert: true,
      );
      return true;
    } catch (e) {
      print('Erro ao atualizar progresso: $e');
      return false;
    }
  }

  // Histórico de Peso
  static Future<bool> addWeightHistory(
    mongo.ObjectId userId,
    WeightHistory weightHistory,
  ) async {
    try {
      final userCollection = _db.collection(MongoDBConfig.usersCollection);
      await userCollection.update(
        mongo.where.eq('_id', userId),
        {
          r'$push': {
            'weightHistory': weightHistory.toMap(),
          },
        },
      );
      return true;
    } catch (e) {
      print('Erro ao adicionar histórico de peso: $e');
      return false;
    }
  }

  // Atualização de Peso
  static Future<bool> updateUserWeight(String email, double newWeight) async {
    try {
      if (!_isInitialized || !_db.isConnected) {
        print('[updateUserWeight] Banco de dados não inicializado ou desconectado');
        await initialize();
      }

      final userCollection = _db.collection(MongoDBConfig.usersCollection);
      print('[updateUserWeight] Atualizando peso do usuário: $email');
      
      // Busca o usuário atual
      final userData = await userCollection.findOne(mongo.where.eq('email', email));
      if (userData == null) {
        print('[updateUserWeight] Usuário não encontrado');
        return false;
      }

      // Converte para objeto User
      final user = User.fromMap(userData);
      
      // Adiciona o novo peso ao histórico com o horário de Brasília
      final now = DateTime.now().toLocal();
      print('[updateUserWeight] Horário do registro: ${now.toString()}');
      
      user.weightHistory.add(WeightHistory(
        date: now,
        weight: newWeight,
      ));

      // Atualiza o peso atual
      user.weight = newWeight;

      // Atualiza no banco de dados
      await userCollection.update(
        mongo.where.eq('email', email),
        {
          r'$set': {
            'weight': newWeight,
            'weightHistory': user.weightHistory.map((w) => w.toMap()).toList(),
          }
        },
      );

      print('[updateUserWeight] Peso atualizado com sucesso');
      return true;
    } catch (e) {
      print('[updateUserWeight] Erro ao atualizar peso: $e');
      return false;
    }
  }

  static Future<bool> toggleWorkoutFavorite(mongo.ObjectId workoutId) async {
    try {
      print('[Database] Alternando favorito para treino: $workoutId');
      
      if (!_isInitialized) {
        print('[Database] Banco não inicializado. Tentando inicializar...');
        await initialize();
      }

      final workoutCollection = _db.collection(MongoDBConfig.workoutTemplatesCollection);
      
      // Primeiro, busca o treino para saber o estado atual do isFavorite
      final workout = await workoutCollection.findOne(
        mongo.where.id(workoutId),
      );

      if (workout == null) {
        print('[Database] Treino não encontrado: $workoutId');
        return false;
      }

      // Inverte o valor atual de isFavorite
      final newIsFavorite = !(workout['isFavorite'] as bool? ?? false);

      // Atualiza o documento
      final result = await workoutCollection.updateOne(
        mongo.where.id(workoutId),
        mongo.modify.set('isFavorite', newIsFavorite),
      );

      print('[Database] Treino atualizado: ${result.isSuccess}');
      return result.isSuccess;
    } catch (e) {
      print('[Database] Erro ao alternar favorito: $e');
      return false;
    }
  }

  static Future<void> close() async {
    if (_isInitialized) {
      await _db.close();
      _isInitialized = false;
    }
  }
} 