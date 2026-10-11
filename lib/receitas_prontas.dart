import 'models.dart';

/// Receitas prontas: produto completo com ingredientes, embalagem e preço.
/// Os preços dos ingredientes são de referência (mercado, 2026); a pessoa ajusta
/// depois em Ingredientes com o que ela paga.

class ModeloInsumo {
  final String nome;
  final Unidade unidade;
  final double qtdEmbalagem;
  final int precoCentavos;
  final bool embalagem;
  const ModeloInsumo(this.nome, this.unidade, this.qtdEmbalagem, this.precoCentavos,
      {this.embalagem = false});
}

class ModeloReceita {
  final String nome;
  final String categoria;
  final String descricao;
  final int rendimento;
  final int precoVendaCentavos;
  final List<(ModeloInsumo, double)> itens;
  const ModeloReceita({
    required this.nome,
    required this.categoria,
    required this.descricao,
    required this.rendimento,
    required this.precoVendaCentavos,
    required this.itens,
  });
}

// Ingredientes e embalagens (pacote como vem no mercado).
const _leiteCondensado = ModeloInsumo('Leite condensado', Unidade.g, 395, 790);
