import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../models/cart_item.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  _StoreScreenState createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final List<CartItem> _cartItems = [];
  bool _isCartVisible = false;

  final List<Product> products = [
    Product(
      id: '1',
      name: 'Whey Protein Isolado',
      description: 'Whey protein isolado de alta qualidade, 900g',
      price: 159.90,
      imageUrl: 'assets/images/products/whey.jpg',
    ),
    Product(
      id: '2',
      name: 'Barra de Proteína',
      description: 'Caixa com 12 barras proteicas de 45g',
      price: 79.90,
      imageUrl: 'assets/images/products/protein_bar.jpg',
    ),
    Product(
      id: '3',
      name: 'BCAA em Pó',
      description: 'BCAA 2:1:1 em pó, 200g',
      price: 49.90,
      imageUrl: 'assets/images/products/bcaa.jpg',
    ),
    Product(
      id: '4',
      name: 'Creatina',
      description: 'Creatina monohidratada pura, 300g',
      price: 89.90,
      imageUrl: 'assets/images/products/creatine.jpg',
    ),
    Product(
      id: '5',
      name: 'Pré-treino',
      description: 'Pré-treino energético, 300g',
      price: 119.90,
      imageUrl: 'assets/images/products/pre_workout.jpg',
    ),
    Product(
      id: '6',
      name: 'Coqueteleira',
      description: 'Coqueteleira com divisória, 600ml',
      price: 29.90,
      imageUrl: 'assets/images/products/shaker.jpg',
    ),
  ];

  void _addToCart(Product product) {
    setState(() {
      final existingItem = _cartItems.firstWhere(
        (item) => item.product.id == product.id,
        orElse: () => CartItem(product: product, quantity: 0),
      );

      if (existingItem.quantity == 0) {
        _cartItems.add(CartItem(product: product));
      } else {
        existingItem.quantity++;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} adicionado ao carrinho'),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'Ver Carrinho',
            onPressed: () {
              setState(() {
                _isCartVisible = true;
              });
            },
          ),
        ),
      );
    });
  }

  void _removeFromCart(CartItem item) {
    setState(() {
      if (item.quantity > 1) {
        item.quantity--;
      } else {
        _cartItems.remove(item);
      }
    });
  }

  double get _cartTotal {
    return _cartItems.fold(0, (total, item) => total + item.total);
  }

  Widget _buildCartItem(CartItem item) {
    return ListTile(
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Image.asset(
          item.product.imageUrl,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.fitness_center,
              color: Theme.of(context).colorScheme.primary,
            );
          },
        ),
      ),
      title: Text(
        item.product.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        'R\$ ${item.product.price.toStringAsFixed(2)} x ${item.quantity}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'R\$ ${item.total.toStringAsFixed(2)}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () => _removeFromCart(item),
          ),
        ],
      ),
    );
  }

  Widget _buildCart() {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          AppBar(
            title: const Text('Carrinho'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  _isCartVisible = false;
                });
              },
            ),
          ),
          if (_cartItems.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Seu carrinho está vazio',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _cartItems.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) => _buildCartItem(_cartItems[index]),
              ),
            ),
          if (_cartItems.isNotEmpty)
            SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          'R\$ ${_cartTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          // TODO: Implementar checkout
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Compra finalizada com sucesso!'),
                            ),
                          );
                          setState(() {
                            _cartItems.clear();
                            _isCartVisible = false;
                          });
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Finalizar Compra'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCartVisible) {
      return _buildCart();
    }

    return Scaffold(
      appBar: AppBar(
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () {
                  setState(() {
                    _isCartVisible = true;
                  });
                },
              ),
              if (_cartItems.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _cartItems.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    ),
                    child: Image.asset(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.fitness_center,
                            size: 48,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'R\$ ${product.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => _addToCart(product),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: const Text('Adicionar'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
