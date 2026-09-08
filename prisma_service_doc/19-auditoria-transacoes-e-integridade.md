# Auditoria, transações e integridade

## 1. Auditoria em camadas

O Prisma possui mais de um mecanismo:

```text
DomainConfigMiddleware -> identidade HTTP
ProgramFactory         -> identidade técnica de Job
CommonBaseDbContext    -> IdUsu/IdUsuCriacao no SaveChanges
InterceptorUserAndDate -> compatibilidade de payload DevEx
AuditoriaBsn           -> relatórios e rastreabilidade funcional
```

Cada camada resolve um problema diferente. O `DbContext` é a garantia transversal; o BSN produz
informação funcional de auditoria.

## 2. Transações locais

Bulk update/insert pode ocorrer dentro de uma transação do contexto, como no upload de evolução. Isso
protege a substituição de uma versão por outra dentro da mesma fonte.

Não existe transação automática entre `WhgContext`, `XpPosiContext`, XML e Financeiro. Fluxos cross-context
precisam de idempotência, status e compensação.

## 3. Integridade do banco

Constraints e códigos SQL são tratados como parte do contrato. O `BaseDbContext` converte conflitos em
exceções de domínio, enquanto as constraints continuam protegendo concorrência e unicidade.

A aplicação não deve depender apenas de uma verificação anterior:

```text
check "não existe"
  + concorrência
  -> constraint única
  -> CustomConflictException
```

## 4. Soft delete e versionamento

Em cargas de dados, `FlAtivo` frequentemente representa validade lógica. Inativar e inserir nova versão
preserva histórico e facilita auditoria, mas exige que toda leitura aplique o filtro correto.

## 5. Locks

Locks locais em `BaseBsn` protegem uma instância. `IDistributedLock` usa SQL Server para coordenar
réplicas. Ambos devem ser acompanhados por timeout, cancellation token e uma chave estável.

Lock não substitui idempotência: após timeout, uma execução pode ter persistido parcialmente.

## 6. Checklist de integridade

Para cada fluxo que grava dados, documentar:

- chave natural;
- constraint relevante;
- transação usada;
- possibilidade de execução repetida;
- status intermediário;
- rollback/compensação;
- auditoria preenchida;
- lock local/distribuído;
- comportamento após cancelamento.
