// Valores em dinheiro são guardados em centavos (int) para evitar erro de arredondamento.

int _ultimoId = 0;

/// Id único e sempre crescente. Só o relógio não basta: itens criados no
/// mesmo instante (no web o relógio tem precisão de milissegundo) repetiam o id
/// e a receita acabava usando o ingrediente errado.
int _nextId() {
  final agora = DateTime.now().microsecondsSinceEpoch;
  _ultimoId = agora > _ultimoId ? agora : _ultimoId + 1;
  return _ultimoId;
}

enum Unidade { g, ml, un }

extension UnidadeLabel on Unidade {
  String get label => name;
}
