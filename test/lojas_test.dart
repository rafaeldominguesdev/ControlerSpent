import 'dart:convert';

import 'package:confeitaria/models.dart';
import 'package:confeitaria/store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final brigadeiro = Produto(nome: 'Brigadeiro', rendimento: 25, precoVendaCentavos: 300);

  Future<Store> abrir() async {
    final store = Store();
    await store.carregar();
    return store;
  }

  test('os dados de antes das lojas viram a loja 1, sem perder nada', () async {
    SharedPreferences.setMockInitialValues({
      'produtos': jsonEncode([brigadeiro.toJson()]),
      'ajustes': jsonEncode(Ajustes(nomeNegocio: 'Doces da Lu').toJson()),
    });
    final store = await abrir();
    expect(store.lojas.map((l) => l.nome), ['Doces da Lu']);
    expect(store.produtos.single.nome, 'Brigadeiro');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('produtos'), isNull); // a chave antiga foi embora
    expect(prefs.getString('produtos_1'), isNotNull);

    // Abrindo de novo, continua tudo lá.
    final denovo = await abrir();
    expect(denovo.produtos.single.nome, 'Brigadeiro');
  });

  test('cada loja tem os seus próprios dados', () async {
    SharedPreferences.setMockInitialValues({
      'produtos': jsonEncode([brigadeiro.toJson()]),
    });
    final store = await abrir();
    await store.novaLoja('Bolos da Lu');
    expect(store.lojaAtual.nome, 'Bolos da Lu');
    expect(store.produtos, isEmpty);
    expect(store.ajustes.nomeNegocio, 'Bolos da Lu');

    await store.salvarProduto(Produto(nome: 'Bolo de cenoura'));
    await store.trocarLoja(store.lojas.first.id);
    expect(store.produtos.map((p) => p.nome), ['Brigadeiro']);

    // A loja escolhida é lembrada.
    await store.trocarLoja(store.lojas.last.id);
    final denovo = await abrir();
    expect(denovo.lojaAtual.nome, 'Bolos da Lu');
    expect(denovo.produtos.map((p) => p.nome), ['Bolo de cenoura']);
  });

  test('a foto de qualquer loja pode ser trocada e fica guardada', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await abrir();
    final primeira = store.lojas.single;
    await store.novaLoja('Bolos da Lu'); // a primeira deixa de ser a loja em uso
    await store.mudarFotoLoja(primeira.id, 'Zm90bw==');
    final denovo = await abrir();
    expect(denovo.lojas.first.fotoBase64, 'Zm90bw==');
    expect(denovo.lojas.last.fotoBase64, isNull);
  });

  test('apagar uma loja leva os dados dela e volta para outra', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await abrir();
    final segunda = await store.novaLoja('Segunda');
    await store.salvarProduto(Produto(nome: 'Pudim'));
    await store.removerLoja(segunda.id);
    expect(store.lojas, hasLength(1));
    expect(store.produtos, isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('produtos_${segunda.id}'), isNull);

    await store.removerLoja(store.lojas.single.id); // a última não pode ser apagada
    expect(store.lojas, hasLength(1));
  });

  test('a cópia de segurança volta igual, como loja nova ou por cima da atual', () async {
    SharedPreferences.setMockInitialValues({
      'produtos': jsonEncode([brigadeiro.toJson()]),
      'lancamentos': jsonEncode([
        Lancamento.venda(brigadeiro, 100, qtd: 10, preco: 300, pagamento: Pagamento.pix, taxa: 0)
            .toJson(),
      ]),
    });
    final store = await abrir();
    final copia = store.exportarLoja();

    await store.importarLoja(copia, comoNova: true);
    expect(store.lojas, hasLength(2));
    expect(store.produtos.single.nome, 'Brigadeiro');
    expect(store.lancamentos.single.vendidos, 10);

    await store.salvarProduto(Produto(nome: 'Extra'));
    await store.importarLoja(copia, comoNova: false);
    expect(store.lojas, hasLength(2));
    expect(store.produtos.map((p) => p.nome), ['Brigadeiro']);

    expect(() => store.importarLoja('{"outro": 1}', comoNova: true), throwsFormatException);
    expect(store.lojas, hasLength(2)); // arquivo errado não mexe em nada
  });
}
