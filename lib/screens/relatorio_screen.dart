import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'ajustes_screen.dart';

final _mesAno = DateFormat("MMMM 'de' yyyy", 'pt_BR');
final _mesNome = DateFormat('MMMM', 'pt_BR');
final _mesCurto = DateFormat('MMM', 'pt_BR');

String _listaNomes(List<String> nomes) => switch (nomes.length) {
      0 => '',
      1 => nomes.first,
      _ => '${nomes.sublist(0, nomes.length - 1).join(', ')} e ${nomes.last}',
    };

bool _emAndamento(DateTime mes) {
  final hoje = DateTime.now();
  return mes.year == hoje.year && mes.month == hoje.month;
}

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// O relatório como um extrato: o que entrou, o que saiu e o que ficou no mês
/// e as vendas semana a semana.
class RelatorioScreen extends StatefulWidget {
  final Store store;
  const RelatorioScreen({super.key, required this.store});

  @override
  State<RelatorioScreen> createState() => _RelatorioScreenState();
}

class _RelatorioScreenState extends State<RelatorioScreen> {
  DateTime _mes = DateTime(DateTime.now().year, DateTime.now().month);
  bool _voltando = false;

  void _mudarMes(int delta) => setState(() {
        _voltando = delta < 0;
        _mes = DateTime(_mes.year, _mes.month + delta);
      });

  void _abrirAjustes() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => AjustesScreen(store: widget.store)));

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final r = store.resumo(_mes.year, _mes.month);
        return Scaffold(
          appBar: AppBar(title: const Text('Relatório')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(Espaco.borda, Espaco.xs, Espaco.borda, Espaco.secao),
            children: [
              _SeletorMes(
                mes: _mes,
                onAnterior: () => _mudarMes(-1),
                // Não há o que ver nos meses que ainda não chegaram.
                onProximo: _emAndamento(_mes) ? null : () => _mudarMes(1),
              ),
              const SizedBox(height: Espaco.l),
              // O conteúdo do mês desliza para o lado da seta tocada.
              AnimatedSwitcher(
                duration: Movimento.medio,
                switchInCurve: Movimento.entrada,
                switchOutCurve: Movimento.saida,
                transitionBuilder: (child, anim) {
                  final entrando = child.key == ValueKey(_mes);
                  final dx = (entrando ? 1 : -1) * (_voltando ? -0.06 : 0.06);
                  return FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween(begin: Offset(dx, 0), end: Offset.zero).animate(anim),
                      child: child,
                    ),
                  );
                },
                layoutBuilder: (atual, anteriores) => Stack(
                  alignment: Alignment.topCenter,
                  children: [...anteriores, if (atual != null) atual],
                ),
                child: _ConteudoMes(
                  key: ValueKey(_mes),
                  store: store,
                  r: r,
                  mes: _mes,
                  onAjustes: _abrirAjustes,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ConteudoMes extends StatelessWidget {
  final Store store;
  final ResumoMes r;
  final DateTime mes;
  final VoidCallback onAjustes;
  const _ConteudoMes(
      {super.key,
      required this.store,
      required this.r,
      required this.mes,
      required this.onAjustes});

  @override
  Widget build(BuildContext context) {
    final t = context.tipos;
    final vendeu = r.itens.any((l) => l.vendidos > 0);
    final blocos = <Widget>[
      _Extrato(r: r, emAndamento: _emAndamento(mes), onAjustes: onAjustes),
      if (!vendeu)
        Vazio(
          icone: Icons.receipt_long_outlined,
          titulo: 'Nada vendido em ${_mesNome.format(mes)}',
          texto: 'As vendas que você registrar na aba Vendas aparecem aqui, semana a semana.',
        )
      else ...[
        Padding(
          padding: const EdgeInsets.only(top: Espaco.secao, bottom: Espaco.m),
          child: Text('Semana a semana', style: t.secao()),
        ),
        _Semanas(r: r, mes: mes),
      ],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, b) in blocos.indexed) EntradaSuave(ordem: i, child: b),
      ],
    );
  }
}

/// "‹ Outubro de 2026 ›": as setas trocam o mês.
class _SeletorMes extends StatelessWidget {
  final DateTime mes;
  final VoidCallback onAnterior;
  final VoidCallback? onProximo;
  const _SeletorMes({required this.mes, required this.onAnterior, required this.onProximo});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = context.tipos;
    return Container(
      decoration: BoxDecoration(color: c.realce, borderRadius: BorderRadius.circular(Raio.grande)),
      child: Row(children: [
        IconButton(
          tooltip: 'Mês anterior',
          color: c.acao,
          onPressed: onAnterior,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Text(_cap(_mesAno.format(mes)),
              textAlign: TextAlign.center, style: t.corpo(peso: FontWeight.w600)),
        ),
        IconButton(
          tooltip: 'Próximo mês',
          color: c.acao,
          onPressed: onProximo,
          icon: const Icon(Icons.chevron_right),
        ),
      ]),
    );
  }
}

/// Entrou (vendas), saiu (ingredientes, embalagens e taxas) e ficou (lucro).
class _Extrato extends StatelessWidget {
  final ResumoMes r;
  final bool emAndamento;
  final VoidCallback onAjustes;
  const _Extrato({required this.r, required this.emAndamento, required this.onAjustes});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = context.tipos;
    final saiu = r.custo + r.taxas;
    final ficou = r.lucroBolso;
    final a = r.ajustes;
    final contas = a.totalFixos + a.salarioCentavos;
    final nomesContas = [
      for (final f in a.fixos)
        if (f.valorCentavos > 0) f.nome.toLowerCase(),
      if (a.salarioCentavos > 0) 'seu salário',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Espaco.l, Espaco.l, Espaco.l, Espaco.xs),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _LinhaExtrato(
            icone: Icons.south_west_rounded,
            cor: c.positivo,
            fundo: c.dinheiroSuave,
            titulo: 'Entrou',
            detalhe: switch (r.vendidos) {
              0 => 'nenhuma venda ainda',
              1 => '1 unidade vendida',
              final n => '$n unidades vendidas',
            },
            valor: ValorAnimado(r.faturamento,
                sinal: r.faturamento > 0,
                style: t.valor(size: 17, color: r.faturamento > 0 ? c.positivo : c.tintaSuave)),
          ),
          const SizedBox(height: Espaco.l),
          _LinhaExtrato(
            icone: Icons.north_east_rounded,
            cor: c.negativo,
            fundo: c.negativo.withValues(alpha: 0.1),
            titulo: 'Saiu',
            detalhe: r.taxas == 0 && r.perdas == 0
                ? 'ingredientes e embalagens'
                : _listaNomes([
                    'ingredientes',
                    if (r.taxas > 0) 'taxas',
                    if (r.perdas > 0) 'perdas',
                  ]),
            valor: ValorAnimado(-saiu,
                style: t.valor(size: 17, color: saiu > 0 ? c.negativo : c.tintaSuave)),
          ),
          const SizedBox(height: Espaco.m),
          const Tracejado(),
          const SizedBox(height: Espaco.m),
          _LinhaExtrato(
            icone: Icons.account_balance_wallet_outlined,
            cor: c.acao,
            fundo: c.realce,
            titulo: 'Ficou',
            detalhe: ficou < 0 ? 'prejuízo' : 'seu lucro',
            forte: true,
            valor: ValorAnimado(ficou,
                style: t.display(size: 30, color: ficou < 0 ? c.negativo : c.positivo)),
          ),
          if (r.faturamento > 0) ...[
            const SizedBox(height: Espaco.xl),
            _DeCadaDez(r: r),
          ],
          const SizedBox(height: Espaco.l),
          const Divider(height: 1),
          if (contas == 0)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: onAjustes,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Incluir gás, luz e seu salário'),
              ),
            )
          else
            _Contas(
              sobra: r.lucroReal,
              emAndamento: emAndamento,
              detalhe: '${_cap(_listaNomes(nomesContas))}: ${reais(contas)}',
            ),
        ]),
      ),
    );
  }
}

/// O lucro diante das contas fixas e do salário: quanto sobra ou quanto falta.
/// No mês em andamento, o que falta não é prejuízo: ainda dá tempo de vender.
class _Contas extends StatelessWidget {
  final double sobra;
  final bool emAndamento;
  final String detalhe;
  const _Contas({required this.sobra, required this.emAndamento, required this.detalhe});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = context.tipos;
    final (titulo, cor) = switch ((sobra >= 0, emAndamento)) {
      (true, true) => ('Sobra depois das contas', c.positivo),
      (true, false) => ('Sobrou depois das contas', c.positivo),
      (false, true) => ('Falta para cobrir as contas', c.atencao),
      (false, false) => ('Faltou para cobrir as contas', c.negativo),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Espaco.m),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titulo, style: t.corpo()),
            Text(detalhe, style: t.apoio().copyWith(fontSize: 12)),
          ]),
        ),
        const SizedBox(width: Espaco.m),
        Text(reais(sobra.abs()), style: t.valor(size: 16, color: cor, peso: FontWeight.w700)),
      ]),
    );
  }
}

class _LinhaExtrato extends StatelessWidget {
  final IconData icone;
  final Color cor, fundo;
  final String titulo, detalhe;
  final Widget valor;
  final bool forte;
  const _LinhaExtrato({
    required this.icone,
    required this.cor,
    required this.fundo,
    required this.titulo,
    required this.detalhe,
    required this.valor,
    this.forte = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tipos;
    return Row(children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: fundo, shape: BoxShape.circle),
        child: Icon(icone, size: 20, color: cor),
      ),
      const SizedBox(width: Espaco.m),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titulo, style: t.corpo(peso: forte ? FontWeight.w700 : FontWeight.w600)),
          Text(detalhe, style: t.apoio().copyWith(fontSize: 12)),
        ]),
      ),
      const SizedBox(width: Espaco.s),
      valor,
    ]);
  }
}

/// "De cada R$ 10 vendidos, R$ 5,80 ficaram com você", com dez quadradinhos
/// (um por real) pintados de verde até onde vai o lucro.
class _DeCadaDez extends StatelessWidget {
  final ResumoMes r;
  const _DeCadaDez({required this.r});

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = context.tipos;
    final fracao = r.lucroBolso / r.faturamento;
    if (fracao <= 0) {
      return Text(
        fracao == 0
            ? 'Empatou: tudo o que entrou foi para os custos.'
            : 'Os custos passaram as vendas em ${reais(-r.lucroBolso)}.',
        style: t.apoio(color: c.negativo),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text.rich(
        TextSpan(children: [
          const TextSpan(text: 'De cada R\$ 10 vendidos, '),
          TextSpan(
            text: reais(fracao * 1000),
            style: TextStyle(color: c.positivo, fontWeight: FontWeight.w700),
          ),
          const TextSpan(text: ' ficaram com você.'),
        ]),
        style: t.apoio(color: c.tinta),
      ),
      const SizedBox(height: Espaco.s),
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: fracao.clamp(0.0, 1.0) * 10),
        duration: const Duration(milliseconds: 800),
        curve: Movimento.entrada,
        builder: (_, cheios, __) => Row(children: [
          for (var i = 0; i < 10; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : 3),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: SizedBox(
                    height: 10,
                    child: Stack(fit: StackFit.expand, children: [
                      ColoredBox(color: c.realce),
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: (cheios - i).clamp(0.0, 1.0),
                        child: ColoredBox(color: c.dinheiro),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
        ]),
      ),
    ]);
  }
}

enum _Quando { passou, agora, falta }

/// Vendas de 7 em 7 dias (1 a 7, 8 a 14...), com a semana de hoje marcada.
class _Semanas extends StatelessWidget {
  final ResumoMes r;
  final DateTime mes;
  const _Semanas({required this.r, required this.mes});

  @override
  Widget build(BuildContext context) {
    final dias = DateUtils.getDaysInMonth(mes.year, mes.month);
    final semanas = [for (var d = 1; d <= dias; d += 7) (d, math.min(d + 6, dias))];
    final valores = [
      for (final (de, ate) in semanas)
        r.itens
            .where((l) => l.data.day >= de && l.data.day <= ate)
            .fold(0.0, (s, l) => s + l.faturamento),
    ];
    final maior = valores.fold(0.0, math.max);
    final hoje = _emAndamento(mes) ? DateTime.now().day : null;
    final mesCurto = _mesCurto.format(mes).replaceAll('.', '');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Espaco.s),
        child: Column(children: [
          for (final (i, (de, ate)) in semanas.indexed)
            _LinhaSemana(
              nome: 'Semana ${i + 1}',
              periodo: de == ate ? '$de $mesCurto' : '$de a $ate $mesCurto',
              valor: valores[i],
              fracao: maior == 0 ? 0 : valores[i] / maior,
              quando: hoje == null || hoje > ate
                  ? _Quando.passou
                  : (hoje >= de ? _Quando.agora : _Quando.falta),
              ordem: i,
            ),
        ]),
      ),
    );
  }
}

class _LinhaSemana extends StatelessWidget {
  final String nome, periodo;
  final double valor, fracao;
  final _Quando quando;
  final int ordem;
  const _LinhaSemana({
    required this.nome,
    required this.periodo,
    required this.valor,
    required this.fracao,
    required this.quando,
    required this.ordem,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.cores;
    final t = context.tipos;
    final escala = MediaQuery.textScalerOf(context);
    final agora = quando == _Quando.agora;
    final falta = quando == _Quando.falta;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Espaco.s, vertical: Espaco.s),
      decoration: agora
          ? BoxDecoration(color: c.realce, borderRadius: BorderRadius.circular(Raio.pequeno))
          : null,
      child: Row(children: [
        SizedBox(
          width: escala.scale(88),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(nome,
                style: t
                    .corpo(peso: FontWeight.w600, color: falta ? c.tintaSuave : c.tinta)
                    .copyWith(fontSize: 14)),
            Text(agora ? 'esta semana' : periodo,
                style: t.apoio(color: agora ? c.acao : null).copyWith(fontSize: 12)),
          ]),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              height: 10,
              child: Stack(fit: StackFit.expand, children: [
                ColoredBox(color: agora ? c.superficie : c.realce),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: fracao),
                  duration: Duration(milliseconds: 600 + ordem * 70),
                  curve: Movimento.entrada,
                  builder: (_, f, __) => FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: f,
                    child: ColoredBox(color: c.acao),
                  ),
                ),
              ]),
            ),
          ),
        ),
        SizedBox(
          width: escala.scale(100),
          child: Text(
            falta ? '—' : (valor > 0 ? comSinal(valor) : reais(0)),
            textAlign: TextAlign.right,
            style: valor > 0
                ? t.valor(size: 14, color: c.positivo, peso: FontWeight.w700)
                : t.valor(size: 14, color: c.tintaSuave, peso: FontWeight.w500),
          ),
        ),
      ]),
    );
  }
}
