
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'insumos_screen.dart';
import 'produtos_screen.dart';

/// Foto larga no topo; sem foto, um espaço convidando a pôr uma.
class _FotoGrande extends StatelessWidget {
  final int id;
  final String? base64;
  final VoidCallback onTap;
  const _FotoGrande({required this.id, required this.base64, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressionavel(
      escala: 0.98,
      child: Semantics(
        button: true,
        label: base64 == null ? 'Pôr uma foto' : 'Trocar a foto',
        child: GestureDetector(
          onTap: onTap,
          child: AspectRatio(
            aspectRatio: 16 / 8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Raio.grande),
              child: Stack(fit: StackFit.expand, children: [
                Hero(
                  tag: 'foto-$id',
                  child: AnimatedSwitcher(
                    duration: Movimento.medio,
                    // Ocupa a área toda (o padrão do AnimatedSwitcher encolhe o filho).
                    layoutBuilder: (atual, anteriores) => Stack(
                      fit: StackFit.expand,
                      children: [...anteriores, if (atual != null) atual],
                    ),
                    child: base64 == null
                        ? ColoredBox(key: const ValueKey('sem'), color: context.cores.bege)
                        : Image.memory(FotoProduto.bytes(base64!),
                            key: ValueKey(base64!.length), fit: BoxFit.cover),
                  ),
                ),
                if (base64 == null)
                  Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.add_a_photo_outlined, color: context.cores.cacau, size: 30),
                    const SizedBox(height: Espaco.s),
                    Text('Pôr uma foto',
                        style:
                            context.tipos.corpo(peso: FontWeight.w600, color: context.cores.cacau)),
                  ])
                else
                  Positioned(
                    right: Espaco.m,
                    bottom: Espaco.m,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: context.cores.tinta.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(Raio.pequeno),
                      ),
                      child: Text('Trocar foto',
                          style: context.tipos
                              .apoio(color: context.cores.sobreCacau)
                              .copyWith(fontWeight: FontWeight.w600)),
                    ),
                  ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _Resumo extends StatelessWidget {
  final Calculo calc;
  final int rendimento;
  final VoidCallback onUsarSugerido;
  const _Resumo({required this.calc, required this.rendimento, required this.onUsarSugerido});

  @override
  Widget build(BuildContext context) {
    final cor = corStatus(context, calc.status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Espaco.l, Espaco.s, Espaco.l, Espaco.s),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          LinhaConta('Custo da receita', calc.custoReceita,
              detalhe: rendimento == 1 ? 'Rende 1 unidade' : 'Rende $rendimento unidades'),
          LinhaConta('Custo de cada unidade', calc.custoUnitario, forte: true),
          const Tracejado(),
          Row(children: [
            Expanded(child: Text('Preço sugerido', style: context.tipos.corpo())),
            Text(reais(calc.precoSugerido),
                style: context.tipos.valor(size: 18, peso: FontWeight.w700)),
          ]),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
              onPressed: onUsarSugerido,
              child: const Text('Usar este preço'),
            ),
          ),
          if (calc.precoVenda != null) ...[
            const Divider(),
            const SizedBox(height: Espaco.xs),
            LinhaConta('Lucro em cada unidade', calc.lucroUnitario!, forte: true, cor: cor),
            Padding(
              padding: const EdgeInsets.only(bottom: Espaco.s),
              child: Text(
                'Margem de ${(calc.margemReal! * 100).toStringAsFixed(0)}%. ${textoStatus(calc.status)}.',
                style: context.tipos.apoio(color: cor),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

class _EscolherInsumo extends StatelessWidget {
  final Store store;
  final Set<int> excluir;
  const _EscolherInsumo({required this.store, required this.excluir});

  @override
  Widget build(BuildContext context) {
    final lista = store.insumos.where((i) => !excluir.contains(i.id)).toList();
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(children: [
        ListTile(
          leading: const Icon(Icons.add_circle_outline),
          title: const Text('Cadastrar novo ingrediente'),
          onTap: () async {
            final novo = await editarInsumo(context, store);
            if (novo != null && context.mounted) Navigator.pop(context, novo);
          },
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(children: [
            for (final i in lista)
              ListTile(
                title: Text(i.nome),
                subtitle: Text(
                    '${fmtQtd(i.qtdEmbalagem)} ${i.unidade.label} por ${reais(i.precoCentavos)}'),
                onTap: () => Navigator.pop(context, i),
              ),
          ]),
        ),
      ]),
    );
  }
}
