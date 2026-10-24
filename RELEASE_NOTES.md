# 🏋️‍♂️ Offline Gym — Versão 1.4.2 (Build 9)

> **Aplicativo 100% Offline, Gratuito e Sem Anúncios para Treinos, Hábitos e Evolução Corporal.**  
> *Seus dados, sua privacidade, direto no seu celular.*

---

## 🚀 O que há de novo na v1.4.2?

### ⏱️ 1. Alarme Nativo de Descanso e Ducking Inteligente
* **Alarme com Tela Desligada / Bloqueada:** Implementado canal nativo dedicado (`offline_gym_rest_alarm_v3`) com prioridade máxima e agendamento robusto no sistema operacional, garantindo o aviso sonoro pontual mesmo com o aparelho bloqueado.
* **Música Sem Interrupção (Ducking):** Redução suave e temporária de volume para que músicas no Spotify, Deezer ou YouTube Music continuem tocando em segundo plano sem pausar nem cortar.
* **Contagem 3-2-1 Sincronizada:** Bips sonoros e hápticos precisos nos últimos 3 segundos antes do término da série com a tela ligada.
* **Validação Física Concluída:** Testado e aprovado em dispositivo real Android (Samsung Galaxy S23 / One UI).

### ⚡ 2. Otimização de Performance e Fluidez no Histórico
* **Fim do Delay ao Rolar:** O cálculo fisiológico do Coach e radar de simetria foram desacoplados e memorizados na memória com isolamento `RepaintBoundary`, eliminando qualquer travamento ou carregamento durante a rolagem rápida no Histórico a 120 FPS cravados.

### 🛡️ 3. Conformidade Google Play e Transparência
* **Permissões Documentadas:** Alinhamento estrito da Política de Privacidade com as diretrizes da Google Play Console (`CAMERA` local para fotos de perfil, diário e evolução, e `RECEIVE_BOOT_COMPLETED` para restauração de lembretes locais).

---

## 🌟 Recursos Consolidados na v1.4.1

### 📄 1. Exportação Nativa de Fichas e Relatórios em PDF e CSV
* **Geração Binária Direta no Dispositivo:** O aplicativo agora renderiza documentos PDF de alta fidelidade sem depender de navegadores, WebView ou internet.
* **Ficha Semanal de Treinos (Aba Planos):** Exportação completa da rotina de cada dia da semana diagramada para imprimir ou enviar via WhatsApp ao seu instrutor/aluno.
* **Relatório Executivo de Histórico (Aba Histórico):** Resumo com volume acumulado em toneladas, distribuição por grupamento muscular, recordes pessoais (PRs) e histórico de sessões para acompanhamento profissional.
* **Planilhas CSV:** Exportação estruturada para importação e análise avançada no Microsoft Excel ou Google Planilhas.

### 🧠 2. Estimativa de Fadiga e Recuperação Muscular por Músculo (Microciclo)
* **Prevenção Ativa de Overtraining:** O Coach Científico Offline agora rastreia o intervalo em horas decorrido desde o último treino de cada grupo muscular individual (Peitoral, Costas, Quadríceps, Isquiotibiais, Ombros, Bíceps, Tríceps e Panturrilhas).
* **Barras Dinâmicas de Recuperação:** Visualize instantaneamente qual músculo está 100% pronto para nova sobrecarga e qual ainda está em fase de regeneração tecidual, com alertas fisiológicos preventivos.

### ⚡ 3. Desempenho com Isolate (`compute()`) em Background
* **Fluidez Máxima a 120 FPS:** A busca e filtragem no catálogo de **+2.000 exercícios** foi desacoplada da thread principal de renderização da UI para um Isolate em segundo plano.
* **Digitação Sem Engasgos:** Resposta imediata caractere a caractere, mesmo em aparelhos de entrada ou modelos antigos.

### 🎛️ 4. Configuração de Intensidade Háptica Tátil
* **Resposta ao Toque Sob Medida:** Novo seletor nas Configurações para escolher entre vibração **Forte**, **Média** ou **Desativada** ao alternar séries, tocar em botões e concluir exercícios.

### 🎯 5. Padronização de Interface Repetições e Cargas (Hoje & Planos)
* **Botão Único Unificado (`reps • kg`):** Substituição dos campos anteriores de arrasto horizontal por um botão moderno e tátil.
* **Fim dos Conflitos de Rolagem:** Zero interferência ou travamentos ao rolar a tela verticalmente durante o treino.
* **Seletor Deslizante Cupertino:** Acesso instantâneo a roletas magnéticas de repetições (1–100) e cargas (passos de 0,5 kg), atalhos de salto rápido (10 a 300 kg), cálculo de anilhas por lado e opção de *"Aplicar em todas as séries"*.

---

## 📦 Arquivos Anexados nesta Release

| Arquivo | Plataforma | Método de Instalação |
| :--- | :--- | :--- |
| **`Offline-Gym.apk`** | Android (Universal / ARM64 / x86_64) | Instalação direta (Toque e instale) |
| **`Offline-Gym-iOS.ipa`** | iOS / iPhone | Sideload via Sideloadly, AltStore, SideStore ou TrollStore |

---

## 📲 Como Instalar

### 🤖 No Android
1. Baixe o arquivo **`Offline-Gym.apk`** anexado abaixo.
2. Abra o arquivo baixado nas notificações ou no gerenciador de arquivos.
3. Se solicitado, permita a instalação de fontes desconhecidas para o seu navegador/gerenciador.
4. Toque em **Instalar** e abra o app!

---

### 🍎 No iPhone (iOS)
> **Nota técnica:** Por ser um app open-source distribuído fora da App Store oficial, o arquivo `.ipa` foi gerado via GitHub Actions sem assinatura comercial (`--no-codesign`) e utiliza o recurso oficial de instalação pessoal (*Sideloading*):

#### Opção A — Pelo Computador (Windows ou Mac) via Sideloadly (Recomendado):
1. Baixe o **`Offline-Gym-iOS.ipa`** no seu PC.
2. Baixe o programa gratuito [Sideloadly](https://sideloadly.io/) no computador e abra-o.
3. Conecte seu iPhone via cabo USB e confie no computador.
4. Arraste o arquivo `Offline-Gym-iOS.ipa` para dentro do Sideloadly.
5. Digite seu Apple ID e clique em **Start**.
6. No iPhone, vá em **Ajustes → Geral → Gestão de Dispositivos**, toque no seu e-mail e clique em **"Confiar"**.
7. *(Se estiver no iOS 16+)*: Vá em **Ajustes → Privacidade e Segurança → Modo Desenvolvedor** e ative-o.

#### Opção B — Pelo Linux via AltServer-Linux:
1. Conecte o iPhone via USB com `usbmuxd` ativo.
2. Emparelhe com `idevicepair pair`.
3. Execute o [AltServer-Linux](https://github.com/NyaMisty/AltServer-Linux):
   ```bash
   ./AltServer-x86_64 -u $(idevice_id -l) -a seu-email@apple.com -p sua-senha Offline-Gym-iOS.ipa
   ```

#### Opção C — Direto no iPhone (Sem PC toda semana):
* **SideStore / AltStore:** Baixe o `.ipa` pelo Safari e escolha *"Abrir com SideStore/AltStore"*.
* **TrollStore:** Baixe o `.ipa` e selecione *"Install with TrollStore"* (instalação permanente).

---

## 🔒 Garantia de Privacidade
* **100% Offline:** Sem dependência de servidores remotos ou computação em nuvem.
* **Zero Telemetria:** Sem Firebase Analytics, Google Ads, Facebook SDK ou rastreadores de qualquer espécie.
* **Segurança Criptográfica:** Backups protegidos por AES-256-GCM com KDF Argon2id.

---
*Criado por **Luan Thierry** ([@LuanThierry](https://github.com/LuanThierry)). Distribuído sob a Licença MIT.*
