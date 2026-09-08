# Catálogo de integrações externas

## 1. O padrão de integração do Prisma

As integrações ficam em `Core/Services/<Parceiro>/` e normalmente possuem:

```text
Interface
  -> implementação do serviço
  -> options
  -> autenticação específica
  -> HttpClient/handler
  -> DTOs de entrada e saída
  -> tratamento de erro
  -> health check
  -> BSN ou Job consumidor
```

A integração não é apenas uma chamada HTTP. É uma fronteira que concentra contrato externo, credencial,
telemetria, retry, conversão e persistência local.

## 2. Clientes registrados no composition root

`DependencyInjectionExtencion.ConfigureServices` registra clientes de CMD, XP, Addepar, Anbima, Itaú,
B3, Extranet Gateway, OutSystems, Azure, Graph, BigDataCorp, Protheus, Signature e outros.

Quando há `HttpClient`, a configuração fica próxima da autenticação:

- `BaseAddress` vem de options;
- URLs são normalizadas com `TrimEnd('/')`;
- headers específicos são adicionados na composição;
- handlers mTLS são configurados no mesmo ponto;
- implementações podem ser selecionadas por feature flag.

## 3. XP: seleção de autenticação por configuração

`IXpAuthService` pode resolver `XpNewAuthService` ou `XpAuthService` conforme
`XpNewAuthCustomOptions.FlNovaAuthXp`. O consumidor conhece somente a interface.

Esse padrão permite rollout progressivo:

```text
flag desligada -> fluxo de autenticação antigo
flag ligada    -> fluxo novo
```

A mudança de implementação não precisa contaminar todos os BSNs consumidores.

## 4. mTLS e certificados

Há handlers especializados para XP, Itaú e B3. O handler XP valida existência de chave privada e
expiração, registra thumbprint/subject/data de validade e falha rápido quando o certificado não pode ser
carregado.

Falhar no boot ou na criação do handler é preferível a iniciar chamadas que retornarão 401 silenciosos.
A tarefa `LoadCertificatesStartupTask` complementa o carregamento antecipado.

O handler B3 possui uma ressalva crítica: `ServerCertificateCustomValidationCallback` retorna `true`.
Isso deve ser tratado como exceção operacional cuidadosamente revisada, não como padrão a copiar.

## 5. Serviços que retornam dados em formatos diferentes

O Prisma integra JSON, CSV, XML, arquivos compactados, Service Bus, Blob e Graph. Por isso os serviços
fazem mais que desserializar:

- particionam arquivos;
- removem duplicidades;
- normalizam datas e decimais;
- agrupam posições por tipo de ativo;
- transformam respostas externas em DTOs de domínio;
- salvam logs de requisição em Blob quando necessário.

`AddeparService`, `XpSecuritiesService`, `XpWealthServiceV2`, `B3ImbarqService` e os loaders XML são
bons pontos de estudo para essa camada de anti-corruption.

## 6. Health check como contrato operacional

Os parceiros registrados em `PrismaService/HealthCheck/Configure/HeathCheckServiceOptions.cs` são tratados
como dependências operacionais reais. O health check verifica comunicação ou consulta representativa,
não apenas se o processo web está vivo.

Um parceiro novo deve ser avaliado em conjunto:

```text
Service + Auth + Options + HealthCheck + Logging + Retry + Job/BSN consumidor
```

## 7. O que observar em cada integração

Ao documentar uma integração, registrar:

- quem é o owner do contrato;
- onde a credencial é carregada;
- se a chamada é síncrona ou processada por Job;
- como são tratados timeouts e 4xx/5xx;
- se há retry e em quais status;
- se existe idempotência;
- quais dados são persistidos;
- como a dependência aparece no health dashboard;
- quais segredos não podem aparecer nos logs.
