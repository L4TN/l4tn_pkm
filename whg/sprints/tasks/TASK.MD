# Documento de Especificação
**Especificação:** "Anexo 1 E-mail: RE_ Desenvolvimento - cadastro e PLD.msg
**Detalhes:** 

Em relação ao Cadastro de Pessoas de contas Ativas, e ao tópico de Prevenção à Lavagem de Dinheiro da área de compliance:

    1 - O usuário solicitou a implementação de uma funcionalidade de teste de "Regras de Acompanhamento" que consistentem em alguns critérios/regras. 
    2 - Sempre que houver a execução deste teste, ele poderá gerar uma flag de alerta, caso tenha um flag de alerta, o usuário irá realizar uma análise, registrar um comentário e concluir a sua análise.

    2.1 - Critérios:
        1 - CPF diferente de Status "Regular" (https://docs.bigdatacorp.com.br/plataforma/reference/pessoas_basic_data_with_configurable_recency - TaxIdStatus)
        2 - Indicativo de óbito (https://docs.bigdatacorp.com.br/plataforma/reference/ondemand_rf_status_person - AdditionalOutputData.IsDead - Ano de Óbito)
        3 - Histórico de Sanções (Considerar índice de semelhança acima de 80%) (https://docs.bigdatacorp.com.br/plataforma/reference/pessoas_kyc - MinMatch)
        4 - Indicação de PEP (https://docs.bigdatacorp.com.br/plataforma/reference/pessoas_kyc - considerexpandedpep) 
        5 - Compatibilidade das movimentações com valores declarados  
        (Movimentação superior a 50% de valor de aplicações declarado no cadastro e clientes com posição atual acima dos investimentos declarados)
        Movimentação: Valor de aumento da carteira (aqui imagino que tenha a posição de carteiras da XP, ou mesmo direto de API deles)
        Aplicações: Prisma-Cadastro-Comercial-Pessoas-Informações Adicionais-Aplicações, ou, direto API XP.

Em relação a tela do Prisma, tenho dois ajustes:
    1 - Incluir um campo contendo: “Biografia de vida” (https://docs.bigdatacorp.com.br/plataforma/reference/pessoas_genai_description_gpt_x1_5)
        O retorno de dados aqui será um texto resumo de todos os dados analisados

    2 - Incluir um campo de “Renda Estimada” (https://docs.bigdatacorp.com.br/plataforma/reference/marketplace_partner_datarisk_income_prediction_person)

O sugeriu usar a tela de Recon de Portfólio por conta das regras para isso(usando o memso motor mas com visão para Compliance), mas o Gestor entende que colocar algo assim no módulo de Recon fugiria do escopo do mesmo, recomendando criar algo no próprio módulo do Bureau.


Sobre a verificações, poderia ser sim em qualquer tela, mas teria que ser de modo geral (em lote), algo que traga a lista de pessoas com os respectivos flags.

Qual seria a periodicidade dos testes? 
    Seria mensal, exceto o de sanções que seria semanal. E aqui, acho que teria que ter uma comparação com o status anterior, ou seja, eu quero saber se o cliente não era PEP e passou a ser, se ele não estava em lista de sansões e agora está, se ele não tinha indicação de óbito e agora tem, etc. Esses são os casos que preciso de fato analisar.

O que gostaria de gerar como evidência (além do seu comentário e OK do teste)?  
    Além do que você mencionou, gostaria de guardar o resultado da pesquisa.
Quer armazenar alguma evidência do teste que não gere alerta? 
    Sim.
Vai gerar algum relatório ou uma exportação simples dos dados da tela já são suficientes?  
    Acho que seria bom gerarmos algum relatório, mostrando a quantidade de consultas, aletas gerados, análises concluídas, tipo de conclusão.
Tem alguma simulação que já faz manualmente em compliance (via Macro, Power BI) para termos ideia do tipo de controle? 
    Não tenho.
 
Em relação à regra 5, a ideia é validar a posição do cliente com o patrimonio declarado. Estamos olhando isso para todos, mas, dado que a posição pode aumentar após essa análise, a ideia é revalidar caso tenha algum aumento significativo.

Obs: Vale lembrar que não foi desenvolvido ainda o Bureau para PJ. Na época foi priorizado PF, então, para essas verificações, eu foquei em informações de PF.
Para PJ, a ideia é pedir pra vocês em seguida, quando concluímos de PF.

**Área Demandante:** Compliance 

## Issues - To Do

### ISSUE 3231 - Ajustes do Bureau - Tela de Batimento de PLD para PF e PJ

**Subtasks:**
- TASK 3236 - Ajustes no Bureau de PF
- TASK 3235 - Armazenamento histórico das consultas - OK
- TASK 3234 - Armazenamento histórico das liberações - NOK
- TASK 3233 - Avaliação periódica (Cadastro VS Bureau VS Posição)
- TASK 3232 - Bureau p/ PJ (Pessoas, Gestores, ADMs e Contrapartes)

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