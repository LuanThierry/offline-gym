# Política de Privacidade — Offline Gym (Treinos e Hábitos Offline)

**Última atualização:** Outubro de 2026  
**Versão de referência:** `1.4.0+7`

O **Offline Gym (Treinos e Hábitos Offline)** foi projetado desde a base sob o princípio **100% Offline-First e Privacidade Total no Dispositivo**.

## 1. Coleta e Compartilhamento de Dados
- **Nenhuma coleta remota:** O aplicativo **não solicita a permissão `android.permission.INTERNET`** e não realiza conexões com servidores externos, APIs em nuvem, serviços de telemetria, analytics ou redes de anúncios.
- **Zero compartilhamento com terceiros:** Nenhum dado pessoal, histórico de treinos, hábitos, tarefas, peso corporal ou fotos é transmitido, vendido ou compartilhado com terceiros.
- **Uso sem cadastro:** O aplicativo não exige criação de conta, e-mail, telefone ou login social.

## 2. Armazenamento Local no Aparelho
Todas as informações registradas pelo usuário permanecem armazenadas exclusivamente no armazenamento interno privado do próprio dispositivo Android:
- **Banco de dados SQLite local (`sqflite`):** guarda perfil local (nome, idade, metas), planos semanais de treino, catálogo personalizado, histórico de séries e cargas, registros de peso corporal, diário de treino, hábitos e tarefas.
- **Diretório privado do aplicativo:** armazena a foto de perfil, fotos ou GIFs associados aos exercícios, imagens do diário e fotos mensais de evolução, além das cópias locais de backup.
- **Preferências locais (`shared_preferences`):** guardam configurações de tema (claro, escuro ou sistema), som/vibração do cronômetro e escudos de ofensiva.

## 3. Permissões Utilizadas no Android
- **`POST_NOTIFICATIONS`:** utilizada exclusivamente para exibir lembretes locais de treino agendados no próprio celular.
- **`VIBRATE`:** utilizada para o feedback tátil e alarme ao término do cronômetro de descanso entre séries.
- **Seletor de Arquivos / Galeria do Sistema:** utilizado apenas quando o próprio usuário escolhe associar uma imagem a um exercício, registrar foto mensal/diário, escolher um toque personalizado ou exportar/importar um arquivo de backup.

## 4. Backups e Criptografia (`.ogb`)
- O usuário pode salvar cópias locais no próprio aparelho ou exportar um arquivo de backup criptografado (`.ogb`).
- Os arquivos `.ogb` são protegidos com derivação de chave **Argon2id** e criptografia autenticada **AES-256-GCM** usando a senha definida pelo usuário no momento da exportação.
- O aplicativo não armazena nem envia essa senha para nenhum local externo. Caso o usuário compartilhe o arquivo de backup por aplicativos de terceiros (como e-mail, mensageiros ou armazenamento em nuvem próprio), o arquivo estará sob a proteção da criptografia `.ogb` e das políticas do serviço escolhido pelo usuário.

## 5. Exclusão dos Dados
Como todos os dados residem exclusivamente no aparelho do usuário, é possível:
- Excluir treinos, hábitos, tarefas, fotos, registros de peso ou backups locais diretamente nas telas do aplicativo;
- Limpar o armazenamento do aplicativo nas configurações do Android ou desinstalar o aplicativo, o que remove todos os dados armazenados na pasta privada do app.

## 6. Código Aberto e Transparência
O código-fonte do aplicativo é aberto e distribuído sob a **Licença MIT**, permitindo auditoria pública completa do funcionamento offline e do tratamento local dos dados no repositório oficial:
- Repositório: [https://github.com/LuanThierry/offline-gym](https://github.com/LuanThierry/offline-gym)
