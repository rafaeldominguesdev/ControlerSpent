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
    app.main();
    await calma(t);
    await Future<void>.delayed(const Duration(seconds: 2)); // fontes
    await calma(t);
    await binding.takeScreenshot('01_relatorio');

    // Vendas: só vendas, com cliente.
    await aba(t, 'Vendas');
    await binding.takeScreenshot('02_vendas');
    await t.tap(find.text('Registrar venda'));
    await calma(t);
    await t.tap(find.text('Brigadeiro gourmet').last);
    await calma(t);
    await rolar(t, 300, onde: find.byType(SingleChildScrollView).last);
    await binding.takeScreenshot('03_venda_cliente');
    await fecharFolha(t);

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

    // Produtos e receitas prontas.
    await aba(t, 'Produtos');
    await binding.takeScreenshot('08_produtos');
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

    // Modo escuro.
    await t.tap(find.byTooltip('Configurações').first);
    await calma(t);
    await t.tap(find.text('Escuro').last);
    await calma(t);
    await t.tap(find.byType(BackButton));
    await calma(t);
    await aba(t, 'Produção');
    await binding.takeScreenshot('12_producao_escuro');
    await aba(t, 'Vendas');
    await binding.takeScreenshot('13_vendas_escuro');

    await t.tap(find.byTooltip('Configurações').first);
    await calma(t);
    await t.tap(find.text('Automático').last);
    await calma(t);
    await t.tap(find.byType(BackButton));
    await calma(t);
  });
}
