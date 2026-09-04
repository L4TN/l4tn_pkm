# 🏆 Exemplo de Controller Best Practices

Baseado na análise do Prisma Service - Um exemplo prático e inspirador para seu backend.

---

## 📂 Estrutura de Pastas Recomendada

```
YourProject/
├── src/
│   ├── PresentationLayer/
│   │   └── Controllers/
│   │       ├── V1/
│   │       │   ├── Clientes/
│   │       │   │   └── ClienteController.cs
│   │       │   ├── Produtos/
│   │       │   │   └── ProdutoController.cs
│   │       │   └── Pedidos/
│   │       │       └── PedidoController.cs
│   │       └── Filters/
│   │           └── ExceptionHandlingFilter.cs
│   │
│   ├── ApplicationLayer/
│   │   ├── BSN/                          ← Business Service Network
│   │   │   ├── Clientes/
│   │   │   │   ├── ClienteBsn.cs
│   │   │   │   └── ClienteValidacaoBsn.cs
│   │   │   ├── Produtos/
│   │   │   │   └── ProdutoBsn.cs
│   │   │   └── Base/
│   │   │       └── BaseBsn.cs
│   │   │
│   │   ├── DTOs/
│   │   │   ├── Requests/
│   │   │   │   ├── CreateClienteRequest.cs
│   │   │   │   ├── UpdateClienteRequest.cs
│   │   │   │   └── GetClienteRequest.cs
│   │   │   ├── Responses/
│   │   │   │   ├── ClienteResponse.cs
│   │   │   │   └── PaginatedResponse.cs
│   │   │   └── Pagination/
│   │   │       └── PaginationParams.cs
│   │   │
│   │   ├── Enums/
│   │   │   ├── EStatusCliente.cs
│   │   │   ├── ETipoCliente.cs
│   │   │   └── EResultOperation.cs
│   │   │
│   │   ├── Interfaces/
│   │   │   └── BSN/
│   │   │       ├── IClienteBsn.cs
│   │   │       ├── IProdutoBsn.cs
│   │   │       └── Base/
│   │   │           └── IBaseBsn.cs
│   │   │
│   │   ├── Models/
│   │   │   ├── Pagination/
│   │   │   │   └── PaginatedList.cs
│   │   │   └── Common/
│   │   │       └── OperationResult.cs
│   │   │
│   │   ├── Mapper/
│   │   │   ├── ClienteProfile.cs
│   │   │   └── ProdutoProfile.cs
│   │   │
│   │   ├── Validators/
│   │   │   ├── CreateClienteValidator.cs
│   │   │   └── UpdateClienteValidator.cs
│   │   │
│   │   └── Filters/
│   │       ├── ValidateFilterAttribute.cs
│   │       └── AuthorizationFilter.cs
│   │
│   ├── DomainLayer/
│   │   ├── Entities/
│   │   │   ├── Clientes/
│   │   │   │   └── Cliente.cs
│   │   │   ├── Produtos/
│   │   │   │   └── Produto.cs
│   │   │   └── Base/
│   │   │       └── BaseEntity.cs
│   │   │
│   │   ├── Interfaces/
│   │   │   ├── Repositories/
│   │   │   │   ├── IClienteRepository.cs
│   │   │   │   ├── Base/
│   │   │   │   │   └── IRepository.cs
│   │   │   │   └── Cache/
│   │   │   │       └── ICacheRepository.cs
│   │   │   │
│   │   │   └── Services/
│   │   │       ├── INotificationService.cs
│   │   │       └── IEncryptionService.cs
│   │   │
│   │   └── Enums/
│   │       └── EStatusOperacao.cs
│   │
│   ├── InfrastructureLayer/
│   │   ├── Contexts/
│   │   │   └── AppDbContext.cs
│   │   │
│   │   ├── Repositories/
│   │   │   ├── Clientes/
│   │   │   │   └── ClienteRepository.cs
│   │   │   ├── Base/
│   │   │   │   └── Repository.cs
│   │   │   └── Cache/
│   │   │       └── CacheRepository.cs
│   │   │
│   │   ├── Services/
│   │   │   ├── NotificationService.cs
│   │   │   ├── EncryptionService.cs
│   │   │   └── EmailService.cs
│   │   │
│   │   └── Migrations/
│   │       └── [EF Migrations]
│   │
│   └── CrossCuttingLayer/
│       ├── IoC/
│       │   ├── DependencyInjection.cs
│       │   └── DependencyInjectionExtension.cs
│       │
│       ├── Exceptions/
│       │   ├── CustomValidationException.cs
│       │   ├── CustomBusinessException.cs
│       │   └── CustomEnquadramentoException.cs
│       │
│       ├── Extensions/
│       │   ├── StringExtensions.cs
│       │   ├── EnumExtensions.cs
│       │   └── DateTimeExtensions.cs
│       │
│       ├── Helpers/
│       │   └── MaskHelper.cs
│       │
│       └── Constants/
│           ├── ErrorMessages.cs
│           └── SuccessMessages.cs
│
├── Program.cs
└── appsettings.json
```

---

## 🎯 1. EXEMPLO DE CONTROLLER (Padrão Gold)

### ClienteController.cs

```csharp
using ApplicationLayer.BSN.Clientes;
using ApplicationLayer.DTOs.Clientes.Requests;
using ApplicationLayer.DTOs.Clientes.Responses;
using ApplicationLayer.Interfaces.BSN;
using CrossCuttingLayer.Exceptions;
using CrossCuttingLayer.Extensions;
using DomainLayer.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;

namespace PresentationLayer.Controllers.V1
{
    /// <summary>
    /// Gerencia todas as operações relacionadas a clientes
    /// Endpoints: /api/v1/clientes
    /// </summary>
    [ApiVersion("1.0")]
    [Route("api/v{version:apiVersion}/[controller]")]
    [ApiController]
    [Authorize]
    public class ClienteController : BaseController
    {
        private readonly IClienteBsn _clienteBsn;
        private readonly IDomainConfig _domainConfig;
        private readonly ILogger<ClienteController> _logger;

        /// <summary>
        /// Construtor com injeção de dependências
        /// </summary>
        public ClienteController(
            IClienteBsn clienteBsn,
            IDomainConfig domainConfig,
            ILogger<ClienteController> logger)
        {
            _clienteBsn = clienteBsn ?? throw new ArgumentNullException(nameof(clienteBsn));
            _domainConfig = domainConfig ?? throw new ArgumentNullException(nameof(domainConfig));
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        }

        #region GET Operations

        /// <summary>
        /// Obtém todos os clientes com paginação e filtros
        /// </summary>
        /// <param name="request">Parâmetros de filtro e paginação</param>
        /// <param name="cancellationToken">Token de cancelamento</param>
        /// <response code="200">Lista de clientes retornada com sucesso</response>
        /// <response code="400">Erro na validação dos parâmetros</response>
        /// <response code="401">Não autenticado</response>
        [HttpGet]
        [ProduceResponseType(typeof(ApiResponse<PaginatedResponse<ClienteResponse>>), 200)]
        [ProduceResponseType(typeof(ApiResponse<string>), 400)]
        public async Task<IActionResult> GetAll(
            [FromQuery] GetClienteRequest request,
            CancellationToken cancellationToken = default)
        {
            try
            {
                LogarRequisicao(nameof(GetAll), request);

                // Validar entrada
                if (request == null)
                    throw new CustomValidationException("Parâmetros de filtro são obrigatórios");

                // Chamar o BSN
                var resultado = await _clienteBsn.GetAllAsync(request, cancellationToken);

                return Ok(new ApiResponse<PaginatedResponse<ClienteResponse>>
                {
                    Success = true,
                    Data = resultado,
                    Message = "Clientes recuperados com sucesso"
                });
            }
            catch (CustomValidationException ex)
            {
                _logger.LogWarning($"Validação falhou: {ex.Message}");
                return BadRequest(new ApiResponse<string>
                {
                    Success = false,
                    Message = ex.Message
                });
            }
            catch (Exception ex)
            {
                return HandleException(ex, nameof(GetAll));
            }
        }

        /// <summary>
        /// Obtém um cliente específico pelo ID
        /// </summary>
        /// <param name="id">ID do cliente</param>
        /// <param name="cancellationToken">Token de cancelamento</param>
        /// <response code="200">Cliente encontrado</response>
        /// <response code="404">Cliente não encontrado</response>
        [HttpGet("{id}")]
        [ProduceResponseType(typeof(ApiResponse<ClienteResponse>), 200)]
        [ProduceResponseType(typeof(ApiResponse<string>), 404)]
        public async Task<IActionResult> GetById(
            int id,
            CancellationToken cancellationToken = default)
        {
            try
            {
                _logger.LogInformation($"Recuperando cliente ID: {id}");

                if (id <= 0)
                    throw new CustomValidationException("ID do cliente deve ser maior que zero");

                var cliente = await _clienteBsn.GetByIdAsync(id, cancellationToken);

                if (cliente == null)
                    return NotFound(new ApiResponse<string>
                    {
                        Success = false,
                        Message = $"Cliente com ID {id} não encontrado"
                    });

                return Ok(new ApiResponse<ClienteResponse>
                {
                    Success = true,
                    Data = cliente,
                    Message = "Cliente recuperado com sucesso"
                });
            }
            catch (Exception ex)
            {
                return HandleException(ex, nameof(GetById));
            }
        }

        #endregion

        #region POST Operations

        /// <summary>
        /// Cria um novo cliente
        /// </summary>
        /// <param name="request">Dados do cliente a ser criado</param>
        /// <param name="cancellationToken">Token de cancelamento</param>
        /// <response code="201">Cliente criado com sucesso</response>
        /// <response code="400">Erro na validação dos dados</response>
        /// <response code="409">Conflito (cliente já existe)</response>
        [HttpPost]
        [ProduceResponseType(typeof(ApiResponse<ClienteResponse>), 201)]
        [ProduceResponseType(typeof(ApiResponse<string>), 400)]
        [ProduceResponseType(typeof(ApiResponse<string>), 409)]
        public async Task<IActionResult> Create(
            [FromBody] CreateClienteRequest request,
            CancellationToken cancellationToken = default)
        {
            try
            {
                LogarRequisicao(nameof(Create), request);

                if (!ModelState.IsValid)
                    return BadRequest(ModelState);

                // Enriquecer request com dados do usuário atual
                request.IdUsuarioCriacao = _domainConfig.CurrentUserId;
                request.DataCriacao = DateTime.UtcNow;

                var resultado = await _clienteBsn.CreateAsync(request, cancellationToken);

                return CreatedAtAction(
                    nameof(GetById),
                    new { id = resultado.IdCliente },
                    new ApiResponse<ClienteResponse>
                    {
                        Success = true,
                        Data = resultado,
                        Message = "Cliente criado com sucesso"
                    });
            }
            catch (CustomBusinessException ex)
            {
                _logger.LogWarning($"Erro de negócio: {ex.Message}");
                return Conflict(new ApiResponse<string>
                {
                    Success = false,
                    Message = ex.Message
                });
            }
            catch (CustomValidationException ex)
            {
                _logger.LogWarning($"Validação falhou: {ex.Message}");
                return BadRequest(new ApiResponse<string>
                {
                    Success = false,
                    Message = ex.Message
                });
            }
            catch (Exception ex)
            {
                return HandleException(ex, nameof(Create));
            }
        }

        /// <summary>
        /// Atualiza um cliente existente
        /// </summary>
        /// <param name="id">ID do cliente</param>
        /// <param name="request">Dados atualizados</param>
        /// <param name="cancellationToken">Token de cancelamento</param>
        /// <response code="200">Cliente atualizado com sucesso</response>
        /// <response code="400">Erro na validação</response>
        /// <response code="404">Cliente não encontrado</response>
        [HttpPut("{id}")]
        [ProduceResponseType(typeof(ApiResponse<ClienteResponse>), 200)]
        [ProduceResponseType(typeof(ApiResponse<string>), 400)]
        [ProduceResponseType(typeof(ApiResponse<string>), 404)]
        public async Task<IActionResult> Update(
            int id,
            [FromBody] UpdateClienteRequest request,
            CancellationToken cancellationToken = default)
        {
            try
            {
                LogarRequisicao(nameof(Update), request);

                if (id <= 0)
                    throw new CustomValidationException("ID do cliente inválido");

                if (!ModelState.IsValid)
                    return BadRequest(ModelState);

                request.IdCliente = id;
                request.IdUsuarioAlteracao = _domainConfig.CurrentUserId;
                request.DataAlteracao = DateTime.UtcNow;

                var resultado = await _clienteBsn.UpdateAsync(request, cancellationToken);

                if (resultado == null)
                    return NotFound(new ApiResponse<string>
                    {
                        Success = false,
                        Message = $"Cliente com ID {id} não encontrado"
                    });

                return Ok(new ApiResponse<ClienteResponse>
                {
                    Success = true,
                    Data = resultado,
                    Message = "Cliente atualizado com sucesso"
                });
            }
            catch (Exception ex)
            {
                return HandleException(ex, nameof(Update));
            }
        }

        #endregion

        #region DELETE Operations

        /// <summary>
        /// Deleta um cliente (soft delete)
        /// </summary>
        /// <param name="id">ID do cliente</param>
        /// <param name="cancellationToken">Token de cancelamento</param>
        /// <response code="204">Cliente deletado com sucesso</response>
        /// <response code="404">Cliente não encontrado</response>
        [HttpDelete("{id}")]
        [ProduceResponseType(204)]
        [ProduceResponseType(typeof(ApiResponse<string>), 404)]
        public async Task<IActionResult> Delete(
            int id,
            CancellationToken cancellationToken = default)
        {
            try
            {
                _logger.LogInformation($"Deletando cliente ID: {id}");

                if (id <= 0)
                    throw new CustomValidationException("ID do cliente inválido");

                var sucesso = await _clienteBsn.DeleteAsync(id, _domainConfig.CurrentUserId, cancellationToken);

                if (!sucesso)
                    return NotFound(new ApiResponse<string>
                    {
                        Success = false,
                        Message = $"Cliente com ID {id} não encontrado"
                    });

                return NoContent();
            }
            catch (Exception ex)
            {
                return HandleException(ex, nameof(Delete));
            }
        }

        #endregion

        #region EXPORT Operations

        /// <summary>
        /// Exporta clientes em formato Excel
        /// </summary>
        /// <param name="request">Filtros para exportação</param>
        /// <param name="cancellationToken">Token de cancelamento</param>
        /// <response code="200">Arquivo gerado com sucesso</response>
        [HttpPost("exportar")]
        [ProduceResponseType(typeof(FileResult), 200)]
        public async Task<IActionResult> Exportar(
            [FromBody] GetClienteRequest request,
            CancellationToken cancellationToken = default)
        {
            try
            {
                LogarRequisicao(nameof(Exportar), request);

                (var memoryStream, var fileName) = await _clienteBsn.ExportarAsync(request, cancellationToken);

                return File(
                    memoryStream,
                    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                    fileName);
            }
            catch (Exception ex)
            {
                return HandleException(ex, nameof(Exportar));
            }
        }

        #endregion

        #region Helper Methods

        /// <summary>
        /// Loga a requisição com payload
        /// </summary>
        private void LogarRequisicao<T>(string metodo, T request)
        {
            try
            {
                var payload = JsonConvert.SerializeObject(request);
                _logger.LogInformation($"[{metodo}] Payload: {payload}");
            }
            catch
            {
                _logger.LogInformation($"[{metodo}] Requisição recebida");
            }
        }

        /// <summary>
        /// Trata exceções genéricas
        /// </summary>
        private IActionResult HandleException(Exception ex, string metodo)
        {
            var mensagem = ex.Message;
            if (ex.InnerException != null)
                mensagem = $"{ex.InnerException.Message} | {mensagem}";

            _logger.LogError(ex, $"[{metodo}] Erro não tratado: {mensagem}");

            return StatusCode(500, new ApiResponse<string>
            {
                Success = false,
                Message = "Erro interno do servidor. Por favor, contate o suporte.",
                Detail = mensagem
            });
        }

        #endregion
    }
}
```

---

## 🎯 2. BaseController (Classe Base)

```csharp
using Microsoft.AspNetCore.Mvc;
using System;

namespace PresentationLayer.Controllers
{
    /// <summary>
    /// Classe base para todas as controllers
    /// </summary>
    [ApiController]
    public abstract class BaseController : ControllerBase
    {
        /// <summary>
        /// Obtém o ID do usuário atual do contexto da requisição
        /// </summary>
        protected string GetCurrentUserId() 
            => User?.FindFirst("sub")?.Value ?? "ANONYMOUS";

        /// <summary>
        /// Obtém o nome do usuário atual
        /// </summary>
        protected string GetCurrentUserName() 
            => User?.FindFirst("name")?.Value ?? "UNKNOWN";

        /// <summary>
        /// Verifica se o usuário tem uma claim específica
        /// </summary>
        protected bool UserHasClaim(string claimType, string claimValue) 
            => User?.HasClaim(claimType, claimValue) ?? false;
    }
}
```

---

## 📦 3. DTOs - Request

### Clientes/Requests/CreateClienteRequest.cs

```csharp
using System;
using System.ComponentModel.DataAnnotations;

namespace ApplicationLayer.DTOs.Clientes.Requests
{
    /// <summary>
    /// DTO para criação de novo cliente
    /// </summary>
    public class CreateClienteRequest
    {
        /// <summary>
        /// Nome do cliente
        /// </summary>
        [Required(ErrorMessage = "Nome é obrigatório")]
        [StringLength(150, MinimumLength = 3, 
            ErrorMessage = "Nome deve ter entre 3 e 150 caracteres")]
        public string Nome { get; set; }

        /// <summary>
        /// Email do cliente
        /// </summary>
        [Required(ErrorMessage = "Email é obrigatório")]
        [EmailAddress(ErrorMessage = "Email inválido")]
        public string Email { get; set; }

        /// <summary>
        /// CPF ou CNPJ
        /// </summary>
        [Required(ErrorMessage = "CPF/CNPJ é obrigatório")]
        [StringLength(14, MinimumLength = 11, 
            ErrorMessage = "CPF/CNPJ inválido")]
        public string CpfCnpj { get; set; }

        /// <summary>
        /// Tipo de cliente (Pessoa Física ou Jurídica)
        /// </summary>
        [Required(ErrorMessage = "Tipo de cliente é obrigatório")]
        public ETipoCliente TipoCliente { get; set; }

        /// <summary>
        /// Status inicial do cliente
        /// </summary>
        public EStatusCliente Status { get; set; } = EStatusCliente.Ativo;

        /// <summary>
        /// ID do usuário que faz a criação (preenchido pela controller)
        /// </summary>
        [System.Text.Json.Serialization.JsonIgnore]
        public int IdUsuarioCriacao { get; set; }

        /// <summary>
        /// Data de criação (preenchida pela controller)
        /// </summary>
        [System.Text.Json.Serialization.JsonIgnore]
        public DateTime DataCriacao { get; set; }
    }
}
```

### Clientes/Requests/GetClienteRequest.cs

```csharp
using ApplicationLayer.Models.Pagination;
using System;

namespace ApplicationLayer.DTOs.Clientes.Requests
{
    /// <summary>
    /// DTO para filtrar clientes com paginação
    /// </summary>
    public class GetClienteRequest : PaginationParams
    {
        /// <summary>
        /// Filtro por nome (partial match)
        /// </summary>
        public string Nome { get; set; }

        /// <summary>
        /// Filtro por email
        /// </summary>
        public string Email { get; set; }

        /// <summary>
        /// Filtro por CPF/CNPJ
        /// </summary>
        public string CpfCnpj { get; set; }

        /// <summary>
        /// Filtro por tipo de cliente
        /// </summary>
        public ETipoCliente? TipoCliente { get; set; }

        /// <summary>
        /// Filtro por status
        /// </summary>
        public EStatusCliente? Status { get; set; }

        /// <summary>
        /// Data inicial do filtro
        /// </summary>
        public DateTime? DataCriacaoInicio { get; set; }

        /// <summary>
        /// Data final do filtro
        /// </summary>
        public DateTime? DataCriacaoFim { get; set; }

        /// <summary>
        /// Campo para ordenação
        /// </summary>
        public string OrderBy { get; set; } = "DataCriacao";

        /// <summary>
        /// Direção de ordenação (asc/desc)
        /// </summary>
        public string OrderDirection { get; set; } = "desc";
    }
}
```

---

## 📦 4. DTOs - Response

### Clientes/Responses/ClienteResponse.cs

```csharp
using System;

namespace ApplicationLayer.DTOs.Clientes.Responses
{
    /// <summary>
    /// DTO de resposta para cliente
    /// </summary>
    public class ClienteResponse
    {
        public int IdCliente { get; set; }
        public string Nome { get; set; }
        public string Email { get; set; }
        public string CpfCnpj { get; set; }
        public ETipoCliente TipoCliente { get; set; }
        public EStatusCliente Status { get; set; }
        public DateTime DataCriacao { get; set; }
        public DateTime? DataAlteracao { get; set; }
        public string NomeCriador { get; set; }
    }
}
```

### ApiResponse.cs (Wrapper padrão)

```csharp
using System;
using Newtonsoft.Json;

namespace ApplicationLayer.DTOs
{
    /// <summary>
    /// Wrapper padrão para todas as respostas API
    /// </summary>
    public class ApiResponse<T>
    {
        /// <summary>
        /// Indica se a operação foi bem-sucedida
        /// </summary>
        [JsonProperty("success")]
        public bool Success { get; set; }

        /// <summary>
        /// Dados da resposta
        /// </summary>
        [JsonProperty("data")]
        public T Data { get; set; }

        /// <summary>
        /// Mensagem de sucesso ou erro
        /// </summary>
        [JsonProperty("message")]
        public string Message { get; set; }

        /// <summary>
        /// Detalhes adicionais do erro
        /// </summary>
        [JsonProperty("detail", NullValueHandling = NullValueHandling.Ignore)]
        public string Detail { get; set; }

        /// <summary>
        /// Timestamp da resposta
        /// </summary>
        [JsonProperty("timestamp")]
        public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    }

    /// <summary>
    /// Wrapper para respostas sem dados
    /// </summary>
    public class ApiResponse
    {
        public bool Success { get; set; }
        public string Message { get; set; }
        public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    }
}
```

### PaginatedResponse.cs

```csharp
using System.Collections.Generic;

namespace ApplicationLayer.DTOs.Clientes.Responses
{
    /// <summary>
    /// DTO de resposta paginada
    /// </summary>
    public class PaginatedResponse<T>
    {
        public List<T> Items { get; set; }
        public int PageNumber { get; set; }
        public int PageSize { get; set; }
        public int TotalItems { get; set; }
        public int TotalPages => (TotalItems + PageSize - 1) / PageSize;
        public bool HasPreviousPage => PageNumber > 1;
        public bool HasNextPage => PageNumber < TotalPages;
    }
}
```

---

## 🧠 5. BSN - Business Service Layer

### Interfaces/IClienteBsn.cs

```csharp
using ApplicationLayer.DTOs.Clientes.Requests;
using ApplicationLayer.DTOs.Clientes.Responses;
using ApplicationLayer.Interfaces.BSN.Base;
using System;
using System.Threading;
using System.Threading.Tasks;

namespace ApplicationLayer.Interfaces.BSN
{
    /// <summary>
    /// Interface para operações de negócio de cliente
    /// </summary>
    public interface IClienteBsn : IBaseBsn
    {
        Task<PaginatedResponse<ClienteResponse>> GetAllAsync(
            GetClienteRequest request, 
            CancellationToken cancellationToken = default);

        Task<ClienteResponse> GetByIdAsync(
            int id, 
            CancellationToken cancellationToken = default);

        Task<ClienteResponse> CreateAsync(
            CreateClienteRequest request, 
            CancellationToken cancellationToken = default);

        Task<ClienteResponse> UpdateAsync(
            UpdateClienteRequest request, 
            CancellationToken cancellationToken = default);

        Task<bool> DeleteAsync(
            int id, 
            int idUsuario, 
            CancellationToken cancellationToken = default);

        Task<(MemoryStream stream, string fileName)> ExportarAsync(
            GetClienteRequest request, 
            CancellationToken cancellationToken = default);

        Task<bool> ValidarDuplicidadeAsync(
            string cpfCnpj, 
            int? excludeId = null, 
            CancellationToken cancellationToken = default);
    }
}
```

### BSN/Clientes/ClienteBsn.cs

```csharp
using ApplicationLayer.BSN.Base;
using ApplicationLayer.DTOs.Clientes.Requests;
using ApplicationLayer.DTOs.Clientes.Responses;
using ApplicationLayer.Interfaces.BSN;
using AutoMapper;
using CrossCuttingLayer.Exceptions;
using DomainLayer.Entities.Clientes;
using DomainLayer.Interfaces;
using DomainLayer.Interfaces.Repositories;
using FluentValidation;
using Microsoft.Extensions.Logging;
using OfficeOpenXml;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;

namespace ApplicationLayer.BSN.Clientes
{
    /// <summary>
    /// Business Service Network para Clientes
    /// Contém toda a lógica de negócio relacionada a clientes
    /// </summary>
    public class ClienteBsn : BaseBsn<ClienteBsn>, IClienteBsn
    {
        private readonly IClienteRepository _repository;
        private readonly IMapper _mapper;
        private readonly IValidator<CreateClienteRequest> _createValidator;
        private readonly IValidator<UpdateClienteRequest> _updateValidator;
        private readonly IDomainConfig _domainConfig;

        public ClienteBsn(
            IClienteRepository repository,
            IMapper mapper,
            IValidator<CreateClienteRequest> createValidator,
            IValidator<UpdateClienteRequest> updateValidator,
            IDomainConfig domainConfig,
            ILogger<ClienteBsn> logger) : base(logger)
        {
            _repository = repository ?? throw new ArgumentNullException(nameof(repository));
            _mapper = mapper ?? throw new ArgumentNullException(nameof(mapper));
            _createValidator = createValidator ?? throw new ArgumentNullException(nameof(createValidator));
            _updateValidator = updateValidator ?? throw new ArgumentNullException(nameof(updateValidator));
            _domainConfig = domainConfig ?? throw new ArgumentNullException(nameof(domainConfig));
        }

        /// <summary>
        /// Obtém todos os clientes com filtros e paginação
        /// </summary>
        public async Task<PaginatedResponse<ClienteResponse>> GetAllAsync(
            GetClienteRequest request,
            CancellationToken cancellationToken = default)
        {
            try
            {
                _logger.LogInformation($"Recuperando clientes. Página: {request.PageNumber}, Tamanho: {request.PageSize}");

                var query = _repository.GetQueryable();

                // Aplicar filtros
                if (!string.IsNullOrWhiteSpace(request.Nome))
                    query = query.Where(c => c.Nome.Contains(request.Nome));

                if (!string.IsNullOrWhiteSpace(request.Email))
                    query = query.Where(c => c.Email.Contains(request.Email));

                if (!string.IsNullOrWhiteSpace(request.CpfCnpj))
                    query = query.Where(c => c.CpfCnpj == request.CpfCnpj);

                if (request.TipoCliente.HasValue)
                    query = query.Where(c => c.TipoCliente == request.TipoCliente);

                if (request.Status.HasValue)
                    query = query.Where(c => c.Status == request.Status);

                if (request.DataCriacaoInicio.HasValue)
                    query = query.Where(c => c.DataCriacao >= request.DataCriacaoInicio);

                if (request.DataCriacaoFim.HasValue)
                    query = query.Where(c => c.DataCriacao <= request.DataCriacaoFim);

                // Contar total antes da paginação
                var totalItems = query.Count();

                // Aplicar paginação
                query = query.Skip((request.PageNumber - 1) * request.PageSize)
                             .Take(request.PageSize);

                // Aplicar ordenação
                query = ApplyOrdering(query, request.OrderBy, request.OrderDirection);

                var clientes = await query.ToListAsync(cancellationToken);

                var dtos = _mapper.Map<List<ClienteResponse>>(clientes);

                return new PaginatedResponse<ClienteResponse>
                {
                    Items = dtos,
                    PageNumber = request.PageNumber,
                    PageSize = request.PageSize,
                    TotalItems = totalItems
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Erro ao recuperar clientes");
                throw;
            }
        }

        /// <summary>
        /// Obtém um cliente pelo ID
        /// </summary>
        public async Task<ClienteResponse> GetByIdAsync(
            int id,
            CancellationToken cancellationToken = default)
        {
            try
            {
                var cliente = await _repository.GetByIdAsync(id, cancellationToken);

                if (cliente == null)
                    throw new CustomBusinessException($"Cliente com ID {id} não encontrado");

                return _mapper.Map<ClienteResponse>(cliente);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Erro ao recuperar cliente {id}");
                throw;
            }
        }

        /// <summary>
        /// Cria um novo cliente
        /// </summary>
        public async Task<ClienteResponse> CreateAsync(
            CreateClienteRequest request,
            CancellationToken cancellationToken = default)
        {
            try
            {
                _logger.LogInformation($"Criando novo cliente: {request.Nome}");

                // Validar com FluentValidation
                var validationResult = await _createValidator.ValidateAsync(request, cancellationToken);
                if (!validationResult.IsValid)
                {
                    var erros = string.Join("; ", validationResult.Errors.Select(e => e.ErrorMessage));
                    throw new CustomValidationException(erros);
                }

                // Validar duplicidade
                var existe = await ValidarDuplicidadeAsync(request.CpfCnpj, cancellationToken: cancellationToken);
                if (existe)
                    throw new CustomBusinessException("Já existe um cliente com este CPF/CNPJ");

                // Mapear para entidade
                var cliente = _mapper.Map<Cliente>(request);
                cliente.Status = EStatusCliente.Ativo;

                // Salvar
                await _repository.AddAsync(cliente, cancellationToken);
                await _repository.SaveChangesAsync(cancellationToken);

                _logger.LogInformation($"Cliente criado com sucesso. ID: {cliente.IdCliente}");

                return _mapper.Map<ClienteResponse>(cliente);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Erro ao criar cliente");
                throw;
            }
        }

        /// <summary>
        /// Atualiza um cliente existente
        /// </summary>
        public async Task<ClienteResponse> UpdateAsync(
            UpdateClienteRequest request,
            CancellationToken cancellationToken = default)
        {
            try
            {
                _logger.LogInformation($"Atualizando cliente ID: {request.IdCliente}");

                // Validar
                var validationResult = await _updateValidator.ValidateAsync(request, cancellationToken);
                if (!validationResult.IsValid)
                {
                    var erros = string.Join("; ", validationResult.Errors.Select(e => e.ErrorMessage));
                    throw new CustomValidationException(erros);
                }

                // Obter cliente
                var cliente = await _repository.GetByIdAsync(request.IdCliente, cancellationToken);
                if (cliente == null)
                    throw new CustomBusinessException($"Cliente com ID {request.IdCliente} não encontrado");

                // Validar duplicidade (se mudou CPF/CNPJ)
                if (cliente.CpfCnpj != request.CpfCnpj)
                {
                    var existe = await ValidarDuplicidadeAsync(
                        request.CpfCnpj, 
                        excludeId: request.IdCliente, 
                        cancellationToken: cancellationToken);
                    
                    if (existe)
                        throw new CustomBusinessException("Já existe outro cliente com este CPF/CNPJ");
                }

                // Mapear e atualizar
                _mapper.Map(request, cliente);

                await _repository.UpdateAsync(cliente, cancellationToken);
                await _repository.SaveChangesAsync(cancellationToken);

                _logger.LogInformation($"Cliente atualizado com sucesso");

                return _mapper.Map<ClienteResponse>(cliente);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Erro ao atualizar cliente {request.IdCliente}");
                throw;
            }
        }

        /// <summary>
        /// Deleta um cliente (soft delete)
        /// </summary>
        public async Task<bool> DeleteAsync(
            int id,
            int idUsuario,
            CancellationToken cancellationToken = default)
        {
            try
            {
                _logger.LogInformation($"Deletando cliente ID: {id}");

                var cliente = await _repository.GetByIdAsync(id, cancellationToken);
                if (cliente == null)
                    return false;

                cliente.Status = EStatusCliente.Inativo;
                cliente.DataAlteracao = DateTime.UtcNow;
                cliente.IdUsuarioAlteracao = idUsuario;

                await _repository.UpdateAsync(cliente, cancellationToken);
                await _repository.SaveChangesAsync(cancellationToken);

                _logger.LogInformation($"Cliente deletado com sucesso");

                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Erro ao deletar cliente {id}");
                throw;
            }
        }

        /// <summary>
        /// Exporta clientes para Excel
        /// </summary>
        public async Task<(MemoryStream stream, string fileName)> ExportarAsync(
            GetClienteRequest request,
            CancellationToken cancellationToken = default)
        {
            try
            {
                _logger.LogInformation("Exportando clientes para Excel");

                var clientes = await GetAllAsync(request, cancellationToken);

                EPPlus.LicenseContext.SetLicenseContext(EPPlus.LicenseContext.NonCommercial);

                using (var package = new ExcelPackage())
                {
                    var worksheet = package.Workbook.Worksheets.Add("Clientes");

                    // Cabeçalhos
                    worksheet.Cells[1, 1].Value = "ID";
                    worksheet.Cells[1, 2].Value = "Nome";
                    worksheet.Cells[1, 3].Value = "Email";
                    worksheet.Cells[1, 4].Value = "CPF/CNPJ";
                    worksheet.Cells[1, 5].Value = "Tipo";
                    worksheet.Cells[1, 6].Value = "Status";
                    worksheet.Cells[1, 7].Value = "Data Criação";

                    // Preencher dados
                    int row = 2;
                    foreach (var cliente in clientes.Items)
                    {
                        worksheet.Cells[row, 1].Value = cliente.IdCliente;
                        worksheet.Cells[row, 2].Value = cliente.Nome;
                        worksheet.Cells[row, 3].Value = cliente.Email;
                        worksheet.Cells[row, 4].Value = cliente.CpfCnpj;
                        worksheet.Cells[row, 5].Value = cliente.TipoCliente.ToString();
                        worksheet.Cells[row, 6].Value = cliente.Status.ToString();
                        worksheet.Cells[row, 7].Value = cliente.DataCriacao;
                        row++;
                    }

                    worksheet.Column(1).Width = 10;
                    worksheet.Column(2).Width = 30;
                    worksheet.Column(3).Width = 30;
                    worksheet.Column(4).Width = 15;
                    worksheet.Column(5).Width = 15;
                    worksheet.Column(6).Width = 15;
                    worksheet.Column(7).Width = 15;

                    var stream = new MemoryStream();
                    await package.SaveAsAsync(stream, cancellationToken);
                    stream.Position = 0;

                    var fileName = $"Clientes_{DateTime.UtcNow:yyyyMMdd_HHmmss}.xlsx";

                    return (stream, fileName);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Erro ao exportar clientes");
                throw;
            }
        }

        /// <summary>
        /// Valida duplicidade de CPF/CNPJ
        /// </summary>
        public async Task<bool> ValidarDuplicidadeAsync(
            string cpfCnpj,
            int? excludeId = null,
            CancellationToken cancellationToken = default)
        {
            try
            {
                var query = _repository.GetQueryable()
                    .Where(c => c.CpfCnpj == cpfCnpj && c.Status != EStatusCliente.Inativo);

                if (excludeId.HasValue)
                    query = query.Where(c => c.IdCliente != excludeId);

                return await query.AnyAsync(cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Erro ao validar duplicidade de {cpfCnpj}");
                throw;
            }
        }

        /// <summary>
        /// Aplica ordenação ao query
        /// </summary>
        private IQueryable<Cliente> ApplyOrdering(
            IQueryable<Cliente> query,
            string orderBy,
            string orderDirection)
        {
            var isAscending = orderDirection?.ToLower() == "asc";

            return orderBy?.ToLower() switch
            {
                "nome" => isAscending ? query.OrderBy(c => c.Nome) : query.OrderByDescending(c => c.Nome),
                "email" => isAscending ? query.OrderBy(c => c.Email) : query.OrderByDescending(c => c.Email),
                "datacriacao" => isAscending ? query.OrderBy(c => c.DataCriacao) : query.OrderByDescending(c => c.DataCriacao),
                _ => query.OrderByDescending(c => c.DataCriacao) // Default
            };
        }
    }
}
```

---

## 🎨 6. Enums

### Enums/ETipoCliente.cs

```csharp
using System.ComponentModel.DataAnnotations;

namespace ApplicationLayer.Enums
{
    /// <summary>
    /// Tipos de cliente
    /// </summary>
    public enum ETipoCliente
    {
        [Display(Name = "Pessoa Física")]
        PessoaFisica = 1,

        [Display(Name = "Pessoa Jurídica")]
        PessoaJuridica = 2,

        [Display(Name = "Fundo de Investimento")]
        FundoInvestimento = 3,

        [Display(Name = "Plano de Previdência")]
        PlanoPrevdencia = 4
    }
}
```

### Enums/EStatusCliente.cs

```csharp
namespace ApplicationLayer.Enums
{
    /// <summary>
    /// Status do cliente
    /// </summary>
    public enum EStatusCliente
    {
        /// <summary>
        /// Cliente ativo
        /// </summary>
        Ativo = 1,

        /// <summary>
        /// Cliente inativo
        /// </summary>
        Inativo = 2,

        /// <summary>
        /// Cliente bloqueado
        /// </summary>
        Bloqueado = 3,

        /// <summary>
        /// Cliente em análise
        /// </summary>
        EmAnalise = 4
    }
}
```

---

## 📐 7. Dependency Injection Setup

### Program.cs

```csharp
using IoC;
using Microsoft.AspNetCore.Builder;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

var builder = WebApplication.CreateBuilder(args);

// Adicionar serviços
builder.Services.AddControllers();
builder.Services.AddApiVersioning();
builder.Services.AddSwaggerGen();

// ✨ IoC Configuration (centralizado)
builder.Services.ConfigureIoC(builder.Configuration);

// Autenticação
builder.Services.AddAuthentication("Bearer")
    .AddJwtBearer(options =>
    {
        options.Authority = builder.Configuration["Auth:Authority"];
        options.Audience = builder.Configuration["Auth:Audience"];
    });

// CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend", builder =>
    {
        builder.WithOrigins(builder.Configuration["Cors:AllowedOrigins"].Split(","))
               .AllowAnyMethod()
               .AllowAnyHeader();
    });
});

var app = builder.Build();

// Middleware
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseCors("AllowFrontend");
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();
```

### CrossCuttingLayer/IoC/DependencyInjectionExtension.cs

```csharp
using ApplicationLayer.BSN.Clientes;
using ApplicationLayer.Interfaces.BSN;
using ApplicationLayer.Mapper;
using ApplicationLayer.Validators;
using AutoMapper;
using DomainLayer.Interfaces;
using DomainLayer.Interfaces.Repositories;
using DomainLayer.Services;
using FluentValidation;
using InfrastructureLayer.Contexts;
using InfrastructureLayer.Repositories;
using InfrastructureLayer.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using System.Reflection;

namespace IoC
{
    public static class DependencyInjectionExtension
    {
        /// <summary>
        /// Configura toda a injeção de dependência da aplicação
        /// </summary>
        public static IServiceCollection ConfigureIoC(
            this IServiceCollection services,
            IConfiguration configuration)
        {
            // 1. DbContexts
            ConfigureDbContexts(services, configuration);

            // 2. Repositories
            ConfigureRepositories(services);

            // 3. BSNs (Business Service Networks)
            ConfigureBsns(services);

            // 4. Domain Services
            ConfigureDomainServices(services);

            // 5. Infrastructure Services
            ConfigureInfrastructureServices(services);

            // 6. AutoMapper
            ConfigureAutoMapper(services);

            // 7. FluentValidation
            ConfigureValidators(services);

            // 8. Options
            ConfigureOptions(services, configuration);

            return services;
        }

        private static void ConfigureDbContexts(
            IServiceCollection services,
            IConfiguration configuration)
        {
            var connectionString = configuration.GetConnectionString("DefaultConnection");

            services.AddDbContext<AppDbContext>(options =>
            {
                options.UseSqlServer(connectionString, sqlServerOptionsAction: sqlOptions =>
                {
                    sqlOptions.CommandTimeout(180);
                    sqlOptions.EnableRetryOnFailure(3);
                });

#if DEBUG
                options.EnableSensitiveDataLogging();
#endif
            });
        }

        private static void ConfigureRepositories(IServiceCollection services)
        {
            // Repositories
            services.AddScoped<IClienteRepository, ClienteRepository>();
            services.AddScoped<IProdutoRepository, ProdutoRepository>();
            
            // Cache
            services.AddScoped<IRedisRepository, RedisRepository>();
        }

        private static void ConfigureBsns(IServiceCollection services)
        {
            services.AddScoped<IClienteBsn, ClienteBsn>();
            services.AddScoped<IProdutoBsn, ProdutoBsn>();
        }

        private static void ConfigureDomainServices(IServiceCollection services)
        {
            services.AddScoped<IDomainConfig, DomainConfig>();
            services.AddScoped<INotificationService, NotificationService>();
            services.AddScoped<IEncryptionService, EncryptionService>();
        }

        private static void ConfigureInfrastructureServices(IServiceCollection services)
        {
            services.AddScoped<IEmailService, EmailService>();
            services.AddScoped<ISmsService, SmsService>();
            services.AddHttpClient<IExternalApiService, ExternalApiService>();
        }

        private static void ConfigureAutoMapper(IServiceCollection services)
        {
            services.AddAutoMapper(config =>
            {
                config.AddProfile<ClienteProfile>();
                config.AddProfile<ProdutoProfile>();
            });
        }

        private static void ConfigureValidators(IServiceCollection services)
        {
            services.AddValidatorsFromAssemblyContaining<CreateClienteValidator>();
        }

        private static void ConfigureOptions(
            IServiceCollection services,
            IConfiguration configuration)
        {
            services.Configure<JwtOptions>(configuration.GetSection("Jwt"));
            services.Configure<SmtpOptions>(configuration.GetSection("Smtp"));
            services.Configure<AppSettings>(configuration.GetSection("AppSettings"));
        }
    }
}
```

---

## 🔥 PONTOS FORTES DA ORGANIZAÇÃO PRISMA SERVICE

### 1. **Clean Architecture Multilayer** ✅
```
Presentation Layer    → Controllers
Application Layer     → BSN (Business Logic), DTOs, Interfaces
Domain Layer         → Entities, Enums, Exceptions
Infrastructure Layer → Repositories, DbContexts, External Services
Cross-Cutting Layer  → IoC, Extensions, Exceptions, Helpers
```

**Benefício:** Separação clara de responsabilidades, testabilidade, manutenibilidade

---

### 2. **Padrão BSN (Business Service Network)** ✅
- Camada de negócio isolada das controllers
- Facilita testes unitários
- Reutilização de lógica

```csharp
// ❌ Não fazer (lógica na controller)
[HttpPost]
public async Task<IActionResult> Create([FromBody] Cliente request)
{
    // SELECT * FROM Clientes WHERE CpfCnpj = ...
    // INSERT INTO ...
}

// ✅ Fazer (lógica no BSN)
[HttpPost]
public async Task<IActionResult> Create([FromBody] CreateClienteRequest request)
{
    var result = await _clienteBsn.CreateAsync(request);
    return CreatedAtAction(..., result);
}
```

---

### 3. **Injeção de Dependência Centralizada** ✅
- Um único arquivo (DependencyInjectionExtension.cs)
- Fácil de manter e escalar
- Reflexão automática para descoberta de tipos

```csharp
// Centralizado no IoC
services.ConfigureDbContexts(configuration);
services.ConfigureRepositories(services);
services.ConfigureBsns(services);
services.ConfigureValidators(services);
services.ConfigureAutoMapper(services);
```

**Benefício:** Mudanças de dependência em um único lugar

---

### 4. **Enums com Display Attributes** ✅
```csharp
public enum ETipoCliente
{
    [Display(Name = "Pessoa Física")]
    PessoaFisica = 1,

    [Display(Name = "Pessoa Jurídica")]
    PessoaJuridica = 2
}
```

**Benefício:** Melhor documentação e integração com UI

---

### 5. **DTOs Separados por Request/Response** ✅
```
DTOs/
├── Requests/
│   ├── CreateClienteRequest
│   ├── UpdateClienteRequest
│   └── GetClienteRequest (com filtros)
├── Responses/
│   ├── ClienteResponse
│   └── PaginatedResponse<T>
```

**Benefício:** Flexibilidade, segurança, versionamento

---

### 6. **Validação Multinível** ✅
```csharp
// Nível 1: Data Annotations
[Required]
[EmailAddress]
public string Email { get; set; }

// Nível 2: FluentValidation (BSN)
var result = await _validator.ValidateAsync(request);

// Nível 3: Business Rules (BSN)
var existe = await ValidarDuplicidadeAsync(request.CpfCnpj);
```

**Benefício:** Validação robusta em múltiplas camadas

---

### 7. **Padrão de Resposta Wrapper** ✅
```csharp
public class ApiResponse<T>
{
    public bool Success { get; set; }
    public T Data { get; set; }
    public string Message { get; set; }
    public string Detail { get; set; }
    public DateTime Timestamp { get; set; }
}

// Sempre retornar
{
    "success": true,
    "data": { /* ... */ },
    "message": "Operação realizada com sucesso",
    "timestamp": "2024-01-15T10:30:00Z"
}
```

**Benefício:** Padronização, facilita parsing no frontend

---

### 8. **Logging Structured** ✅
```csharp
_logger.LogInformation($"[{metodo}] Payload: {JsonConvert.SerializeObject(request)}");
_logger.LogError(ex, $"[{metodo}] Erro não tratado: {mensagem}");
```

**Benefício:** Rastreabilidade, debugging facilitado

---

### 9. **Autorização por Atributo** ✅
```csharp
[Authorize]
[HttpPost]
public async Task<IActionResult> Create(...)
{
    var usuarioId = _domainConfig.CurrentUserId;
    // ...
}
```

**Benefício:** Segurança declarativa

---

### 10. **Paginação e Filtros Reutilizáveis** ✅
```csharp
public class PaginationParams
{
    public int PageNumber { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}

public class GetClienteRequest : PaginationParams
{
    public string Nome { get; set; }
    public string Email { get; set; }
    // ... filtros específicos
}
```

**Benefício:** DRY (Don't Repeat Yourself)

---

### 11. **AutoMapper para Mapping** ✅
```csharp
// Configuração
public class ClienteProfile : Profile
{
    public ClienteProfile()
    {
        CreateMap<CreateClienteRequest, Cliente>();
        CreateMap<Cliente, ClienteResponse>();
    }
}

// Uso
var cliente = _mapper.Map<Cliente>(request);
var dto = _mapper.Map<ClienteResponse>(cliente);
```

**Benefício:** Evita manual mapping repetitivo

---

### 12. **Tratamento de Exceções Customizadas** ✅
```csharp
public class CustomValidationException : Exception { }
public class CustomBusinessException : Exception { }
public class CustomEnquadramentoException : Exception { }

// Uso
if (!ModelState.IsValid)
    throw new CustomValidationException("...");

if (cliente.Status == Bloqueado)
    throw new CustomBusinessException("Cliente bloqueado");
```

**Benefício:** Diferenciação de tipos de erro, tratamento específico

---

### 13. **Versionamento de API** ✅
```csharp
[ApiVersion("1.0")]
[Route("api/v{version:apiVersion}/[controller]")]
public class ClienteController : BaseController { }
```

**Benefício:** Suporte a múltiplas versões sem breaking changes

---

### 14. **Documentação Swagger/OpenAPI** ✅
```csharp
/// <summary>
/// Obtém todos os clientes com paginação
/// </summary>
/// <param name="request">Filtros e paginação</param>
/// <response code="200">Lista de clientes</response>
[HttpGet]
[ProduceResponseType(typeof(ApiResponse<List<ClienteResponse>>), 200)]
public async Task<IActionResult> GetAll([FromQuery] GetClienteRequest request)
```

**Benefício:** Auto-documentação, Swagger gerado automaticamente

---

### 15. **Soft Delete Pattern** ✅
```csharp
// Em vez de deletar, marcar como inativo
cliente.Status = EStatusCliente.Inativo;
cliente.DataAlteracao = DateTime.UtcNow;

// Nas queries, sempre filtrar
query = query.Where(c => c.Status != EStatusCliente.Inativo);
```

**Benefício:** Auditoria, recuperação de dados

---

## 🎁 BÔNUS: Appsettings Structure

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=...",
    "PrismaDatabase": "Server=..."
  },

  "Jwt": {
    "Authority": "https://auth-server.com",
    "Audience": "api-app",
    "Issuer": "auth-server"
  },

  "Cors": {
    "AllowedOrigins": "http://localhost:3000,https://app.com"
  },

  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft": "Warning"
    }
  },

  "AppSettings": {
    "PageSize": 20,
    "MaxPageSize": 100,
    "CacheExpirationMinutes": 30
  },

  "Smtp": {
    "Host": "smtp.gmail.com",
    "Port": 587,
    "Username": "noreply@app.com",
    "Password": "****"
  }
}
```

---

## 🚀 Conclusão

### O que torna o Prisma Service exemplar:

✅ **Organização Clara** - Separação vertical por domínio  
✅ **Escalabilidade** - Adicionar novas features sem quebrar o existente  
✅ **Testabilidade** - Interfaces, mocks, injeção de dependência  
✅ **Manutenibilidade** - Código legível, bem documentado  
✅ **Performance** - Cache, paginação, queries otimizadas  
✅ **Segurança** - Autorização, validação, soft delete  
✅ **Observabilidade** - Logging estruturado, auditoria  

**Aplique esses padrões ao seu backend e você terá uma arquitetura profissional, escalável e fácil de manter! 🎯**
