import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'abertura.dart';
import 'exemplo.dart';
import 'screens/mais_screen.dart';
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
    // Por enquanto só o tema claro (o escuro continua em theme.dart para depois).
    return MaterialApp(
      title: 'Controler Spent',
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: temaClaro,
      builder: (context, child) => GestureDetector(
        // Tocar fora de um campo fecha o teclado em qualquer tela.
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        // Acompanha o tamanho de letra do celular, mas sem passar de 130%
        // para os números e as listas não quebrarem.
        child: MediaQuery.withClampedTextScaling(maxScaleFactor: 1.3, child: child!),
      ),
      home: Abertura(child: Home(store: store)),
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
  final _paginas = PageController(initialPage: 0); // abre em Relatório
  int _aba = 0;

  late final List<Widget> _telas = [
    RelatorioScreen(store: widget.store),
    VendasScreen(store: widget.store),
    ProducaoScreen(store: widget.store),
    ProdutosScreen(store: widget.store),
    MaisScreen(store: widget.store),
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
      // Com mais de uma loja, as abas das lojas ficam no topo de todas as telas.
      // A estrutura é sempre a mesma (só a faixa some), para as abas de baixo
      // não perderem a página em que estão quando a segunda loja é criada.
      body: ListenableBuilder(
        listenable: widget.store,
        builder: (context, paginas) {
          final varias = widget.store.lojas.length > 1;
          return Column(children: [
            _AbasLojas(store: widget.store),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: varias,
                child: paginas!,
              ),
            ),
          ]);
        },
        child: PageView(
          controller: _paginas,
          onPageChanged: (i) => setState(() => _aba = i),
          children: [for (final t in _telas) ManterViva(child: t)],
        ),
      ),
      bottomNavigationBar: NavAnimada(
        controller: _paginas,
        atual: _aba,
        onTap: _irPara,
        itens: const [
          ItemNav(Icons.bar_chart_outlined, Icons.bar_chart, 'Relatório'),
          ItemNav(Icons.receipt_long_outlined, Icons.receipt_long, 'Vendas'),
          ItemNav(Icons.soup_kitchen_outlined, Icons.soup_kitchen, 'Produção'),
          ItemNav(Icons.storefront_outlined, Icons.storefront, 'Produtos'),
          ItemNav(Icons.more_horiz, Icons.more_horiz, 'Mais'),
        ],
      ),
    );
  }
}

/// As lojas em abas, no alto do app; um toque troca de loja. Só aparece quando
/// existe mais de uma.
class _AbasLojas extends StatelessWidget {
  final Store store;
  const _AbasLojas({required this.store});

  @override
  Widget build(BuildContext context) {
    if (store.lojas.length < 2) return const SizedBox.shrink();
    final c = context.cores;
    final t = context.tipos;
    final atual = store.lojaAtual.id;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.papel,
        border: Border(bottom: BorderSide(color: c.linha)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 46,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Espaco.borda - Espaco.s),
            children: [
              for (final l in store.lojas)
                InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    store.trocarLoja(l.id);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Espaco.s),
                    // O traço embaixo tem a largura do nome da loja.
                    child: IntrinsicWidth(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Expanded(
                          child: Row(children: [
                            if (l.fotoBase64 != null) ...[
                              AvatarLoja(l, tamanho: 22),
                              const SizedBox(width: Espaco.s),
                            ],
                            Text(
                              l.nome,
                              style: t.corpo(
                                peso: l.id == atual ? FontWeight.w700 : FontWeight.w500,
                                color: l.id == atual ? c.tinta : c.tintaSuave,
                              ),
                            ),
                          ]),
                        ),
                        AnimatedContainer(
                          duration: Movimento.medio,
                          curve: Movimento.entrada,
                          height: 3,
                          color: l.id == atual ? c.acao : Colors.transparent,
                        ),
                      ]),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
