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

## Como as contas são feitas

A lógica é a mesma da planilha:

| O quê | Conta |
| --- | --- |
| Custo de 1 g, 1 ml ou 1 unidade | preço do pacote ÷ quantidade do pacote |
| Custo da receita | soma de cada ingrediente × quanto vai na receita |
| Custo de uma unidade | custo da receita ÷ quantas unidades ela rende |
| Preço sugerido | custo de uma unidade ÷ (1 − margem desejada) |
| Lucro de uma venda | valor vendido − custo do que foi vendido − taxa da maquininha |

E algumas regras para o lucro não enganar:

- O custo entra no lucro quando o produto é **vendido** (só o que foi vendido) ou **perdido**.
  A produção não entra no lucro: ela vira estoque, os "prontos para vender".
- O estoque de um produto conta a partir da primeira produção registrada dele.
- As contas fixas (gás, luz, internet…) e o salário ficam no fim do relatório: o lucro do mês
  menos essas contas mostra quanto sobra ou quanto ainda falta. No mês em andamento, o que
  falta não é prejuízo: ainda dá tempo de vender.
- Dinheiro é guardado em centavos, em números inteiros, para não haver erro de arredondamento.

## Seus dados

- Tudo fica no próprio celular: não tem conta, servidor nem internet.
- Cada loja guarda os seus dados separados das outras.
- Em **Mais → Backup**, "Salvar uma cópia" gera um arquivo `.json` da loja e abre o menu de
  compartilhar do celular (Arquivos, WhatsApp, e-mail). "Restaurar uma cópia" lê esse arquivo
  e pergunta se ele vira uma loja nova ou se substitui os dados da loja atual; um arquivo que
  não é uma cópia do app não muda nada.
- Para trocar de celular, inclusive de iPhone para Android: salvar a cópia no aparelho antigo
  e restaurar no novo.

## Rodando o projeto

Precisa do [Flutter](https://flutter.dev) com Dart 3.

```sh
flutter pub get
flutter run                              # no celular ou simulador conectado
flutter run --dart-define=EXEMPLO=true   # abre com uma confeitaria de exemplo
```

### Testes

```sh
flutter test
```

Os testes cobrem o cálculo de custo e preço, a leitura de números no jeito brasileiro
("1.000", "7,50"), a regra de produção e estoque, as lojas (dados separados e a migração dos
dados de antes das lojas) e o backup.

Para tirar prints de todas as telas no simulador (com o app desinstalado antes, para ele abrir
com os dados de exemplo):

```sh
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/telas_test.dart --dart-define=EXEMPLO=true
```

Os prints ficam em `build/prints/`.

### No iPhone

Com uma conta Apple gratuita, o app vale por 7 dias; depois é só instalar de novo, e os dados
continuam:

```sh
flutter build ios --release
xcrun devicectl device install app --device <UDID> build/ios/iphoneos/Runner.app
```

### No Android

```sh
flutter build apk --release
```

O APK fica em `build/app/outputs/flutter-apk/app-release.apk`.

## Por dentro

### Tecnologias

- Flutter e Dart 3, com Material 3
- `shared_preferences`: os dados, em JSON, no próprio aparelho
- `google_fonts`: Newsreader nos títulos e números grandes, Figtree no resto
- `animations` (troca de telas), `image_picker` (fotos) e `intl` (datas e reais em pt-BR)
- `share_plus`, `file_picker` e `path_provider`: o backup
- `flutter_launcher_icons` e `flutter_native_splash`: o ícone e a tela de abertura

### Estrutura

```text
lib/
  main.dart               abas do app (e as abas das lojas no topo)
  abertura.dart           animação de abertura
  models.dart             ingredientes, produtos, cálculo, vendas, produção, perdas, lojas
  store.dart              dados por loja, estoque, backup e formatação de dinheiro
  theme.dart              cores, espaçamentos, cantos, movimento e tipografia
  widgets.dart            componentes compartilhados
  exemplo.dart            confeitaria de exemplo (--dart-define=EXEMPLO=true)
  receitas_prontas.dart   as receitas prontas
  screens/                as telas
test/                     testes de cálculo, produção, lojas e backup
integration_test/         tour de prints das telas
assets/logo/              logo em SVG, degradê e PNGs do ícone e da abertura
tool/degrade_logo.py      gera o degradê em malha da logo
```

### Visual

- A logo são três barras azul-marinho sobre um degradê em malha com as cores da marca
  (`tool/degrade_logo.py`). O ícone e a tela de abertura saem dela com
  `dart run flutter_launcher_icons` e `dart run flutter_native_splash:create`.
- O app inteiro é no azul da logo, por enquanto só no tema claro. Dinheiro entrando aparece
  sempre em verde.
- Ao abrir, o degradê da logo se forma na tela, o nome aparece e o app entra com um zoom.
