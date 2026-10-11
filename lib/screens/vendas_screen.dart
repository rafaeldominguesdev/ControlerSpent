import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'lancar.dart';

/// Só vendas: quanto entrou hoje, o botão de registrar e o caderno por dia.
class VendasScreen extends StatelessWidget {
  final Store store;
  const VendasScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final c = context.cores;
        final t = context.tipos;
        final hoje = DateTime.now();
        final vendas = store.lancamentos.where((l) => l.tipo == TipoLancamento.venda);
        final deHoje = vendas.where((l) => mesmoDia(l.data, hoje));
        final vendidoHoje = deHoje.fold(0.0, (s, l) => s + l.faturamento);
        final lucroHoje = deHoje.fold(0.0, (s, l) => s + l.lucro);
        final dias = agruparPorDia(vendas);

        final blocos = <Widget>[
          Rotulo('Hoje, ${formatoDiaCurto.format(hoje)}'),
          const SizedBox(height: Espaco.xs),
          ValorAnimado(vendidoHoje, style: t.display(size: 36, color: c.positivo)),
          const SizedBox(height: 2),
          Text(
            vendidoHoje == 0
                ? 'Nenhuma venda hoje ainda.'
                : 'vendidos, com ${reais(lucroHoje)} de lucro.',
            style: t.apoio(),
          ),
          const SizedBox(height: Espaco.l),
          Pressionavel(
            child: FilledButton.icon(
              onPressed: () => registrarRapido(context, store, TipoLancamento.venda),
              icon: const Icon(Icons.add, size: 22),
              label: const Text('Registrar venda'),
            ),
          ),
          const SizedBox(height: Espaco.secao),
          if (dias.isEmpty)
            const Vazio(
              icone: Icons.receipt_long_outlined,
              titulo: 'Seu caderno de vendas',
              texto: 'Cada venda que você registrar aparece aqui, separada por dia, '
                  'com o cliente e quanto foi lucro.',
            )
          else
            for (final dia in dias)
              GrupoDia(
                store: store,
                dia: dia.$1,
                itens: dia.$2,
                resumo: Text(reais(dia.$2.fold(0.0, (s, l) => s + l.faturamento)),
                    style: t.valor(size: 12, color: c.positivo)),
              ),
        ];

        return Scaffold(
          appBar: AppBar(title: const Text('Vendas')),
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
