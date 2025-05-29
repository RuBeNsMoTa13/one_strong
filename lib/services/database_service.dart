import 'package:mongo_dart/mongo_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/workout_template.dart';
import '../config/mongodb_config.dart';

class DatabaseService {
  static late Db _db;
  static bool _isInitialized = false;
  static const String _userIdKey = 'userId';
  static const String _userEmailKey = 'userEmail';

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('\n[Database] Iniciando conexão com MongoDB...');
      print('[Database] String de conexão: ${MongoDBConfig.connectionString}');
      
      _db = await Db.create(MongoDBConfig.connectionString);
      
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
      
      final userData = await userCollection.findOne(where.eq('email', email));
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
        where.eq('_id', user.id),
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
    ObjectId? userId,
  }) async {
    try {
      final templateCollection = _db.collection(MongoDBConfig.workoutTemplatesCollection);
      final query = presetsOnly
          ? where.eq('isPreset', true)
          : where.or([
              where.eq('isPreset', true),
              if (userId != null) where.eq('createdBy', userId),
            ] as SelectorBuilder);

      final templates = await templateCollection.find(query).toList();
      return templates.map((t) => WorkoutTemplate.fromMap(t)).toList();
    } catch (e) {
      print('Erro ao buscar templates: $e');
      return [];
    }
  }

  static Future<bool> saveWorkoutTemplate(WorkoutTemplate template) async {
    try {
      final templateCollection = _db.collection(MongoDBConfig.workoutTemplatesCollection);
      await templateCollection.insert(template.toMap());
      return true;
    } catch (e) {
      print('Erro ao salvar template: $e');
      return false;
    }
  }

  static Future<bool> updateWorkoutTemplate(WorkoutTemplate template) async {
    try {
      final templateCollection = _db.collection(MongoDBConfig.workoutTemplatesCollection);
      await templateCollection.update(
        where.eq('_id', template.id),
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
    ObjectId userId,
    ObjectId workoutId,
    ObjectId exerciseId,
    ExerciseProgress progress,
  ) async {
    try {
      final progressCollection = _db.collection(MongoDBConfig.exerciseProgressCollection);
      await progressCollection.update(
        where.and([
          where.eq('userId', userId),
          where.eq('workoutId', workoutId),
          where.eq('exerciseId', exerciseId),
        ] as SelectorBuilder),
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
    ObjectId userId,
    WeightHistory weightHistory,
  ) async {
    try {
      final userCollection = _db.collection(MongoDBConfig.usersCollection);
      await userCollection.update(
        where.eq('_id', userId),
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
      final userData = await userCollection.findOne(where.eq('email', email));
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
        where.eq('email', email),
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

  static Future<void> close() async {
    if (_isInitialized) {
      await _db.close();
      _isInitialized = false;
    }
  }
} 