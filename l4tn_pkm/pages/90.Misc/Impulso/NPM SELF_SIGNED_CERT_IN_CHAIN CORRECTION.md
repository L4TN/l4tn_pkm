- **# README — Instalar via npm ignorando certificado (Windows) ***(modo rápido e inseguro)*
  title:: NPM SELF_SIGNED_CERT_IN_CHAIN CORRECTION
  
  > **Aviso**: isto desativa validação TLS e usa HTTP. Use só para **destravar** a instalação. Recomendado **reverter** ao final.
  
  **## Copiar e colar (CMD do Windows)**
  
  > Ajuste o caminho do projeto na primeira linha, se preciso.
  
  ```bat
  
  cd /d C:\Users\matheus.dias\source\lambdas\whatsapp-orchestrator-agent
  
  :: Desliga verificação de certificado e SSL estrito
  
  set NODE_TLS_REJECT_UNAUTHORIZED=0
  
  set npm_config_strict_ssl=false
  
  :: Usa registry sem HTTPS (HTTP puro)
  
  npm config set registry http://registry.npmjs.org/ --location=project
  
  :: Remove CA custom em todos os níveis
  
  npm config delete cafile --location=project
  
  npm config delete cafile --location=user
  
  npm config delete cafile --location=global
  
  :: (Opcional) Evitar EBUSY no Windows
  
  taskkill /F /IM node.exe  >NUL 2>&1
  
  taskkill /F /IM Code.exe  >NUL 2>&1
  
  taskkill /F /IM WebStorm64.exe >NUL 2>&1
  
  :: Limpeza básica
  
  rmdir /s /q node_modules
  
  del /f /q package-lock.json
  
  npm cache clean --force
  
  :: Instala pulando scripts (evita postInstall via HTTPS)
  
  npm install --save-dev serverless@3.39.0 --ignore-scripts
  
  :: Conferência
  
  npx serverless --version
  
  ```
  
  **## Reverter (recomendado depois que terminar)**
  
  ```bat
  
  npm config delete registry --location=project
  
  npm config set strict-ssl true --location=project
  
  set NODE_TLS_REJECT_UNAUTHORIZED=
  
  ```
  
  ---
  
  **### Observações rápidas**
- Se o proxy da rede **redirecionar** HTTP→HTTPS, será necessário confiar no CA corporativo (modo seguro) em vez deste atalho.
- Para o modo seguro: usar `set NODE_OPTIONS=--use-openssl-ca=false` **ou** `NODE_EXTRA_CA_CERTS` apontando para um bundle PEM confiável.