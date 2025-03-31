require('dotenv').config();
const express = require('express');
const { MongoClient, ServerApiVersion } = require('mongodb');
const cors = require('cors');
const app = express();
const PORT = process.env.PORT || 3000;

// Habilita CORS para todas as origens
app.use(cors());

// Middleware para parsing JSON
app.use(express.json({ limit: '10kb' }));

// Conexão com MongoDB
const client = new MongoClient(process.env.MONGODB_URI, {
  serverApi: {
    version: ServerApiVersion.v1,
    strict: true,
    deprecationErrors: true,
  },
  connectTimeoutMS: 5000,
  socketTimeoutMS: 30000
});

// Database connection
async function run() {
  try {
    await client.connect();
    console.log("✅ Connected to MongoDB!");
    
    const db = client.db("strongone");
    const usersCollection = db.collection("users");

    // Rota de saúde do servidor
    app.get('/api/health', (req, res) => {
      res.status(200).json({ 
        status: 'OK', 
        message: 'Server is running',
        database: client.topology.isConnected() ? 'Connected' : 'Disconnected',
        timestamp: new Date().toISOString()
      });
    });

    // Rota de registro
    app.post('/api/register', async (req, res) => {
      try {
        console.log('Corpo da requisição recebido:', req.body);
        const { name, email, password } = req.body;
        
        if (!email || !password) {
          return res.status(400).json({ 
            success: false,
            error: "Email e senha são obrigatórios" 
          });
        }
    
        const existingUser = await usersCollection.findOne({ email });
        if (existingUser) {
          return res.status(409).json({ 
            success: false,
            error: "E-mail já cadastrado" 
          });
        }
    
        const result = await usersCollection.insertOne({
          name,
          email,
          password, // Em produção: use bcrypt!
          createdAt: new Date()
        });
    
        if (result.insertedId) {
          return res.status(201).json({
            success: true,
            message: "Usuário cadastrado com sucesso",
            userId: result.insertedId.toString() // Converta para string
          });
        } else {
          return res.status(500).json({ 
            success: false,
            error: "Erro ao registrar o usuário" 
          });
        }
    
      } catch (err) {
        console.error("Erro no registro:", err);
        return res.status(500).json({ 
          success: false,
          error: "Erro interno no servidor"
        });
      }
    });

    // Middleware para rotas não encontradas
    app.use((req, res) => {
      res.status(404).json({
        success: false,
        error: "Endpoint not found",
      });
    });

    // Inicia o servidor
    app.listen(PORT, () => {
      console.log(`🚀 Server running on http://localhost:${PORT}`);
    });

  } catch (err) {
    console.error("❌ MongoDB connection error:", err);
    process.exit(1);
  }
}

// Inicia a aplicação
run().catch(err => {
  console.error('❌ Fatal error:', err);
  process.exit(1);
});

// Manipuladores para encerramento limpo
process.on('SIGINT', async () => {
  await client.close();
  console.log('🛑 Server gracefully shutdown');
  process.exit(0);
});

process.on('unhandledRejection', err => {
  console.error('⚠️ Unhandled rejection:', err);
});
