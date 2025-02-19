import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'Camera.dart';
import 'Layout/BottomBar.dart';
import 'Galery.dart'; // Importa a página da galeria ou outras páginas que você tem
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
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
        ).copyWith(),
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

  //Variáveis para os anúncios
  late BannerAd _bannerAd;
  bool _isBannerAdLoaded = false;

  InterstitialAd? _interstitialAd;

  final String adUnitId = 'ca-app-pub-3940256099942544/1033173712'; 

  // Lista de widgets das páginas
  final List<Widget> _pages = [
    MyHomePage(title: 'BarberEase'), // Sua página inicial
    Galery(),
    Camera(), // A página da galeria que você criou
    // Adicione mais páginas conforme necessário
  ];

  @override
  void initState() {
    super.initState();
    _loadBannerAd(); // Chama a função para carregar o banner ao iniciar
    _loadInterstitialAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          print('Ad loaded: ${ad.adUnitId}');
          setState(() {
            _isBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          print('Failed to load banner ad: $error');
          ad.dispose();
        },
      ),
    );
    _bannerAd.load();
  }
  
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('Falha ao carregar o anúncio: $error');
          _interstitialAd = null;
        },
      ),
    );
  }

  void _showInterstitialAd(VoidCallback onAdClosed) {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadInterstitialAd(); // Recarrega um novo anúncio
          onAdClosed(); // Chama a função para mudar de tela
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('Erro ao exibir anúncio: $error');
          ad.dispose();
          onAdClosed(); // Se falhar, muda de tela direto
        },
      );

      _interstitialAd!.show();
    } else {
      onAdClosed(); // Se não houver anúncio, muda de tela direto
    }
  }

  @override
  void dispose() {
    super.dispose();
    _bannerAd.dispose(); // Libera o banner quando a tela for descartada
  }

  void _onItemTapped(int index) {
    if(index == 1 || index == 2){
      _showInterstitialAd((){
        setState((){
          _selectedIndex = index;
        });
      });
    }
    else{
        setState((){
          _selectedIndex = index;
        });
    }
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('BarberEase'),
      ),
      body: Stack(
        children: [
          //Página Ativa
          _pages[_selectedIndex],

          //Exibe o banner se carregado
          if (_isBannerAdLoaded)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 50,
                child: AdWidget(ad: _bannerAd), // Exibe o banner
              ),
            ),
        ],
      ),
      bottomNavigationBar: Bottombar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped, // Passa a função para mudar de página
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class MyHomePage extends StatelessWidget {
  final String title;

  const MyHomePage({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Bem-vindo ao BarberEase...'), // O botão central que você já tem
    );
  }
}

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
