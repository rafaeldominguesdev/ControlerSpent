
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme.dart';
import '../widgets.dart';

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
