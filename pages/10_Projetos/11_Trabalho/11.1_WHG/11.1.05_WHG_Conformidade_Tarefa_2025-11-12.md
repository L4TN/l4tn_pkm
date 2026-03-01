# Tasks
- Compliance
  collapsed:: true
	- Ajustar bug de botão que desabilita após passar do limite, e ele não volta a habilitar
	- Verificar APIs que não estão retornando e Remover APIs que dao erro de Disabled etc
	- ![image.png](../assets/image_1762378372405_0.png){:height 430, :width 1248}
	- Ao preencher CPF ou CNPJ, mudo a lista de Categorias
	- ![image.png](../assets/image_1762378160432_0.png)
	- O Mak no Bureau nao aparece como PEP, mas em PLD aparece, pq ? sao duas apis diferentes?
	- ![image.png](../assets/image_1761313415874_0.png)
	-
- Ajustar Segregações de Acesso de Bureau e PLD
  collapsed:: true
	- Ajustar Descrição de Path dos Componentes do Bureau, PLD e Regras PLD
	- Quebrar APIs de PLD_REG_GET e CAD_PLD_REG_UPD em (GETs, PUTs, UPDs e DOWN)
	- ![image.png](../assets/image_1761233758078_0.png)
	- ![image.png](../assets/image_1761233766589_0.png)
	  NAO PODE TER APENAS UPD, TEM QUE TER SÓ OS GETS
	-
	- ![image.png](../assets/image_1761233820953_0.png)
	  ALTERAR CADASTRO DO CAMINHO
	-
	-
	-
	- ![image.png](../assets/image_1761233846545_0.png)
	- QUEBRAR EM GET UPD DOWNLOAD
	-
	- ![image.png](../assets/image_1761233897626_0.png)
	  REMOVER API ANTIGA
	- FUNCIONALIDADE PARA DOWNLOAD (PARA APARECER BUTTON DE DOWNLOAD OU NAO )
	- arrumar caminho no cad
	- tela de reprocessamentos resolver bug
	- ![image.png](../assets/image_1761234104598_0.png)
	-
	- cad regras separar get do PUT
	-
	-
	- Segregação de acessos entre GET (apenas consulta), UPD (processamento e atualização) e DOWN (download dos arquivos e retornos)
	- Diminuir combo de Data para ter mais espaço ao layer “Última Data”
	- Segregação de acessos entre GET (apenas consulta), UPD (processamento e atualização) e DOWN (download dos arquivos e retornos)
- Guardian
  collapsed:: true
	- Criar Tela de Worker (ao clicar em webjob abrir uma tela ou modal para o Worker)
	- Add jobs faltantes (alguns jobs não estão comtemplados, por todos)
	- Rotina de erros para o WebJobDataLake (adicionar nos checks opção para ver todos os erros ou só os erros específicos)
	- tAB DE WORKER E TAB DE WEBJOB
	- ![image.png](../assets/image_1761245785829_0.png) 
	  ![image.png](../assets/image_1761245613094_0.png)
	- Dias.. Tem duas forma de fazer:
	- Colocar deixar o Guardian mandar erro de tudo que acontecer, e usamos essa config só para indicar o que deve ser exceção para NÃO enviar erro de tudo;
	- Usar essa config só para indicar o que DEVE enviar erro de tudo;
	  Eu particularmente prefiro a primeira. Assim a gente consegue ir verificando o que de fato deve ser ignorado.
	- Somente hj ou Ultima Execau habilitados deixam disable as datas Guardian
	- Monatr time line de worker com os dados do insights (o objetivo é ver a concorrencia)
- XP Auth Migração
  collapsed:: true
	- Passos Mak
	-
- Migração Consolidação
  collapsed:: true
	- Documento Excel
	-
- Suportes Consolidação
  collapsed:: true
	- Ativos
		- Trocar 12585 -> 12622 (Gabigol)
		- Excluir 34684 (Pedro)
	- Add Caixa no AT para evitar problema de retorno netado pelo AT (Cotrim)
	- Match de Ativo não víncula (Vinicius)
	- Boleta de Compromissadas, taxa errada,  id produto faltando (Cotrim)
	-
-
- Prioridade (Matrix de Einshowver)
- XP Auth Migração -Importante e Urgente
- Compliance - Importante e Urgente
- Guardian - Importante e Não Urgente
- Migração Consolidação - Importante e Não Urgente
- Suportes Consolidação - Não Importante e Não Urgente
-
-
-
-