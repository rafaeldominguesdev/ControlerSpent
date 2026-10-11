import 'package:confeitaria/models.dart';
import 'package:confeitaria/store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calcula custo, preço sugerido e margem como a planilha', () {
    final leite =
        Insumo(nome: 'Leite condensado', unidade: Unidade.g, qtdEmbalagem: 395, precoCentavos: 790);
    final forminha = Insumo(
        nome: 'Forminha',
        unidade: Unidade.un,
        qtdEmbalagem: 100,
        precoCentavos: 500,
        ehEmbalagem: true);
    final p =
        Produto(nome: 'Brigadeiro', rendimento: 20, margem: 0.5, precoVendaCentavos: 250, itens: [
      ItemReceita(insumoId: leite.id, qtd: 395),
      ItemReceita(insumoId: forminha.id, qtd: 20),
    ]);
    final c = Calculo.de(p, {leite.id: leite, forminha.id: forminha});
    expect(c.custoReceita, closeTo(890, 0.001)); // 7,90 + 1,00
    expect(c.custoUnitario, closeTo(44.5, 0.001));
    expect(c.precoSugerido, closeTo(89, 0.001));
    expect(c.lucroUnitario, closeTo(205.5, 0.001));
    expect(c.status, StatusPreco.lucrativo);
  });

  test('lê números no formato brasileiro', () {
    expect(parseCentavos('7,50'), 750);
    expect(parseCentavos('1.234,56'), 123456);
    expect(parseCentavos('7.5'), 750);
    expect(parseNum('395'), 395);
    expect(parseNum('1.000'), 1000);
    expect(parseNum('12.500'), 12500);
    expect(parseNum('0.395'), 0.395);
    expect(fmtQtd(1000), '1.000');
    expect(fmtQtd(2.5), '2,5');
    expect(fmtNum(0.0399 * 100), '3,99');
    expect(fmtNum(1000), '1000');
    expect(fmtNum(0), '0');
    expect(fmtNum(10.5), '10,5');
  });

  test('lançamento: sobra entra no custo e lucro real desconta fixos', () {
    final l = Lancamento(
        produtoId: 1,
        produtoNome: 'Brigadeiro',
        data: DateTime(2026, 10, 5),
        feitos: 50,
        vendidos: 45,
        precoUnitCentavos: 300,
        custoUnitCentavos: 100,
        taxaPct: 0.05);
    expect(l.faturamento, 13500);
    expect(l.custo, 5000);
    expect(l.perda, 500);
    expect(l.taxas, closeTo(675, 0.001));
    expect(l.lucro, closeTo(7825, 0.001));
    final r = ResumoMes(
        [l], Ajustes(salarioCentavos: 2000, fixos: [CustoFixo(nome: 'Gás', valorCentavos: 1000)]));
    expect(r.lucroBolso, closeTo(7825, 0.001));
    expect(r.lucroReal, closeTo(4825, 0.001));
    expect(r.porProduto().single.vendidos, 45);
  });

  test('itens criados no mesmo instante ganham ids diferentes', () {
    final ids = {
      for (var i = 0; i < 500; i++)
        Insumo(nome: 'x', unidade: Unidade.g, qtdEmbalagem: 1, precoCentavos: 1).id
    };
    expect(ids.length, 500);
  });

  test('reais usa o sinal de menos tipográfico', () {
    expect(reais(-1200), '\u2212R\$\u00a012,00');
    expect(reais(-0.2), 'R\$\u00a00,00');
  });
}
