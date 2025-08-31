Teste motor consolidação

Mock Testes

TST_WHG_16264559

Criar carteira Testes
Simular dados Mockup

Boletas
Id_Cliente 4135 
Cod_Conta 16264559
Id_Ativo 33109
Id_Carteira_Consolidacao 1751
Dt_Operacao 7/22/2025
Dt_Emissao 8/27/2025
Dt_Cotizacao 7/22/2025
Dt_Liquidacao 7/22/2025
Dt_Vencimento 4/12/2027
Vlr_Gross_Up 15
Ind_C_V C
Qtd_Boleta 1
Pr_Boleta 5196059.302
Tp_Valor Q
Vlr_Boleta 5196059.302
Pct_Tx_Rentabilidade_Pos 96
Pct_Tx_Rentabilidade_Pre NULL
Vlr_Tx_Cupom_Pre NULL

Id_Cliente 4135 
Cod_Conta 16264559
Id_Ativo 31287
Id_Carteira_Consolidacao 1751
Dt_Operacao 7/23/2025
Dt_Emissao 8/27/2025
Dt_Cotizacao 7/23/2025
Dt_Liquidacao 7/23/2025
Dt_Vencimento 3/15/2027
Vlr_Gross_Up 15
Ind_C_V C
Qtd_Boleta 2
Pr_Boleta 1048250.867
Tp_Valor Q
Vlr_Boleta 2096501.733
Pct_Tx_Rentabilidade_Pos 96.5
Pct_Tx_Rentabilidade_Pre NULL
Vlr_Tx_Cupom_Pre NULL




Com base nas boletas acima de modelagem Tb_Boleta_ComDinheiro
Faça um De-Para para a modelagem Tb_Movimentacao_Carteira_XP
no c#, ou seja de insert na tabela Tb_Movimentacao_Carteira_XP com base nas linhas de Tb_Boleta_ComDinheiro

SELECT TOP (1000) [Id_Boleta_ComDinheiro]
      ,[Id_Operacao_ComDinheiro]
      ,[Id_Ativo]
      ,[Id_Carteira_Consolidacao]
      ,[Dt_Operacao]
      ,[Dt_Emissao]
      ,[Dt_Cotizacao]
      ,[Dt_Liquidacao]
      ,[Dt_Vencimento]
      ,[Vlr_Gross_Up]
      ,[Ind_C_V]
      ,[Qtd_Boleta]
      ,[Pr_Boleta]
      ,[Tp_Valor]
      ,[Vlr_Boleta]
      ,[Id_Usu]
      ,[Dt_Cpu]
      ,[Dt_Cpu_Fim]
      ,[Ind_Altera_Caixa]
      ,[Id_Tipo_Marcacao_Ativo]
      ,[Pct_Tx_Rentabilidade_Pos]
      ,[Pct_Tx_Rentabilidade_Pre]
      ,[Vlr_Tx_Cupom_Pre]
      ,[Cod_Origem_Boleta]
      ,[Id_Origem_Boleta]
      ,[Ind_Ted]
      ,[Id_Produto_Ativo]
      ,[Ind_Gerencial]
  FROM [prisma].[dbo].[Tb_Boleta_ComDinheiro]



SELECT TOP (1000) [Id_Movimentacao_Carteira_XP]
      ,[Id_Cliente]
      ,[Id_Classe]
      ,[Id_Sub_Classe]
      ,[Classificacao]
      ,[Cod_Cetip]
      ,[Cod_Conta]
      ,[Cod_Gestora]
      ,[Dt_Cotizacao]
      ,[Dt_Expiracao]
      ,[Dt_Liquidacao]
      ,[Dt_Operacao]
      ,[Dt_Processamento]
      ,[Gestora]
      ,[Id_Ativo]
      ,[Fl_Ativo]
      ,[Iss_Value]
      ,[Nm_Ativo]
      ,[Nr_Cnpj]
      ,[Outros_Custos]
      ,[Preco]
      ,[XP_Quantity]
      ,[Tp_Movimentacao]
      ,[Tp_Desc_Movimentacao]
      ,[Tx_Registro]
      ,[Vlr_Bruto]
      ,[Vlr_Corretagem]
      ,[Vlr_Honorarios]
      ,[Vlr_IOF]
      ,[Vlr_IR]
      ,[Vlr_Liquido]
      ,[Corretagem_Renda_Variavel]
      ,[Vlr_ISS_Renda_Variavel]
      ,[Taxa_Registro_Renda_Variavel]
      ,[Outros_Custos_Renda_Variavel]
      ,[Taxas_Renda_Variavel]
      ,[Id_Usu]
      ,[Dt_Cpu]
      ,[Dt_Cpu_Fim]
      ,[Porcentagem_Indice_RF]
      ,[Indice_RF]
      ,[Taxa_RF]
      ,[Emissor]
  FROM [xp_posi].[Tb_Movimentacao_Carteira_XP]


sabendo que no meu código C# o De-para é:
            var dtoResult = result.Select(r =>
            {
                try
                {
                    return new ConsolidacaoMovBoletaDTO
                    {
                        IdMovimentacao = r.IdMovimentacaoCarteiraXP,
                        IdCliente = r.IdCliente.Value,
                        CodConta = r.CodConta,
                        TpMovimentacao = r.TpMovimentacao,
                        Classificacao = r.Classificacao,
                        IdAtivo = r.IdAtivo,
                        NmAtivo = r.NmAtivo,
                        Color = r.Color,
                        DtOperacao = r.DtOperacao.Value,
                        DtCotizacao = r.DtCotizacao.Value,
                        DtLiquidacao = r.DtLiquidacao.HasValue ? r.DtLiquidacao.Value : (DateTime?)r.DtCotizacao.Value,
                        DtVencimento = r.DtExpiracao.HasValue ? r.DtExpiracao.Value : (DateTime?)null,
                        Preco = r.Preco,
                        Quantidade = r.Quantidade,
                        VlrBruto = r.VlrBruto,
                        DescClasse = r.DescClasse,
                        DescSubclasse = r.DescSubclasse,
                        IsCompromissada = r.TpMovimentacao == "AV" || r.TpMovimentacao == "CR" ? true : false
                    };
                }
                catch (CustomException ex)
                {
                    _logger.LogError($"Erro no item com IdMovimentacao = {r.IdMovimentacaoCarteiraXP} em GetBoletasMovimentacaoXPTrades - Replicação Mov XP Consolidação, Detalhes do erro: {ex.Message}");
                    throw;
                }
            }).ToList();


result é do tipo List<Tb_Movimentacao_Carteira_XP>


INSERT INTO [xp_posi].[Tb_Movimentacao_Carteira_XP] (
    [Id_Cliente], [Id_Classe], [Id_Sub_Classe], [Classificacao], [Cod_Cetip], [Cod_Conta], [Cod_Gestora],
    [Dt_Cotizacao], [Dt_Expiracao], [Dt_Liquidacao], [Dt_Operacao], [Dt_Processamento], [Gestora], [Id_Ativo],
    [Fl_Ativo], [Iss_Value], [Nm_Ativo], [Nr_Cnpj], [Outros_Custos], [Preco], [XP_Quantity], [Tp_Movimentacao],
    [Tp_Desc_Movimentacao], [Tx_Registro], [Vlr_Bruto], [Vlr_Corretagem], [Vlr_Honorarios], [Vlr_IOF], [Vlr_IR],
    [Vlr_Liquido], [Corretagem_Renda_Variavel], [Vlr_ISS_Renda_Variavel], [Taxa_Registro_Renda_Variavel],
    [Outros_Custos_Renda_Variavel], [Taxas_Renda_Variavel], [Id_Usu], [Porcentagem_Indice_RF],
    [Indice_RF], [Taxa_RF], [Emissor]
) VALUES (
    4135, -- Id_Cliente
    6, -- Id_Classe (RENDA FIXA)
    6, -- Id_Sub_Classe (RENDA FIXA)
    'C', -- Classificacao (Ind_C_V)
    '25B02386280', -- Cod_Cetip
    16264559, -- Cod_Conta
    41462, -- Cod_Gestora
    '2025-02-13', -- Dt_Cotizacao
    '2030-01-18', -- Dt_Expiracao (Dt_Vencimento)
    '2025-02-13', -- Dt_Liquidacao
    '2025-02-13', -- Dt_Operacao
    GETDATE(), -- Dt_Processamento
    'WHG', -- Gestora
    30562, -- Id_Ativo
    1, -- Fl_Ativo
    NULL, -- Iss_Value
    'LCA 25B02386280', -- Nm_Ativo
    NULL, -- Nr_Cnpj
    NULL, -- Outros_Custos
    1000.000000, -- Preco (Pr_Boleta)
    3000.000000, -- XP_Quantity (Qtd_Boleta)
    'C', -- Tp_Movimentacao (Ind_C_V)
    'Compra definitiva', -- Tp_Desc_Movimentacao
    NULL, -- Tx_Registro
    3000000.000000, -- Vlr_Bruto (Vlr_Boleta)
    NULL, -- Vlr_Corretagem
    NULL, -- Vlr_Honorarios
    0.000000, -- Vlr_IOF
    0.000000, -- Vlr_IR
    3000000.000000, -- Vlr_Liquido (Vlr_Boleta)
    0.000000, -- Corretagem_Renda_Variavel
    0.000000, -- Vlr_ISS_Renda_Variavel
    0.000000, -- Taxa_Registro_Renda_Variavel
    0.000000, -- Outros_Custos_Renda_Variavel
    0.000000, -- Taxas_Renda_Variavel
    'prisma.whg', -- Id_Usu
    100.0000, -- Porcentagem_Indice_RF (Pct_Tx_Rentabilidade_Pos)
    'CDI', -- Indice_RF
    0.00000000, -- Taxa_RF
    'BANCO COOPERATIVO SICOOB S.A.' -- Emissor
);

INSERT INTO [xp_posi].[Tb_Movimentacao_Carteira_XP] (
    [Id_Cliente], [Id_Classe], [Id_Sub_Classe], [Classificacao], [Cod_Cetip], [Cod_Conta], [Cod_Gestora],
    [Dt_Cotizacao], [Dt_Expiracao], [Dt_Liquidacao], [Dt_Operacao], [Dt_Processamento], [Gestora], [Id_Ativo],
    [Fl_Ativo], [Iss_Value], [Nm_Ativo], [Nr_Cnpj], [Outros_Custos], [Preco], [XP_Quantity], [Tp_Movimentacao],
    [Tp_Desc_Movimentacao], [Tx_Registro], [Vlr_Bruto], [Vlr_Corretagem], [Vlr_Honorarios], [Vlr_IOF], [Vlr_IR],
    [Vlr_Liquido], [Corretagem_Renda_Variavel], [Vlr_ISS_Renda_Variavel], [Taxa_Registro_Renda_Variavel],
    [Outros_Custos_Renda_Variavel], [Taxas_Renda_Variavel], [Id_Usu], [Porcentagem_Indice_RF],
    [Indice_RF], [Taxa_RF], [Emissor]
) VALUES (
    4135, -- Id_Cliente
    6, -- Id_Classe (RENDA FIXA)
    6, -- Id_Sub_Classe (RENDA FIXA)
    'C', -- Classificacao (Ind_C_V)
    '25C03521748', -- Cod_Cetip
    16264559, -- Cod_Conta
    41462, -- Cod_Gestora
    '2025-03-14', -- Dt_Cotizacao
    '2027-03-15', -- Dt_Expiracao (Dt_Vencimento)
    '2025-03-14', -- Dt_Liquidacao
    '2025-03-14', -- Dt_Operacao
    GETDATE(), -- Dt_Processamento
    'WHG', -- Gestora
    31287, -- Id_Ativo
    1, -- Fl_Ativo
    NULL, -- Iss_Value
    'LCI 25C03521748', -- Nm_Ativo
    NULL, -- Nr_Cnpj
    NULL, -- Outros_Custos
    1000000.000000, -- Preco (Pr_Boleta)
    6.000000, -- XP_Quantity (Qtd_Boleta)
    'C', -- Tp_Movimentacao (Ind_C_V)
    'Compra definitiva', -- Tp_Desc_Movimentacao
    NULL, -- Tx_Registro
    6000000.000000, -- Vlr_Bruto (Vlr_Boleta)
    NULL, -- Vlr_Corretagem
    NULL, -- Vlr_Honorarios
    0.000000, -- Vlr_IOF
    0.000000, -- Vlr_IR
    6000000.000000, -- Vlr_Liquido (Vlr_Boleta)
    0.000000, -- Corretagem_Renda_Variavel
    0.000000, -- Vlr_ISS_Renda_Variavel
    0.000000, -- Taxa_Registro_Renda_Variavel
    0.000000, -- Outros_Custos_Renda_Variavel
    0.000000, -- Taxas_Renda_Variavel
    'prisma.whg', -- Id_Usu
    96.5000, -- Porcentagem_Indice_RF (Pct_Tx_Rentabilidade_Pos)
    'CDI', -- Indice_RF
    0.00000000, -- Taxa_RF
    'CAIXA ECONOMICA' -- Emissor
);

INSERT INTO [xp_posi].[Tb_Movimentacao_Carteira_XP] (
    [Id_Cliente], [Id_Classe], [Id_Sub_Classe], [Classificacao], [Cod_Cetip], [Cod_Conta], [Cod_Gestora],
    [Dt_Cotizacao], [Dt_Expiracao], [Dt_Liquidacao], [Dt_Operacao], [Dt_Processamento], [Gestora], [Id_Ativo],
    [Fl_Ativo], [Iss_Value], [Nm_Ativo], [Nr_Cnpj], [Outros_Custos], [Preco], [XP_Quantity], [Tp_Movimentacao],
    [Tp_Desc_Movimentacao], [Tx_Registro], [Vlr_Bruto], [Vlr_Corretagem], [Vlr_Honorarios], [Vlr_IOF], [Vlr_IR],
    [Vlr_Liquido], [Corretagem_Renda_Variavel], [Vlr_ISS_Renda_Variavel], [Taxa_Registro_Renda_Variavel],
    [Outros_Custos_Renda_Variavel], [Taxas_Renda_Variavel], [Id_Usu], [Porcentagem_Indice_RF],
    [Indice_RF], [Taxa_RF], [Emissor]
) VALUES (
    4135, -- Id_Cliente
    6, -- Id_Classe (RENDA FIXA)
    6, -- Id_Sub_Classe (RENDA FIXA)
    'C', -- Classificacao (Ind_C_V)
    '25E02189605', -- Cod_Cetip
    16264559, -- Cod_Conta
    41462, -- Cod_Gestora
    '2025-05-09', -- Dt_Cotizacao
    '2030-04-15', -- Dt_Expiracao (Dt_Vencimento)
    '2025-05-09', -- Dt_Liquidacao
    '2025-05-09', -- Dt_Operacao
    GETDATE(), -- Dt_Processamento
    'WHG', -- Gestora
    32030, -- Id_Ativo
    1, -- Fl_Ativo
    NULL, -- Iss_Value
    'LCA 25E02189605', -- Nm_Ativo
    NULL, -- Nr_Cnpj
    NULL, -- Outros_Custos
    1000.000000, -- Preco (Pr_Boleta)
    5000.000000, -- XP_Quantity (Qtd_Boleta)
    'C', -- Tp_Movimentacao (Ind_C_V)
    'Compra definitiva', -- Tp_Desc_Movimentacao
    NULL, -- Tx_Registro
    5000000.000000, -- Vlr_Bruto (Vlr_Boleta)
    NULL, -- Vlr_Corretagem
    NULL, -- Vlr_Honorarios
    0.000000, -- Vlr_IOF
    0.000000, -- Vlr_IR
    5000000.000000, -- Vlr_Liquido (Vlr_Boleta)
    0.000000, -- Corretagem_Renda_Variavel
    0.000000, -- Vlr_ISS_Renda_Variavel
    0.000000, -- Taxa_Registro_Renda_Variavel
    0.000000, -- Outros_Custos_Renda_Variavel
    0.000000, -- Taxas_Renda_Variavel
    'prisma.whg', -- Id_Usu
    97.0000, -- Porcentagem_Indice_RF (Pct_Tx_Rentabilidade_Pos)
    'CDI', -- Indice_RF
    0.00000000, -- Taxa_RF
    'BANCO COOPERATIVO SICOOB S.A.' -- Emissor
);

INSERT INTO [xp_posi].[Tb_Movimentacao_Carteira_XP] (
    [Id_Cliente], [Id_Classe], [Id_Sub_Classe], [Classificacao], [Cod_Cetip], [Cod_Conta], [Cod_Gestora],
    [Dt_Cotizacao], [Dt_Expiracao], [Dt_Liquidacao], [Dt_Operacao], [Dt_Processamento], [Gestora], [Id_Ativo],
    [Fl_Ativo], [Iss_Value], [Nm_Ativo], [Nr_Cnpj], [Outros_Custos], [Preco], [XP_Quantity], [Tp_Movimentacao],
    [Tp_Desc_Movimentacao], [Tx_Registro], [Vlr_Bruto], [Vlr_Corretagem], [Vlr_Honorarios], [Vlr_IOF], [Vlr_IR],
    [Vlr_Liquido], [Corretagem_Renda_Variavel], [Vlr_ISS_Renda_Variavel], [Taxa_Registro_Renda_Variavel],
    [Outros_Custos_Renda_Variavel], [Taxas_Renda_Variavel], [Id_Usu], [Porcentagem_Indice_RF],
    [Indice_RF], [Taxa_RF], [Emissor]
) VALUES (
    4135, -- Id_Cliente
    6, -- Id_Classe (RENDA FIXA)
    6, -- Id_Sub_Classe (RENDA FIXA)
    'C', -- Classificacao (Ind_C_V)
    '25F02730791', -- Cod_Cetip
    16264559, -- Cod_Conta
    41462, -- Cod_Gestora
    '2025-06-18', -- Dt_Cotizacao
    '2030-06-17', -- Dt_Expiracao (Dt_Vencimento)
    '2025-06-18', -- Dt_Liquidacao
    '2025-06-18', -- Dt_Operacao
    GETDATE(), -- Dt_Processamento
    'WHG', -- Gestora
    32573, -- Id_Ativo
    1, -- Fl_Ativo
    NULL, -- Iss_Value
    'LCD FLU 25F02730791', -- Nm_Ativo
    NULL, -- Nr_Cnpj
    NULL, -- Outros_Custos
    10000.000000, -- Preco (Pr_Boleta)
    285.000000, -- XP_Quantity (Qtd_Boleta)
    'C', -- Tp_Movimentacao (Ind_C_V)
    'Compra definitiva', -- Tp_Desc_Movimentacao
    NULL, -- Tx_Registro
    2850000.000000, -- Vlr_Bruto (Vlr_Boleta)
    NULL, -- Vlr_Corretagem
    NULL, -- Vlr_Honorarios
    0.000000, -- Vlr_IOF
    0.000000, -- Vlr_IR
    2850000.000000, -- Vlr_Liquido (Vlr_Boleta)
    0.000000, -- Corretagem_Renda_Variavel
    0.000000, -- Vlr_ISS_Renda_Variavel
    0.000000, -- Taxa_Registro_Renda_Variavel
    0.000000, -- Outros_Custos_Renda_Variavel
    0.000000, -- Taxas_Renda_Variavel
    'prisma.whg', -- Id_Usu
    96.0000, -- Porcentagem_Indice_RF (Pct_Tx_Rentabilidade_Pos)
    'CDI', -- Indice_RF
    0.00000000, -- Taxa_RF
    'BNDES' -- Emissor
);

INSERT INTO [xp_posi].[Tb_Movimentacao_Carteira_XP] (
    [Id_Cliente], [Id_Classe], [Id_Sub_Classe], [Classificacao], [Cod_Cetip], [Cod_Conta], [Cod_Gestora],
    [Dt_Cotizacao], [Dt_Expiracao], [Dt_Liquidacao], [Dt_Operacao], [Dt_Processamento], [Gestora], [Id_Ativo],
    [Fl_Ativo], [Iss_Value], [Nm_Ativo], [Nr_Cnpj], [Outros_Custos], [Preco], [XP_Quantity], [Tp_Movimentacao],
    [Tp_Desc_Movimentacao], [Tx_Registro], [Vlr_Bruto], [Vlr_Corretagem], [Vlr_Honorarios], [Vlr_IOF], [Vlr_IR],
    [Vlr_Liquido], [Corretagem_Renda_Variavel], [Vlr_ISS_Renda_Variavel], [Taxa_Registro_Renda_Variavel],
    [Outros_Custos_Renda_Variavel], [Taxas_Renda_Variavel], [Id_Usu], [Porcentagem_Indice_RF],
    [Indice_RF], [Taxa_RF], [Emissor]
) VALUES (
    4135, -- Id_Cliente
    6, -- Id_Classe (RENDA FIXA)
    6, -- Id_Sub_Classe (RENDA FIXA)
    'C', -- Classificacao (Ind_C_V)
    '25F07417671', -- Cod_Cetip
    16264559, -- Cod_Conta
    41462, -- Cod_Gestora
    '2025-06-27', -- Dt_Cotizacao
    '2028-06-30', -- Dt_Expiracao (Dt_Vencimento)
    '2025-06-27', -- Dt_Liquidacao
    '2025-06-27', -- Dt_Operacao
    GETDATE(), -- Dt_Processamento
    'WHG', -- Gestora
    32697, -- Id_Ativo
    1, -- Fl_Ativo
    NULL, -- Iss_Value
    'LCA 25F07417671', -- Nm_Ativo
    NULL, -- Nr_Cnpj
    NULL, -- Outros_Custos
    10000.000000, -- Preco (Pr_Boleta)
    19.000000, -- XP_Quantity (Qtd_Boleta)
    'C', -- Tp_Movimentacao (Ind_C_V)
    'Compra definitiva', -- Tp_Desc_Movimentacao
    NULL, -- Tx_Registro
    190000.000000, -- Vlr_Bruto (Vlr_Boleta)
    NULL, -- Vlr_Corretagem
    NULL, -- Vlr_Honorarios
    0.000000, -- Vlr_IOF
    0.000000, -- Vlr_IR
    190000.000000, -- Vlr_Liquido (Vlr_Boleta)
    0.000000, -- Corretagem_Renda_Variavel
    0.000000, -- Vlr_ISS_Renda_Variavel
    0.000000, -- Taxa_Registro_Renda_Variavel
    0.000000, -- Outros_Custos_Renda_Variavel
    0.000000, -- Taxas_Renda_Variavel
    'prisma.whg', -- Id_Usu
    92.9000, -- Porcentagem_Indice_RF (Pct_Tx_Rentabilidade_Pos)
    'CDI', -- Indice_RF
    0.00000000, -- Taxa_RF
    'BNDES' -- Emissor
);

INSERT INTO [xp_posi].[Tb_Movimentacao_Carteira_XP] (
    [Id_Cliente], [Id_Classe], [Id_Sub_Classe], [Classificacao], [Cod_Cetip], [Cod_Conta], [Cod_Gestora],
    [Dt_Cotizacao], [Dt_Expiracao], [Dt_Liquidacao], [Dt_Operacao], [Dt_Processamento], [Gestora], [Id_Ativo],
    [Fl_Ativo], [Iss_Value], [Nm_Ativo], [Nr_Cnpj], [Outros_Custos], [Preco], [XP_Quantity], [Tp_Movimentacao],
    [Tp_Desc_Movimentacao], [Tx_Registro], [Vlr_Bruto], [Vlr_Corretagem], [Vlr_Honorarios], [Vlr_IOF], [Vlr_IR],
    [Vlr_Liquido], [Corretagem_Renda_Variavel], [Vlr_ISS_Renda_Variavel], [Taxa_Registro_Renda_Variavel],
    [Outros_Custos_Renda_Variavel], [Taxas_Renda_Variavel], [Id_Usu], [Porcentagem_Indice_RF],
    [Indice_RF], [Taxa_RF], [Emissor]
) VALUES (
    4135, -- Id_Cliente
    6, -- Id_Classe (RENDA FIXA)
    6, -- Id_Sub_Classe (RENDA FIXA)
    'C', -- Classificacao (Ind_C_V)
    '25D01802177', -- Cod_Cetip
    16264559, -- Cod_Conta
    41462, -- Cod_Gestora
    '2025-07-07', -- Dt_Cotizacao
    '2027-04-05', -- Dt_Expiracao (Dt_Vencimento)
    '2025-07-07', -- Dt_Liquidacao
    '2025-07-07', -- Dt_Operacao
    GETDATE(), -- Dt_Processamento
    'WHG', -- Gestora
    33099, -- Id_Ativo
    1, -- Fl_Ativo
    NULL, -- Iss_Value
    'LCI 25D01802177', -- Nm_Ativo
    NULL, -- Nr_Cnpj
    NULL, -- Outros_Custos
    1038583.021722, -- Preco (Pr_Boleta)
    1.000000, -- XP_Quantity (Qtd_Boleta)
    'C', -- Tp_Movimentacao (Ind_C_V)
    'Compra definitiva', -- Tp_Desc_Movimentacao
    NULL, -- Tx_Registro
    1038583.020000, -- Vlr_Bruto (Vlr_Boleta)
    NULL, -- Vlr_Corretagem
    NULL, -- Vlr_Honorarios
    0.000000, -- Vlr_IOF
    0.000000, -- Vlr_IR
    1038583.020000, -- Vlr_Liquido (Vlr_Boleta)
    0.000000, -- Corretagem_Renda_Variavel
    0.000000, -- Vlr_ISS_Renda_Variavel
    0.000000, -- Taxa_Registro_Renda_Variavel
    0.000000, -- Outros_Custos_Renda_Variavel
    0.000000, -- Taxas_Renda_Variavel
    'prisma.whg', -- Id_Usu


    96.5000, -- Porcentagem_Indice_RF (Pct_Tx_Rentabilidade_Pos)
    'CDI', -- Indice_RF
    0.00000000, -- Taxa_RF
    'CAIXA ECONOMICA' -- Emissor
);

INSERT INTO [xp_posi].[Tb_Movimentacao_Carteira_XP] (
    [Id_Cliente], [Id_Classe], [Id_Sub_Classe], [Classificacao], [Cod_Cetip], [Cod_Conta], [Cod_Gestora],
    [Dt_Cotizacao], [Dt_Expiracao], [Dt_Liquidacao], [Dt_Operacao], [Dt_Processamento], [Gestora], [Id_Ativo],
    [Fl_Ativo], [Iss_Value], [Nm_Ativo], [Nr_Cnpj], [Outros_Custos], [Preco], [XP_Quantity], [Tp_Movimentacao],
    [Tp_Desc_Movimentacao], [Tx_Registro], [Vlr_Bruto], [Vlr_Corretagem], [Vlr_Honorarios], [Vlr_IOF], [Vlr_IR],
    [Vlr_Liquido], [Corretagem_Renda_Variavel], [Vlr_ISS_Renda_Variavel], [Taxa_Registro_Renda_Variavel],
    [Outros_Custos_Renda_Variavel], [Taxas_Renda_Variavel], [Id_Usu], [Porcentagem_Indice_RF],
    [Indice_RF], [Taxa_RF], [Emissor]
) VALUES (
    4135, -- Id_Cliente
    6, -- Id_Classe (RENDA FIXA)
    6, -- Id_Sub_Classe (RENDA FIXA)
    'C', -- Classificacao (Ind_C_V)
    '25C04436540', -- Cod_Cetip
    16264559, -- Cod_Conta
    41462, -- Cod_Gestora
    '2025-07-28', -- Dt_Cotizacao
    '2027-03-24', -- Dt_Expiracao (Dt_Vencimento)
    '2025-07-28', -- Dt_Liquidacao
    '2025-07-28', -- Dt_Operacao
    GETDATE(), -- Dt_Processamento
    'WHG', -- Gestora
    33213, -- Id_Ativo
    1, -- Fl_Ativo
    NULL, -- Iss_Value
    'LCI 25C04436540', -- Nm_Ativo
    NULL, -- Nr_Cnpj
    NULL, -- Outros_Custos
    1046886.171068, -- Preco (Pr_Boleta)
    1.000000, -- XP_Quantity (Qtd_Boleta)
    'C', -- Tp_Movimentacao (Ind_C_V)
    'Compra definitiva', -- Tp_Desc_Movimentacao	
    NULL, -- Tx_Registro
    1046886.170000, -- Vlr_Bruto (Vlr_Boleta)
    NULL, -- Vlr_Corretagem
    NULL, -- Vlr_Honorarios
    0.000000, -- Vlr_IOF
    0.000000, -- Vlr_IR
    1046886.170000, -- Vlr_Liquido (Vlr_Boleta)
    0.000000, -- Corretagem_Renda_Variavel
    0.000000, -- Vlr_ISS_Renda_Variavel
    0.000000, -- Taxa_Registro_Renda_Variavel
    0.000000, -- Outros_Custos_Renda_Variavel
    0.000000, -- Taxas_Renda_Variavel
    'prisma.whg', -- Id_Usu


    96.0000, -- Porcentagem_Indice_RF (Pct_Tx_Rentabilidade_Pos)
    'CDI', -- Indice_RF
    0.00000000, -- Taxa_RF
    'CAIXA ECONOMICA' -- Emissor
);

-- Continuando com os demais registros conforme a lista fornecida...





SELECT TOP (1000) [Id_Header]
      ,[Dt_Posicao]
      ,[Produto]
      ,[Id_Ativo]
      ,[Nr_Cpf_Cnpj]
      ,[Nm_Cpf_Cnpj]
      ,[Vlr_Pat_Liq]
      ,[Instrumento]
      ,[Isin]
      ,[Preco]
      ,[Quantidade]
      ,[Vlr_Liquido]
      ,[Vlr_Ajuste]
      ,[Id_Cliente]
      ,[Tp_Header]
      ,[Quantidade_Garantia]
      ,[Quantidade_Aluguel]
  FROM [prisma].[xml].[View_Posicao_Consolidada] WHERE Id_Cliente = '4135' and Dt_Posicao between '2025-07-22' and '2025-07-23' ORDER BY Dt_Posicao DESC





-------------------------------------------------


SELECT TOP (100) [Id_Movimentacao_Carteira_XP]
      ,[Dt_Operacao]
      ,[Id_Cliente]
	  ,[Id_Ativo]
      ,[Id_Classe]
      ,[Id_Sub_Classe]
      ,[Classificacao]
      ,[Cod_Cetip]
      ,[Cod_Conta]
      ,[Cod_Gestora]
      ,[Dt_Cotizacao]
      ,[Dt_Expiracao]
      ,[Dt_Liquidacao]
      ,[Dt_Processamento]
      ,[Gestora]
      ,[Fl_Ativo]
      ,[Iss_Value]
      ,[Nm_Ativo]
      ,[Nr_Cnpj]
      ,[Outros_Custos]
      ,[Preco]
      ,[XP_Quantity]
      ,[Tp_Movimentacao]
      ,[Tp_Desc_Movimentacao]
      ,[Tx_Registro]
      ,[Vlr_Bruto]
      ,[Vlr_Corretagem]
      ,[Vlr_Honorarios]
      ,[Vlr_IOF]
      ,[Vlr_IR]
      ,[Vlr_Liquido]
      ,[Corretagem_Renda_Variavel]
      ,[Vlr_ISS_Renda_Variavel]
      ,[Taxa_Registro_Renda_Variavel]
      ,[Outros_Custos_Renda_Variavel]
      ,[Taxas_Renda_Variavel]
      ,[Id_Usu]
      ,[Dt_Cpu]
      ,[Dt_Cpu_Fim]
      ,[Porcentagem_Indice_RF]
      ,[Indice_RF]
      ,[Taxa_RF]
      ,[Emissor]
  FROM [xp_posi].[Tb_Movimentacao_Carteira_XP] 
  WHERE Id_Cliente = '4135' and Dt_Operacao BETWEEN '2025-07-02' AND '2025-07-28'
  ORDER BY Dt_Operacao ASC
  -- Resultado da Query Acima: 
	  -- Dt_Operacao 2025-07-07 e Id_Ativo 33099 (Não tem no XML)
	  -- Dt_Operacao 2025-07-22 e Id_Ativo 33109 (Tem no XML D-0 E D-1)
	  -- Dt_Operacao 2025-07-23 e Id_Ativo 31287 ()
	  -- Dt_Operacao 2025-07-28 e Id_Ativo 33213


  -- TST_WHG_16264559
  -- Data Corte Movimentação XP é de 02/07/2025
  -- XML a partir de 2025-07-02
  SELECT TOP (100) * FROM xml.View_Posicao_Consolidada 
  WHERE Id_Cliente = '4135' and Dt_Posicao BETWEEN '2025-07-02' AND '2025-07-29' AND Id_Ativo != '8642' AND Id_Ativo != '761' -- AND Id_Ativo = '33109'
  ORDER BY Dt_Posicao ASC
 -- Dt_Operacao 2025-07-22 e Id_Ativo 33109, Tem no XML D-0 E D-1 -> Id_HEader 1679117 Dt_Posicao 2025-07-22 e 2025-07-23 e Id_Ativo 33109
