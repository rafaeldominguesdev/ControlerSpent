import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

/// Nome de arquivo sem acento nem espaço: "Doces da Lu" vira "doces-da-lu".
String _simples(String s) {
  const de = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
  const para = 'aaaaaeeeeiiiiooooouuuucn';
  final b = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    final i = de.indexOf(ch);
    b.write(i >= 0 ? para[i] : ch);
  }
  return b.toString().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');
}

/// Cópia de segurança da loja em uso: salvar num arquivo (pelo menu de
/// compartilhar do celular: Arquivos, WhatsApp, e-mail) e restaurar depois,
/// neste ou em outro celular.
class BackupScreen extends StatefulWidget {
  final Store store;
  const BackupScreen({super.key, required this.store});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _ocupado = false;

  Store get store => widget.store;

  void _avisar(String texto) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), persist: false, duration: const Duration(seconds: 4)));

  Future<void> _salvar(Rect? origem) async {
    setState(() => _ocupado = true);
    try {
      final pasta = await getTemporaryDirectory();
      final dia = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final arquivo =
          File('${pasta.path}/controler-spent-${_simples(store.lojaAtual.nome)}-$dia.json');
      await arquivo.writeAsString(store.exportarLoja());
      final r = await SharePlus.instance.share(ShareParams(
        files: [XFile(arquivo.path, mimeType: 'application/json')],
        subject: 'Cópia da loja ${store.lojaAtual.nome}',
        sharePositionOrigin: origem,
      ));
      if (r.status != ShareResultStatus.dismissed) await store.marcarCopiaManual();
    } catch (_) {
      if (mounted) _avisar('Não deu para salvar a cópia. Tente de novo.');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _restaurar() async {
    final PlatformFile? arquivo;
    try {
      arquivo = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['json']);
    } catch (_) {
      if (mounted) _avisar('Não deu para abrir os arquivos do celular.');
      return;
    }
    if (arquivo == null || !mounted) return;
    await _restaurarDe(() async => utf8.decode(await arquivo!.readAsBytes()));
  }

  Future<void> _restaurarDe(Future<String> Function() ler) async {
    final comoNova = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurar a cópia'),
        content: Text('Pode virar uma loja nova, ou trocar os dados de '
            '"${store.lojaAtual.nome}" pelos da cópia (os de agora são apagados).'),
        actionsOverflowDirection: VerticalDirection.down,
        actionsOverflowButtonSpacing: Espaco.xs,
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Criar uma loja nova'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: ctx.cores.negativo),
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Trocar os dados de ${store.lojaAtual.nome}'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        ],
      ),
    );
    if (comoNova == null || !mounted) return;

    setState(() => _ocupado = true);
    try {
      final texto = await ler();
      await store.importarLoja(texto, comoNova: comoNova);
      if (mounted) _avisar('Cópia restaurada em "${store.lojaAtual.nome}".');
    } on FormatException catch (e) {
      if (mounted) _avisar(e.message);
    } catch (_) {
      if (mounted) _avisar('Esse arquivo não é uma cópia do Controler Spent.');
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = context.tipos;

    Widget acao(IconData icone, String titulo, String texto, void Function(Rect? origem) onTap) =>
        Builder(builder: (context) {
          return ListTile(
            enabled: !_ocupado,
            minVerticalPadding: Espaco.m,
            leading: Container(
              width: 40,
              height: 40,
              decoration:
                  BoxDecoration(color: c.realce, borderRadius: BorderRadius.circular(Raio.pequeno)),
              child: Icon(icone, color: c.acao, size: 22),
            ),
            title: Text(titulo),
            subtitle: Text(texto),
            onTap: () {
              // No iPad o menu de compartilhar precisa saber de onde abre.
              final caixa = context.findRenderObject() as RenderBox?;
              onTap(caixa == null ? null : caixa.localToGlobal(Offset.zero) & caixa.size);
            },
          );
        });

    return Scaffold(
      appBar: AppBar(title: const Text('Backup')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Espaco.borda, Espaco.s, Espaco.borda, Espaco.secao),
        children: [
          Text(
              'Guarde uma cópia de "${store.lojaAtual.nome}" de vez em quando: se trocar ou '
              'perder o celular, é só restaurar.',
              style: t.apoio()),
          const SizedBox(height: Espaco.l),
          GrupoLista(recuoDivisoria: 70, children: [
            acao(Icons.ios_share, 'Salvar uma cópia',
                'Escolha onde guardar: Arquivos, WhatsApp, e-mail…', _salvar),
            acao(Icons.settings_backup_restore, 'Restaurar uma cópia',
                'Escolha o arquivo da cópia (termina em .json)', (_) => _restaurar()),
          ]),
          const SizedBox(height: Espaco.l),
          _AvisoCopia(ultima: store.ultimaCopiaManual),
          const SizedBox(height: Espaco.xl),
          const Rotulo('Cópias automáticas'),
          const SizedBox(height: Espaco.xs),
          Text(
              'Todo dia o app guarda sozinho uma cópia (as dos últimos 14 dias). Servem para '
              'desfazer um engano, mas somem se o app for apagado: por isso, salve também '
              'uma cópia fora do celular.',
              style: t.apoio().copyWith(fontSize: 12)),
          const SizedBox(height: Espaco.s),
          FutureBuilder<List<File>>(
            future: store.copiasAutomaticas(),
            builder: (context, snap) {
              final copias = snap.data ?? const <File>[];
              if (copias.isEmpty) {
                return Text('Nenhuma ainda. A primeira aparece na próxima anotação.',
                    style: t.apoio());
              }
              return GrupoLista(children: [
                for (final f in copias)
                  ListTile(
                    enabled: !_ocupado,
                    leading: Icon(Icons.history, color: c.tintaSuave),
                    title: Text(_nomeCopia(f)),
                    trailing:
                        Text('Restaurar', style: t.corpo(color: c.acao).copyWith(fontSize: 14)),
                    onTap: () => _restaurarDe(() => f.readAsString()),
                  ),
              ]);
            },
          ),
          if (_ocupado) ...[
            const SizedBox(height: Espaco.xl),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }
}

/// "Hoje", "Ontem" ou "seg, 12 out", a partir do nome "loja1-2026-10-12.json".
String _nomeCopia(File f) {
  final m = RegExp(r'(\d{4})-(\d{2})-(\d{2})').firstMatch(f.path);
  if (m == null) return f.uri.pathSegments.last;
  final d = DateTime(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
  final hoje = DateTime.now();
  final h = DateTime(hoje.year, hoje.month, hoje.day);
  final dias = h.difference(d).inDays;
  if (dias == 0) return 'Hoje';
  if (dias == 1) return 'Ontem';
  return DateFormat("EEE, d 'de' MMM", 'pt_BR').format(d).replaceAll('.', '');
}

/// Quando foi a última cópia guardada fora do celular, em verde ou em alerta.
class _AvisoCopia extends StatelessWidget {
  final DateTime? ultima;
  const _AvisoCopia({required this.ultima});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = context.tipos;
    final dias = ultima == null ? null : DateTime.now().difference(ultima!).inDays;
    final emDia = dias != null && dias < 7;
    final cor = emDia ? c.positivo : c.atencao;
    final texto = switch (dias) {
      null => 'Você ainda não guardou nenhuma cópia fora do celular.',
      0 => 'Última cópia fora do celular: hoje.',
      1 => 'Última cópia fora do celular: ontem.',
      _ => 'Última cópia fora do celular: há $dias dias.',
    };
    return Container(
      padding: const EdgeInsets.all(Espaco.l),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(Raio.medio),
      ),
      child: Row(children: [
        Icon(emDia ? Icons.verified_outlined : Icons.warning_amber_rounded, color: cor),
        const SizedBox(width: Espaco.m),
        Expanded(child: Text(texto, style: t.corpo(color: cor).copyWith(fontSize: 14))),
      ]),
    );
  }
}
