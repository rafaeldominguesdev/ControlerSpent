import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'ajustes_screen.dart';

final _mesNome = DateFormat('MMMM', 'pt_BR');
final _mesCurto = DateFormat('MMM', 'pt_BR');
final _diaMes = DateFormat("d MMM", 'pt_BR');
final _semCentavos = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$', decimalDigits: 0);

String _listaNomes(List<String> nomes) => switch (nomes.length) {
      0 => '',
      1 => nomes.first,
      _ => '${nomes.sublist(0, nomes.length - 1).join(', ')} e ${nomes.last}',
    };

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
String _curto(DateTime d) => _mesCurto.format(d).replaceAll('.', '');
String _dia(DateTime d) => _diaMes.format(d).replaceAll('.', '');

/// "R$ 1.528", sem centavos (para caber na tabela e no topo).
String _reais0(double centavos) => centavos <= -50
    ? '−${_semCentavos.format(-centavos / 100)}'
    : _semCentavos.format(math.max(0.0, centavos) / 100);

DateTime _hoje() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

enum _Tipo { semana, mes, ano, outro }

/// Um intervalo [ini, fim) de dias inteiros.
typedef _Faixa = ({DateTime ini, DateTime fim});

bool _dentro(DateTime d, _Faixa f) => !d.isBefore(f.ini) && d.isBefore(f.fim);
int _dias(_Faixa f) => DateTime.utc(f.fim.year, f.fim.month, f.fim.day)
    .difference(DateTime.utc(f.ini.year, f.ini.month, f.ini.day))
    .inDays;

typedef _Numeros = ({double vendas, int pedidos, double lucro});

_Numeros _numeros(Iterable<Lancamento> ls) {
  var vendas = 0.0, lucro = 0.0;
  var pedidos = 0;
  for (final l in ls) {
    if (l.tipo == TipoLancamento.producao) continue; // produção não entra no lucro
    vendas += l.faturamento;
    lucro += l.lucro;
    if (l.tipo == TipoLancamento.venda) pedidos++;
  }
  return (vendas: vendas, pedidos: pedidos, lucro: lucro);
}

/// O relatório de um período (semana, mês, ano ou um intervalo escolhido):
/// números em destaque comparados com o período anterior, o gráfico das
/// vendas, as formas de pagamento e a tabela por produto. Pode ser enviado
/// como imagem.
class RelatorioScreen extends StatefulWidget {
  final Store store;
  const RelatorioScreen({super.key, required this.store});

  @override
  State<RelatorioScreen> createState() => _RelatorioScreenState();
}

class _RelatorioScreenState extends State<RelatorioScreen> {
  _Tipo _tipo = _Tipo.mes;
  DateTime _ref = _hoje(); // um dia dentro do período mostrado
  DateTimeRange? _personalizado;
  final _foto = GlobalKey();
  bool _enviando = false;

  _Faixa _faixa(_Tipo tipo, DateTime ref) => switch (tipo) {
        _Tipo.semana => (
            ini: DateTime(ref.year, ref.month, ref.day - (ref.weekday - 1)),
            fim: DateTime(ref.year, ref.month, ref.day - (ref.weekday - 1) + 7),
          ),
        _Tipo.mes => (ini: DateTime(ref.year, ref.month), fim: DateTime(ref.year, ref.month + 1)),
        _Tipo.ano => (ini: DateTime(ref.year), fim: DateTime(ref.year + 1)),
        _Tipo.outro => (
            ini: DateTime(
                _personalizado!.start.year, _personalizado!.start.month, _personalizado!.start.day),
            fim: DateTime(
                _personalizado!.end.year, _personalizado!.end.month, _personalizado!.end.day + 1),
          ),
      };

  /// O período de mesmo tamanho logo antes.
  _Faixa _anterior(_Faixa f) => switch (_tipo) {
        _Tipo.semana => (
            ini: DateTime(f.ini.year, f.ini.month, f.ini.day - 7),
            fim: f.ini,
          ),
        _Tipo.mes => (ini: DateTime(f.ini.year, f.ini.month - 1), fim: f.ini),
        _Tipo.ano => (ini: DateTime(f.ini.year - 1), fim: f.ini),
        _Tipo.outro => (
            ini: DateTime(f.ini.year, f.ini.month, f.ini.day - _dias(f)),
            fim: f.ini,
          ),
      };

  void _andar(int passo) {
    HapticFeedback.selectionClick();
    setState(() => _ref = switch (_tipo) {
          _Tipo.semana => DateTime(_ref.year, _ref.month, _ref.day + 7 * passo),
          _Tipo.mes => DateTime(_ref.year, _ref.month + passo),
          _Tipo.ano => DateTime(_ref.year + passo),
          _Tipo.outro => _ref,
        });
  }

  Future<void> _escolherTipo(_Tipo tipo) async {
    if (tipo != _Tipo.outro) {
      setState(() {
        _tipo = tipo;
        _ref = _hoje();
      });
      return;
    }
    final hoje = _hoje();
    final escolhido = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: hoje,
      initialDateRange: _personalizado ??
          DateTimeRange(start: DateTime(hoje.year, hoje.month, hoje.day - 29), end: hoje),
      helpText: 'Escolha o período',
      saveText: 'Ver',
    );
    if (escolhido == null) return;
    setState(() {
      _personalizado = escolhido;
      _tipo = _Tipo.outro;
    });
  }

  String _titulo(_Faixa f) {
    final ultimo = DateTime(f.fim.year, f.fim.month, f.fim.day - 1);
    return switch (_tipo) {
      _Tipo.mes => '${_cap(_mesNome.format(f.ini))} ${f.ini.year}',
      _Tipo.ano => '${f.ini.year}',
      _ => f.ini.year == ultimo.year && f.ini.year == DateTime.now().year
          ? '${_dia(f.ini)} – ${_dia(ultimo)}'
          : '${_dia(f.ini)} ${f.ini.year} – ${_dia(ultimo)} ${ultimo.year}',
    };
  }

  String _nomeAnterior(_Faixa f) => switch (_tipo) {
        _Tipo.semana => 'semana passada',
        _Tipo.mes => _curto(f.ini),
        _Tipo.ano => '${f.ini.year}',
        _Tipo.outro => 'período anterior',
      };

  Future<void> _compartilhar(String titulo) async {
    final contexto = _foto.currentContext;
    if (contexto == null || _enviando) return;
    final origem = context.findRenderObject() as RenderBox?;
    setState(() => _enviando = true);
    try {
      final caixa = contexto.findRenderObject()! as RenderRepaintBoundary;
      final imagem = await caixa.toImage(pixelRatio: 3);
      final bytes = await imagem.toByteData(format: ui.ImageByteFormat.png);
      final pasta = await getTemporaryDirectory();
      final arquivo = File('${pasta.path}/relatorio.png');
      await arquivo.writeAsBytes(bytes!.buffer.asUint8List());
      await SharePlus.instance.share(ShareParams(
        files: [XFile(arquivo.path, mimeType: 'image/png')],
        text: 'Relatório ${widget.store.lojaAtual.nome} · $titulo',
        sharePositionOrigin:
            origem == null ? null : origem.localToGlobal(Offset.zero) & origem.size,
      ));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não deu para gerar a imagem. Tente de novo.')));
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _abrirAjustes() =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => ContasScreen(store: widget.store)));

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final c = context.cores;
        final t = context.tipos;
        final faixa = _faixa(_tipo, _ref);
        final hoje = _hoje();
        final emAndamento = _dentro(hoje, faixa);

        // No período em andamento, compara com o anterior só até o mesmo ponto.
        final ant = _anterior(faixa);
        final decorridos = emAndamento ? _dias((ini: faixa.ini, fim: hoje)) + 1 : null;
        final antCorte = decorridos == null
            ? ant
            : _tipo == _Tipo.mes
                ? (
                    ini: ant.ini,
                    fim: DateTime(
                        ant.ini.year,
                        ant.ini.month,
                        math.min(hoje.day, DateUtils.getDaysInMonth(ant.ini.year, ant.ini.month)) +
                            1),
                  )
                : (
                    ini: ant.ini,
                    fim: DateTime(ant.ini.year, ant.ini.month, ant.ini.day + decorridos)
                  );

        final doPeriodo = [
          for (final l in store.lancamentos)
            if (_dentro(l.data, faixa)) l
        ];
        final r = ResumoMes(doPeriodo, store.ajustes);
        final atual = _numeros(doPeriodo);
        final antes = _numeros(store.lancamentos.where((l) => _dentro(l.data, antCorte)));
        final titulo = _titulo(faixa);
        final podeAvancar = _tipo != _Tipo.outro && !faixa.fim.isAfter(hoje);

        Widget secao(String s, {String? apoio}) => Padding(
              padding: const EdgeInsets.only(top: Espaco.xxl, bottom: Espaco.m),
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(child: Text(s, style: t.secao())),
                if (apoio != null) Text(apoio, style: t.apoio().copyWith(fontSize: 12)),
              ]),
            );

        final blocos = <Widget>[
          // Período: nome grande com setas, como virar a página do caderno.
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(store.lojaAtual.nome.toUpperCase(),
                    style: t.rotulo().copyWith(fontSize: 11, letterSpacing: 1.1)),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(titulo, style: t.tituloTela()),
                ),
              ]),
            ),
            if (_tipo != _Tipo.outro) ...[
              _Seta(Icons.chevron_left_rounded, 'Período anterior', () => _andar(-1)),
              _Seta(Icons.chevron_right_rounded, 'Próximo período',
                  podeAvancar ? () => _andar(1) : null),
            ],
          ]),
          const SizedBox(height: Espaco.l),
          _Destaques(
            atual: atual,
            antes: antes,
            nomeAnterior: _nomeAnterior(ant),
          ),
          secao('Vendas', apoio: _tipo == _Tipo.ano ? 'por mês' : 'por dia'),
          _Grafico(
              lancamentos: doPeriodo,
              faixa: faixa,
              porMes: _tipo == _Tipo.ano || _dias(faixa) > 62),
          secao('Formas de pagamento'),
          _Pagamentos(lancamentos: doPeriodo),
          secao('Por produto'),
          _Tabela(
            r: r,
            fotos: {for (final p in store.produtos) p.id: p.fotoBase64},
            contas: _tipo == _Tipo.mes
                ? _Contas(r: r, emAndamento: emAndamento, onAjustes: _abrirAjustes)
                : null,
          ),
          const SizedBox(height: Espaco.s),
          Text('Lucro: o que sobra das vendas depois de ingredientes, embalagens, taxas e perdas.',
              style: t.apoio().copyWith(fontSize: 12)),
        ];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Relatório'),
            actions: [
              IconButton(
                tooltip: 'Enviar como imagem',
                onPressed: _enviando ? null : () => _compartilhar(titulo),
                icon: _enviando
                    ? const SizedBox(
                        width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.ios_share_rounded),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Espaco.borda, 0, Espaco.borda, Espaco.s),
                child: SeletorOpcoes<_Tipo>(
                  opcoes: const [
                    (_Tipo.semana, 'Semana'),
                    (_Tipo.mes, 'Mês'),
                    (_Tipo.ano, 'Ano'),
                    (_Tipo.outro, 'Outro'),
                  ],
                  valor: _tipo,
                  onChanged: _escolherTipo,
                ),
              ),
            ),
          ),
          body: SingleChildScrollView(
            child: RepaintBoundary(
              key: _foto,
              child: ColoredBox(
                color: c.papel,
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(Espaco.borda, Espaco.l, Espaco.borda, Espaco.secao),
                  child: Column(
                    key: ValueKey((_tipo, faixa.ini)),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (i, b) in blocos.indexed) EntradaSuave(ordem: i, child: b),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Seta extends StatelessWidget {
  final IconData icone;
  final String dica;
  final VoidCallback? onTap;
  const _Seta(this.icone, this.dica, this.onTap);

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: dica,
        onPressed: onTap,
        icon: Icon(icone, size: 28),
        style: IconButton.styleFrom(
          backgroundColor: onTap == null ? null : context.cores.superficie,
          side: BorderSide(color: context.cores.linha),
        ),
      );
}

/// Vendas em destaque e, embaixo, pedidos, ticket médio e lucro lado a lado.
class _Destaques extends StatelessWidget {
  final _Numeros atual, antes;
  final String nomeAnterior;
  const _Destaques({required this.atual, required this.antes, required this.nomeAnterior});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = context.tipos;
    final apoio = t.apoio().copyWith(fontSize: 12);

    Widget comparacao(double agora, double antes) {
      if (antes <= 0) return Text(agora > 0 ? 'novo' : '—', style: apoio);
      final pct = ((agora - antes) / antes * 100).round();
      if (pct == 0) return Text('igual', style: apoio);
      final sobe = pct > 0;
      final cor = sobe ? c.positivo : c.negativo;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(sobe ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              size: 13, color: cor),
          Text('${pct.abs()}%', style: t.valor(size: 12, color: cor, peso: FontWeight.w700)),
        ]),
      );
    }

    final ticket = atual.pedidos == 0 ? 0.0 : atual.vendas / atual.pedidos;
    final ticketAntes = antes.pedidos == 0 ? 0.0 : antes.vendas / antes.pedidos;

    Widget mini(String rotulo, Widget valor, Widget comparar) => Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Espaco.l, Espaco.m, Espaco.s, Espaco.l),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(rotulo, style: t.rotulo().copyWith(fontSize: 12)),
              const SizedBox(height: 4),
              FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: valor),
              const SizedBox(height: 6),
              comparar,
            ]),
          ),
        );

    final medio = t.valor(size: 19, peso: FontWeight.w700);
    final divisaoV = Container(width: 1, height: 56, color: c.linha);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          color: c.dinheiroSuave,
          padding: const EdgeInsets.fromLTRB(Espaco.l, Espaco.l, Espaco.l, Espaco.l),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(Raio.pequeno),
              ),
              child: Icon(icone, color: cor, size: 22),
            ),
            const SizedBox(width: Espaco.m),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(rotulo, style: t.corpo(color: c.tintaSuave))),
                  comparar,
                ]),
                const SizedBox(height: 2),
                FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: numero),
              ]),
            ),
          ]),
        );

    // Os fios começam depois do ícone, como numa lista.
    const divisoria = Divider(indent: Espaco.l + 42 + Espaco.m, endIndent: Espaco.l);
    final nome = _mesNome.format(mesAnterior);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Card(
        child: Column(children: [
          linha(
            Icons.payments_outlined,
            c.acao,
            'Vendas',
            ValorAnimado(atual.vendas, doZero: true, style: grande),
            comparacao(atual.vendas, antes.vendas, semBase: 'sem vendas em $curto'),
          ),
          divisoria,
          linha(
            Icons.receipt_long_outlined,
            c.destaque,
            'Pedidos',
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: atual.pedidos.toDouble()),
              duration: const Duration(milliseconds: 600),
              curve: Movimento.entrada,
              builder: (_, v, __) => Text('${v.round()}', style: grande),
            ),
            comparacao(atual.pedidos.toDouble(), antes.pedidos.toDouble(),
                semBase: 'sem pedidos em $curto'),
          ),
          divisoria,
          linha(
            Icons.trending_up_rounded,
            c.positivo,
            'Lucro',
            ValorAnimado(atual.lucro,
                doZero: true,
                style: grande.copyWith(color: atual.lucro < 0 ? c.negativo : c.positivo)),
            comparacao(atual.lucro, antes.lucro, semBase: 'sem lucro em $curto'),
          ),
        ]),
      ),
      const SizedBox(height: Espaco.s),
      Text(ateDia == null ? 'Comparado a $nome.' : 'Comparado a $nome até o dia $ateDia.',
          style: t.apoio().copyWith(fontSize: 12)),
    ]);
  }
}

/// A tabela por produto (quantidade, vendas e lucro), como na planilha, com o
/// total e as contas do mês no fim.
class _Tabela extends StatelessWidget {
  final ResumoMes r;
  final DateTime mes;
  final Map<int, String?> fotos;
  final bool emAndamento;
  final VoidCallback onAjustes;
  const _Tabela({
    required this.r,
    required this.mes,
    required this.fotos,
    required this.emAndamento,
    required this.onAjustes,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = context.tipos;
    final escala = MediaQuery.textScalerOf(context);
    final colunaQtd = escala.scale(34);
    final colunaValor = escala.scale(76);
    final cabeca = t.apoio().copyWith(fontSize: 12, fontWeight: FontWeight.w600);
    final numero = t.valor(size: 14, peso: FontWeight.w500);
    final forte = t.valor(size: 15, peso: FontWeight.w700);
    const respiro = EdgeInsets.symmetric(horizontal: Espaco.l, vertical: Espaco.m);

    Widget fileira(Widget nome, Widget qtd, Widget vendas, Widget lucro,
            {EdgeInsets padding = respiro}) =>
        Padding(
          padding: padding,
          child: Row(children: [
            Expanded(child: nome),
            SizedBox(width: colunaQtd, child: Align(alignment: Alignment.centerRight, child: qtd)),
            SizedBox(
                width: colunaValor, child: Align(alignment: Alignment.centerRight, child: vendas)),
            SizedBox(
                width: colunaValor, child: Align(alignment: Alignment.centerRight, child: lucro)),
          ]),
        );

    final produtos = r.porProduto()
      ..sort((a, b) => b.vendidos != a.vendidos
          ? b.vendidos.compareTo(a.vendidos)
          : b.faturamento.compareTo(a.faturamento));

    final linhas = <Widget>[
      ColoredBox(
        color: c.realce,
        child: fileira(Text('Produto', style: cabeca), Text('Qtd', style: cabeca),
            Text('Vendas', style: cabeca), Text('Lucro', style: cabeca),
            padding: const EdgeInsets.symmetric(horizontal: Espaco.l, vertical: Espaco.s)),
      ),
      if (produtos.isEmpty)
        Padding(
          padding: respiro,
          child: Text('Nada vendido em ${_mesNome.format(mes)}.', style: t.apoio()),
        ),
      for (final (i, p) in produtos.indexed) ...[
        if (i > 0) const Divider(indent: Espaco.l + 30 + Espaco.s, endIndent: Espaco.l),
        fileira(
          Row(children: [
            FotoProduto(fotos[p.id], tamanho: 30),
            const SizedBox(width: Espaco.s),
            Expanded(
              child: Text(p.nome,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.corpo().copyWith(fontSize: 14, height: 1.2)),
            ),
          ]),
          Text('${p.vendidos}', style: numero),
          Text(_reais0(p.faturamento), style: numero),
          Text(_reais0(p.lucro), style: p.lucro < 0 ? numero.copyWith(color: c.negativo) : numero),
        ),
      ],
      // Total com o traço de cima mais forte, como numa conta feita no papel.
      DecoratedBox(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: c.tinta, width: 1.2))),
        child: fileira(
          Text('Total', style: t.corpo(peso: FontWeight.w700).copyWith(fontSize: 15)),
          Text('${r.vendidos}', style: forte),
          Text(_reais0(r.faturamento), style: forte),
          Text(_reais0(r.lucroBolso),
              style: forte.copyWith(color: r.lucroBolso < 0 ? c.negativo : c.positivo)),
        ),
      ),
      _Contas(r: r, emAndamento: emAndamento, onAjustes: onAjustes),
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Card(
        clipBehavior: Clip.antiAlias,
        child: AnimatedSize(
          duration: Movimento.medio,
          curve: Movimento.entrada,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: Movimento.medio,
            child: Column(key: ValueKey(mes), children: linhas),
          ),
        ),
      ),
      const SizedBox(height: Espaco.s),
      Text('Lucro: o que sobra das vendas depois de ingredientes, embalagens, taxas e perdas.',
          style: t.apoio().copyWith(fontSize: 12)),
    ]);
  }
}

/// As contas fixas e o salário, embaixo do total: quanto são e quanto sobra ou
/// falta. No mês em andamento, o que falta não é prejuízo: ainda dá tempo de vender.
class _Contas extends StatelessWidget {
  final ResumoMes r;
  final bool emAndamento;
  final VoidCallback onAjustes;
  const _Contas({required this.r, required this.emAndamento, required this.onAjustes});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = context.tipos;
    final a = r.ajustes;
    final contas = (a.totalFixos + a.salarioCentavos).toDouble();
    const respiro = EdgeInsets.symmetric(horizontal: Espaco.l, vertical: Espaco.m);

    if (contas == 0) {
      return Container(
        color: c.papel,
        padding: const EdgeInsets.fromLTRB(Espaco.l, Espaco.xs, Espaco.xs, Espaco.xs),
        child: Row(children: [
          Expanded(child: Text('Contas do mês (gás, luz, salário)', style: t.apoio())),
          TextButton(onPressed: onAjustes, child: const Text('Incluir')),
        ]),
      );
    }

    final nomes = [
      for (final f in a.fixos)
        if (f.valorCentavos > 0) f.nome.toLowerCase(),
      if (a.salarioCentavos > 0) 'seu salário',
    ];
    final sobra = r.lucroReal;
    final (rotulo, cor) = switch ((sobra >= 0, emAndamento)) {
      (true, true) => ('Sobra no mês', c.positivo),
      (true, false) => ('Sobrou no mês', c.positivo),
      (false, true) => ('Falta para cobrir', c.atencao),
      (false, false) => ('Faltou para cobrir', c.negativo),
    };
    return Container(
      color: c.papel,
      child: Column(children: [
        Padding(
          padding: respiro,
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Contas do mês', style: t.corpo().copyWith(fontSize: 14)),
                Text(_listaNomes(nomes), style: t.apoio().copyWith(fontSize: 11)),
              ]),
            ),
            Text('− ${_reais0(contas)}',
                style: t.valor(size: 14, color: c.tintaSuave, peso: FontWeight.w500)),
          ]),
        ),
        const Divider(indent: Espaco.l, endIndent: Espaco.l),
        Padding(
          padding: respiro,
          child: Row(children: [
            Expanded(
                child: Text(rotulo, style: t.corpo(peso: FontWeight.w700).copyWith(fontSize: 15))),
            Text(_reais0(sobra.abs()), style: t.valor(size: 15, color: cor, peso: FontWeight.w700)),
          ]),
        ),
      ]),
    );
  }
}
