# Briefing - Persistência de Atendimentos & Interações de IA

Vou utilizar duas tabelas do supabase:

## 1. attendment

Representa um atendimento (estado de vida: início, reatribuições, encerramento).

Salvar na tabela "attendment", os seguintes dados:
- `workspace_id` (uuid) - **sempre**.
- `agent_id` (uuid) - agente "dono" do atendimento.
- `agent_version_id` (uuid) - versão do agente.
- `departament_id` (text) - departamento.
- `channel_id` (text) - canal de origem.
- `chat_id` (text) - id lógico da conversa (Huggy).
- `status` (public.attendment_status) - ex.: 'active', 'ended'. (aqui preciso criar um enum)

Observações:
- Quando for enviar encerramento de chat atualizar `status='ended'`.
- Reatribuições (mudanças de agente/departamento etc.), deve ser feito um UPDATE na linha do atendimento.
- Idempotência de criação: se houver risco de retry, passe um id seu (UUID) e **reutilize-o** no retry.(criar uma linha nova ou dar update)

### Exemplo - criar atendimento
```json
{
  "workspace_id": "WS-UUID",
  "agent_id": "AGENT-UUID",
  "agent_version_id": "AGENT-VERSION-UUID",
  "departament_id": "sales",
  "channel_id": "5511999999999",
  "chat_id": "123456",
  "status": "active"
}
```

### Exemplo - encerrar atendimento (depende de ação da Huggy)
```json
{
  "id": "ATTENDMENT-UUID",
  "status": "ended",\
  "ended_at": "2025-08-15T18:47:12Z"
}
```

### Exemplo - reatribuir agente (depende de ação da Huggy)
```json
{
  "id": "ATTENDMENT-UUID",
  "agent_id": "NEW-AGENT-UUID"
}
```

## 2. attendment_ai_interaction (hoje já tem uma função que faz isso )

Representa interações com serviços de AI (Agentes de AI + Function Calling, LLM, ML de Automação de Dados, SST, TTS) dentro do atendimento 

Esta tabela armazena **três tipos** de interação (campo `kind`):
- `'model_response'` → resposta do LLM (texto).
- `'action'` → **ações internas** executadas (enum ai_action_type).
- `'tool_call'` → chamada de **ferramenta externa/customizada** (FK tool_key → agent_tool.id).

### Enums usados
- `ai_interaction_kind`: 'model_response' | 'action' | 'tool_call'
- `ai_interaction_status`: 'ok' | 'error' | 'partial' (status padronizado do evento)
- `ai_action_type`: - REQUEUE | ARCHIVE_CONVERSATION | FINISH_CONVERSATION | TRANSFER_CONVERSATION | CHANGE_DEPARTMENT | CHANGE_WORKFLOW | CHANGE_WORKFLOW_STAGE | CHANGE_TABULATION | ADD_TAG | REMOVE_TAG | ADD_NOTE | SEND_FILE | SEND_IMAGE | SEND_AUDIO | UPDATE_CONTACT | TRANSFER_TO_FLOW

### Campos comuns (sempre que possível)
**Chaves e dimensões** (preencher sempre que possível):
- `attendment_id` (uuid) - **sempre**
- `agent_id` (uuid) - agente "atuante" no evento
- `agent_version_id` (uuid)
- `workspace_id` (uuid)
- `company_id` (text)
- `departament_id` (text)
- `channel_id` (text)
- `chat_id` (text)
- `kind` (enum) - **obrigatório** (default 'model_response')
- `status_std` (enum) - 'ok'|'error'|'partial'
- `success` (bool) - redundante com status_std, mas útil
- `metadata` (jsonb) - extras do evento (sem PII sensível)

### Campos de latência

- `requested_at`, `responded_at` (timestamptz) - quando existir, o trigger calcula latency_ms.
- `latency_ms` (int) - calculado pelo trigger quando há requested_at e responded_at.

### Subtipo: model_response (kind='model_response')

- **Obrigatórios:** `model`, `prompt`, `response`
- **Unicidade:** `message_id` é **UNIQUE** apenas quando `kind='model_response'`
- **Tokens:** `input_tokens`, `output_tokens` (opcional)

#### Exemplo
```json
{
  "kind": "model_response",
  "attendment_id": "ATT-UUID",
  "workspace_id": "WS-UUID",
  "agent_id": "AGENT-UUID",
  "agent_version_id": "AGENT-VERSION-UUID",
  "chat_id": "huggy-123456",
  "model": "gpt-4o-mini",
  "prompt": "Pergunta do usuário...",
  "response": "Resposta do modelo...",
  "requested_at": "2025-08-15T18:30:10Z",
  "responded_at": "2025-08-15T18:30:11Z",
  "status_std": "ok",
  "success": true,
  "message_id": "provider-msg-abc123",
  "input_tokens": 120,
  "output_tokens": 45
}
```

### Subtipo: action (kind='action')

- **Obrigatório:** `action_type` (enum ai_action_type)
- **Idempotência opcional:** `action_id` (UNIQUE quando não nulo) - use para **evitar duplicar** a mesma ação ao reprocessar.
- **Parâmetros/resultado:** `action_params` (jsonb), `action_result` (jsonb)
- **Tempo:** se a ação tem ciclo request/response, preencha requested_at/responded_at para latência.

#### Exemplo

```json
{
  "kind": "action",
  "attendment_id": "ATT-UUID",
  "workspace_id": "WS-UUID",
  "agent_id": "AGENT-UUID",
  "action_type": "TRANSFER_CONVERSATION",
  "action_id": "act-9d21b2", // idempotência
  "action_params": { "to_agent_id": "AGENT2-UUID" },
  "action_result": { "status": "queued" },
  "requested_at": "2025-08-15T18:31:00Z",
  "responded_at": "2025-08-15T18:31:01Z",
  "status_std": "ok",
  "success": true
}
```

### Subtipo: tool_call (kind='tool_call')

- **Obrigatório:** `tool_key` (uuid) → **FK** para `public.agent_tool(id)`
- **Idempotência opcional:** `tool_call_id` (UNIQUE quando não nulo)
- **HTTP/integração:** `tool_endpoint`, `http_method`, `tool_status_code`, `tool_request`, `tool_response`
- **Tempo:** `requested_at`/`responded_at` → trigger calcula latency_ms

#### Exemplo
```json
{
  "kind": "tool_call",
  "attendment_id": "ATT-UUID",
  "workspace_id": "WS-UUID",
  "agent_id": "AGENT-UUID",
  "tool_key": "TOOL-UUID",
  "tool_call_id": "call-4f3a7c", // idempotência
  "tool_endpoint": "https://api.crm.io/contacts/123",
  "http_method": "PATCH",
  "tool_request": { "email": "user@ex.com" },
  "tool_response": { "ok": true },
  "tool_status_code": 200,
  "requested_at": "2025-08-15T18:32:00Z",
  "responded_at": "2025-08-15T18:32:02Z",
  "status_std": "ok",
  "success": true
}
```

## O que não fazer
- Não "recriar" atendimentos para trocar agente/departamento. Use **UPDATE** no mesmo attendment.
- Quando enviar `requested_at` e `responded_at` mandar horas locais sem timezone. Use UTC.

## Sequência típica (happy path)
1. **Cria** attendment se ele nao existir, (`status='active'`).
2. Durante a conversa:
   - grava **model_response** sempre que a IA responder.
   - grava **action** quando a IA executar algo (ex.: TRANSFER_CONVERSATION)
   - grava **tool_call** quando a IA chamar integração externa. (as function callings disparadas pelo agente estao em huggy_service.py, tem que adaptar esse arquivo para receber os parametros para serem logados)
3. Se o atendimento mudar de agente/departamento, **UPDATE** no attendment.
4. **Encerra** attendment (`status='ended'`).