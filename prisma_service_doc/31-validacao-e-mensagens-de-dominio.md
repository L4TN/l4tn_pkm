# Validação e mensagens de domínio

## 1. Registro automático

`ConfigureValidators` usa `AddValidatorsFromAssemblyContaining` para descobrir validators FluentValidation
sem uma lista manual por classe.

```text
validator concreto + FluentValidation
  -> assembly scanning
  -> container
  -> validação automática da API
```

## 2. `BaseValidator<T>`

`Core/Domain/Validators/BaseValidator.cs` fornece `IServiceProvider` e acesso cacheado a serviços,
principalmente `IMessageDomainService`. O validator pode expressar regra com mensagem centralizada em vez
de duplicar texto.

## 3. Extensões de regra

`ValidatorExtension` define regras reutilizáveis como `DeveSerMaiorQueZero` para `int`, `int?`, `decimal`
e `decimal?`. A regra técnica e a mensagem de domínio ficam em um único ponto.

```text
GreaterThan(0) + MessageDomain.DeveSerMaiorQueZero()
```

Esse pattern transforma validação repetida em vocabulário legível.

## 4. Ciclo da validação

```text
request
  -> FluentValidation automático
  -> ValidationResult
  -> CustomValidationException/payload
  -> ApplicationApiHandler
  -> HTTP 400
```

BSNs também podem chamar `ExecuteValidatorAsync` pela `BaseBsn` quando a validação ocorre fora do
binding HTTP, como em Jobs ou fluxos internos.

## 5. Mensagem como dependência de domínio

O `MessageDomainService` carrega JSON base, aplica mensagens do banco e valida por reflection se os
métodos públicos possuem chave. Validators, BSNs e exceções reutilizam esse vocabulário.

Isso evita que uma mesma regra seja apresentada com mensagens diferentes em API, Job e integração.

## 6. Limite importante

A validação de forma/entrada não substitui regra de negócio. Unique constraints, autorização, status,
consistência temporal e integridade entre contextos continuam pertencendo a BSN, banco ou integração.
