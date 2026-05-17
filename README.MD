# 👁️ Studio Reborn | Advanced Wall Admin (Multi-Framework)

> **Sistema de ESP/Wall administrativo de alta performance.** Uma ferramenta de moderação essencial para a staff do seu servidor FiveM, projetada do zero com foco absoluto em **otimização de FPS** e **arquitetura limpa**.

---

## 🚀 O Grande Diferencial: Otimização e Módulos Extra

A maioria dos scripts de "Wall" ou "Admin ESP" disponíveis na comunidade destroem o client side (*drops de FPS*) e o server side (*alto resmon*). Isso acontece porque eles rodam loops `GetPlayers()` e consultam o banco de dados/framework a cada *tick* (milissegundo) para pegar nomes e permissões.

O **Wall Admin do Studio Reborn** resolve isso com uma arquitetura de **Cache Síncrono Assíncrono**:
1. O Client **não faz consultas** de dados ao framework.
2. O Servidor coleta os dados de forma otimizada a cada 2 segundos (`Config.RefreshRate`) e envia um pacote pronto apenas para as staffs que estão com o Wall ativado.
3. O Client apenas desenha na tela (`DrawText3D`) lendo a memória em cache. 

Resultado? Um painel extremamente responsivo e impacto **zero** na performance do jogo, mesmo com o servidor lotado.

---

## ✨ Engenharia & Destaques

* **Interface Modular NUI (Dark Tech):** Um painel interativo (ativado via `/wall`) construído com HTML/CSS puro, sem frameworks pesados, com animações suaves e design "Glass-free".
* **Controle Granular de Módulos:** O admin pode ligar/desligar funções em tempo real para não poluir a tela:
  * **Wall Base:** Mostra Nome, Passaporte (ID), Source, Vida (%) e Colete (%).
  * **Traçados (Linhas):** Desenha uma linha direta do admin até os jogadores.
  * **Armamento:** Exibe a arma atual equipada na mão do jogador (mapeamento via `weapons.lua`).
  * **Veículos:** Mostra o modelo e a placa do veículo em que o jogador está.
* **Escalonamento Dinâmico (Dynamic Scale):** O tamanho das fontes e o espaçamento (`dynamicGap`) ajustam-se automaticamente dependendo da distância real entre o admin e o jogador.
* **Culling de Renderização:** O script utiliza `IsSphereVisible` e verificação matemática de raio (`Config.MaxDistance`) para só usar poder de processamento da placa de vídeo se o jogador estiver de fato na área de visão/renderização.
* **Staff Awareness:** Tags inteligentes notificam o admin se o alvo está `[Invisível]`, se é um membro da `[Staff]`, ou se também está com o `[Wall]` ativado (evitando confusões na hora da moderação).

---

## 📦 Universal Multi-Framework

O resource foi desenhado para ser "Plug and Play" nas maiores bases da atualidade. 
Basta abrir o `config.lua` e definir a sua base:

```lua
Config.Framework = 'qbox' -- Opções: 'qbox', 'qbcore', 'esx', 'vrp', 'standalone'

```

O servidor se adapta instantaneamente e busca as funções corretas de permissão e identidade (Ex: `QBCore.Functions.GetPlayer` ou `vRP.getUserIdentity`).

---

## 📦 Instalação

1. Faça o download deste repositório e coloque na pasta `resources` do seu servidor.
2. Configure o seu framework e o raio de distância no `config.lua`.
3. Adicione ao seu `server.cfg`:

```cfg
ensure sr_walladmin

```

---

## 🎮 Fluxo de Utilização In-Game

1. Digite o comando `/wall`.
2. O Painel NUI será aberto na sua tela.
3. Ative o **Wall Base**. Em seguida, ative os sub-módulos que precisar (Linhas, Armas, Veículos).
4. Pressione `ESC` ou clique no botão de fechar para voltar ao jogo.
5. Para desativar tudo, abra o painel novamente e desligue a chave principal.

---

## 💻 Arquitetura de Pastas

```text
sr_WallAdmin/
├── fxmanifest.lua
├── config.lua          # Configuração de Framework e Distância Max
├── weapons.lua         # Dicionário de hashes de armas traduzido
├── client/
│   └── main.lua        # Cálculo de distância, Renderização 3D e NUI Callbacks
├── server/
│   └── main SERVER.lua # Coleta de dados multi-framework e rotina de Sync (Cache)
└── web/
    ├── index.html      # Estrutura do Painel NUI
    ├── style.css       # Estilização (Studio Reborn Theme)
    └── script.js       # Lógica de interface e Toggles

```

---

## 👨‍💻 Créditos e Licença

Desenvolvido e arquitetado por **Studio Reborn / Felipe Manorov**. Focado em Engenharia de Software avançada, Clean Code e otimização de infraestruturas de alta performance para ecossistemas FiveM.

* [GitHub Oficial do Autor](https://github.com/cmanorov)

---

*Distribuído sob os termos da licença MIT. Livre para uso comercial, modificações e exibições de portfólio.*