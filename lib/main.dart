import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'abertura.dart';
import 'exemplo.dart';
import 'models.dart';
import 'screens/insumos_screen.dart';
import 'screens/producao_screen.dart';
import 'screens/produtos_screen.dart';
import 'screens/relatorio_screen.dart';
import 'screens/vendas_screen.dart';
import 'store.dart';
import 'theme.dart';
import 'widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  final store = Store();
  await store.carregar();
  if (const bool.fromEnvironment('EXEMPLO') && store.produtos.isEmpty) {
    await carregarExemplo(store);
  }
  // Espera as fontes (até 2 s) com a tela nativa ainda na frente: a abertura
  // já aparece com a letra certa, sem trocar de fonte no meio.
  await GoogleFonts.pendingFonts([GoogleFonts.newsreader(), GoogleFonts.figtree()])
      .timeout(const Duration(seconds: 2), onTimeout: () => const []);
  runApp(ConfeitariaApp(store: store));
}

class ConfeitariaApp extends StatelessWidget {
  final Store store;
  const ConfeitariaApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: store.tema,
      builder: (context, tema, _) => MaterialApp(
        title: 'Doce Controle',
        debugShowCheckedModeBanner: false,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: temaClaro,
        darkTheme: temaEscuro,
        themeMode: switch (tema) {
          TemaApp.sistema => ThemeMode.system,
          TemaApp.claro => ThemeMode.light,
          TemaApp.escuro => ThemeMode.dark,
        },
        // Troca claro/escuro com as cores se misturando, sem piscar.
        themeAnimationDuration: Movimento.lento,
        themeAnimationCurve: Curves.easeInOut,
        builder: (context, child) => GestureDetector(
          // Tocar fora de um campo fecha o teclado em qualquer tela.
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          // Acompanha o tamanho de letra do celular, mas sem passar de 130%
          // para os números e as listas não quebrarem.
          child: MediaQuery.withClampedTextScaling(maxScaleFactor: 1.3, child: child!),
        ),
        home: Abertura(child: Home(store: store)),
      ),
    );
  }
}

class Home extends StatefulWidget {
  final Store store;
  const Home({super.key, required this.store});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _paginas = PageController();
  int _aba = 0;

  late final List<Widget> _telas = [
    RelatorioScreen(store: widget.store),
    VendasScreen(store: widget.store),
    ProducaoScreen(store: widget.store),
    ProdutosScreen(store: widget.store),
    InsumosScreen(store: widget.store),
  ];

  void _irPara(int i) {
    if (i == _aba || !_paginas.hasClients) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _paginas.jumpToPage(i);
      return;
    }
    // Para abas distantes, pula para a vizinha e anima só o último passo,
    // em vez de atravessar as telas do meio.
    if ((i - _aba).abs() > 1) _paginas.jumpToPage(i > _aba ? i - 1 : i + 1);
    _paginas.animateToPage(i, duration: Movimento.pagina, curve: Movimento.entrada);
  }

  @override
  void dispose() {
    _paginas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _paginas,
        onPageChanged: (i) => setState(() => _aba = i),
        children: [for (final t in _telas) ManterViva(child: t)],
      ),
      bottomNavigationBar: NavAnimada(
        controller: _paginas,
        atual: _aba,
        onTap: _irPara,
        itens: const [
          ItemNav(Icons.bar_chart_outlined, Icons.bar_chart, 'Relatório'),
          ItemNav(Icons.receipt_long_outlined, Icons.receipt_long, 'Vendas'),
          ItemNav(Icons.bakery_dining_outlined, Icons.bakery_dining, 'Produção'),
          ItemNav(Icons.cake_outlined, Icons.cake, 'Produtos'),
          ItemNav(Icons.egg_outlined, Icons.egg, 'Ingredientes'),
        ],
      ),
    );
  }
}
