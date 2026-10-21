# Licença e tratamento de dados

## Licença do código

O código-fonte do Offline Gym é publicado sob a licença MIT, disponível no
arquivo [`LICENSE`](../LICENSE). Ela permite usar, copiar, modificar e
redistribuir o código, inclusive em projetos comerciais, desde que o aviso de
direitos autorais e o texto da licença acompanhem as cópias ou partes
substanciais do software.

A MIT não obriga quem distribui uma versão modificada a publicar as próprias
alterações. Também não concede, por si só, direito de usar o nome, o logotipo ou
a identidade visual do Offline Gym como se fossem oficiais. Dependências e
outros componentes de terceiros mantêm as respectivas licenças.

O arquivo `LICENSE` delimita a concessão ao código-fonte do projeto. Nome,
logotipos, ícone, capturas de tela e material promocional ficam fora dessa
concessão; não use esses elementos para sugerir que um fork é a versão oficial.

## Onde os dados ficam

O app não exige conta nem sincroniza os registros com um servidor. Os dados de
uso ficam no armazenamento privado do aplicativo no aparelho:

| Informação                                                         | Uso no app                                                           | Armazenamento                                  |
| ------------------------------------------------------------------ | -------------------------------------------------------------------- | ---------------------------------------------- |
| Nome, idade, meta de peso e foto de perfil                         | Identificar o perfil e personalizar lembretes e metas                | SQLite e pasta privada de imagens              |
| Planos, rotinas, modelos e exercícios (+2.000 no catálogo offline) | Exibir o treino selecionado para cada dia                            | SQLite; fotos e GIFs na pasta privada do app   |
| Hábitos diários, registros de progresso e tarefas (To-Do)          | Acompanhamento de rotina, ofensiva de hábitos e mapa de consistência | SQLite                                         |
| Treinos concluídos, séries, repetições, carga e duração            | Histórico, recordes pessoais (PR) e gráficos de evolução             | SQLite                                         |
| Peso corporal                                                      | Perfil e evolução corporal                                           | SQLite, compartilhado entre perfil e histórico |
| Diário, figurinhas e imagens                                       | Anotações por data                                                   | SQLite e pasta privada de imagens              |
| Fotos mensais de evolução                                          | Comparação visual ao longo do tempo                                  | SQLite e pasta privada de imagens              |
| Tema, áudio, escudos de ofensiva e preferências de lembrete        | Configuração da experiência local                                    | Preferências do app e arquivos privados        |
| Backups salvos no celular                                          | Cópias locais instantâneas e automáticas pré-importação              | Pasta privada `backups_locais` do app          |
| Desafio mensal adiado                                              | Lembrar que a pessoa escolheu pular a foto neste mês                 | Preferência local; não é enviado a servidor    |

As notificações de treino são agendadas localmente pelo Android. O app pode
mostrar o nome e a rotina escolhidos pelo usuário na notificação do próprio
aparelho.

## Fotos mensais e sequência de treinos

A foto mensal é apresentada como um desafio de acompanhamento. A pessoa pode
registrar uma foto ou tocar em **Pular por enquanto**. Pular libera as telas do
app naquele mês; o desafio pode ser acessado depois e volta a aparecer no mês
seguinte. As fotos não são enviadas a um serviço remoto pelo app.

A ofensiva é calculada a partir dos dias com treinos concluídos no histórico
local. A contagem semanal usa os dias únicos de segunda a domingo. Não há
servidor, conta ou placar compartilhado.

## Exportação e importação de backup

Os backups novos são compactados e criptografados antes de serem compartilhados.
O formato usa Argon2id para derivar uma chave a partir da senha, com salt
aleatório de 16 bytes, 19 MiB de memória, paralelismo 1 e duas iterações. O
conteúdo é cifrado com AES-256-GCM, nonce aleatório de 12 bytes e autenticação
de 16 bytes. Os parâmetros públicos e os dados cifrados vão no arquivo `.ogb`;
a senha não é gravada no app nem no backup.

A senha é escolhida em cada exportação. O app não consegue recuperar uma senha
esquecida; guarde-a em um gerenciador seguro. Uma senha longa e exclusiva é
recomendada. Um arquivo alterado ou uma senha incorreta é recusado antes da
restauração. Backups `.zip` antigos, sem criptografia, continuam aceitos para
migração.

O app não impõe um limite artificial ao histórico ou à quantidade de fotos
guardadas localmente. A exportação reúne o arquivo de dados e as imagens na
memória do aparelho; aparelhos com pouca memória livre podem não conseguir
exportar um backup muito grande, embora os dados locais continuem guardados.

O backup pode conter perfil, planos, histórico, peso, diários e imagens. Ao
escolher um app externo para guardar ou compartilhar o arquivo, a pessoa passa
a depender das práticas desse serviço. A criptografia protege o arquivo fora
do app enquanto a senha não for divulgada.

Os registros normais do aparelho continuam no SQLite e em arquivos privados; a
criptografia descrita acima protege o arquivo exportado. Ela não cifra o banco
SQLite nem os arquivos de imagem no armazenamento privado do app.

## Documento de referência

Este arquivo descreve o comportamento implementado no projeto. Antes de publicar
na Play Store, a política de privacidade e o formulário Segurança dos dados
devem ser preenchidos com base na versão final compilada e em todos os SDKs
incluídos nela.

## Criador, Autoria e Apoio

- **Criador e Desenvolvedor Original:** **Luan Thierry** ([@LuanThierry](https://github.com/LuanThierry))
- **Apoio Voluntário via LivePix:** [**https://livepix.gg/luanthierry**](https://livepix.gg/luanthierry)

O Offline Gym é um projeto independente de código aberto. Se você aprecia a iniciativa de manter uma ferramenta fitness 100% offline, gratuita e que respeita a privacidade de dados no dispositivo, apoie o criador deixando uma estrela no GitHub ou enviando uma contribuição pelo LivePix!
