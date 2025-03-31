// home_screen.dart
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('StrongOne - Treinos')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Bem-vindo ao StrongOne!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Treino para Iniciantes'),
            ),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Treino Avançado'),
            ),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Treino de Força'),
            ),
          ],
        ),
      ),
    );
  }
}
