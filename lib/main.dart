import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/insumos_screen.dart';
import 'screens/producao_screen.dart';
import 'screens/produtos_screen.dart';
import 'screens/relatorio_screen.dart';
import 'screens/vendas_screen.dart';
import 'store.dart';
import 'theme.dart';
import 'widgets.dart';

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
