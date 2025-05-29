import 'dart:io';

void main() {
  // Verifica se o arquivo .env existe
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    print('ERRO: Arquivo .env não encontrado!');
    print('Por favor, crie o arquivo .env na raiz do projeto com o seguinte conteúdo:');
    print('''
MONGODB_USER=rubens13mota
MONGODB_PASSWORD="\$RubensMota13\$"
MONGODB_HOST=cluster0.qqpvsgb.mongodb.net
MONGODB_DATABASE=strongone
PORT=3000
''');
    exit(1);
  }

  // Lê o conteúdo do arquivo
  final content = envFile.readAsStringSync();
  print('Conteúdo do arquivo .env:');
  print(content);

  // Verifica se todas as variáveis necessárias estão presentes
  final requiredVars = [
    'MONGODB_USER',
    'MONGODB_PASSWORD',
    'MONGODB_HOST',
    'MONGODB_DATABASE',
    'PORT'
  ];

  final missingVars = [];
  for (final var_ in requiredVars) {
    if (!content.contains(var_)) {
      missingVars.add(var_);
    }
  }

  if (missingVars.isNotEmpty) {
    print('\nERRO: Variáveis ausentes no arquivo .env:');
    for (final var_ in missingVars) {
      print('- $var_');
    }
    exit(1);
  }

  print('\nArquivo .env está configurado corretamente!');
} 