# Política de Privacidade — Offline Gym (Treinos e Hábitos Offline)

**Última atualização:** Outubro de 2026
**Versão de referência:** `1.4.2+9`
**Responsável pelo Projeto:** Luan Thierry ([@LuanThierry](https://github.com/LuanThierry))
**Contato e Suporte Oficial:** [luanthierry.suporte@gmail.com](mailto:luanthierry.suporte@gmail.com) • [GitHub Issues](https://github.com/LuanThierry/offline-gym/issues)
**URL Pública Oficial:** [https://github.com/LuanThierry/offline-gym/blob/main/PRIVACY_POLICY.md](https://github.com/LuanThierry/offline-gym/blob/main/PRIVACY_POLICY.md)

O **Offline Gym (Treinos e Hábitos Offline)** foi projetado desde a base sob o princípio **100% Offline-First e Privacidade Total no Dispositivo**.

## 1. Coleta e Compartilhamento de Dados
- **Nenhuma coleta remota:** O aplicativo **não solicita a permissão `android.permission.INTERNET`** e não realiza conexões com servidores externos, APIs em nuvem, serviços de telemetria, analytics ou redes de anúncios.
- **Zero compartilhamento com terceiros:** Nenhum dado pessoal, histórico de treinos, hábitos, tarefas, peso corporal ou fotos é transmitido, vendido ou compartilhado com terceiros.
- **Uso sem cadastro:** O aplicativo não exige criação de conta, e-mail, telefone ou login social.

## 2. Armazenamento Local no Aparelho
Todas as informações registradas pelo usuário permanecem armazenadas exclusivamente no armazenamento interno privado do próprio dispositivo:
- **Banco de dados SQLite local (`sqflite`):** guarda perfil local (nome, idade, metas), planos semanais de treino, catálogo personalizado, histórico de séries e cargas, registros de peso corporal, diário de treino, hábitos e tarefas.
- **Diretório privado do aplicativo:** armazena a foto de perfil, fotos ou GIFs associados aos exercícios, imagens do diário e fotos mensais de evolução, além das cópias locais de backup.
- **Preferências locais (`shared_preferences`):** guardam configurações de tema (claro, escuro ou AMOLED), som/vibração do cronômetro, intensidade háptica e escudos de ofensiva.

## 3. Permissões Utilizadas
- **`POST_NOTIFICATIONS`:** utilizada exclusivamente para exibir lembretes locais de treino agendados no próprio celular e alerta nativo de fim de descanso.
- **`WAKE_LOCK`:** utilizada temporariamente para manter o cronômetro ativo em contagem regressiva de descanso entre séries.
- **`VIBRATE`:** utilizada para o feedback tátil configurável e alerta sonoro/vibratório do cronômetro.
- **`CAMERA`:** utilizada unicamente quando o usuário escolhe capturar uma foto com a câmera do aparelho para a foto de perfil, fotos de evolução física mensal ou registros no diário de treino. Nenhuma foto é transmitida para fora do aparelho; todas ficam guardadas exclusivamente no armazenamento interno privado do aplicativo.
- **`RECEIVE_BOOT_COMPLETED`:** utilizada exclusivamente para reagendar no sistema operacional os lembretes locais de treino configurados caso o dispositivo seja desligado ou reiniciado.
- **Seletor de Arquivos / Galeria do Sistema:** utilizado apenas quando o próprio usuário escolhe associar uma imagem a um exercício, registrar foto de evolução/diário, escolher um toque personalizado ou exportar/importar um arquivo de backup.

## 4. Backups e Criptografia (`.ogb`)
- O usuário pode salvar cópias locais no próprio aparelho ou exportar um arquivo de backup criptografado (`.ogb`).
- Os arquivos `.ogb` são protegidos com derivação de chave **Argon2id** e criptografia autenticada **AES-256-GCM** usando a senha definida pelo usuário no momento da exportação.
- O aplicativo não armazena nem envia essa senha para nenhum local externo. Caso o usuário compartilhe o arquivo de backup por aplicativos de terceiros (como e-mail, mensageiros ou armazenamento em nuvem próprio), o arquivo estará sob a proteção da criptografia `.ogb` e das políticas do serviço escolhido pelo usuário.

## 5. Exclusão e Retenção dos Dados
Como todos os dados residem exclusivamente no aparelho do usuário:
- O usuário mantém total controle sobre suas informações a qualquer momento;
- É possível excluir treinos, hábitos, tarefas, fotos, registros de peso ou backups locais diretamente nas telas do aplicativo;
- Ao limpar o armazenamento do aplicativo nas configurações do sistema ou desinstalar o aplicativo, todos os dados armazenados na pasta privada do app são definitiva e permanentemente apagados do dispositivo.

## 6. Isenção de Alegações Médicas
O Offline Gym é uma ferramenta de auxílio ao registro de treinos e rotinas de exercícios físicos. Todas as estimativas de volume, simetria e descanso são informativas e baseadas em literatura de treinamento esportivo, não constituindo prescrição, diagnóstico ou aconselhamento médico ou fisioterapêutico. Recomenda-se a orientação de profissionais habilitados de Educação Física e Saúde.

## 7. Código Aberto e Transparência
O código-fonte do aplicativo é aberto e distribuído sob a **Licença MIT**, permitindo auditoria pública completa do funcionamento offline e do tratamento local dos dados no repositório oficial:
- Repositório: [https://github.com/LuanThierry/offline-gym](https://github.com/LuanThierry/offline-gym)
