<div align="center">

#  Offline Gym

**Seus treinos organizados, mesmo sem internet.**

Aplicativo Android feito com **Flutter, Dart e SQLite**, com foco em simplicidade, funcionamento offline e armazenamento local.

[ Baixar APK para Android](https://github.com/LuanThierry/offline-gym/releases/latest/download/Offline-Gym.apk) · [ Ver versões](https://github.com/LuanThierry/offline-gym/releases) · [ Código-fonte](https://github.com/LuanThierry/offline-gym)

![Flutter](https://img.shields.io/badge/Flutter-mobile-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-language-0175C2?logo=dart&logoColor=white)
![SQLite](https://img.shields.io/badge/SQLite-local%20database-003B57?logo=sqlite&logoColor=white)
![Status](https://img.shields.io/badge/status-projeto%20pessoal-informational)

</div>

---

##  Sobre o projeto

Criei o **Offline Gym** para ter uma forma prática de organizar meus treinos sem depender de conexão com a internet. A ideia é reunir em um só lugar o planejamento dos exercícios, o acompanhamento das séries e cargas e o histórico do que foi realizado.

Eu queria priorizar algo que funcionasse de verdade no dia a dia: abrir o aplicativo na academia, consultar o treino, registrar o progresso e continuar mesmo quando a conexão não estiver disponível.

O projeto também é uma forma de colocar em prática meus estudos de desenvolvimento: trabalhar com interface mobile, persistência de dados, gerenciamento de estado, testes e geração de uma versão Android instalável.

##  Funcionalidades

- **Planejamento de treinos:** organizar exercícios por dia da semana e configurar séries, repetições e carga de referência.
- **Registro durante o treino:** marcar séries concluídas e acompanhar as cargas utilizadas.
- **Carga por série:** ajustar a carga de cada série sem alterar automaticamente a carga de referência do plano.
- **Persistência local:** guardar os dados no SQLite, sem exigir uma conta ou sincronização com um servidor.
- **Retomada do treino:** preservar o estado da sessão em andamento para ajudar a continuar após uma interrupção ou fechamento inesperado do app.
- **Histórico:** consultar sessões concluídas e acompanhar a evolução do treino.
- **Peso corporal:** registrar pesagens e acompanhar essa evolução separadamente das cargas dos exercícios.
- **Mídia local:** selecionar fotos ou GIFs da galeria para associar aos exercícios, mantendo os arquivos no dispositivo.

> O projeto está em evolução. Consulte a versão publicada e teste as funções no seu aparelho para confirmar o comportamento da compilação que você instalou.

##  Decisões e problemas que procurei resolver

### 1. Usar o aplicativo sem depender da internet

Uma rotina de treino não deveria ficar inacessível só porque a conexão caiu ou a academia tem sinal ruim. Por isso, priorizei uma abordagem **offline-first**, com persistência local em SQLite.

### 2. Evitar perder o progresso de uma sessão

Um treino pode ser interrompido por uma ligação, pelo sistema ou por fechar o aplicativo sem querer. A proposta de persistir a sessão em andamento é permitir que o usuário retome de onde parou, em vez de precisar reconstruir tudo manualmente.

### 3. Registrar o treino feito, não só o planejado

A carga de referência de um exercício é diferente da carga usada em cada série. Separei esses conceitos para permitir ajustes durante o treino e manter um histórico mais fiel do que foi executado.

### 4. Manter as informações organizadas

O histórico de sessões e o registro de peso corporal representam coisas diferentes. Mantê-los separados ajuda a consultar cada tipo de evolução sem misturar métricas.

### 5. Reduzir dependências de serviços externos

Para este projeto, preferi armazenamento local e mídia selecionada pelo usuário. Isso reduz a dependência de serviços de terceiros para as funções centrais do app e ajuda a manter a experiência disponível offline.

Essas escolhas podem ser úteis para outras pessoas que procuram um registro de treino simples, com dados locais e sem precisar criar uma conta.

##  Tecnologias

- **Flutter e Dart** — construção da aplicação mobile.
- **SQLite (`sqflite`)** — armazenamento local dos dados.
- **Provider** — gerenciamento de estado.
- **`image_picker`** — seleção de mídia da galeria.
- **`fl_chart`** — visualização de evolução em gráficos.
- **`table_calendar`** — calendário para navegação pelo histórico.

##  Instalação no Android

1. Abra a página de [Releases](https://github.com/LuanThierry/offline-gym/releases).
2. Baixe o arquivo **`Offline-Gym.apk`** anexado à versão mais recente.
3. Abra o arquivo no celular e siga as instruções do Android. O sistema pode solicitar autorização para instalar aplicativos baixados dessa origem.
4. Se o app já estiver instalado e o Android informar incompatibilidade de assinatura ou de atualização, **não desinstale a versão existente**, principalmente se tiver dados que deseja preservar.

**Importante sobre os dados:** os registros ficam armazenados localmente no dispositivo. Não há sincronização em nuvem implementada neste projeto; desinstalar o aplicativo ou limpar seus dados pode apagar os registros locais. Faça testes com cuidado e mantenha uma cópia das informações importantes.

##  Executar o projeto localmente

Você precisará do Flutter SDK instalado e de um ambiente configurado para Android.

```bash
git clone https://github.com/LuanThierry/offline-gym.git
cd offline-gym
flutter pub get
flutter run
```

Para validar o projeto:

```bash
flutter analyze
flutter test
```

Para gerar um APK Release separado por arquitetura:

```bash
flutter build apk --release --split-per-abi
```

O APK ARM de 64 bits costuma ser o arquivo `app-arm64-v8a-release.apk`, dentro de `build/app/outputs/flutter-apk/`.

##  Validação

Na versão inicial publicada, executei as verificações abaixo no ambiente de desenvolvimento:

- `flutter analyze` — concluído sem problemas reportados.
- `flutter test` — todos os testes existentes passaram.
- `flutter build apk --release --split-per-abi` — compilação Release gerada.

Essas verificações não substituem testes em diferentes aparelhos e versões do Android. Feedbacks sobre erros e melhorias são bem-vindos.

##  Usei inteligência artificial

Usei IA como ferramenta de apoio durante o planejamento, a implementação, a refatoração e a investigação de problemas. Também executei as ferramentas de análise e testes para verificar o projeto, em vez de considerar uma sugestão de código correta automaticamente.

Para mim, a parte importante desse processo é aprender a definir requisitos, avaliar as mudanças, entender os erros e validar o resultado. A IA fez parte do fluxo de trabalho, mas não substituiu a necessidade de revisar e testar a aplicação.

##  Próximos passos

- Continuar testando a preservação dos dados e a retomada de sessões.
- Melhorar a documentação conforme novas versões forem publicadas.
- Corrigir problemas identificados no uso real e evoluir a experiência de treino.

## Feedback

Encontrou um problema ou tem uma ideia? Abra uma [Issue no GitHub](https://github.com/LuanThierry/offline-gym/issues) descrevendo o que aconteceu, os passos para reproduzir e, se possível, a versão do Android e do aplicativo.

##  Licença

A licença ainda será definida. Até lá, o código pode ser consultado publicamente, mas a publicação do repositório, por si só, não concede automaticamente permissão para redistribuir ou reutilizar o projeto.

---

<div align="center">

Feito como projeto pessoal de aprendizado e desenvolvimento. 

</div>
