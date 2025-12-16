Tasks:

	Possibilitar a geração de boletas via gerador de trade XML quando não houver nenhum trade via API
	Possibilitar a geração de boletas via gerador de trade XML para datas anteriores a 31/05/2022

Eu tenho um fluxo de replicação automático de Movimentações/Boletas/Trades Financeiros, que consiste em 

Criar uma solicitação de replicação com DtInicio DtFim e idCliente
Selecionar no banco de dados as posições ou movimentações de um idCliente
Agrupar e fazer os devidos tratamentos para normalizar essas posições(se for posição iremos gerar movimentações) e ou movimentações 
Normalizamos no formato de Envio correto/Modelagem da CMD para a API da CMD

Neste fluxo acima temos dois tipos de Sources distintos, Movimentação XP (Vem via API Rest e são armazenados no Banco de Dados) e Posição de XML (XML Vem via API Rest e são armazenados no Banco de Dados)

Falando sobre o Fluxo de Movimentação XP:
Nós pegamos todas as movimentações XP e agrupamos elas e normalizamos para o formato da Modelagem da CMD para enviar via API
Mas antes de enviar se a source for do tipo Movimentação XP, então vamos checar no XML (pois vamos completar os buracos na MovXP utilizando as Posições do XML)
No caso de posições XML nós passamos as posicoes por um motor que faz uma posicao contra a outra para determinar as movimentacoes (movimentacoes sintéticas)
Caso essa movimentacao proveniente do XML ela for de Caixa, nós adicionamos ela junto aos trades finais/trade de mov xp

Qual é o meu problema hoje, é que hj se tiver somente uma movimentação XP (e supondo que no dia deveria ter tido 5 movimentações e não só uma) eu uso as movimentações sintéticas do XML para completar o buraco
porém nesse fluxo é necessário a seguinte alteração: Quando tiver zero movimentações XP, eu quero que tbm seja completado o buraco com as movimentações sintéticas vindas das posições do XML

No caso de movimentações sintéticas de caixa, nós hj já adicionamos direto na lista das movimentações XP/movimentações finais pois a api/movimentações xp do banco nunca irão ter Caixa

Eu preciso que seja implementado uma correção para suportar que quando nao houber nenhum trade via Movimentação XP, seja preenchido com movimentação sintética da Posição XML.
Preciso alterar somente onde for necessário, hj esse preenchimento só funciona quando há pelo menos um trade, mas precisa funcionar quando há zero trades (hj existem travas que nao permitem isso)
o ponto central dessa demanda é dentro da função ReplicateTradesToComDinheiro, por isso irei mostrar apenas desse nível para frente.

Flow:
ProcessaFilaAsync -> GetProcessamentoPendenteAsync -> ChangeStatusAsync -> ProcessaPosicaoPortfolioAsync -> 

ReplicateStockTradesToComDinheiro -> ReplicateTradesToComDinheiro -> GetTrades -> GetBoletasMovimentacaoXPTrades

																				SE MOV.XP 
																					Então
																						GetTrades -> GetBoletasPosicaoXML
																						Lógica de agrupar os trades e equalizar eles
																					CASO CONTRÁRIO
																						Lógica de agrupar os trades e equalizar eles
Arquivos:																															A							
ConsolidacaoBsn:

        public async Task<bool> ReplicateTradesToComDinheiro(EConsolidacaoSourceReplication tpFonte, string customerCode = null, int? idCliente = null, string nrCnpj = null, int? idAtivo = null, DateTime? startOperationDate = null, DateTime? endOperationDate = null, int idFilaProcessamento = 0)
        {
            try
            {
                (List<ConsolidacaoMovBoletaDTO> trades, List<ConsolidacaoMovBoletaDTO> ignorados) = 
                    await GetTrades(tpFonte, customerCode, idCliente, nrCnpj, idAtivo, startOperationDate, endOperationDate, "Operation");

                List<ConsolidacaoMovBoletaDTO> tradesXML = null;
                Dictionary<string, List<ConsolidacaoMovBoletaDTO>> groupedTradesXML = null;
                Dictionary<string, List<ConsolidacaoMovBoletaDTO>> aggregatedTradesXML = null;
                Dictionary<string, List<CreateOrUpdateComDinheiroTradeRequest>> tradesComDinheiroRequestXML = null;
                List<int> idsAtivosProdutoAcao = new();

                if (tpFonte == EConsolidacaoSourceReplication.MOVIMENTACAOXP)
                {
                    var tpFonteXml = EConsolidacaoSourceReplication.XML;

                    (tradesXML, _) =
                        await GetTrades(tpFonteXml, customerCode, idCliente, nrCnpj, idAtivo, startOperationDate, endOperationDate, "Operation", indConsideraCaixa: true);

                    var idsAtivosFundos = await _whgContext.TbAtivo.Where(a => a.IdTipoAtivo == 1).Select(a => a.IdAtivo).ToListAsync();
                    List<ConsolidacaoMovBoletaDTO> tradesToRemove = new();

                    foreach (var trd in tradesXML)
                    {
                        trd.CodConta = customerCode;

                        // Ativo de fundo
                        if (trd.IdAtivo.HasValue && idsAtivosFundos.Contains(trd.IdAtivo.Value) && trd.DtCotizacao.HasValue)
                        {
                            // Trade de fundo no último dia útil de maio ou de novembro vamos excluir
                            // O motivo são os come-cotas
                            if (IsUltimoDiaUtilMonth(trd.DtCotizacao.Value, 5) || IsUltimoDiaUtilMonth(trd.DtCotizacao.Value, 11))
                            {
                                tradesToRemove.Add(trd);
                            }
                        }
                    }
                   
                    foreach (var trdToRemove in tradesToRemove)
                    {
                        tradesXML.Remove(trdToRemove);
                    }

                    // Vamos filtrar apenas os trades de diferenças de caixa
                    var tradesXMLCaixa = tradesXML?.Where(trd => trd.IsIdAtivoCaixa)?.ToList() ?? new();

                    // Vamos incluir os trades de caixa nos trades de movimentação XP
                    // A base dos trades de caixa é o próprio XML
                    trades.AddRange(tradesXMLCaixa);

                    // A ideia é que com os tradesXML a gente consiga validar versos os trades feitos pela API de movimentações
                    groupedTradesXML = GroupTradesByWallet(tradesXML, idFilaProcessamento);
                    aggregatedTradesXML = AggregateTrades(groupedTradesXML, idFilaProcessamento, tpFonteXml);
                    tradesComDinheiroRequestXML = NormalizeTradesToComDinheiro(aggregatedTradesXML, idFilaProcessamento, tpFonte);

                    // Adiciona todos os ativos que sejam de posições vendidas
                    idsAtivosProdutoAcao.AddRange(tradesXML.Where(t => t.IsPosicaoVendida && t.IdAtivo.HasValue).Select(t => t.IdAtivo.Value).Distinct().ToList());

                    // Adiciona todos os ativos de boletas anteriores na mesma carteira que já tenham sido realizadas via produto
                    var keysCarteiras = tradesComDinheiroRequestXML
                            .SelectMany(t => t.Value)
                            .Select(t => t.GetIdCarteiraConsolidacao())
                            .Distinct()
                            .Select(t => new { IdCarteiraConsolidacao = t })
                            .ToList();

                    var idsAtivosBoletasProdutoAcao = await _whgContext.TbBoletaComDinheiro
                        .MemoryJoin(_whgContext, keysCarteiras, o => o.IdCarteiraConsolidacao, d => d.IdCarteiraConsolidacao)
                        //.Where(b => b.DtOperacao >= startOperationDate) // Não vamos validar data, a partir do momento que aquele ativo já teve uma boleta com o produto, vamos replicar todas no mesmo padrão
                        .Where(b => b.IdProdutoAtivo.HasValue && b.IdProdutoAtivoNavigation.CodProdutoComDinheiro == "acao")
                        .AsNoTracking()
                        .Select(b => b.IdAtivo)
                        .Distinct()
                        .ToListAsync();

                    idsAtivosProdutoAcao.AddRange(idsAtivosBoletasProdutoAcao);

                    // Inclui apenas os distintos
                    idsAtivosProdutoAcao = idsAtivosProdutoAcao.Distinct().ToList();
                }

                if (trades.Any())
                {
                    var groupedTrades = GroupTradesByWallet(trades, idFilaProcessamento);
                    var groupedTradesIgnored = GroupTradesByWallet(ignorados, idFilaProcessamento);

                    var aggregatedTrades = AggregateTrades(groupedTrades, idFilaProcessamento, tpFonte);
                    var aggregatedTradesIgnorados = AggregateTrades(groupedTradesIgnored, idFilaProcessamento, tpFonte);

                    var tradesComDinheiroRequest = NormalizeTradesToComDinheiro(aggregatedTrades, idFilaProcessamento, tpFonte, idsAtivosProdutoAcao);
                    var tradesComDinheiroRequestIgnorados = NormalizeTradesToComDinheiro(aggregatedTradesIgnorados, idFilaProcessamento, tpFonte, idsAtivosProdutoAcao);

                    if (tradesComDinheiroRequestXML != null && tradesComDinheiroRequest != null)
                    {
                        EqualizeTrades(tradesComDinheiroRequest, tradesComDinheiroRequestXML);

                        //var matchTrades = _tradeBsn.MatchTrades
                        //    (
                        //        await ConvertToITradeListAsync(tradesComDinheiroRequestXML, Domain.Entities.Posicao.Base.SourcePosition.XML),
                        //        await ConvertToITradeListAsync(tradesComDinheiroRequest, Domain.Entities.Posicao.Base.SourcePosition.CONSOLIDACAO)
                        //    );

                        //Console.WriteLine(matchTrades);
                    }

                    var tradesComDinheiroRequestHasheds = GenerateAndSetHashes(tradesComDinheiroRequest);

                    await SyncTradesPrismaComDinheiro(tpFonte, tradesComDinheiroRequestHasheds, tradesComDinheiroRequestIgnorados, idFilaProcessamento, startOperationDate, endOperationDate);
                }

                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Erro ao replicar os novos Trades de Movimentação Carteira XP para a ComDinheiro");
                throw;
            }
        }
		
		        private async Task<(List<ConsolidacaoMovBoletaDTO> result, List<ConsolidacaoMovBoletaDTO> ignorados)> GetTrades(
            EConsolidacaoSourceReplication source,
            string customerCode,
            int? idCliente,
            string nrCnpj,
            int? idAtivo,
            DateTime? startDate,
            DateTime? endDate,
            string TpDate = "Cpu",
            bool indConsideraCaixa = false)
        {
            // Verifica se as datas de início e fim foram fornecidas
            if (!startDate.HasValue || !endDate.HasValue)
            {
                throw new ArgumentException("As datas de início e fim devem ser fornecidas.");
            }

            // Inicializa as listas de resultado e ignorados
            List<ConsolidacaoMovBoletaDTO> result = new List<ConsolidacaoMovBoletaDTO>();
            List<ConsolidacaoMovBoletaDTO> ignorados = new List<ConsolidacaoMovBoletaDTO>();

            switch (source)
            {
                case EConsolidacaoSourceReplication.MOVIMENTACAOXP:
                    (result, ignorados) = await GetBoletasMovimentacaoXPTrades(customerCode, startDate.Value, endDate.Value, TpDate);
                    break;
                case EConsolidacaoSourceReplication.XML:
                    result = await GetBoletasPosicaoXML(idCliente, nrCnpj, idAtivo, startDate.Value, endDate.Value, indConsideraCaixa);
                    break;
                default:
                    throw new ArgumentException($"Tipo de source não suportado, não há lógica definida para a source: {source}.");
            }

            return (result, ignorados);
        }
		
		
		        private void EqualizeTrades(
            Dictionary<string, List<CreateOrUpdateComDinheiroTradeRequest>> tradesComDinheiroRequest, 
            Dictionary<string, List<CreateOrUpdateComDinheiroTradeRequest>> tradesComDinheiroRequestXML)
        {
            foreach (var xp in tradesComDinheiroRequest)
            {
                if (tradesComDinheiroRequestXML.TryGetValue(xp.Key, out var xml))
                {
                    List<TradeComDinheiroGroupedDTO> GetTradesAgrupados(List<CreateOrUpdateComDinheiroTradeRequest> trds) => 
                        trds
                            .Where(t => t.GetIdAtivo().HasValue)
                            .GroupBy(t => new 
                            { 
                                t.DataCotizacao, 
                                IdAtivo = t.GetIdAtivo().Value,
                                IndCV = t.IndCV.Trim().ToUpper() == "C" ? "C" : "V"
                            })
                            .Select(t => new TradeComDinheiroGroupedDTO(
                                t.Key.DataCotizacao,
                                t.Key.IdAtivo,
                                t.Key.IndCV,
                                Math.Abs(t.Average(tt => tt.PrecoUnitario ?? 0m)),
                                Math.Abs(t.Sum(tt => tt.VlrTotalBruto ?? 0m)),
                                Math.Abs(t.Sum(tt => tt.Quantidade ?? 0m)),
                                t.ToList()
                            ))
                            .ToList();

                    var tradesXPAgrupadosByIndCV = GetTradesAgrupados(xp.Value.ToList());
                    var tradesXMLAgrupadosByIndCV = GetTradesAgrupados(xml.ToList());

                    foreach (var trdXML in tradesXMLAgrupadosByIndCV.GroupBy(t => new { t.DtCotizacao, t.IdAtivo }))
                    {
                        // XML
                        var trdsXMLMesmoAtivo = trdXML.ToList();

                        var nettingQtdXml = trdsXMLMesmoAtivo.Sum(t => (t.IndCV == "C" ? 1 : -1) * t.Qtd);
                        var nettingVlrXml = trdsXMLMesmoAtivo.Sum(t => (t.IndCV == "C" ? 1 : -1) * t.VlrFinanceiro);

                        // XP
                        var trdsXPMesmoAtivo = tradesXPAgrupadosByIndCV
                            .Where(t => t.DtCotizacao == trdXML.Key.DtCotizacao && t.IdAtivo == trdXML.Key.IdAtivo)
                            .ToList();

                        var nettingQtdXP = trdsXPMesmoAtivo.Sum(t => (t.IndCV == "C" ? 1 : -1) * t.Qtd);
                        var nettingVlrXP = trdsXPMesmoAtivo.Sum(t => (t.IndCV == "C" ? 1 : -1) * t.VlrFinanceiro);

                        // Vamos ajustar inicialmente em cenários de apenas 1 trade em cada uma das pontas
                        bool isSingleTrade = trdsXMLMesmoAtivo.Count == 1 && trdsXPMesmoAtivo.Count == 1;

                        var firstXML = trdsXMLMesmoAtivo.FirstOrDefault();
                        var firstXP = trdsXPMesmoAtivo.FirstOrDefault();

                        // Possui no XML mas não na API de cotização
                        if (nettingQtdXml != 0m && nettingQtdXP == 0m)
                        {
                            // Adiciona os trades do XML dentro da movimentação XP
                            // Movimentação XP não possui esta boleta
                            var newTradesToAdd = trdsXMLMesmoAtivo.SelectMany(t => t.List).ToList();

                            newTradesToAdd.ForEach(nt => nt.MsgAviso = "Trade não existia nas movimentações XP mas estava presente no XML");

                            xp.Value.AddRange(newTradesToAdd);
                        }
                        // Temos o trade nas duas pontas (quantidades diferentes de 0)
                        else if (nettingQtdXml != 0m && nettingQtdXP != 0m)
                        {
                            bool hasDiffQtd = Math.Abs(nettingQtdXml - nettingQtdXP) > 0.0001m; // Diferenças até a 4a casa decimal vamos ajustar

                            if (isSingleTrade) // Estamos tratando apenas um trade nas duas pontas
                            {
                                var firstXPItem = firstXP.List.First();
                                var firstXMLItem = firstXML.List.First();

                                if (firstXML.IndCV == firstXP.IndCV) // O indicador de compra/venda da boleta é igual
                                {
                                    if (hasDiffQtd) 
                                    {
                                        var diffQtd = Math.Abs(nettingQtdXml) - Math.Abs(nettingQtdXP);
                                        var qtdAtual = firstXPItem.Quantidade;
                                        
                                        if ((qtdAtual + diffQtd) >= 0)
                                        {
                                            firstXPItem.MsgAviso = $"Trade existente no XML ({nettingQtdXml:n4}) e nas movimentações XP ({nettingQtdXP:n4}), porém, com divergências de quantidade. A movimentação XP foi ajustada com a diferença entre ambas";
                                            firstXPItem.Quantidade = qtdAtual + diffQtd; // Vamos acertar a quantidade da boleta
                                            firstXPItem.VlrTotalBruto = firstXPItem.Quantidade * firstXPItem.PrecoUnitario;
                                        }
                                        else
                                        {
                                            _logger.LogTrace("A soma da quantidade atual + diferença fica menor que 0");
                                        }
                                    } 
                                    else if (nettingVlrXP == 0m && nettingVlrXml != 0m)
                                    {
                                        var diffVlr = Math.Abs(nettingVlrXml) - Math.Abs(nettingVlrXP);
                                        firstXPItem.VlrTotalBruto += diffVlr;
                                        firstXPItem.MsgAviso = $"Trade existente nas movimentações XP, porém, com financeiro zerado (no XML o financeiro não estava zerado)";
                                    }
                                }
                                else
                                {
                                    _logger.LogTrace("Indicador de compra e venda diferentes");
                                }
                            }
                            else
                            {
                                if (hasDiffQtd)
                                {
                                    _logger.LogTrace("Pendente tratar múltiplos trades");
                                }
                            }
                        }
                    }
                }
            }
        }
		
		
		
		
		
		
		
		if (trades.Any()) /* POSSÍVEL PONTO DE TRAVA, SE N HOUVER MOVIMENTAÇÕES XP ESSE TRECHO NAO SERÁ EXECUTADO*/
		if (tradesComDinheiroRequestXML != null && tradesComDinheiroRequest != null) /* POSSÍVEL PONTO DE TRAVA, SE N HOUVER MOVIMENTAÇÕES XP ESSE TRECHO NAO SERÁ EXECUTADO*/
		foreach (var xp in tradesComDinheiroRequest) // Ponto de Trava, se não houver trades XP não vai entrar aqui
        bool isSingleTrade = trdsXMLMesmoAtivo.Count == 1 && trdsXPMesmoAtivo.Count == 1; // Ponto de Trava, se não tiver igual nas duas pontas não vai passar, precisa suportar 0 aqui na ponta da XP


		Cenários
		TpFonte: MovXP, 0 Boletas de MovXP, Não tem boletas de XML
		TpFonte: MovXP, 0 Boletas de MovXP, Tem 1 Boleta de XML
		TpFonte: MovXP, 0 Boletas de MovXP, Tem N Boletas de XML
		TpFonte: MovXP, 1 Boleta de MovXP, Não tem boletas de XML
		TpFonte: MovXP, 1 Boleta de MovXP, Tem 1 Boleta de XML
		TpFonte: MovXP, 1 Boleta de MovXP, Tem N Boletas de XML
		TpFonte: MovXP, N Boletas de MovXP, Não tem boletas de XML
		TpFonte: MovXP, N Boletas de MovXP, Tem 1 Boleta de XML
		TpFonte: MovXP, N Boletas de MovXP, Tem N Boletas de XML (mais de uma)
		
		TpFonte: XML, Não tem boletas de XML
		TpFonte: XML, Tem 1 Boleta de XML
		TpFonte: XML, Tem N Boletas de XML
						
								
Caso Ruim (N tem o trade na Mov XP e é incluido o Trade do XML na Mov XP):
4759928
15/07/2024 - 19/07/2024 (Caso Ruim, pois o trade gerado pelo XML é adicionao na Movimentação XP, logo o equalize vai fucionar)


Caso bom (tem o trade na Mov XP e ele não é incluído na MovXP, )



Caso caminho Feliz Atual(Tem todos os Trades )	






				
				
				
				
ListaTrades 0
ListaTradesXML 	1 

Se o trade gerado a apartir do XML for de Caixa, adiciona na lista de Trades

ListaTrades 1
ListaTradesXML 	1





 


ListaTradesGeral




































SELECT
    Id_Cliente,
    COUNT(DISTINCT Convert(date, Dt_Operacao)) AS Contagem_Datas_Distintas
FROM
    xp_posi.Tb_Movimentacao_Carteira_XP
WHERE
    YEAR(Convert(date, Dt_Operacao)) = 2024
GROUP BY
    Id_Cliente
ORDER BY
    Id_Cliente;

SELECT
    Id_Cliente,
    COUNT(DISTINCT Convert(date, Dt_Posicao)) AS Contagem_Datas_Distintas
FROM
    xml.Tb_Header
WHERE
    YEAR(Convert(date, Dt_Posicao)) = 2024 AND Tp_Header = 'C'
GROUP BY
    Id_Cliente
ORDER BY
    Id_Cliente;





SELECT *
FROM
    xp_posi.Tb_Movimentacao_Carteira_XP
WHERE
    Id_Cliente = 782
    AND YEAR(Convert(date, Dt_Operacao)) = 2024
    AND MONTH(Convert(date, Dt_Operacao)) = 7
ORDER BY
    Dt_Operacao;


	SELECT *
FROM
    xml.Tb_Header
WHERE
    Id_Cliente = 782
    AND YEAR(Convert(date, Dt_Posicao)) = 2024
    AND MONTH(Convert(date, Dt_Posicao)) = 7
ORDER BY
    Dt_Posicao;


CARTEIRA - 4759928







# ISSUE

TASKS 

## 1. Resumo da Demanda

- **Título:**   
- **Descrição:**   
- **Solicitante:**   
- **Data da Solicitação:**

## 2. Objetivo

- **Motivo da importância:**   
- **Problema a ser resolvido ou oportunidade gerada:**   
- **Impacto esperado:** 

## 3. Requisitos Funcionais

- **O que o sistema precisa fazer?**   
- Descrição de funcionalidades:  
    - Casos de uso  
    - Atores envolvidos  
    - Cenários e regras de negócio

## 4. Requisitos Não Funcionais

- **Desempenho:**   
- **Segurança:**   
- **Escalabilidade:**   
- **Outros:**

## 5. Fluxo de Trabalho (Workflow)

- **Fluxograma:** (Incluir link para o fluxograma ou diagrama)  
- **Passo a passo das interações:**   
- **Diagramas UML:** (Opcional)

## 6. Regras de Negócio

- **Regras específicas:**

## 7. Critérios de Aceitação

- **Condições para considerar a demanda "pronta":**  
    - Funcionalidades implementadas  
    - Testes realizados  
    - Casos de uso aprovados  
    - Cenários de erro tratados

## 8. Dependências

- **Tecnológicas:**   
- **Equipes:**

## 9. Plano de Testes

- **Testes Unitários:**   
- **Testes de Integração:**   
- **Testes Manuais/Automatizados:**   
- **Critérios de aprovação dos testes:**

## 10. Plano de Implementação

- **Etapas do Desenvolvimento:**   
- **Tarefas:**   
    - Tarefa 1  
    - Tarefa 2  
- **Tecnologias/linguagens utilizadas:**

## 11. Prazo e Esforço Estimado

- **Data de Início:**   
- **Data de Entrega Prevista:**   
- **Esforço estimado:**   
- **Recursos alocados:**

## 12. Histórico de Alterações

- **Modificações:**   
    - Data  
    - Motivo  
    - Alterações realizadas

## 13. Considerações Finais

- **Riscos Identificados:**   
- **Pontos de Atenção:**   
- **Aprovações Necessárias:**




