# **Briefing — Persistência de Atendimentos & Interações de IA**

## **Visão geral**

Você vai gravar dados em **duas tabelas**:

1. public.attendment → representa **um atendimento** (estado de vida: início, reatribuições, encerramento).

2. public.attendment\_ai\_interaction → representa **eventos do agente/IA** dentro do atendimento (respostas de modelo, **ações internas** e **chamadas de ferramentas**).

## **Regras de tempo e timezone (importante)**

* Não precisa enviar datas, isso será feito pela banco de dados, tanto INSERT, quanto UPDATE

## **O que salvar e como**

### **1\) public.attendment**

#### Campos essenciais (sempre enviar)

* id (uuid) — pode omitir para usar gen\_random\_uuid().

* workspace\_id (uuid) — **sempre**.

* agent\_id (uuid) — agente “dono” do atendimento.

* agent\_version\_id (uuid) — versão do agente .

* departament\_id (text) — departamento.

* channel\_id (text) — canal de origem.

* chat\_id (text) — id lógico da conversa (Huggy).

* status (public.attendment\_status) — ex.: 'active', 'ended' .

### **Boas práticas & validações**

* Quando for enviar encerramento de chat atualizar status='ended'.

* **Reatribuições** (mudanças de agente/departamento etc.) devem ser feitas via **UPDATE** no atendimento.

* **Idempotência** de criação: se houver risco de retry, passe um id seu (UUID) e **reutilize-o** no retry.

### **Exemplo — criar atendimento**

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

### **Exemplo — encerrar atendimento**

```json
{  "id": "ATTENDMENT-UUID",  "status": "ended",  "ended_at": "2025-08-15T18:47:12Z"}
```

### **Exemplo — reatribuir agente**

```json
{  "id": "ATTENDMENT-UUID",  "agent_id": "NEW-AGENT-UUID"}
```

## **2\) public.attendment\_ai\_interaction**

Esta tabela armazena **três tipos** de interação (campo kind):

* 'model\_response' → resposta do LLM (texto).

* 'action' → **ações internas** executadas (enum ai\_action\_type).

* 'tool\_call' → chamada de **ferramenta externa/customizada** (FK tool\_key → agent\_tool.id).

**Enums usados**

* public.ai\_interaction\_kind: 'model\_response' | 'action' | 'tool\_call'

* public.ai\_interaction\_status: 'ok' | 'error' | 'partial' (status padronizado do evento)

* public.ai\_action\_type:
  
   REQUEUE | ARCHIVE\_CONVERSATION | FINISH\_CONVERSATION | TRANSFER\_CONVERSATION | CHANGE\_DEPARTMENT | CHANGE\_WORKFLOW | CHANGE\_WORKFLOW\_STAGE | CHANGE\_TABULATION | ADD\_TAG | REMOVE\_TAG | ADD\_NOTE | SEND\_FILE | SEND\_IMAGE | SEND\_AUDIO | UPDATE\_CONTACT | TRANSFER\_TO\_FLOW

**Campos comuns (sempre que possível)**

* **Chaves e dimensões** (preencher sempre que possível):
  
  * attendment\_id (uuid) — **sempre**
  
  * agent\_id (uuid) — agente “atuante” no evento
  
  * agent\_version\_id (uuid)
  
  * workspace\_id (uuid)
  
  * company\_id (text)
  
  * departament\_id (text)
  
  * channel\_id (text)
  
  * chat\_id (text)
  
  * kind (enum) — **obrigatório** (default 'model\_response')
  
  * status\_std (enum) — 'ok'|'error'|'partial'
  
  * success (bool) — redundante com status\_std, mas útil
  
  * metadata (jsonb) — extras do evento (sem PII sensível)

**Campos de latência**

* requested\_at, responded\_at (timestamptz) — quando existir, o trigger calcula latency\_ms.

* latency\_ms (int) — calculado pelo trigger quando há requested\_at e responded\_at.

**Subtipo: model\_response ( kind='model\_response' )**

* **Obrigatórios:** model, prompt, response

* **Unicidade:** message\_id é **UNIQUE** apenas quando kind='model\_response'

* **Tokens:** input\_tokens, output\_tokens (opcional)

**Exemplo**

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

### **Subtipo: action (kind='action')**

* **Obrigatório:** action\_type (enum ai\_action\_type)

* **Idempotência opcional:** action\_id (UNIQUE quando não nulo) — use para **evitar duplicar** a mesma ação ao reprocessar.

* **Parâmetros/resultado:** action\_params (jsonb), action\_result (jsonb)

* **Tempo:** se a ação tem ciclo request/response, preencha requested\_at/responded\_at para latência.

**Exemplo**

```json
{
  "kind": "action",
  "attendment_id": "ATT-UUID",
  "workspace_id": "WS-UUID",
  "agent_id": "AGENT-UUID",
  "action_type": "TRANSFER_CONVERSATION",
  "action_id": "act-9d21b2",          // idempotência
  "action_params": { "to_agent_id": "AGENT2-UUID" },
  "action_result": { "status": "queued" },
  "requested_at": "2025-08-15T18:31:00Z",
  "responded_at": "2025-08-15T18:31:01Z",
  "status_std": "ok",
  "success": true
}
```

### **Subtipo: tool\_call (kind='tool\_call')**

* **Obrigatório:** tool\_key (uuid) → **FK** para public.agent\_tool(id)

* **Idempotência opcional:** tool\_call\_id (UNIQUE quando não nulo)

* **HTTP/integração:** tool\_endpoint, http\_method, tool\_status\_code, tool\_request, tool\_response

* **Tempo:** requested\_at/responded\_at → trigger calcula latency\_ms

```json
{
  "kind": "tool_call",
  "attendment_id": "ATT-UUID",
  "workspace_id": "WS-UUID",
  "agent_id": "AGENT-UUID",
  "tool_key": "TOOL-UUID",
  "tool_call_id": "call-4f3a7c",      // idempotência
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

## **O que não fazer**

* Não enviar started\_at e ended\_at. Isso vai ser preenchido pelo banco.

* Não “recriar” atendimentos para trocar agente/departamento. Use **UPDATE** no mesmo attendment.

* Quando enviar `requested_at` e `responded_at` mandar horas locais sem timezone. Use UTC.--

## **Sequência típica (happy path)**

1. **Cria** attendment (status='active').

2. Durante a conversa:
   
   * grava **model\_response** sempre que a IA responder.
   
   * grava **action** quando a IA executar algo (ex.: TRANSFER\_CONVERSATION).
   
   * grava **tool\_call** quando a IA chamar integração externa.

3. Se o atendimento mudar de agente/departamento, **UPDATE** no attendment.

4. **Encerra** attendment (status='ended').
