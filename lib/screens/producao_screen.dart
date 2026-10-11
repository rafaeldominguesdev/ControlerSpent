import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'ajustes_screen.dart';
import 'lancar.dart';

/// Produção: o que ficou pronto, o estoque para vender e as perdas.
class ProducaoScreen extends StatelessWidget {
  final Store store;
  const ProducaoScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final c = context.cores;
        final t = context.tipos;
        final hoje = DateTime.now();
        final registros = store.lancamentos
            .where((l) => l.tipo == TipoLancamento.producao || l.tipo == TipoLancamento.perda);
        final feitosHoje = registros
            .where((l) => l.tipo == TipoLancamento.producao && mesmoDia(l.data, hoje))
            .fold(0, (s, l) => s + l.feitos);
        final prontos = [
          for (final p in store.produtos)
            if (store.estoque(p.id) > 0) (p, store.estoque(p.id)),
        ];
        final dias = agruparPorDia(registros);

        final blocos = <Widget>[
          Rotulo('Hoje, ${formatoDiaCurto.format(hoje)}'),
          const SizedBox(height: Espaco.xs),
          Text('$feitosHoje', style: t.display(size: 36)),
          const SizedBox(height: 2),
          Text(feitosHoje == 1 ? 'unidade feita hoje.' : 'unidades feitas hoje.', style: t.apoio()),
          const SizedBox(height: Espaco.l),
          Pressionavel(
            child: FilledButton.icon(
              onPressed: () => registrarRapido(context, store, TipoLancamento.producao),
              icon: const Icon(Icons.add, size: 22),
              label: const Text('Registrar produção'),
            ),
          ),
          const SizedBox(height: Espaco.s),
          Pressionavel(
            child: OutlinedButton.icon(
              onPressed: () => registrarRapido(context, store, TipoLancamento.perda),
              icon: const Icon(Icons.remove_circle_outline, size: 20),
              label: const Text('Anotar perda ou sobra'),
            ),
          ),
          const SizedBox(height: Espaco.secao),
          Text('Prontos para vender', style: t.secao()),
          const SizedBox(height: Espaco.m),
          if (prontos.isEmpty)
            Text('Nada no estoque. Quando registrar uma produção, ela aparece aqui.',
                style: t.apoio())
          else
            GrupoLista(recuoDivisoria: 64, children: [
              for (final (p, n) in prontos)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Espaco.l, vertical: Espaco.m),
                  child: Row(children: [
                    FotoProduto(p.fotoBase64, tamanho: 38),
                    const SizedBox(width: Espaco.m),
                    Expanded(
                      child: Text(p.nome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.corpo(peso: FontWeight.w600)),
                    ),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(n == 1 ? '1 pronto' : '$n prontos', style: t.valor()),
                      if (p.precoVendaCentavos != null)
                        Text('valem ${reais(n * p.precoVendaCentavos!)}',
                            style: t.apoio(color: c.positivo).copyWith(fontSize: 12)),
                    ]),
                  ]),
                ),
            ]),
          const SizedBox(height: Espaco.secao),
          if (dias.isEmpty)
            const Vazio(
              icone: Icons.bakery_dining_outlined,
              titulo: 'Seu caderno de produção',
              texto: 'Registre quantos você fez. O app desconta o que for vendido '
                  'e mostra quanto ainda tem pronto.',
            )
          else
            for (final dia in dias)
              GrupoDia(
                store: store,
                dia: dia.$1,
                itens: dia.$2,
                resumo: Text(
                  '${dia.$2.where((l) => l.tipo == TipoLancamento.producao).fold(0, (s, l) => s + l.feitos)} feitos',
                  style: t.apoio().copyWith(fontSize: 12),
                ),
              ),
        ];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Produção'),
            actions: [BotaoConfiguracoes(store: store)],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(Espaco.borda, Espaco.xs, Espaco.borda, Espaco.secao),
            children: [
              for (final (i, b) in blocos.indexed) EntradaSuave(ordem: i ~/ 3, child: b),
            ],
          ),
        );
      },
    );
  }
}
