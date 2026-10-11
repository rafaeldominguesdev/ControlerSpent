import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
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
        final totalProntos = prontos.fold(0, (s, x) => s + x.$2);
        final valemProntos = prontos.fold(0, (s, x) => s + x.$2 * (x.$1.precoVendaCentavos ?? 0));

        final blocos = <Widget>[
          const Rotulo('Prontos para vender'),
          const SizedBox(height: Espaco.xs),
          Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('$totalProntos', style: t.display(size: 46)),
                const SizedBox(width: Espaco.s),
                Text(totalProntos == 1 ? 'unidade' : 'unidades', style: t.apoio()),
              ]),
          const SizedBox(height: Espaco.s),
          Wrap(spacing: Espaco.s, runSpacing: Espaco.s, children: [
            if (valemProntos > 0)
              Pilula('valem ${reais(valemProntos)}', cor: c.positivo, icone: Icons.sell_outlined),
            Pilula('$feitosHoje feitos hoje', cor: c.acao, icone: Icons.bakery_dining_outlined),
          ]),
          const SizedBox(height: Espaco.xl),
          BotaoPrincipal(
            texto: 'Registrar produção',
            icone: Icons.add,
            onPressed: () => registrarRapido(context, store, TipoLancamento.producao),
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
          if (prontos.isNotEmpty) ...[
            Text('No estoque', style: t.secao()),
            const SizedBox(height: Espaco.m),
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
                    Text(n == 1 ? '1 pronto' : '$n prontos', style: t.valor()),
                  ]),
                ),
            ]),
            const SizedBox(height: Espaco.secao),
          ],
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
          appBar: AppBar(title: const Text('Produção')),
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
