import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

/// As lojas da confeiteira: qual está em uso, trocar, criar e apagar.
class LojasScreen extends StatelessWidget {
  final Store store;
  const LojasScreen({super.key, required this.store});

  Future<void> _nova(BuildContext context) async {
    final campo = TextEditingController();
    final nome = await showDialog<String>(
      context: context,
      builder: (ctx) {
        void criar() => Navigator.pop(ctx, campo.text.trim());
        return AlertDialog(
          title: const Text('Nova loja'),
          content: TextField(
            controller: campo,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Nome da loja', hintText: 'Bolos da Lu'),
            onSubmitted: (_) => criar(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
              onPressed: criar,
              child: const Text('Criar'),
            ),
          ],
        );
      },
    );
    if (nome == null || nome.isEmpty) return;
    await store.novaLoja(nome);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text('Loja "$nome" criada e em uso. Ela começa vazia; as lojas ficam em abas no topo.'),
      persist: false,
      duration: const Duration(seconds: 4),
    ));
  }

  Future<void> _apagar(BuildContext context, Loja loja) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Apagar ${loja.nome}?'),
        content: const Text('Os produtos, ingredientes e vendas dessa loja vão ser apagados. '
            'Se quiser guardar, faça um backup dela antes.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: ctx.cores.negativo),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (ok == true) await store.removerLoja(loja.id);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final c = context.cores;
        final t = context.tipos;
        return Scaffold(
          appBar: AppBar(title: const Text('Lojas')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(Espaco.borda, Espaco.s, Espaco.borda, Espaco.secao),
            children: [
              Text(
                  'Cada loja tem os seus produtos, ingredientes, vendas e relatório. '
                  'Com mais de uma, elas aparecem em abas no topo do app.',
                  style: t.apoio()),
              const SizedBox(height: Espaco.l),
              GrupoLista(recuoDivisoria: 70, children: [
                for (final l in store.lojas)
                  ListTile(
                    minVerticalPadding: Espaco.m,
                    leading: AvatarLoja(l, tamanho: 40),
                    title: Text(l.nome),
                    subtitle: l.id == store.lojaAtual.id
                        ? Text('Em uso', style: t.apoio(color: c.positivo))
                        : const Text('Toque para usar esta'),
                    trailing: store.lojas.length > 1
                        ? IconButton(
                            tooltip: 'Apagar ${l.nome}',
                            icon: Icon(Icons.delete_outline, color: c.tintaSuave),
                            onPressed: () => _apagar(context, l),
                          )
                        : null,
                    onTap: () => store.trocarLoja(l.id),
                  ),
              ]),
              const SizedBox(height: Espaco.l),
              BotaoPrincipal(texto: 'Nova loja', icone: Icons.add, onPressed: () => _nova(context)),
            ],
          ),
        );
      },
    );
  }
}
