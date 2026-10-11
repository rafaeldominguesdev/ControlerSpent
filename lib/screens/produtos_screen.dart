import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

Color corStatus(BuildContext context, StatusPreco s) => switch (s) {
      StatusPreco.lucrativo => context.cores.positivo,
      StatusPreco.atencao => context.cores.atencao,
      StatusPreco.prejuizo => context.cores.negativo,
      StatusPreco.semPreco => context.cores.tintaSuave,
    };

String textoStatus(StatusPreco s) => switch (s) {
      StatusPreco.lucrativo => 'Lucrativo',
      StatusPreco.atencao => 'Atenção',
      StatusPreco.prejuizo => 'Prejuízo',
      StatusPreco.semPreco => 'Sem preço',
    };

class _LinhaProduto extends StatelessWidget {
  final Produto p;
  final Calculo c;
  final VoidCallback onTap;
  const _LinhaProduto({required this.p, required this.c, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cor = corStatus(context, c.status);
    final margem = c.margemReal == null ? null : '${(c.margemReal! * 100).toStringAsFixed(0)}%';
    // Só escreve o status quando pede atenção; margem boa já fala por si.
    final legenda = switch (c.status) {
      StatusPreco.lucrativo => '$margem de margem',
      StatusPreco.semPreco => 'sem preço',
      _ => '${textoStatus(c.status)}, $margem',
    };
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Espaco.l, vertical: Espaco.m),
        child: Row(children: [
          Hero(
            tag: 'foto-${p.id}',
            child: FotoProduto(p.fotoBase64, tamanho: 44),
          ),
          const SizedBox(width: Espaco.m),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.tipos.corpo(peso: FontWeight.w600)),
              Text('Custa ${reais(c.custoUnitario)}',
                  style: context.tipos.apoio().copyWith(fontSize: 12)),
            ]),
          ),
          const SizedBox(width: Espaco.s),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(reais(c.precoVenda ?? c.precoSugerido),
                style: context.tipos.valor(
                    color: c.precoVenda == null ? context.cores.tintaSuave : context.cores.tinta)),
            Text(legenda, style: context.tipos.apoio(color: cor).copyWith(fontSize: 12)),
          ]),
        ]),
      ),
    );
  }
}
