Minha empresa é a ImpulsoCore

E fizemos um fork  do projeto Chatwoot do Github, vamos personalizar o sistema para nossas necessidades

Passo a passo para subir imagem do chatwoot docker
Criar conta no Docker hub
npm config set registry http://registry.npmjs.org/
rodar dentro da pasta do projeto
git rm --cached -r .
git reset --hard
rodar dentro da pasta do projeto do Chatwoot
docker login (Tem que estar logado, vai ter verificacao de one time code entre cmd e browser auth)
rm -rf spec/enterprise (estar no gitbash)
rm -rf enterprise (estar no gitbash)
echo -en '\nENV CW_EDITION="ce"' >> docker/Dockerfile
docker buildx build --no-cache --push  --tag seu-nome-usuario-docker/chatwoot-dev:v1 -f ./docker/Dockerfile . (Estar com o Docker e seu Docker engine rodando e precisa ter criado anres o repositorio 'chatwoot-dev', esse comando nao cria automaticamente e dá falha sem explicar o erro)
Se os comandos acima derem erro de SSL, no dockerfile adicionar esse bypass de certificado:
RUN npm config set strict-ssl false (linha 45)

Etapa 2 - Deploy na Cloud para Máquina Virtual do EC2
Abra a AWS Console da Cloud
Para conectar na maquina da Cloud EC2 precisamos adicionar nosso IP a lista de IPs permitidos na AWS
Pegamos nosso IP no site MeuIP - Qual o meu IP ?
Vamos em VPC e em Security\Security Groups, criamos um grupo ou atualizamos o já existente
Selecionamos o Grupo e clicamos em 'Action\Edit Inbound Rules':
Adicionamos uma role do 'Type' SSH e adicionamos nosso IP, na 'Description' colocamos de quem é esse IP
*Não se pode ter dois IPs em duplicidades/iquais, então um IP só pode estar em uma única regra 
Após isso podemos ir ao serviço EC2 e selecionamos a instancia que queremos conectar e clicamos em 'Connect'
Selecionamos a guia 'SSH Cliente', a aws irá prover o comando windows para conectar na instancia da maquina virtual do EC2
*Também podemos usar o WinSCP
Conectando dentro da maquina do EC2, iremos puxar a imagem do Docker

sudo nano /home/ubuntu/docker-compose.yaml
sudo docker login 
sudo docker compose pull
sudo docker compose up -d rails sidekiq
sudo nginx -t && sudo systemctl reload nginx (Reinicio o serviço pra subir as ultimas atualizacoes do meu Web App Chatwoot


Duvida, o container do Chatwoot serve apenas para executar o build do compilado ou se serve tbm para desenvolver ? Eu preciso editar o codigo e sei que tentar rodar o repositorio no meu windows vai ser doloroso devido as dependencias, ent queria editar o codigo dentro do docker e rodar localhost pra verificacao