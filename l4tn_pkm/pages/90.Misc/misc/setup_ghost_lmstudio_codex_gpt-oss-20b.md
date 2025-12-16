# Setup completo: Windows Ghost Spectre + LM Studio + GPT-OSS-20B local exposto via ngrok + Codex

Este documento resume o processo para transformar um PC com RTX 3090 em um **servidor de IA local** (GPT-OSS-20B) acessível pela internet via **ngrok** e utilizável como **agente de código (Codex)** em outros dispositivos (terminal e VS Code).

---

## Visão geral do fluxo

1. Instalar **Windows 11 Ghost Spectre** (otimizado para performance).  
2. Instalar **drivers NVIDIA** + **CUDA Toolkit** para usar a RTX 3090 ao máximo.  
3. Instalar e configurar o **LM Studio** com o modelo **GPT-OSS-20B**.  
4. Expor o servidor local do LM Studio pela internet com **ngrok**.  
5. Instalar e configurar o **Codex CLI** apontando para esse modelo local.  
6. Usar o Codex no **VS Code** com **raciocínio máximo** e **contexto grande**.

---

## 1. Instalação do Windows 11 Ghost Spectre

1. Baixe a **ISO do Windows 11 Ghost Spectre** (builds “Superlite” focadas em performance).  
   - Essas builds removem bloatware e serviços desnecessários, resultando em:
     - Menor uso de RAM  
     - Menor latência  
     - Mais recursos livres para CPU/GPU (IA, jogos, workloads pesados)

2. Grave a ISO em um pendrive bootável (ex.: **Rufus**):
   - Selecione a ISO do Ghost Spectre  
   - Tipo de partição conforme sua placa-mãe (UEFI / BIOS)

3. Dê **boot pelo pendrive** e faça uma instalação limpa:
   - Apague partições antigas (se quiser começar do zero)  
   - Instale o sistema normalmente

4. Ao final da instalação:
   - Mantenha **apenas o essencial**  
   - Evite instalar apps desnecessários  
   - Priorize:
     - Drivers  
     - Ferramentas de dev  
     - Ferramentas de IA (LM Studio, ngrok, etc.)

---

## 2. Instalar drivers NVIDIA e CUDA Toolkit

### 2.1 Drivers NVIDIA

1. Baixe os **drivers mais recentes** para a **RTX 3090** no site da NVIDIA.  
2. Na instalação:
   - Selecione **“Custom (Advanced)”**  
   - Marque **“Perform a clean installation”**  
   - Isso remove resíduos de instalações antigas e garante suporte completo ao CUDA/cuDNN.

### 2.2 CUDA Toolkit

1. Baixe o **CUDA Toolkit** compatível com sua versão de driver, também no site da NVIDIA.  
2. Durante a instalação:
   - Aceite os **paths padrão**  
   - Ele vai instalar `nvcc`, bibliotecas e runtime CUDA.

3. Após instalar, **reinicie o PC** e teste no terminal (PowerShell ou CMD):

```bash
nvidia-smi
```

Se tudo estiver OK, você verá sua **RTX 3090** listada com versão de driver e uso de GPU.

---

## 3. Instalar e configurar o LM Studio

### 3.1 Download e instalação

1. Baixe o **LM Studio para Windows** em:  
   - <https://lmstudio.ai>  
2. Instale normalmente (`.exe`) e abra o LM Studio.

### 3.2 Baixar o modelo GPT-OSS-20B

1. Na aba **“Models”** ou **“Explore”**, procure por:

   - `gpt-oss-20b` (modelo open source da OpenAI)

2. Clique em **Download** e aguarde o modelo ser baixado e indexado.

### 3.3 Configurações de inferência do modelo

No LM Studio, em **“My Models”**, abra o `gpt-oss-20b` e clique na **engrenagem** (per-model defaults):

- **Context Length**: `131072` (≈ 131k tokens)  
  - Aproveita o máximo de contexto suportado pelo modelo (se a build permitir).

- **Max Response Tokens**: algo como `16384`  
  - Permite respostas grandes sem travar.

- **Flash Attention**: **ON**  
  - Otimiza uso de memória e velocidade em contextos grandes (perfeito para RTX 3090).

- **GPU KV Cache Offload / Offload to GPU**: **ON**  
  - Mantém o KV cache na VRAM, acelerando gerações com contextos de 4k–32k.  
  - Se faltar VRAM em contextos absurdos, você pode experimentar **desligar** essa opção.

- **GPU Percent / Layers on GPU**: `100%`  
  - Use o máximo de camadas na GPU.  
  - A RTX 3090 (24 GB VRAM) aguenta bem o modelo 20B se configurado corretamente.

### 3.4 Configurações do servidor local (Developer / API Server)

Na aba de **“Developer” / “Server”** do LM Studio:

- **Server Port**: `1234` (padrão).  
- **Serve on Local Network**: **ON**  
  - Permite acesso via IP local e tunelamento (ngrok).  
- **Enable CORS**: **ON**  
  - Necessário para apps web e clientes externos chamarem a API.  
- **Allow per-request MCPs**: **ON** somente se você quiser integrar MCPs (não é obrigatório).  
- **Just-in-Time Model Loading (JIT)**: **ON**  
  - Carrega o modelo sob demanda.  
- **Auto unload unused JIT loaded models**: **ON**  
  - Libera VRAM quando o modelo fica ocioso.  
- **Max idle TTL**: `30–60` minutos  
  - Tempo de inatividade antes de descarregar o modelo.  
- **Only Keep Last JIT Loaded Model**: **ON**  
  - Ideal quando você usa só um modelo grande (20B).

Clique em **Start Server**.

### 3.5 Testar localmente

No PowerShell ou CMD:

```bash
curl http://localhost:1234/v1/models
```

Se estiver tudo certo, você verá `openai/gpt-oss-20b` (e outros modelos) listados.

---

## 4. Expor o LM Studio na internet com ngrok

### 4.1 Download e instalação do ngrok (Windows)

1. Acesse a página oficial de download do ngrok para Windows:  
   - <https://ngrok.com/download/windows>  

2. Baixe o agente para Windows (`ngrok.exe`) e coloque em uma pasta acessível (por ex. `C:\Tools\ngrok`).  
   - Adicione essa pasta ao **PATH** ou sempre acesse a partir dela no PowerShell.

3. Crie uma **conta gratuita** no site do ngrok.  
4. No dashboard do ngrok, copie o seu **authtoken**.

No PowerShell:

```powershell
ngrok config add-authtoken SEU_AUTHTOKEN_AQUI
```

### 4.2 Criar túnel para o LM Studio

Com o servidor do LM Studio rodando na porta `1234`, execute:

```powershell
ngrok http 1234
```

O ngrok exibirá algo como:

- `https://xxxx-xxxx-1234.ngrok-free.app -> http://localhost:1234`

Guarde a URL **HTTPS** (`https://...ngrok-free.app`).  
Ela será o seu `base_url` remoto compatível com a API da OpenAI (rota `/v1`).

Exemplo de base URL para usar depois no Codex:

```text
https://xxxx-xxxx-1234.ngrok-free.app/v1
```

> **Importante:** mantenha o ngrok e o LM Studio abertos enquanto quiser usar o modelo remotamente.

---

## 5. Instalação do Codex CLI

O **Codex** é o agente de código da OpenAI que roda no terminal e integra com vários modelos, incluindo **modelos locais** expostos via API OpenAI-like.

### 5.1 Instalar via npm (recomendado)

Requisitos: Node.js + npm instalados.

```bash
npm install -g @openai/codex
```

Depois, teste:

```bash
codex
```

Na primeira execução, ele vai pedir autenticação (conta/chave da OpenAI ou fluxo de login).

### 5.2 Outras formas de instalação (opcional)

- macOS/Linux: alguns sistemas podem ter suporte via gerenciador de pacotes (ex.: `brew install codex`).  
- Binários diretos: Releases no GitHub `openai/codex`.

---

## 6. Conceitos principais do Codex

O Codex funciona como um **agente interativo de codificação**, com comandos próprios:

### 6.1 Comandos úteis

- `/init` – cria `AGENTS.md` com instruções para o agente.  
- `/status` – mostra a configuração atual da sessão.  
- `/approvals` – gerencia o que o agente pode fazer sem pedir confirmação.  
- `/model` – escolhe o modelo e o nível de raciocínio.

### 6.2 Providers, perfis e modelos

- `model_providers`: definem **para onde** o Codex envia requisições (API da OpenAI, servidor local via ngrok, etc.).  
- `profiles`: apontam para um provider e modelo específicos, facilitando alternar configurações.

---

## 7. Configurando o Codex para usar o GPT-OSS-20B local (via ngrok)

Você vai conectar o Codex ao **servidor local** exposto pelo ngrok (LM Studio):

- LM Studio → porta `1234` → `http://localhost:1234/v1`  
- ngrok → URL pública → `https://xxxx-xxxx-1234.ngrok-free.app/v1`

### 7.1 Exemplo de `~/.codex/config.toml`

Crie ou edite o arquivo:

**Linux/macOS**: `~/.codex/config.toml`  
**Windows**: geralmente em `C:\Users\SEU_USUARIO\.codex\config.toml`

Exemplo:

```toml
model_reasoning_effort = "high"  # raciocínio máximo

[model_providers.local]
name = "local"
base_url = "https://xxxx-xxxx-1234.ngrok-free.app/v1"

[profiles.oss20b]
model_provider = "local"
model = "openai/gpt-oss-20b"
```

- `base_url` deve apontar para o endpoint compatível com a API da OpenAI (**incluindo `/v1`**).  
- `model` deve ser exatamente o nome aceito pelo servidor local (`openai/gpt-oss-20b` ou o alias que você configurou no LM Studio).

### 7.2 Usando o profile local

No terminal:

```bash
codex --profile oss20b
```

Dentro da UI do Codex, você também pode usar `/model` e selecionar o profile `oss20b` (se listado).

---

## 8. Raciocínio máximo (reasoning effort)

O Codex expõe níveis de “reasoning effort”:

- `low`  
- `medium`  
- `high`

### 8.1 Configuração global (config.toml)

No `config.toml`:

```toml
model_reasoning_effort = "high"
```

Isso instrui o Codex a sempre solicitar **esforço de raciocínio alto**, quando o modelo suportar.

### 8.2 Configuração por sessão

Também é possível passar via linha de comando:

```bash
codex --profile oss20b --config model_reasoning_effort="high"
```

Em versões mais recentes, pode haver opções na interface `/model` para ajustar isso.

### 8.3 Como perceber que está em “high”

- Respostas tendem a ser **mais longas**,  
- Com **mais passos intermediários**, explicações detalhadas,  
- Em alguns templates, o sistema inclui alguma indicação interna de “high reasoning”.

---

## 9. Contexto e limite de tokens (GPT-OSS-20B)

O `gpt-oss-20b` oferece **contexto grande** (por volta de **131k tokens** para entrada + saída), mas:

- O valor **real** depende de **como o servidor local foi configurado** (LM Studio).

### 9.1 Limite prático

Se o backend estiver com `num_ctx` em 8k / 32k:

- Esse é o **teto real**, mesmo que o modelo suporte mais.  
- Se o limite estourar, o servidor começa a **descartar mensagens antigas**, e o modelo esquece o início da conversa.

### 9.2 Monitorar uso de contexto

- O Codex ainda **não mostra claramente** o uso acumulado de tokens.  
- Você pode:
  - Observar quando o modelo parece esquecer o contexto.  
  - Usar métricas/estatísticas expostas pelo LM Studio (se disponíveis).

---

## 10. Usando o Codex no VS Code com modelo local

A extensão **“Codex IDE”** para VS Code é um front-end que reutiliza a configuração do Codex CLI.

### 10.1 Passos básicos

1. Certifique-se de que o Codex CLI funciona com `--profile oss20b`:

   ```bash
   codex --profile oss20b
   ```

2. Abra o VS Code a partir do mesmo terminal:

   ```bash
   code .
   ```

3. Instale a **extensão oficial do Codex** no VS Code.  
4. No painel do Codex (dentro do VS Code):
   - Abra as **configurações** (ícone de engrenagem).  
   - Selecione o mesmo perfil/modelo (`oss20b`) se ele aparecer.

### 10.2 Problemas comuns

- Algumas versões da extensão podem ignorar `base_url` customizado **até você iniciar uma sessão no CLI** e depois continuar no VS Code.  
- Sempre garanta que:
  - O servidor local (LM Studio) está **rodando**.  
  - O túnel **ngrok** está ativo.  
  - A URL é **HTTPS** e compatível com a API da OpenAI.

---

## 11. Boas práticas de uso

- Use **prompts objetivos** para tarefas específicas de código.  
- Em sessões muito longas, **resuma periodicamente** o contexto (manual ou com o próprio modelo) para economizar tokens.  
- Ajuste `temperature`, `top_p` e limites de contexto **no LM Studio** se quiser controle fino de estilo/comportamento.  
- Para tarefas grandes:
  - Divida em **etapas**.  
  - Use arquivos auxiliares como `AGENTS.md`, notas, e instruções persistentes.  
  - Deixe claro o objetivo final em cada etapa.



codex --profile oss20b --config model_reasoning_effort="high"

---

## 12. Resumo final

Com este setup você terá:

- Um **PC com RTX 3090** rodando **Windows Ghost Spectre**, otimizado para IA.  
- **LM Studio** servindo o modelo **GPT-OSS-20B** localmente, com contexto grande e Flash Attention.  
- Um túnel **ngrok** expondo a API local como se fosse a **API da OpenAI**.  
- O **Codex CLI** e o **VS Code (Codex IDE)** apontando para esse servidor, com:
  - **Raciocínio máximo (`high`)**  
  - **Profile dedicado (`oss20b`)**  
  - Uso integrado em todos os seus projetos de código.

Basta manter: **LM Studio + ngrok + Codex** rodando e você terá um **agente de código 20B local, acessível de qualquer lugar**.
