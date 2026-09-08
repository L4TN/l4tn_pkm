# Patterns de query e performance

## 1. Projeção antes de materialização

`BaseReadRepository` fornece `FindAllProjectToAsync` e `FirstOrDefaultProjectToAsync`. O padrão deve ser
preferido quando a resposta não precisa da entidade inteira:

```text
query EF -> ProjectTo<DTO> -> SQL seleciona campos -> materialização
```

## 2. No tracking consciente

Consultas de leitura podem usar `AsNoTracking`; operações de alteração precisam manter tracking ou
carregar a entidade de forma compatível com o update. O parâmetro existe justamente porque leitura e
escrita têm necessidades diferentes.

## 3. Batch versus bulk

`BatchUpdate`/`BatchDelete` operam sobre query e evitam materialização. `BulkExtensions` processam grandes
listas. A escolha depende de:

- volume;
- necessidade de ChangeTracker;
- auditoria;
- transação;
- retorno das entidades;
- triggers e constraints.

## 4. MemoryJoin

Use quando a lista de chaves foi calculada por outra etapa/contexto e precisa virar escopo de query.
Evita `Contains` gigantes e joins impossíveis entre dois DbContexts.

## 5. Riscos de performance

- `IQueryable` pode executar tarde e em local inesperado;
- projeção não traduz toda função .NET para SQL;
- `Include` excessivo multiplica linhas;
- `Single` pressupõe constraint lógica/real;
- `ToList` cedo demais move volume para memória;
- paralelismo sem limite sobrecarrega parceiro ou banco;
- contextos longos acumulam ChangeTracker.

## 6. Diagnóstico

O sistema possui logging, timers e Application Insights, mas consultas de alto impacto precisam ser
acompanhadas por métricas de duração, quantidade de linhas, contexto, chave de execução e cancelamento.
