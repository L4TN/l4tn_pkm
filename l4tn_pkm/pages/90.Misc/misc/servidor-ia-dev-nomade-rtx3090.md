
# Servidor de IA – Setup Dev Nômade Móvel (RTX 3090)

Este documento justifica a escolha dos componentes de um **servidor de IA portátil**, pensado para:

- Rodar **modelos locais** (ex.: GPT-OSS-20B e até ~40B em Q4).
- Servir como **backend remoto de IA** acessível via rede (ngrok/VPN/etc.).
- Caber em um **setup nômade**, com foco em:
  - tamanho reduzido (formato ITX/SFF),
  - boa ventilação,
  - eficiência energética razoável para uso com power stations (ex.: EcoFlow).

---

## Visão Geral dos Componentes

| Componente  | Recomendação                                   | Preço PIX (R$)          | Link Compra | Por que para seu setup nômade                                                  |
|------------|-----------------------------------------------|--------------------------|------------|-------------------------------------------------------------------------------|
| GPU        | RTX 3090 Afox Bowler 24GB                     | Você tem                 | -          | Inferência de IA pesada (GPT-OSS-20B, modelos grandes, contexto alto).        |
| CPU        | Ryzen 5 5500                                  | Você tem                 | -          | CPU multi-thread competente para alimentar a GPU e tarefas de backend.        |
| Placa-mãe  | ASUS ROG Strix B550-I Gaming                  | 2.500–2.700              | [Terabyte](https://www.terabyteshop.com.br/produto/16576/placa-mae-asus-rog-strix-b550-i-gaming-chipset-b550-amd-am4-mini-itx-ddr4-90mb14l0...) | Formato ITX, PCIe 4.0 p/ RTX 3090, Wi-Fi 6 integrado, ideal p/ case compacto. |
| RAM        | Memória FNX Gamer 32GB DDR4 3200 (FNX32N22D9-32G) | Ver site (valor atual) | [KaBuM!](https://www.kabum.com.br/produto/690541/memoria-fnx-gamer-pc-32gb-ddr4-3200-fnx32n22d9-32g) | 32GB no ponto de equilíbrio: IA local até ~40B Q4 e ambiente de dev estável.  |
| Fonte      | Redragon RGMS 850W SFX 80+ Gold               | 800–1.000                | [KaBuM!](https://www.kabum.com.br/produto/893015/fonte-gamer-redragon-sfx-850w-80-plus-gold-preto-gc-ps016w) | SFX compacta, alta eficiência, segura p/ RTX 3090 em full load.               |
| SSD        | WD Black SN850X 2TB PCIe 4.0                  | 1.244                    | [KaBuM!](https://www.kabum.com.br/produto/379757/ssd-wd-black-sn850x-gaming-storage-2tb-m-2-2280-pcie-gen4x4-nvme-leitura-7300-mb-s-e-gra...) | NVMe PCIe 4.0 muito rápido p/ datasets, checkpoints e cache de modelos.       |
| Case       | DeepCool CH160 Mesh Preto                     | ~520                     | [Mercado Livre](https://www.mercadolivre.com.br/gabinete-mini-itx-deepcool-ch160-mesh-preto-mini-itx-r-ch160-bknm10-g-1/p/MLB47185021) | Case SFF com mesh, boa ventilação, alça de transporte, suporta RTX 3090.      |

---

## Justificativa Detalhada

### 1. GPU – RTX 3090 Afox Bowler 24GB

- **24GB de VRAM** permitem rodar modelos de linguagem de ~13B–20B parâmetros em precisão mista (ex.: GPT-OSS-20B) e quantizados de até ~40B (Q4) com contexto útil.
- Ideal para:
  - **Inferência local** de modelos grandes (chat, code assistant, agentes).
  - Fine-tuning leve / LoRA em alguns cenários.
- No contexto nômade:
  - Você leva **um “mini datacenter” na mochila**: pode expor a API da IA para o notebook principal ou até para outros dispositivos.
  - Reduz dependência de nuvem quando estiver sem conexão estável.

### 2. CPU – Ryzen 5 5500

- 6 cores / 12 threads, suficiente para:
  - Servir APIs,
  - Rodar containers,
  - Fazer pré-processamento dos dados,
  - Alimentar a GPU sem gargalo exagerado em inferência.
- Bom equilíbrio entre **custo, desempenho e consumo**.
- Para uso nômade, isso importa porque:
  - Menor consumo médio → **mais tempo de bateria/power station**.
  - Esquenta menos que CPUs high-end que você não vai aproveitar 100% para inferência.

### 3. Placa-mãe – ASUS ROG Strix B550-I Gaming (ITX)

- **Formato ITX** → reduz o volume geral do setup, permitindo um **case pequeno** que caiba na sua mochila/kit nômade.
- **PCIe 4.0 x16** → entrega banda plena para a RTX 3090.
- **Wi-Fi 6 onboard** → ideal para trabalhar em lugares sem cabeamento (coworking, Airbnb, roça com roteador 4G/Starlink).
- Boa qualidade de VRM, o que ajuda na **estabilidade em uso prolongado** (treino/inferência rodando horas).

### 4. RAM – 32GB DDR4 3200MHz (FNX Gamer)

- 32GB é o **ponto de equilíbrio** para o cenário definido:
  - Windows + serviços do sistema,
  - Engine de IA (LM Studio/llama.cpp/vLLM/etc.),
  - IDE, navegador e ferramentas de dev abertas ao mesmo tempo.
- Para modelos até **~40B em Q4** com foco em **inferência**:
  - A maior parte da carga fica na **VRAM de 24GB**.
  - A RAM segura:
    - Metadados do modelo,
    - Processo da engine,
    - Outras aplicações de dev.
- Vantagens práticas:
  - Menos risco de cair em **swap** (que mata a performance),
  - Ambiente mais fluido para desenvolvimento enquanto a IA roda em paralelo.
- É possível, no futuro, **migrar para 64GB** se você quiser:
  - Rodar múltiplos modelos em paralelo,
  - Brincar com MoE maior com mais partes do modelo na RAM,
  - Aumentar contextos e caches sem se preocupar com memória.

### 5. Fonte – Redragon RGMS 850W SFX 80+ Gold

- A RTX 3090 exige:
  - Fonte robusta (picos de consumo altos),
  - Boa eficiência para não desperdiçar energia em calor.
- **Form factor SFX**:
  - Permite usar **gabinetes menores**, mantendo um sistema potente.
- Certificação **80+ Gold**:
  - Menor perda de energia → **melhor aproveitamento da EcoFlow / power station**.
- Segurança:
  - Menos risco de instabilidade ao rodar a GPU em full load por longos períodos (inferência contínua, benchmarks, etc.).

### 6. SSD – WD Black SN850X 2TB PCIe 4.0

- NVMe PCIe 4.0 com **altas taxas de leitura/gravação**:
  - Carrega modelos grandes mais rápido.
  - Ajuda em operações com datasets pesados e cache de tokens.
- 2TB:
  - Espaço suficiente para:
    - Vários modelos (7B, 13B, 20B, 40B quantizado),
    - Checkpoints,
    - Dados de projetos, containers, etc.
- Em um cenário nômade:
  - Menos necessidade de HDs externos,
  - Menos cabos, menos peso e menos pontos de falha.

### 7. Case – DeepCool CH160 Mesh Preto

- **Case compacto (SFF)** com:
  - **Frente e laterais em mesh** → excelente fluxo de ar para segurar a temperatura da RTX 3090 e do Ryzen.
  - **Alça integrada** → facilita transporte no modo “dev nômade”, literalmente levando o servidor na mão.
- Suporta GPU grande (até ~305mm), então a RTX 3090 Afox encaixa.
- Mesh + boa ventilação:
  - Ajuda a lidar com sessões de inferência longas sem thermal throttling.
- Visual discreto e funcional:
  - Foco em **praticidade**, não em vidro, RGB e “firula”.

---

## Conclusão

Este setup equilibra:

- **Potência de IA** (RTX 3090 + 32GB RAM),
- **Portabilidade** (ITX + case compacto com alça + fonte SFX),
- **Eficiência** (80+ Gold, CPU equilibrada),
- **Velocidade de I/O** (SSD PCIe 4.0 2TB).

A ideia é ter um **servidor de IA móvel** que você pode:

- Colocar na mochila,
- Ligar em uma EcoFlow / tomada de qualquer lugar,
- Expor via rede (ngrok/VPN) para desenvolver e testar agentes, backends e modelos locais **de onde você estiver**.
