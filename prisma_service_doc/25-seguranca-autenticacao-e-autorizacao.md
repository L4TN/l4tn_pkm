# Segurança, autenticação e autorização

## 1. Camadas distintas

O Prisma separa, ainda que com implementações diferentes por runtime:

```text
Autenticação -> quem é o chamador?
Autorização  -> pode executar esta operação?
Escopo       -> quais clientes/dados pode enxergar?
```

Misturar essas três decisões é uma fonte comum de respostas erradas. O contrato recomendado é:

- token ausente ou inválido: `401`;
- usuário válido sem permissão: `403`;
- recurso inexistente: `404`.

## 2. API interna

`PrismaService/Startup.cs` usa Microsoft Identity Web API. Fora de Development, adiciona uma policy
que exige usuário autenticado e claim `email`.

`JwtSecurityTokenHandler.DefaultInboundClaimTypeMap.Clear()` preserva os nomes de claims utilizados
pelo sistema, como `email`, `groups` e `nick`.

## 3. API externa

`PrismaServiceExternal` usa helpers e `JwtMiddleware` próprios para validar tokens de parceiros. Esse
caminho ocorre antes do MVC, portanto seu tratamento de erro precisa ser compatível com o contrato do
`ApplicationApiHandler`, mas não pode depender do filtro MVC.

## 4. Autorização por dados

`ApplicationApiHandler` consulta e cacheia:

- grupos do usuário;
- funcionalidades dos grupos;
- relação funcionalidade/API;
- APIs liberadas para externos;
- usuários externos;
- grupos de acesso a clientes;
- exceções de acesso a clientes.

O path da requisição e o produto entram na decisão. A autorização é configurável no banco e não exige
novo deploy para cada endpoint liberado.

O modelo é mais rico que uma role estática:

```text
usuário + grupos + funcionalidade + produto + path + cliente
```

## 5. Cache de autorização

O filtro usa `IMemoryCache` com TTL diferente conforme o produto. Também mantém chaves para limpeza dos
caches relacionados.

Benefício: reduz consultas repetidas a tabelas de autorização.

Limites:

- cada réplica possui seu próprio cache;
- alteração no banco não chega instantaneamente a todos os nós;
- listas mutáveis precisam de sincronização cuidadosa;
- TTL precisa ser compatível com o risco da alteração.

Em escala horizontal, Redis ou invalidação distribuída deve ser considerado.

## 6. Segurança por cliente

A autorização não termina no endpoint. BSNs como cliente, consolidação e posição carregam listas de
clientes autorizados e usam essas chaves nos filtros EF/`MemoryJoin`.

Isso é uma defesa em profundidade:

```text
Filtro HTTP protege endpoint
  -> BSN calcula escopo permitido
  -> Query filtra cliente/dado
```

A proteção por cliente não deve depender somente da Controller.

## 7. Certificados e autenticação de parceiros

XP, Itaú e B3 usam handlers mTLS especializados. Certificados são carregados por options, alguns são
validados no boot e o XP registra thumbprint, subject e validade para diagnóstico.

Nunca registrar senha, chave privada ou token em log. O thumbprint é identificador operacional, não
substituto para controle de segredo.

## 8. Pontos de revisão

- CORS está configurado com `AllowAnyOrigin`, `AllowAnyMethod` e `AllowAnyHeader` na API; isso precisa
  ser restrito por ambiente/origem.
- O handler B3 aceita qualquer certificado do servidor através de callback customizado; isso reduz a
  segurança TLS e exige justificativa operacional.
- Status de acesso negado precisa ser uniforme entre filtro e middleware JWT.
- Cache de permissões precisa de estratégia quando houver múltiplas réplicas.
- A autorização por path deve considerar normalização, parâmetros e versões da rota.
