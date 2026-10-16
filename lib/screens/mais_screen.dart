import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models.dart';
import '../receitas_prontas.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'ajustes_screen.dart';
import 'backup_screen.dart';
import 'insumos_screen.dart';
import 'lojas_screen.dart';
import 'receitas_prontas_screen.dart';

/// Aba "Mais": cadastros e configurações, o que se usa menos no dia a dia. As
/// configurações ficam em partes, cada uma na sua tela.
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
        final a = store.ajustes;
        final ingredientes = store.insumos.where((i) => !i.ehEmbalagem).length;
        final embalagens = store.insumos.length - ingredientes;
        final prontas = receitasProntas.where((m) => !jaAdicionada(store, m)).length;
        final contas = a.totalFixos + a.salarioCentavos;
        final taxas = [
          for (final p in Pagamento.values)
            if (a.taxa(p) > 0) '${p.label.toLowerCase()} ${fmtNum(a.taxa(p) * 100)}%'
        ];
        final lojas = store.lojas.length;

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
                  AvatarLojaEditavel(store: store, loja: store.lojaAtual),
                  const SizedBox(width: Espaco.l),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(store.lojaAtual.nome, style: t.secao()),
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
              const SizedBox(height: Espaco.xl),
              const EntradaSuave(ordem: 2, child: Rotulo('Configurações')),
              const SizedBox(height: Espaco.s),
              EntradaSuave(
                ordem: 2,
                child: GrupoLista(recuoDivisoria: 70, children: [
                  item(
                    Icons.badge_outlined,
                    'Loja',
                    'Nome e logo',
                    () => _abrir(context, LojaScreen(store: store)),
                  ),
                  item(
                    Icons.receipt_long_outlined,
                    'Contas do mês',
                    contas == 0 ? 'Salário e contas fixas' : '${reais(contas)} por mês',
                    () => _abrir(context, ContasScreen(store: store)),
                  ),
                  item(
                    Icons.credit_card_outlined,
                    'Taxas da maquininha',
                    taxas.isEmpty ? 'Nenhuma taxa' : taxas.join(' · '),
                    () => _abrir(context, TaxasScreen(store: store)),
                  ),
                  item(
                    Icons.storefront_outlined,
                    'Lojas',
                    lojas == 1 ? '1 loja · criar outra' : '$lojas lojas · trocar ou criar',
                    () => _abrir(context, LojasScreen(store: store)),
                  ),
                  item(
                    Icons.backup_outlined,
                    'Backup',
                    store.precisaCopia
                        ? 'Faz tempo que não salva uma cópia'
                        : 'Salvar ou restaurar uma cópia da loja',
                    () => _abrir(context, BackupScreen(store: store)),
                  ),
                ]),
              ),
              const SizedBox(height: Espaco.xl),
              const EntradaSuave(ordem: 3, child: Rotulo('Aparência')),
              const SizedBox(height: Espaco.s),
              EntradaSuave(
                ordem: 3,
                child: SeletorOpcoes<TemaApp>(
                  opcoes: [for (final m in TemaApp.values) (m, m.label)],
                  valor: a.tema,
                  onChanged: store.mudarTema,
                ),
              ),
              const SizedBox(height: Espaco.secao),
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (_, info) => Text(
                  info.hasData
                      ? 'Controler Spent · versão ${info.data!.version} (${info.data!.buildNumber})'
                      : '',
                  textAlign: TextAlign.center,
                  style: t.apoio().copyWith(fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
