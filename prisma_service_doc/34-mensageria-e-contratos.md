# Mensageria e contratos

## 1. Serviço base de mensagens

`BaseMessagingService<TService>` concentra o envio para Azure Service Bus. O serviço concreto informa
fila/contexto e reutiliza:

- `ServiceBusClient` singleton;
- `BusQueuesCustomOptions`;
- `IDomainConfig`;
- serialização `BinaryData.FromObjectAsJson`;
- logging especializado.

## 2. Metadata padrão

Cada mensagem recebe:

- `CorrelationId` novo;
- `MessageType` com nome do contrato;
- `RequestUser` da identidade atual;
- `NmAplicacao` do executável.

Isso cria envelope operacional sem exigir que cada DTO de negócio carregue telemetria e identidade.

```text
contrato de negócio
  + metadata de transporte
  -> Service Bus
```

## 3. Descoberta por convention

`IBaseMessagingService` é marker e `BaseMessagingService<>` é encontrado pelo scanner de DI. Contextos
como Compliance e Finance possuem interface, implementação e fila própria.

## 4. Contrato de mensagem

A restrição `where T : class, IMessagingContract` impede enviar objetos arbitrários. O contrato marca
quais DTOs podem atravessar a fronteira de mensageria.

O consumidor deve tratar `MessageType` como discriminador de transporte e validar payload antes do
processamento.

## 5. Correlação e identidade

O `CorrelationId` permite acompanhar publicação e consumo. `RequestUser` e `NmAplicacao` permitem saber
quem originou a mensagem e qual runtime a publicou, inclusive quando a origem foi um WebJob.

## 6. Pontos de atenção

- criar sender por chamada pode exigir política de dispose/gerenciamento em alto volume;
- `CorrelationId` novo não substitui um correlation id de negócio propagado;
- nome de tipo pode mudar com rename e quebrar consumidores;
- mensagem publicada precisa ser compatível com reentrega;
- erros devem preservar metadata ao serem enviados para retry/dead-letter.
