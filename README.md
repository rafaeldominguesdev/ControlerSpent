# Controler Spent

App de precificação e controle para confeitaria, feito em Flutter para iPhone e Android.
Nasceu de uma planilha de precificação: a confeiteira cadastra o que compra, monta as
receitas e o app calcula custo, preço sugerido e lucro.

## O que faz

- **Ingredientes e embalagens**: cadastro como vem no pacote (ex.: leite condensado, 395 g,
  R$ 7,90); o app calcula o custo de cada grama, ml ou unidade.
- **Produtos**: receita com foto, rendimento, margem e categoria (bolos, docinhos...); em
  grade ou em lista, com filtro por categoria e o preço, o lucro e o custo de cada unidade.
  Inclui **receitas prontas** (pão de mel, brigadeiro, brownie e outras) que reaproveitam os
  ingredientes já cadastrados.
- **Vendas**: o total de hoje em verde, os produtos em grade ou em lista (um toque abre a
  venda: quantidade, pagamento, cliente e observação) e o histórico separado por dia; taxas
  da maquininha descontadas automaticamente.
- **Produção**: quanto ficou pronto, estoque para vender e perdas.
- **Relatório do mês**, com os meses em abas: vendas, pedidos e lucro em destaque, com a
  setinha comparando com o mês passado, e a tabela por produto (quantidade, vendas e lucro),
  como na planilha, com as contas fixas e o salário no fim.
- **Lojas**: dá para ter mais de uma loja, cada uma com os seus produtos, ingredientes, vendas,
  relatório e contas; com mais de uma, elas aparecem em abas no topo do app.
- **Configurações** (aba Mais), em partes: loja (nome e logo), contas do mês (salário e contas
  fixas), taxas da maquininha, lojas e **backup** (salvar uma cópia da loja pelo menu de
  compartilhar e restaurar depois, como loja nova ou por cima da atual).

## Regra de contas

O custo dos ingredientes entra no lucro quando o produto é **vendido** (só o que foi vendido)
ou **perdido**. A produção não entra no lucro: ela alimenta o estoque. Valores em dinheiro são
guardados em centavos para não haver erro de arredondamento.

## Rodando

```sh
flutter pub get
flutter run                                  # celular ou simulador conectado
flutter run --dart-define=EXEMPLO=true       # abre com uma confeitaria de exemplo
flutter test                                 # testes de cálculo e de produção
```

Prints das telas no simulador:

```sh
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/telas_test.dart --dart-define=EXEMPLO=true
```

Os prints ficam em `build/prints/`.

## Instalando no iPhone

Com uma conta Apple gratuita o app vale por 7 dias; depois é só instalar de novo (os dados
continuam):

```sh
flutter build ios --release
xcrun devicectl device install app --device <UDID> build/ios/iphoneos/Runner.app
```

## Estrutura

- `lib/models.dart`: ingredientes, produtos, cálculo, vendas/produção/perdas e resumo do mês
- `lib/store.dart`: armazenamento local, estoque e formatação de dinheiro
- `lib/theme.dart`: cores, espaçamentos, movimento e tipografia
- `lib/widgets.dart`: componentes compartilhados
- `lib/screens/`: telas
- `assets/logo/`: logo (SVG e degradê), ícone e abertura; os tamanhos saem de
  `dart run flutter_launcher_icons` e `dart run flutter_native_splash:create`
