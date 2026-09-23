// Para usar este arquivo:
// 1. Adicione a dependência no pubspec.yaml:
//      dependencies:
//        http: ^1.2.0
//    (ou rode: flutter pub add http)
// 2. Substitua o conteúdo de lib/main.dart por este arquivo.
// 3. No Android, garanta a permissão de internet em
//    android/app/src/main/AndroidManifest.xml:
//      <uses-permission android:name="android.permission.INTERNET"/>
//    (já vem habilitada nos builds de debug padrão)

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MyApp());

// ---------------------------------------------------------------------------
// Modelos
// ---------------------------------------------------------------------------

class Rating {
  final double rate;
  final int count;

  Rating({required this.rate, required this.count});

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      rate: (json['rate'] as num).toDouble(),
      count: (json['count'] as num).toInt(),
    );
  }
}

class Product {
  final int id;
  final String title;
  final double price;
  final String description;
  final String category;
  final String image;
  final Rating rating;

  Product({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.image,
    required this.rating,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      title: json['title'] as String,
      price: (json['price'] as num).toDouble(),
      description: json['description'] as String,
      category: json['category'] as String,
      image: json['image'] as String,
      rating: Rating.fromJson(json['rating'] as Map<String, dynamic>),
    );
  }
}

// ---------------------------------------------------------------------------
// Serviço de API
// ---------------------------------------------------------------------------

class ProductService {
  static const String _url = 'https://fakestoreapi.com/products/10';

  Future<Product> fetchProduct() async {
    final response =
        await http.get(Uri.parse(_url)).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return Product.fromJson(data as Map<String, dynamic>);
    } else {
      throw Exception('Erro ao carregar produto (HTTP ${response.statusCode})');
    }
  }
}

// ---------------------------------------------------------------------------
// App
// ---------------------------------------------------------------------------

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FakeStore Produto',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const ProductPage(),
    );
  }
}

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final ProductService _service = ProductService();
  late Future<Product> _futureProduct;

  @override
  void initState() {
    super.initState();
    _futureProduct = _service.fetchProduct();
  }

  Future<void> _reload() async {
    setState(() {
      _futureProduct = _service.fetchProduct();
    });
    await _futureProduct.catchError((_) => Product(
          id: 0,
          title: '',
          price: 0,
          description: '',
          category: '',
          image: '',
          rating: Rating(rate: 0, count: 0),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Produto'),
        centerTitle: true,
      ),
      body: FutureBuilder<Product>(
        future: _futureProduct,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 56, color: Colors.redAccent),
                    const SizedBox(height: 12),
                    Text(
                      'Não foi possível carregar o produto.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          final product = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _reload,
            child: ProductDetails(product: product),
          );
        },
      ),
    );
  }
}

class ProductDetails extends StatelessWidget {
  final Product product;

  const ProductDetails({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          elevation: 2,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            height: 280,
            child: Image.network(
              product.image,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(Icons.broken_image, size: 64, color: Colors.grey),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Chip(
          label: Text(product.category),
          avatar: const Icon(Icons.category, size: 18),
        ),
        const SizedBox(height: 8),
        Text(
          product.title,
          style: theme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              'US\$ ${product.price.toStringAsFixed(2)}',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            const Icon(Icons.star, color: Colors.amber),
            const SizedBox(width: 4),
            Text(
              '${product.rating.rate.toStringAsFixed(1)} '
              '(${product.rating.count})',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
        const Divider(height: 32),
        Text('Descrição', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(product.description, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 24),
        Text(
          'ID do produto: ${product.id}',
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
      ],
    );
  }
}
