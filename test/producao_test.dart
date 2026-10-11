import 'dart:convert';

import 'package:confeitaria/models.dart';
import 'package:confeitaria/receitas_prontas.dart';
import 'package:confeitaria/store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final produto = Produto(nome: 'Brigadeiro', rendimento: 25, precoVendaCentavos: 300);

  Future<Store> storeCom(List<Lancamento> lancamentos) async {
    SharedPreferences.setMockInitialValues({
      'produtos': jsonEncode([produto.toJson()]),
      'lancamentos': jsonEncode([for (final l in lancamentos) l.toJson()]),
    });
    final store = Store();
    await store.carregar();
    return store;
  }

  test('produção não entra na conta do lucro', () {
    final dia = DateTime(2026, 10, 5);
    final r = ResumoMes([
      Lancamento.producao(produto, 100, 50)..data = dia,
      Lancamento.venda(produto, 100, qtd: 40, preco: 300, pagamento: Pagamento.pix, taxa: 0)
        ..data = dia,
    ], Ajustes());
    expect(r.faturamento, 12000);
    expect(r.custo, 4000); // só o custo dos 40 vendidos
    expect(r.lucroBolso, 8000);
    expect(r.produzidos, 50);
  });

  test('lote antigo vira produção + venda + perda com o mesmo lucro', () async {
    final lote = Lancamento(
      produtoId: produto.id,
      produtoNome: produto.nome,
      data: DateTime(2026, 10, 5, 9),
      feitos: 50,
      vendidos: 44,
      precoUnitCentavos: 300,
      custoUnitCentavos: 100,
      tipo: TipoLancamento.lote,
    );
    final lucroAntes = lote.lucro;
    final store = await storeCom([lote]);

    final tipos = store.lancamentos.map((l) => l.tipo).toList();
    expect(tipos, containsAll([TipoLancamento.producao, TipoLancamento.venda, TipoLancamento.perda]));
    expect(tipos, isNot(contains(TipoLancamento.lote)));
    final r = store.resumo(2026, 10);
    expect(r.lucroBolso, closeTo(lucroAntes, 0.001));
    expect(store.estoque(produto.id), 0);
  });

  test('estoque conta a partir da primeira produção', () async {
    final venda = Lancamento.venda(produto, 100,
        qtd: 30, preco: 300, pagamento: Pagamento.pix, taxa: 0, cliente: ' Ana ');
    final store = await storeCom([
      venda..data = DateTime(2026, 10, 1), // antes de anotar produção: não conta
      Lancamento.producao(produto, 100, 40)..data = DateTime(2026, 10, 3, 6),
      Lancamento.venda(produto, 100, qtd: 12, preco: 300, pagamento: Pagamento.pix, taxa: 0)
        ..data = DateTime(2026, 10, 3, 15),
      Lancamento.perda(produto, 100, 3)..data = DateTime(2026, 10, 4),
    ]);
    expect(store.estoque(produto.id), 25);
    expect(store.clientesRecentes(), ['Ana']); // nome limpo, sem espaços
  });

  test('receita pronta reaproveita ingredientes que já existem', () async {
    SharedPreferences.setMockInitialValues({});
    final store = Store();
    await store.carregar();
    final meuLeite = Insumo(
        nome: 'leite condensado', unidade: Unidade.g, qtdEmbalagem: 395, precoCentavos: 999);
    await store.salvarInsumo(meuLeite);

    final modelo = receitasProntas.firstWhere((m) => m.nome == 'Brigadeiro gourmet');
    final p = await adicionarReceitaPronta(store, modelo);

    expect(jaAdicionada(store, modelo), isTrue);
    expect(p.itens.map((i) => i.insumoId), contains(meuLeite.id));
    expect(store.insumos.where((i) => normalizar(i.nome) == 'leite condensado'), hasLength(1));
    expect(store.insumos.length, modelo.itens.length); // criou só os que faltavam
    expect(store.calcular(p).custoUnitario, greaterThan(0));
  });

  test('normalizar ignora acento, caixa e espaços', () {
    expect(normalizar('  Açúcar   Mascavo '), 'acucar mascavo');
  });
}
