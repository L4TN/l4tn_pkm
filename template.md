
## Identificação
**ID:** [TASK-XXXX]  
**Nome:**
**Data:** [DD/MM/AAAA]  
**Responsável:** [Nome]  
**Status:** [Backlog | Em Análise | Em Desenvolvimento | Em Revisão | Concluído]
**Prioridade:** [P0-Crítica | P1-Alta | P2-Média | P3-Baixa]
**Tipo:** [Feature | Bug Fix | Refactoring | Spike | Infrastructure]


## Escopo e Objetivo

**Objetivo Principal:**
[Descrição concisa do que será entregue e qual problema resolve]

**Contexto de Negócio:**
[Breve explicação do impacto no produto/negócio]

## Stakeholders

| Papel | Nome | Responsabilidade |
| --- | --- | --- |
| Product Owner |     | Aprovação de requisitos |
| Tech Lead |     | Revisão técnica |
| QA  |     | Validação e testes |
| Cliente/Usuário |     | Validação final |

## Análise de Oportunidades

**Valor Agregado:**

- [Benefício principal]
- [Melhorias de performance/qualidade]
- [Redução de débito técnico]

**Riscos Identificados:**

- [Risco técnico ou de negócio]
- [Dependências externas]
- [Impacto em sistemas existentes]

## Requisitos

### Requisitos Funcionais

1. **RF01:** [Descrição do comportamento esperado]
  
  - Critério: [Como validar]
  - Cenários de Teste: [Casos de uso específicos]
2. **RF02:** [Descrição do comportamento esperado]
  
  - Critério: [Como validar]
  - Cenários de Teste: [Casos de uso específicos]

### Requisitos Não-Funcionais

1. **RNF01 - Performance:** [Ex: Tempo de resposta < 200ms]
2. **RNF02 - Segurança:** [Ex: Autenticação OAuth2]
3. **RNF03 - Escalabilidade:** [Ex: Suportar 1000 req/s]
4. **RNF04 - Manutenibilidade:** [Ex: Cobertura de testes > 80%]
5. **RNF05 - Observabilidade:** [Ex: Logs estruturados, traces distribuídos]

### Casos Edge e Tratamento de Erros

- **Cenário:** [Descrição]
  - **Tratamento:** [Como será tratado]
  - **Comportamento Esperado:** [O que o usuário verá]

## Critérios de Aceite

- [ ] Todos os requisitos funcionais implementados
- [ ] Testes unitários com cobertura mínima definida
- [ ] Testes de integração passando
- [ ] Code review aprovado
- [ ] Documentação atualizada
- [ ] Deploy em ambiente de staging validado
- [ ] Performance dentro dos limites especificados

## Solução Técnica

### Arquitetura

[Descrição da abordagem técnica escolhida e justificativa]

### Alternativas Consideradas

| Opção | Prós | Contras | Motivo da Decisão |
| --- | --- | --- | --- |
| Opção A |     |     |     |
| Opção B |     |     |     |

### Design Patterns Aplicados

- [Pattern]: [Justificativa de uso]

### Componentes Afetados

- **Backend:** [Serviços/APIs]
- **Frontend:** [Páginas/Componentes]
- **Banco de Dados:** [Tabelas/Collections]
- **Infraestrutura:** [Recursos necessários]

### Plano de Implementação

1. **Preparação**
  
  - Análise de impacto
  - Setup do ambiente de desenvolvimento
  - Criação da branch
  - Definição de feature flags (se aplicável)
2. **Desenvolvimento**
  
  - Implementação da lógica core
  - Integração com sistemas existentes
  - Implementação de testes
  - Atualização de documentação inline
3. **Validação**
  
  - Testes locais
  - Deploy em ambiente de desenvolvimento
  - Testes de integração
  - Testes de carga (se aplicável)
  - Validação de segurança
4. **Entrega**
  
  - Code review
  - Deploy em staging
  - Validação com stakeholders
  - Smoke tests
  - Deploy em produção
  - Monitoramento ativo pós-deploy

## Estimativas

**Esforço Total:** [X story points / dias]

- Análise: [X horas]
- Desenvolvimento: [X horas]
- Testes: [X horas]
- Deploy: [X horas]
- Buffer de Risco: [X horas]

**Complexidade Técnica:** [Baixa | Média | Alta | Muito Alta]
**Nível de Incerteza:** [Baixo | Médio | Alto]

## Dependências

- [Sistema/API externa]
- [Biblioteca/Framework versão X]
- [Aprovação de design/UX]

## Análise de Impacto

### Sistemas Afetados

- **Direto:** [Componentes que serão modificados]
- **Indireto:** [Componentes que consomem os modificados]

### Contratos e Interfaces

- **APIs Modificadas:** [Endpoints e mudanças]
- **Eventos/Mensageria:** [Topics/Queues afetados]
- **Mudanças Breaking:** [Sim/Não - Detalhar se sim]

### Plano de Migração

[Se aplicável - estratégia para migração de dados ou transição]

## Monitoramento Pós-Deploy

**Métricas de Sucesso:**

- [KPI a ser monitorado]
- [Taxa de erro aceitável]
- [Métrica de performance]

**Alertas e Observabilidade:**

- **Dashboards:** [Links para Grafana/Datadog/etc]
- **Logs:** [Queries relevantes]
- **Traces:** [Operações críticas para rastrear]
- **SLIs/SLOs:** [Indicadores e objetivos de nível de serviço]

**Plano de Rollback:**
[Estratégia caso seja necessário reverter]

**Runbook:**

- **Sintomas de Problema:** [Como identificar falhas]
- **Ações Imediatas:** [Primeiros passos de mitigação]
- **Escalação:** [Quando e para quem escalar]

## Notas Técnicas

[Considerações importantes, decisões técnicas, trade-offs]

## Débitos Técnicos

**Gerados:**

- [Débito assumido conscientemente e justificativa]

**Resolvidos:**

- [Débitos técnicos endereçados nesta task]

## Referências

- **Documentação:** [Links para docs relevantes]
- **ADRs Relacionadas:** [Architecture Decision Records]
- **Tasks Relacionadas:** [TASK-XXXX]
- **PRs/Commits:** [Links quando disponível]

## Lições Aprendidas

[Preencher após conclusão - insights para futuras implementações]

---

**Última Atualização:** [DD/MM/AAAA - Nome]