
# Test Plan (Planejamento de Teste)

Autor: <Seu Nome>  
Data: <Data>  
Versão: 1.0

## 📅 Sumário do Teste

- 🔹 Testes da Lista de Agendamentos (Events Index)
- 🔹 Testes do Diálogo/Modal
- 🔹 Testes do Formulário de Agendamento (Event Form)
- 🔹 Testes de Integração (APIs e Payloads)
- 🔹 Testes de UX/Acessibilidade

## 📄 Plano de Teste

- Ambientes: Dev/QA
- Browsers: Chrome, Firefox (últimas versões)
- Perfis: administrator, agent (conforme meta da rota)
- Dados de apoio: números de WhatsApp de teste, templates WhatsApp publicados, CSVs válidos/ inválidos
- Abordagem: manual exploratório + casos de teste formais; validação visual e via inspector de rede (payloads/requests)

## 📑 Tabela de Conteúdo

- [Testes da Lista de Agendamentos](#-testes-da-lista-de-agendamentos)
  - [TC-ER-LIST-001 – Skeleton de carregamento](#-tc-er-list-001--skeleton-de-carregamento)
  - [TC-ER-LIST-002 – Estado vazio](#-tc-er-list-002--estado-vazio)
  - [TC-ER-LIST-003 – Filtro por busca](#-tc-er-list-003--filtro-por-busca)
  - [TC-ER-LIST-004 – Filtro por canal](#-tc-er-list-004--filtro-por-canal)
  - [TC-ER-LIST-005 – Filtro por status habilitado/desabilitado](#-tc-er-list-005--filtro-por-status-habilitadodesabilitado)
  - [TC-ER-LIST-006 – Paginação](#-tc-er-list-006--paginação)
  - [TC-ER-LIST-007 – Alternar habilitado (toggle)](#-tc-er-list-007--alternar-habilitado-toggle)
  - [TC-ER-LIST-008 – Abrir formulário (Novo/Editar)](#-tc-er-list-008--abrir-formulário-novoeditar)
  - [TC-ER-LIST-009 – Pré-visualizar conteúdo por destinatário](#-tc-er-list-009--pré-visualizar-conteúdo-por-destinatário)
  - [TC-ER-LIST-010 – Excluir agendamento](#-tc-er-list-010--excluir-agendamento)

- [Testes do Diálogo/Modal](#-testes-do-diálogomodal)
  - [TC-ER-DLG-001 – Não fechar ao clicar fora](#-tc-er-dlg-001--não-fechar-ao-clicar-fora)
  - [TC-ER-DLG-002 – Botão X fecha e reseta estado](#-tc-er-dlg-002--botão-x-fecha-e-reseta-estado)
  - [TC-ER-DLG-003 – Título correto (Novo/Editar)](#-tc-er-dlg-003--título-correto-novoeditar)

- [Testes do Formulário de Agendamento](#-testes-do-formulário-de-agendamento)
  - [Validação e gating](#validação-e-gating)
  - [Canal e Agente](#canal-e-agente)
  - [Templates WhatsApp e Placeholders](#templates-whatsapp-e-placeholders)
  - [Destinatários e CSV](#destinatários-e-csv)
  - [Agendamento One-shot](#agendamento-one-shot)
  - [Agendamento Recorrente](#agendamento-recorrente)
  - [Período de Vigência e Enabled derivado](#período-de-vigência-e-enabled-derivado)
  - [Salvar/Feedback de status](#salvarfeedback-de-status)

- [Testes de Integração (APIs e Payloads)](#-testes-de-integração-apis-e-payloads)

- [Testes de UX/Acessibilidade](#-testes-de-uxacessibilidade)

- [Glossário](#glossário)

- [Anexos & Capturas](#-anexos--capturas)

---

## 🔎 Testes da Lista de Agendamentos

### 🧪 TC-ER-LIST-001 – Skeleton de carregamento

Objetivo: Exibir skeleton enquanto carrega.  
Pré-condição: Endpoint de listagem com latência simulada.  
Passos/Esperado:

1. Abrir tela → cartões “skeleton” visíveis durante loading.
2. Após concluir, skeleton some e cartões aparecem.

### 🧪 TC-ER-LIST-002 – Estado vazio

Objetivo: Exibir estado vazio quando não houver agendamentos.  
Pré-condição: Base sem registros.  
Passos/Esperado:

1. Abrir tela → card de vazio com ação “Criar agendamento”.
2. Clicar “Criar agendamento” → abre formulário.

### 🧪 TC-ER-LIST-003 – Filtro por busca

Objetivo: Filtrar por texto.  
Passos/Esperado:

1. Digitar termo no search → lista exibe apenas itens correspondentes (por id/nome).
2. Limpar busca → lista completa retorna.

### 🧪 TC-ER-LIST-004 – Filtro por canal

Objetivo: Filtrar por WhatsApp/Email.  
Passos/Esperado:

1. Selecionar WhatsApp → itens com channel ‘whatsapp’.
2. Selecionar Email → itens com channel ‘email’.

### 🧪 TC-ER-LIST-005 – Filtro por status habilitado/desabilitado

Objetivo: Filtrar por status enabled.  
Passos/Esperado:

1. Selecionar Ativo/ Inativo → somente itens do status escolhido.

### 🧪 TC-ER-LIST-006 – Paginação

Objetivo: Navegar entre páginas.  
Pré-condição: > pageSize registros.  
Passos/Esperado:

1. Avançar/voltar → navegar sem perder filtros; indicador de página atualizado.

### 🧪 TC-ER-LIST-007 – Alternar habilitado (toggle)

Objetivo: Habilitar/Desabilitar item.  
Passos/Esperado:

1. Clicar no ícone power → muda estado visual e persiste via request (verificar 200 OK).
2. Erro de rede → manter estado anterior e exibir feedback de erro (quando implementado).

### 🧪 TC-ER-LIST-008 – Abrir formulário (Novo/Editar)

Objetivo: Abrir modal para criação/edição.  
Passos/Esperado:

1. Clicar “+ Novo” → abre EventForm; título “Novo agendamento”.
2. Clicar “editar” num item → abre EventForm com dados; título “Editar agendamento”.

### 🧪 TC-ER-LIST-009 – Pré-visualizar conteúdo por destinatário

Objetivo: Abrir dialog de preview.  
Passos/Esperado:

1. Expandir destinatários e clicar “Pré-visualizar” → abre preview com conteúdo.
2. Fechar via botão de fechar.

### 🧪 TC-ER-LIST-010 – Excluir agendamento

Objetivo: Remover item com confirmação.  
Passos/Esperado:

1. Clicar lixeira → abre Dialog “alert”.
2. Confirmar → item removido; cancelar → nada acontece.

---

## 🪟 Testes do Diálogo/Modal

### 🧪 TC-ER-DLG-001 – Não fechar ao clicar fora

Objetivo: Garantir que o form não fecha com click-outside.  
Passos/Esperado:

1. Abrir “Novo agendamento” → clicar fora → modal permanece aberto.

### 🧪 TC-ER-DLG-002 – Botão X fecha e reseta estado

Objetivo: Fechar via “X” e resetar estado do form.  
Passos/Esperado:

1. Preencher campos e clicar “X” → fecha, reabrir → campos resetados.

### 🧪 TC-ER-DLG-003 – Título correto (Novo/Editar)

Objetivo: Ver título correto.  
Passos/Esperado:

1. Novo → “Novo agendamento”.
2. Editar → “Editar agendamento”.

---

## 📝 Testes do Formulário de Agendamento

### Validação e gating

- **TC-ER-FORM-001 – Nome obrigatório e asterisco**  
  Objetivo: Exibir “*” vermelho e mensagem “Campo obrigatório”.  
  Passos/Esperado:
  1. Campo vazio → label com “*”, borda vermelha, aviso em vermelho.
  2. Preencher → remove aviso/borda.

- **TC-ER-FORM-002 – Bloqueio das seções até nome preenchido**  
  Objetivo: Seções de “Destinatários”, “Agendamento”, “Período” e “Ações” aparecem esmaecidas e sem interação.  
  Passos/Esperado:
  1. Nome vazio → opacidade reduzida e pointer-events-none.
  2. Preencher Nome → seções liberadas.

- **TC-ER-FORM-003 – Canal padrão WhatsApp ao habilitar seletor**  
  Objetivo: Ao preencher Nome, canal é definido automaticamente para WhatsApp se estiver vazio.  
  Passos/Esperado:
  1. Preencher nome → campo “Canal” vem como WhatsApp.

### Canal e Agente

- **TC-ER-FORM-010 – Dropdown de agente bloqueado até canal**  
  Objetivo: Só habilitar após canal válido. Esperado: tooltip/estilo de desabilitado coerentes.

- **TC-ER-FORM-011 – Listagem de agentes via API**  
  Objetivo: Renderiza “Nome - Telefone”; value = number. Casos:
  - Nome ausente → usa somente telefone.
  - Falha API → alerta exibido.

- **TC-ER-FORM-012 – Carregar templates apenas com canal=WhatsApp e agente selecionado**  
  Esperado: sem agente → lista vazia; com agente → popula; erro → alerta.

### Templates WhatsApp e Placeholders

- **TC-ER-FORM-020 – Toggle global “Primeiro contato (Template)”**  
  Objetivo: Controla exibição de seção de template e marca primeiroContato em todos os recipients. Casos:
  - Ligado → seção visível; payload recipients[].primeiroContato = true.
  - Desligado → seção oculta; recipients[].primeiroContato = false.

- **TC-ER-FORM-021 – Aplicar template e exibir placeholders**  
  Objetivo: Botão “Aplicar” copia texto para a mensagem (one-shot). Lista placeholders detectados. Esperado: placeholders listados e usados na validação.

- **TC-ER-FORM-022 – Validação de placeholders (global e por dia)**  
  Objetivo: Exibir mensagens de erro quando variáveis requeridas não estão preenchidas nos recipients. Casos:
  - Mensagem global, e em recorrente: erro por dia (placeholderDaysError) quando aplicável.

### Destinatários e CSV

- **TC-ER-FORM-030 – Adicionar/Remover destinatários**  
  Esperado: adiciona com vars derivadas; remove corretamente.

- **TC-ER-FORM-031 – Importar CSV (WhatsApp)**  
  Casos:
  - CSV válido com name/phone → importa; dedup por telefone; normaliza espaços.
  - Cabeçalho inválido → mensagem de erro (whatsapp).
  - Telefones inválidos → linhas ignoradas; resumo mostra importados/ignorados.

- **TC-ER-FORM-032 – Importar CSV (Email)**  
  Casos:
  - CSV válido com name/email → importa; dedup por email case-insensitive.
  - Cabeçalho inválido → mensagem de erro (email).
  - Emails inválidos → ignorados com contagem no resumo.

- **TC-ER-FORM-033 – Canal switch preservando campos**  
  Objetivo: Alternar para Email/WhatsApp e garantir que apenas os campos pertinentes ficam ativos (email/phone).

### Agendamento One-shot

- **TC-ER-FORM-040 – Execução única**  
  Objetivo: Exibir apenas runAt; não exibir timezone; payload WhatsApp com “message” (sem messagesByDay).  
  Validações:
  - runAt obrigatório quando oneShot=true.

### Agendamento Recorrente

- **TC-ER-FORM-050 – Dias da semana e horário**  
  Objetivo: Selecionar dias e horário via dropdown (intervalo 15 min). Validações:
  - Quando “Primeiro contato” ativo, todos os dias selecionados devem ter mensagem por dia.

- **TC-ER-FORM-051 – Disparo diário (úteis)**  
  Objetivo: Toggle estilo idêntico ao de one-shot; comportamento:
  - Ligar → seleciona MON–FRI.
  - Desligar → limpa todos os dias.
  - Pode ajustar manualmente após ligar.

- **TC-ER-FORM-052 – Mensagens por dia**  
  Objetivo: Em recorrente, usar somente messagesByDay (sem “message”).  
  Esperado: payload contém apenas messagesByDay com os dias preenchidos.

### Período de Vigência e Enabled derivado

- **TC-ER-FORM-060 – Datepickers**  
  Objetivo: Campos de início/fim com type=date, default hoje (start 00:00Z, end 23:59:59Z).  
  Validações:
  - end > start, senão mensagem de erro visível.

- **TC-ER-FORM-061 – Enabled derivado do período**  
  Objetivo: Não exibir toggle de “habilitado”; enabled calculado ao salvar. Casos:
  - Ambos preenchidos: enabled = now ∈ [start, end].
  - Apenas start: enabled = now ≥ start.
  - Apenas end: enabled = now ≤ end.
  - Nenhum válido: enabled = true (fallback).

### Salvar/Feedback de status

- **TC-ER-FORM-070 – Botão Salvar desabilitado até formulário válido**  
  Objetivo: Impedir submit antes da validação.

- **TC-ER-FORM-071 – Criar agendamento (POST)**  
  Objetivo: Success → status verde “Agendamento criado…”, fechar/atualizar lista.  
  Erro → status vermelho com mensagem.

- **TC-ER-FORM-072 – Atualizar agendamento (PUT)**  
  Objetivo: Success → status verde “Agendamento atualizado…”.

---

## 🔗 Testes de Integração (APIs e Payloads)

- **TC-ER-INT-001 – AGENTS_API** `GET get-agents-list` → items mapeados para `{ id, number, label = "name - label/number" }`.  
  Erro → alerta “Falha ao carregar agentes…”.

- **TC-ER-INT-002 – TEMPLATES_API (listar)** `GET get-whatsapp-templates-list?agent=X`  
  - Filtrar por `inbox_id` quando presente.  
  - Flatten de componentes, placeholders extraídos.  
  - Erro → alerta “Falha ao carregar templates…”.

- **TC-ER-INT-003 – TEMPLATES_API (sync)** `GET …?agent=X&sync=1` → disparo de sync e reload; sucesso/erro com alertas.

- **TC-ER-INT-004 – Payload de criação/edição**  
  Verificar via DevTools o body enviado:
  - Base: `{ name, channel, agent?, recipients[], payload{}, enabled, startAt?, endAt? }`
  - Email: `payload = { subject, text, html }`
  - WhatsApp one-shot: `payload = { message }`
  - WhatsApp recorrente: `payload = { messagesByDay }` (sem `message`)
  - Primeiro contato: `recipients[].primeiroContato = firstContactAll`.
  - Timezone: `America/Sao_Paulo` (oculto na UI); incluído nos recorrentes como base de exibição/armazenamento.

- **TC-ER-INT-005 – Hidratação de edição (hydrateFromValue)**  
  Objetivo: Converter registros antigos c/ `primeiroContato` por destinatário → toggle global ligado.

---

## ♿ Testes de UX/Acessibilidade

- **TC-ER-UX-001** – Estados desabilitados coerentes (cursor/cores/tooltip)  
- **TC-ER-UX-002** – Navegação por teclado (tab order) no formulário e no dialog  
- **TC-ER-UX-003** – Leitura de rótulos/avisos (asterisco e mensagens de erro)  
- **TC-ER-UX-004** – Comportamento consistente de foco ao abrir modal e ao erro de validação  
- **TC-ER-UX-005** – Feedback visual de carregamento (templates, agentes)

---

## Glossário

- **TC**: Test Case (Caso de Teste)  
- **One-shot**: Execução única em `runAt` (UTC)  
- **Recorrente**: Repetição em dias/horários definidos  
- **Enabled derivado**: Habilitado calculado com base no período (`start`/`end`)  
- **Primeiro contato**: Uso de template WhatsApp no primeiro contato

---

## 📁 Anexos & Capturas

- Screenshots da lista (cheia/vazia/filtrada)  
- Screenshots do diálogo (com X, sem click-outside close)  
- Screenshots do formulário (bloqueado/ativo, erros de validação, mensagens por dia)  
- Exemplos de CSV (válido e inválido)  
- Payloads capturados (POST/PUT) para one-shot/recorrente

---

### Sugestão de organização

- Criar um arquivo `todos_os_casos.md` e colar este plano.  
- Manter uma seção “Resultado Obtido” por caso, e anexar prints/payloads durante a execução dos testes.  
- Opcional: adicionar blocos Gherkin para cenários críticos (placeholders, CSV, agendamento recorrente).
