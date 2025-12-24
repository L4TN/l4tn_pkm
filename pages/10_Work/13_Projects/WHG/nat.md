- Ver vídeo sobre as demandas da Tela do Bureau

2025-08-21 16-19-00
	Para tela de PLD:
	- Criar botão de aprovar análise ou desaprovar
	- Botão para Revisitar Análise (Simula as mesmas regras Link que foram rodadas)
	- Resultado comparativo deve ser armazenado
	
	Para tela de Bureau de Dados, armazenar as consultas para serem consultadas posteriormente
		- última vez a rodar, ela queria ver o resultado de fato daquela data 
			Exemplo 19/05/2025 -> tem que ver os resultados dessa data
	
2025-08-20 16-11-13
	- Criar um menu abaixo de dados chamado "Compliance", onde irá ficar o Bureau e o PLD Recon
	
	Para Tela do Bureau de Dados:
		1 - Incluir um campo contendo: “Biografia de vida” https://docs.bigdatacorp.com.br/plataforma/reference/pessoas_genai_description_gpt_x1_5
		O retorno de dados aqui será um texto resumo de todos os dados analisados
		2 - Incluir um campo de “Renda Estimada”	https://docs.bigdatacorp.com.br/plataforma/reference/marketplace_partner_datarisk_income_prediction_person
		
		- Se ignorar o cache, vamos apagar o arquivo atual mais recente e remontamos o arquivo
			- Aqui tem que ter vinculo com IdArquivo última consulta Bureau (mostrar na tela IdArquivo)
		- Se não batemos com o Cache, a expectativa é que peguemos a consulta salva naquela data e mostremos ela.
		- Quando selecionar outra pessoa ou fundo, limpar o Grid
		- Vamos tbm poder consultar Contrapartes: Administrador(Cad./Administrador), Gestor(Cad./Gestor), (Cad./Domínio/Contraparte), Securitizadoras (cad./ativo/Securitizadora ) e Emissor (cad./ativo/emissor), e vamos mostrar somente quem tem CPF/CNPJ.
			 - Colocar esses caras no combox de consulta do Bureau ("Consultar Pessoas" vai mudar),
			 - Dependendo do Combobox que vc selecionar, vamos dar enable false em um e enable true em outro dropdown de "Selecione a Pessoa:"
			 - então vai ter 4 Checkboxes (hj são duas: "Consulta Livre" e "Cadastro de Pessoas"), as 4 que vao ficar são: "Consulta Livre", "PF", "PJ", e "Contrapartes"
			 A grid se atualiza(APIs utilizadas) conforme 		 
		Will tinha achado melhor parquets por conta do grande volume de dados:
			- Bureau de Dados sempre vai ter alto volume de dados
			- Tela de PLD em seus resumos nao terá um alto volume de dados, mas quanto mais regras mais irá ter
	
# Tela PLD
Urgente e Importante (Fazer agora):
	- Ter apenas pessoas Físicas OK
	- Bug Blob OK
	- Perpetuar Arquivo da Análise para download (Resultado Comparativo, leve com todas as regras rodadas)/No resumo/Resultado Análse não ter apenas o Retorno do 
	- Adicionar botão de Fl_Regra_Aprovacap_Manual OK
	- Por Export no Grid(não é necessário criar relatório) OK
	- Ter visão portfólio e e Visão Regra igual tela de "Reconciliação Portfólio", ter todas as colunas de aprovação Manual tbm OK
	- Acertar d-1 para ser pegar sempre o penultimo (um antes da execucao atual), d-1 o dia atual menos 1, mas no nosso caso queremos ver o penultimo mesmo que ele tenha ocorrido 4 anos atras OK 
	- Se a última verificação foi feita a 4 meses atrás, pintamos alinha com uma cor de hit point OK 
	- Colocar IdUsu da exec atual e Idusu do anterior no master detail OK 

Não Urgente e Importante (Fazer quando possível):
	- Colocar observacao tanto no nivel do master(Edit) quanto no detail (view)
	
# Bureau de Dados mas também a comparação de Arquivos local e Bureau
	Para Tela do Bureau de Dados:
	
		Implementar novas APIs:
	
		1 - Incluir um campo contendo: “Biografia de vida” https://docs.bigdatacorp.com.br/plataforma/reference/pessoas_genai_description_gpt_x1_5
		O retorno de dados aqui será um texto resumo de todos os dados analisados ("DATASET DISABLED TEMPORARILY" mas vamos implementar mesmo assim)
		
		{  
			"Datasets": "genai_description_gpt_x1_5",
			"q": "doc{CPF}"  
		}  
				
		2 - Incluir um campo de “Renda Estimada”	https://docs.bigdatacorp.com.br/plataforma/reference/marketplace_partner_datarisk_income_prediction_person ()
		https://plataforma.bigdatacorp.com.br/marketplace
		{  
			"Datasets": "partner_datarisk_income_prediction_person", 
			"q": "doc{CPF}"  
		}  
		
		TEM UM CAMPO
		
		
		- Se ignorar o cache, vamos apagar o arquivo atual mais recente e remontamos o arquivo
			- Aqui tem que ter vinculo com IdArquivo última consulta Bureau (mostrar na tela IdArquivo)
		  Se não batemos com o Cache, a expectativa é que peguemos a consulta salva naquela data e mostremos ela.
		
		- Quando selecionar outra pessoa ou fundo, limpar o Grid
		
		- Vamos tbm poder consultar Contrapartes: 
			Administrador(Cad./Administrador), 
			Gestor(Cad./Gestor), 
			(Cad./Domínio/Contraparte), 
			Securitizadoras (cad./ativo/Securitizadora ) 
			Emissor (cad./ativo/emissor), e vamos mostrar somente quem tem CPF/CNPJ.
			
			 - Colocar esses caras no combox de consulta do Bureau ("Consultar Pessoas" vai mudar),
			 - Dependendo do Combobox que vc selecionar, vamos dar enable false em um e enable true em outro dropdown de "Selecione a Pessoa:"
			 - então vai ter 4 Checkboxes (hj são duas: "Consulta Livre" e "Cadastro de Pessoas"), as 4 que vao ficar são: "Consulta Livre", "PF", "PJ", e "Contrapartes" (na api de GetResumoPessoasForComplianceBureau hj, o retorno tem o tipo de pessoal se é física ou juridica("TpPessoa": "F" ou "TpPessoa": "I"/"TpPessoa": "J" entao vc consegue criar duas listas de selecao para esses checkboxes, a minha ideia é que ao mudar o checkbox selecionado, renderize um dropdown distinto pra cada um inves de um unico dropdown como é hj)
			 
			 
	 
	 import { HttpClient, HttpHeaders } from "@angular/common/http";
import { Injectable } from "@angular/core";
import { Observable } from "rxjs";
import { environment } from "../../../environments/environment";
import { Configuration } from "../configuration";
import { EmissorLookupResponse } from "../model/emissor/emissor-lookup-response.model";

@Injectable()
export class EmissorService {

    private configuration: Configuration
    private url: String = environment.prismaAPIHost + "/api/devex/emissores";
    private headers: HttpHeaders;

    constructor(public httpClient: HttpClient) {
        this.configuration = new Configuration();
        this.headers = new HttpHeaders();
        this.headers.set('Content-Type', 'application/json');
    }

    getLookup(): Observable<{ data: Array<EmissorLookupResponse> }> {
        return this.httpClient.get<{ data: Array<EmissorLookupResponse> }>(`${this.url}/get`, {
            headers: this.headers,
            withCredentials: this.configuration.withCredentials
        }).pipe(res => res)
    }
}

	 
	 
	 import { HttpClient, HttpHeaders } from "@angular/common/http";
import { Injectable } from "@angular/core";
import { Observable } from "rxjs";
import { environment } from "../../../environments/environment";
import { Configuration } from "../configuration";

@Injectable()
export class ContraparteService {

    private configuration: Configuration
    private url: String = environment.prismaAPIHost + "/api/devex/contraparte";
    private headers: HttpHeaders;

    constructor(public httpClient: HttpClient) {
        this.configuration = new Configuration();
        this.headers = new HttpHeaders();
        this.headers.set('Content-Type', 'application/json');
    }

    getContraparte(tpContraparte: string): Observable<any> {
      return this.httpClient.get<any>(`${this.url}/GetContraparte?tpContraparte=${tpContraparte}`, {
          headers: this.headers,
          withCredentials: this.configuration.withCredentials
      }).pipe(res => res)
    }

    getIsRunningPrefixos(idContraparte: number): Observable<boolean> {
        return this.httpClient.get<boolean>(`${this.url}/GetIsRunningPrefixos?idContraparte=${idContraparte}`, {
            headers: this.headers,
            withCredentials: this.configuration.withCredentials
        }).pipe(res => res);
    }
}

	 
	 import { HttpClient, HttpHeaders } from "@angular/common/http";
import { Injectable } from "@angular/core";
import { Observable } from "rxjs";
import { environment } from "../../../environments/environment";
import { Configuration } from "../configuration";
import { GestorLookupResponse } from "../model/gestor/gestor-lookup-response.model";

@Injectable()
export class GestorService {

    private configuration: Configuration
    private url: String = environment.prismaAPIHost + "/api/devex/gestores";
    private headers: HttpHeaders;

    constructor(public httpClient: HttpClient) {
        this.configuration = new Configuration();
        this.headers = new HttpHeaders();
        this.headers.set('Content-Type', 'application/json');
    }

    getLookup(indSortByNm: boolean): Observable<{ data: Array<GestorLookupResponse> }> {
        return this.httpClient.get<{ data: Array<GestorLookupResponse> }>(`${this.url}/get?indSortByNm=${indSortByNm}`, {
            headers: this.headers,
            withCredentials: this.configuration.withCredentials
        }).pipe(res => res)
    }
}

	 
	 import { HttpClient, HttpHeaders } from "@angular/common/http";
import { Injectable } from "@angular/core";
import { Observable } from "rxjs";
import { environment } from "../../../environments/environment";
import { Configuration } from "../configuration";
import { AdministradorLookupResponse } from "../model/administrador/administrador-lookup-response.model";

@Injectable()
export class AdministradorService {

    private configuration: Configuration
    private url: String = environment.prismaAPIHost + "/api/devex/administradores";
    private headers: HttpHeaders;

    constructor(public httpClient: HttpClient) {
        this.configuration = new Configuration();
        this.headers = new HttpHeaders();
        this.headers.set('Content-Type', 'application/json');
    }

    getLookup(indSortByNm: boolean): Observable<{ data: Array<AdministradorLookupResponse> }> {
        return this.httpClient.get<{ data: Array<AdministradorLookupResponse> }>(`${this.url}/get?indSortByNm=${indSortByNm}`, {
            headers: this.headers,
            withCredentials: this.configuration.withCredentials
        }).pipe(res => res)
    }
}

	 
	 
	 import { Injectable } from "@angular/core";
import CustomStore from "devextreme/data/custom_store";
import { SecuritizadoraService } from "../../rest/api/securitizadora.service";


@Injectable()
export class ListaSecuritizadoraService {
  constructor(
    public securitizadoraService: SecuritizadoraService,
  ) { }

  public getSecuritizadoras(): any {
    return {
      paginate: true,
      pageSize: 20,
      loadMode: 'raw',
      store: new CustomStore({
        key: "IdSecuritizadora",
        loadMode: "raw",
        cacheRawData: true,
        load: async () => {
            var result = await this.securitizadoraService.getLookup().toPromise();
            return result.data;
        }
      })
    };
  }

}


Bureau
Colocar o tipo da contraparte (ícone para cada tipo de contraparte) (Usar checkbox)
Nome, documento(cnpj), tipo(required), ultima verificacao (regra required tbm)

tipo(required), ultima verificacao (regra required tbm)
no get/view trazer os status de cada pessoas com base nas regras(visualização rápida)
inverter ordem de botao de consulta e processar (deixar como toolbar)
Pesnar estrutura de Background(PubSub) ou Fila Processamento para 

PLD
Adapdatar a tela para ter a chave forte como a pessoa (igual a recon) (selecao de pessoas, NOK etc )
mudar obs(do sistema ) para detalhe (sistema )
No Consultar trazer todos os dados que tem
No Processar validar um Nr Maximo de Pessoas para Executar 
Sinalizar quando a pessoa foi rodada ou nao
Colocar Data por regra e hora no resumo geral (download pld)