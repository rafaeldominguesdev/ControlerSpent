import 'package:confeitaria/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Percorre as telas principais e tira um print de cada uma.
/// Rodar com o app desinstalado antes (para vir com os dados de exemplo):
///   flutter drive --driver=test_driver/integration_test.dart
///   --target=integration_test/telas_test.dart --dart-define=EXEMPLO=true
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> calma(WidgetTester t) async {
    await t.pumpAndSettle(const Duration(milliseconds: 100));
    await Future<void>.delayed(const Duration(milliseconds: 600));
    await t.pumpAndSettle();
  }

  Future<void> rolar(WidgetTester t, double dy, {Finder? onde}) async {
    await t.drag(onde ?? find.byType(Scrollable).first, Offset(0, -dy));
    await calma(t);
  }

  Future<void> aba(WidgetTester t, String nome) async {
    await t.tap(find.text(nome).last);
    await calma(t);
  }

  Future<void> fecharFolha(WidgetTester t) async {
    await t.tapAt(const Offset(20, 60));
    await calma(t);
  }

  testWidgets('prints das telas', (t) async {
    // A abertura animada não aparece em print aqui: o teste não anda o relógio
    // como o celular. Para ver, abra o app no simulador e tire prints em sequência.
    await app.main();
    await calma(t);
    await Future<void>.delayed(const Duration(seconds: 1));
    await calma(t);

    // O app abre em Vendas, com os produtos à mão (em grade e em lista).
    await binding.takeScreenshot('01_vendas');
    await t.tap(find.byTooltip('Ver em lista'));
    await calma(t);
    await binding.takeScreenshot('01b_vendas_lista');
    await t.tap(find.text('Brigadeiro gourmet').first);
    await calma(t);
    await binding.takeScreenshot('02_venda_quantidade');
    await rolar(t, 300, onde: find.byType(SingleChildScrollView).last);
    await binding.takeScreenshot('03_venda_cliente');
    await fecharFolha(t);
    await t.tap(find.text('Histórico'));
    await calma(t);
    await binding.takeScreenshot('03a_vendas_historico');
    await t.tap(find.text('Vender'));
    await calma(t);
    await t.tap(find.byTooltip('Ver em grade'));
    await calma(t);

    // Relatório: o extrato do mês, as semanas e o mês anterior.
    await aba(t, 'Relatório');
    await binding.takeScreenshot('03b_relatorio');
    await t.dragFrom(const Offset(200, 600), const Offset(0, -420));
    await calma(t);
    await binding.takeScreenshot('03c_relatorio_semanas');
    await t.dragFrom(const Offset(200, 300), const Offset(0, 420));
    await calma(t);
    final meses = find.descendant(of: find.byType(TabBar), matching: find.byType(Tab));
    await t.tap(meses.at(meses.evaluate().length - 2));
    await calma(t);
    await binding.takeScreenshot('03d_relatorio_mes_anterior');

    // Produção: registrar com os atalhos de receita.
    await aba(t, 'Produção');
    await binding.takeScreenshot('04_producao');
    await t.tap(find.text('Registrar produção'));
    await calma(t);
    await binding.takeScreenshot('05_producao_produto');
    await t.tap(find.text('Cookie recheado').last);
    await calma(t);
    await t.tap(find.text('2 receitas'));
    await calma(t);
    await binding.takeScreenshot('06_producao_quantidade');
    await t.tap(find.textContaining('Anotar produção de'));
    await calma(t);
    await binding.takeScreenshot('07_producao_depois');

    // Produtos: grade, lista, filtro por categoria e receitas prontas. (A aba
    // Vendas também tem os botões de grade/lista; os de Produtos vêm depois.)
    await aba(t, 'Produtos');
    await binding.takeScreenshot('08_produtos');
    await t.tap(find.byTooltip('Ver em lista').last);
    await calma(t);
    await binding.takeScreenshot('08b_produtos_lista');
    await t.ensureVisible(find.byKey(const ValueKey('categoria Docinhos')));
    await calma(t);
    await t.tap(find.byKey(const ValueKey('categoria Docinhos')));
    await calma(t);
    await binding.takeScreenshot('08c_produtos_categoria');
    await t.ensureVisible(find.byKey(const ValueKey('categoria Todos')));
    await calma(t);
    await t.tap(find.byKey(const ValueKey('categoria Todos')));
    await calma(t);
    await t.tap(find.text('Brigadeiro gourmet').last);
    await calma(t);
    await binding.takeScreenshot('08d_produto_editar');
    await t.tap(find.byType(BackButton));
    await calma(t);
    await t.tap(find.byTooltip('Ver em grade').last);
    await calma(t);
    await t.tap(find.text('Receitas prontas').first);
    await calma(t);
    await t.tap(find.text('Pão de mel'));
    await calma(t);
    await binding.takeScreenshot('09_receitas_prontas');
    await t.tap(find.text('Adicionar').first);
    await calma(t);
    await binding.takeScreenshot('10_receita_adicionada');
    await t.tap(find.byType(BackButton));
    await calma(t);
    await binding.takeScreenshot('11_produtos_com_pao_de_mel');

    // Aba Mais: ingredientes, receitas prontas e as configurações em partes.
    await aba(t, 'Mais');
    await binding.takeScreenshot('12_mais');
    await t.tap(find.text('Contas do mês'));
    await calma(t);
    await binding.takeScreenshot('13_contas');
    await t.tap(find.byType(BackButton));
    await calma(t);
    await t.tap(find.text('Backup'));
    await calma(t);
    await binding.takeScreenshot('13b_backup');
    await t.tap(find.byType(BackButton));
    await calma(t);

    // Uma segunda loja: as lojas aparecem em abas no topo. No fim ela é apagada,
    // para o simulador voltar a ter uma loja só.
    await t.tap(find.text('Lojas'));
    await calma(t);
    if (find.text('Bolos da Lu').evaluate().isEmpty) {
      await t.tap(find.text('Nova loja'));
      await calma(t);
      await t.enterText(find.byType(TextField).last, 'Bolos da Lu');
      await t.tap(find.text('Criar'));
      await calma(t);
    }
    await binding.takeScreenshot('15_lojas');
    await t.tap(find.byType(BackButton));
    await calma(t);
    await binding.takeScreenshot('16_loja_nova');
    await t.tap(find.text('Doces da Lu').first);
    await calma(t);
    await aba(t, 'Vendas');
    await binding.takeScreenshot('17_vendas_com_abas_de_lojas');
    await aba(t, 'Mais');
    await t.tap(find.text('Lojas'));
    await calma(t);
    await t.tap(find.byTooltip('Apagar Bolos da Lu'));
    await calma(t);
    await t.tap(find.text('Apagar'));
    await calma(t);
    await t.tap(find.byType(BackButton));
    await calma(t);
    await t.tap(find.text('Ingredientes e embalagens'));
    await calma(t);
    await binding.takeScreenshot('14_ingredientes');
    await t.tap(find.text('Leite condensado').first);
    await calma(t);
    await binding.takeScreenshot('14b_ingrediente_editar');
    await fecharFolha(t);
    await t.tap(find.byType(BackButton));
    await calma(t);
  });
}
