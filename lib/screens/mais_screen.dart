import 'package:flutter/material.dart';

import '../receitas_prontas.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'ajustes_screen.dart';
import 'insumos_screen.dart';
import 'receitas_prontas_screen.dart';

/// Aba "Mais": o que é de cadastro e ajuste e se usa menos no dia a dia.
class MaisScreen extends StatelessWidget {
  final Store store;
  const MaisScreen({super.key, required this.store});

  void _abrir(BuildContext context, Widget tela) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => tela));

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final c = context.cores;
        final t = context.tipos;
        final ingredientes = store.insumos.where((i) => !i.ehEmbalagem).length;
        final embalagens = store.insumos.length - ingredientes;
        final prontas = receitasProntas.where((m) => !jaAdicionada(store, m)).length;

        Widget item(IconData icone, String titulo, String apoio, VoidCallback onTap) => ListTile(
              minVerticalPadding: Espaco.m,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: c.realce,
                  borderRadius: BorderRadius.circular(Raio.pequeno),
                ),
                child: Icon(icone, color: c.acao, size: 22),
              ),
              title: Text(titulo),
              subtitle: Text(apoio),
              trailing: Icon(Icons.chevron_right, color: c.tintaSuave),
              onTap: onTap,
            );

        return Scaffold(
          appBar: AppBar(title: const Text('Mais')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(Espaco.borda, Espaco.s, Espaco.borda, Espaco.secao),
            children: [
              EntradaSuave(
                child: Row(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(Raio.medio),
                    child: Image.asset('assets/logo/icone.png', width: 56, height: 56),
                  ),
                  const SizedBox(width: Espaco.l),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(store.ajustes.nomeNegocio, style: t.secao()),
                      Text('Controler Spent', style: t.apoio()),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: Espaco.xl),
              EntradaSuave(
                ordem: 1,
                child: GrupoLista(recuoDivisoria: 70, children: [
                  item(
                    Icons.egg_outlined,
                    'Ingredientes e embalagens',
                    '$ingredientes ingredientes, $embalagens embalagens',
                    () => _abrir(context, InsumosScreen(store: store)),
                  ),
                  item(
                    Icons.menu_book_outlined,
                    'Receitas prontas',
                    prontas == 0 ? 'Todas já adicionadas' : '$prontas para adicionar',
                    () => _abrir(context, ReceitasProntasScreen(store: store)),
                  ),
                ]),
              ),
              const SizedBox(height: Espaco.l),
              EntradaSuave(
                ordem: 2,
                child: GrupoLista(recuoDivisoria: 70, children: [
                  item(
                    Icons.tune,
                    'Configurações',
                    'Nome, salário, contas fixas e taxas',
                    () => _abrir(context, AjustesScreen(store: store)),
                  ),
                ]),
              ),
            ],
          ),
        );
      },
    );
  }
}
