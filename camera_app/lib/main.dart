import 'package:flutter/material.dart';
import 'Camera.dart';
import 'Layout/BottomBar.dart';
import 'Galery.dart'; // Importa a página da galeria ou outras páginas que você tem

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BarberEase',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.white,
          brightness: Brightness.dark,
        ).copyWith(
          // primary: Colors.white,
          // secondary: Colors.black,
          // surface: Colors.black,
          // onSurface: Colors.white,
          // onPrimary: Colors.white,
          // onSecondary: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(), // Altera para HomeScreen
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Índice da página selecionada

  // Lista de widgets das páginas
  final List<Widget> _pages = [
    MyHomePage(title: 'BarberEase'), // Sua página inicial
    Galery(),
    Camera(), // A página da galeria que você criou
    // Adicione mais páginas conforme necessário
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Atualiza o índice selecionado
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BarberEase'),
      ),
      body: _pages[
          _selectedIndex], // Renderiza a página com base no índice selecionado
      bottomNavigationBar: Bottombar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped, // Passa a função para mudar de página
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

// Aqui está sua classe MyHomePage
class MyHomePage extends StatelessWidget {
  final String title;

  const MyHomePage({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child:
          Text('Bem vindo ao BarberEase...'), // O botão central que você já tem
    );
  }
}

// Certifique-se de que sua classe Bottombar aceita os parâmetros currentIndex e onTap
class Bottombar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const Bottombar({Key? key, required this.currentIndex, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.image),
          label: 'Gallery',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.photo_camera),
          label: 'Picture',
        ),
        // Adicione mais itens conforme necessário
      ],
      currentIndex: currentIndex,
      onTap: onTap, // Chama a função quando um item é pressionado
    );
  }
}
