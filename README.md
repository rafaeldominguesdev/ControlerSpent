<p align="center">
  <img src="assets/logo/icone.png" width="104" alt="Logo do Controler Spent: três barras azul-marinho sobre um degradê azul">
</p>

<h1 align="center">Controler Spent</h1>

<p align="center">
  Preço, vendas e lucro de confeitaria, direto no celular.<br>
  Feito em Flutter para iPhone e Android, com tudo guardado no próprio aparelho.
</p>

O Controler Spent nasceu de uma planilha de precificação de confeitaria. A planilha fazia as
contas certas, mas era ruim de usar no dia a dia: para anotar uma venda era preciso abrir o
computador. O app leva a mesma lógica para o celular. A confeiteira cadastra o que compra,
monta as receitas, e o app calcula quanto custa cada unidade, sugere o preço e mostra o lucro
de verdade, venda por venda.

- **Anotar uma venda leva dois toques:** o produto e "Anotar venda".
- **O lucro é o que sobra de verdade:** desconta ingredientes, embalagens, taxas da
  maquininha e perdas.
- **Sem conta e sem internet:** os dados ficam no celular, com backup num arquivo.

## O que o app faz

O app tem cinco abas: **Relatório**, **Vendas**, **Produção**, **Produtos** e **Mais**. Ele
abre em Vendas, que é o que se usa o dia inteiro.

### Vendas

Mostra em verde quanto entrou hoje e quanto disso foi lucro. Os produtos aparecem em grade ou
em lista (o app lembra a escolha), com os mais vendidos dos últimos 30 dias primeiro. Um toque
no produto abre a venda: quantidade (com atalhos de +5 e +10, ou digitando), preço, forma de
pagamento (começa na última usada), cliente e observação. O histórico fica separado por dia.

### Produção

Quantas unidades estão prontas para vender e quanto elas valem. Para registrar a produção há
atalhos por receita ("2 receitas" de um brigadeiro que rende 25 viram 50 unidades), e as
perdas e sobras também são anotadas.

### Produtos

O cardápio, com foto, categoria (bolos, docinhos…), preço, lucro e custo de cada unidade, em
grade ou em lista e com filtro por categoria. O cadastro do produto é a ficha técnica da
planilha: ingredientes da receita, rendimento e margem desejada; o custo e o preço sugerido
mudam enquanto ela digita. Oito receitas prontas (pão de mel, brigadeiro gourmet, beijinho,
brownie, bolo de pote, trufa, cookie e bolo de cenoura) já entram com a ficha montada e
aproveitam os ingredientes que estiverem cadastrados.

### Ingredientes e embalagens

Cadastrados como vêm no pacote (leite condensado, 395 g, R$ 7,90), com foto se ela quiser. O
app calcula o custo de cada grama, mililitro ou unidade.

### Relatório do mês

Os meses ficam em abas. No topo, vendas, pedidos e lucro em destaque, cada um com uma setinha
que compara com o mês passado (no mês em andamento, até o mesmo dia). Embaixo, a tabela por
produto, como na planilha (quantidade, vendas e lucro), com o total, as contas fixas e o
salário, e quanto sobra ou falta para cobri-los.

### Lojas

Quem vende com mais de um nome pode ter mais de uma loja. Cada loja tem os seus produtos,
ingredientes, vendas, relatório e contas, como se fossem apps separados. Com duas ou mais,
elas aparecem em abas no topo do app, e um toque troca de loja. Cada loja pode ter logo ou
foto.

### Configurações

Ficam na aba Mais, em partes: loja (nome e logo), contas do mês (salário e contas fixas), taxas
da maquininha por forma de pagamento, lojas e backup.

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
