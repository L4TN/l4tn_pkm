# Pipeline HTTP e contratos de resposta

## 1. Pipeline observado na API interna

A ordem registrada em `PrismaService/Startup.cs` é conceitualmente:

```text
Developer exception page (Development)
  -> Swagger (fora de Production)
  -> HTTPS redirection
  -> Routing
  -> Authentication
  -> DomainConfigMiddleware
  -> Authorization
  -> CORS
  -> Endpoint routing
  -> Controllers
```

Além do middleware, `ApplicationApiHandler` é adicionado globalmente como filtro MVC. Ele atua depois
que o endpoint foi selecionado e envolve a execução da action.

## 2. Identidade da requisição

`DomainConfigMiddleware` lê a claim `email`, calcula o nick antes do `@` e configura `IDomainConfig`.
Também copia o email para `RequestTelemetry.Context.User.Id` quando há telemetria disponível.

A identidade segue este caminho:

```text
JWT claim email
  -> DomainConfigMiddleware
  -> IDomainConfig scoped
  -> SaveChanges / logs / regras de domínio
```

Para WebJobs, não existe usuário HTTP. `ProgramFactory` configura `prisma.whg` como identidade técnica.

## 3. O filtro global

`ApplicationApiHandler` possui duas responsabilidades principais:

### Antes da action

- extrair path, email e grupos;
- consultar autorização no banco quando o cache não possui a informação;
- calcular funcionalidades e APIs permitidas;
- carregar acesso por cliente;
- reconhecer `SkipAuthenticationControllerHandler`;
- negar acesso antes da action;
- iniciar cronômetro usando `TraceIdentifier`.

### Depois da action

- medir duração;
- emitir log de acesso;
- mapear exceções;
- construir `ObjectResult`;
- anexar `Items` e `CustomObject` em agregados;
- registrar exceções não tratadas;
- marcar a exceção como tratada.

## 4. Contrato de erro

A hierarquia de exceções expressa intenção de aplicação:

```text
CustomNotFoundException    -> recurso não encontrado
CustomValidationException  -> entrada/regra inválida
CustomConflictException    -> conflito de estado ou persistência
CustomForbiddenException   -> autenticado sem permissão
CustomHttpRequestException -> falha de parceiro com status
```

O objetivo é que a Controller lance a exceção tipada, sem montar manualmente o status HTTP. O filtro
traduz o tipo para o protocolo.

```csharp
if (cliente is null)
    throw new CustomNotFoundException("Cliente não encontrado.");
```

## 5. Respostas agregadas

Quando uma exceção possui `AggregateException`, o filtro transforma as exceções internas em `Items`.
Isso é importante para validators e operações que precisam devolver vários problemas em uma resposta,
em vez de perder todos os erros depois do primeiro.

A ideia de contrato é:

```json
{
  "Message": "Existem erros na operação.",
  "Items": [
    { "Message": "Campo obrigatório", "CustomObject": null },
    { "Message": "Valor inválido", "CustomObject": { "Field": "..." } }
  ]
}
```

## 6. O que permanece fora do MVC

`JwtMiddleware` da API externa não passa pelo ciclo de `IActionFilter`. Portanto, seu tratamento de
exceção precisa compartilhar o mesmo mapeador para não criar uma tabela paralela de status.

A documentação recomenda uma unidade única:

```text
ExceptionResponseFactory
  -> status HTTP
  -> payload
  -> logging/contexto
```

Ela deve ser consumida por filtro MVC e middlewares. Antes de escrever uma resposta, o componente deve
verificar `Response.HasStarted`.

## 7. Autenticação versus autorização

O pipeline deve distinguir:

```text
Token ausente/inválido              -> 401 Unauthorized
Token válido, acesso negado         -> 403 Forbidden
Recurso inexistente                 -> 404 Not Found
Conflito de estado                  -> 409 Conflict
Validação de entrada                -> 400 Bad Request
Falha técnica não classificada      -> 500 Internal Server Error
```

O código histórico possui pontos com status divergente, principalmente para forbidden e middleware
externo. A separação acima é o contrato recomendado e deve ser aplicada de forma centralizada.

## 8. Limite real do padrão

O filtro limpa o tratamento transversal, mas não transforma automaticamente uma Controller em camada
fina. A análise encontrou Controllers que ainda:

- injetam `DbContext`;
- fazem projeções EF;
- validam payloads;
- persistem entidades;
- montam regras de negócio;
- retornam formatos específicos do DevExtreme.

O filtro resolve o problema de repetição HTTP; a migração de regra para BSNs e repositories é outro
trabalho arquitetural.
