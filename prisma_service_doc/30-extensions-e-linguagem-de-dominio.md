# Extensions e linguagem de domínio

## 1. `Common/Extensions` é uma camada de produtividade

O Prisma concentra extensões para datas, decimal, enum, LINQ, expressions, JSON, XML, HTTP, streams,
reflection, tasks, logging e filtros. Esse diretório funciona como uma biblioteca interna usada por
Controllers, BSNs, repositories, integrações e Jobs.

## 2. Extensões que mudam a forma do backend

- `DateTimeExtension`: datas úteis, Brasília e regras de calendário;
- `DecimalExtension`/`DoubleExtension`: conversões e normalização financeira;
- `EnumExtension`: descrição e conversão de enums;
- `QueryExtension`: queries dinâmicas por reflection/expression trees;
- `DataSourceFilterExtensions`: extrai filtros recebidos pela UI;
- `AnonymousObjectMutatorExtension`: atualizações sem sobrescrever null;
- `HttpClientExtension`/`HttpContentExtension`: leitura e tratamento de chamadas;
- `ILoggerExtension`: padrão de try/catch com log;
- `TaskExtension`: comportamento assíncrono compartilhado;
- `PropertyInfoExtension`: suporte aos layouts posicionais;
- `XmlNodeExtension`/`JObjectExtension`: integração com formatos externos.

A extensão permite expressar regra repetida como vocabulário do sistema:

```csharp
request.DtReferencia.AddDiasUteis(-du);
valor.ReadAsDecimal();
query.OrderByDynamic(field);
```

## 3. Expressions como infraestrutura

`QueryExtension` cria árvores de expressão para filtros, joins, selects e ordenação dinâmicos. Isso
atende grids e extração dinâmica, mas precisa de whitelist de campos e validação de tipo quando recebe
entrada externa.

Há também `DistinctByAllFields`, que materializa com `AsEnumerable` e usa comparer por reflection.
Esse detalhe é importante: nem toda extensão sobre `IQueryable` continua sendo executada no banco.

## 4. Filtro DevExtreme mutável

`DataSourceFilterExtensions.ExtractAndRemoveFilter<T>` percorre filtros aninhados, localiza um campo,
remove o predicado e devolve seu valor convertido. Isso permite que a aplicação trate alguns parâmetros
fora do filtro genérico antes de entregar o restante ao DataSourceLoader.

É um pattern de pipeline mutável:

```text
filtro da UI -> extrai filtro especial -> remove do filtro -> query genérica restante
```

## 5. O benefício e o risco

O benefício é criar uma linguagem local consistente. O risco é uma regra importante ficar escondida
em um método curto da pasta `Extensions`. Toda extensão de domínio relevante deve ter documentação e
teste, especialmente quando altera `IQueryable`, timezone, arredondamento ou null.
