import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../receitas_prontas.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

class _LinhaReceita extends StatelessWidget {
  final ModeloReceita m;
  final Store store;
  final bool aberta, adicionando;
  final VoidCallback onTap, onAdicionar;
  const _LinhaReceita({
    required this.m,
    required this.store,
    required this.aberta,
    required this.adicionando,
    required this.onTap,
    required this.onAdicionar,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = context.tipos;
    final custo = custoEstimado(store, m);
    final margem = (m.precoVendaCentavos - custo) / m.precoVendaCentavos * 100;
    final ja = jaAdicionada(store, m);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Espaco.l, vertical: Espaco.m),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const FotoProduto(null, tamanho: 44),
            const SizedBox(width: Espaco.m),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(m.nome, style: t.corpo(peso: FontWeight.w600)),
                Text(
                  'Rende ${m.rendimento}, custa ${reais(custo)} cada',
                  style: t.apoio().copyWith(fontSize: 12),
                ),
              ]),
            ),
            const SizedBox(width: Espaco.s),
            AnimatedSwitcher(
              duration: Movimento.medio,
              child: ja
                  ? Row(key: const ValueKey('ok'), mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.check_circle, size: 18, color: c.positivo),
                      const SizedBox(width: Espaco.xs),
                      Text('Adicionado', style: t.apoio(color: c.positivo)),
                    ])
                  : OutlinedButton(
                      key: const ValueKey('add'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: Espaco.m),
                        textStyle: t.corpo(peso: FontWeight.w600).copyWith(fontSize: 13),
                      ),
                      onPressed: adicionando ? null : onAdicionar,
                      child: adicionando
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Adicionar'),
                    ),
            ),
          ]),
          AnimatedSize(
            duration: Movimento.medio,
            curve: Movimento.entrada,
            alignment: Alignment.topCenter,
            child: !aberta
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: Espaco.m, left: 54),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(m.descricao, style: t.apoio(color: c.tinta)),
                      const SizedBox(height: Espaco.s),
                      for (final (mi, qtd) in m.itens)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: Text(
                              '${fmtQtd(qtd)} ${mi.unidade.label} de ${mi.nome.toLowerCase()}',
                              style: t.apoio().copyWith(fontSize: 12)),
                        ),
                      const SizedBox(height: Espaco.s),
                      Text(
                        'Vende a ${reais(m.precoVendaCentavos)}, margem de ${margem.toStringAsFixed(0)}%.',
                        style: t.apoio(color: c.positivo).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ]),
                  ),
          ),
        ]),
      ),
    );
  }
}
