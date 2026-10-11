# Doce Controle

App de precificação e controle para confeitaria, feito em Flutter para iPhone e Android.
Nasceu de uma planilha de precificação: a confeiteira cadastra o que compra, monta as
receitas e o app calcula custo, preço sugerido e lucro.

## O que faz

- **Ingredientes e embalagens**: cadastro como vem no pacote (ex.: leite condensado, 395 g,
  R$ 7,90); o app calcula o custo de cada grama, ml ou unidade.
- **Produtos**: receita com foto, rendimento e margem; custo por unidade, preço sugerido e
  semáforo de margem. Inclui **receitas prontas** (pão de mel, brigadeiro, brownie e outras)
  que reaproveitam os ingredientes já cadastrados.
- **Vendas**: registro em poucos toques (produto, quantidade, pagamento), com cliente e
  observação; taxas da maquininha descontadas automaticamente.
- **Produção**: quanto ficou pronto, estoque para vender e perdas.
- **Relatório do mês**: vendas por dia, lucro, margem, para onde foi o dinheiro, mais
  vendidos, vendas por produto, contas fixas e salário, e os últimos 6 meses.
- **Configurações**: tema claro, escuro ou automático; nome do negócio, salário, contas fixas
  e taxas por forma de pagamento.

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

Prints de todas as telas (claro e escuro) no simulador:

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
- `lib/theme.dart`: cores (claro e escuro), espaçamentos, movimento e tipografia
- `lib/widgets.dart`: componentes compartilhados
- `lib/screens/`: telas
- `assets/icone/`: desenho do ícone (SVG); os tamanhos saem de `dart run flutter_launcher_icons`
