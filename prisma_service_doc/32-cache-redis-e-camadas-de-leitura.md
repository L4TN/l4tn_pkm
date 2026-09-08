# Cache Redis e camadas de leitura

## 1. Cache como repository

`Core/Repository.Redis/Repositories/Base/BaseRepositoryCache.cs` abstrai Redis como repository com:

- chave base por componente;
- expiry default;
- timeout default;
- serialização JSON;
- bytes comprimidos para objetos grandes;
- listas com Redis Hash;
- `GetOrSet`;
- cache local por scope com `Lazy<Task<object>>`;
- cancellation token;
- kill switch `DesativarCache`;
- opção de falhar ou apenas logar (`throwIfError`).

Um cache concreto define principalmente chave, validade e formato do domínio.

## 2. Dois níveis de proteção

```text
memória do scope
  -> Redis
  -> banco/API de origem
```

`GetOrSetObjectWithMemoryScopeAsync` impede chamadas concorrentes repetidas para a mesma chave dentro da
instância do repository. Redis reduz repetição entre requests e processos.

## 3. Cache de objetos grandes

`SetLargeObjectAsync` serializa JSON e comprime com GZip antes de gravar bytes. Isso reduz payload no
Redis, mas adiciona custo de CPU e exige compatibilidade de serialização.

## 4. Cache especializado por domínio

Existem repositories para posição, consolidação, cotações, days, capital comprometido e sistema. As
chaves incorporam filtros relevantes como cliente, data, moeda, classificação e opções de posição.

A qualidade do cache depende mais da chave e invalidação que da classe-base.

## 5. Fail-open versus fail-closed

Por padrão, erros de cache são logados e a operação pode continuar com a fonte original. Com
`throwIfError`, o erro sobe.

Essa escolha deve ser explícita:

- cache de otimização: geralmente fail-open;
- cache usado como estado obrigatório: avaliar fail-closed;
- dados sensíveis: evitar vazamento em cache e logs.

## 6. Limites

- cache local não sincroniza réplicas;
- TTL não substitui invalidação quando dado muda;
- `ConcurrentDictionary` de promises precisa de política para exceções;
- chaves devem conter todos os parâmetros que alteram a resposta;
- `AllowAny` de cache desligado é útil para diagnóstico e kill switch operacional.
