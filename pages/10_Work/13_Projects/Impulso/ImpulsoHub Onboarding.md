### 1) Instância (sua instalação) e Super Admin

Espaço reservado ao dono do Sistema, a própria ImpulsoCore
O Consolde de Super Admin é “andar do síndico”: só quem cuida da instalação acessa `/super_admin` e vê tudo.

O **primeiro usuário** já nasce super admin. Cliente **não** recebe isso. 
(docs: [https://developers.chatwoot.com/self-hosted/monitoring/super-admin-sidekiq](https://developers.chatwoot.com/self-hosted/monitoring/super-admin-sidekiq?utm_source=chatgpt.com)) [Chatwoot Docs](https://developers.chatwoot.com/self-hosted/monitoring/super-admin-sidekiq?utm_source=chatgpt.com)
- ### 2) Account (workspace do cliente)
  
  Cada cliente fica em **uma account** separada (multi-tenant). É dentro da account que você conecta canais, convida time, etc. (docs: [https://developers.chatwoot.com/](https://developers.chatwoot.com/?utm_source=chatgpt.com) & discussão multi-tenant: [https://github.com/chatwoot/chatwoot/issues/7490](https://github.com/chatwoot/chatwoot/issues/7490?utm_source=chatgpt.com)) [Chatwoot Docs+1](https://developers.chatwoot.com/?utm_source=chatgpt.com)
- ### 3) Papéis dentro da account (Administrator / Agent)
  
  Papel **Administrator** configura a account; **Agent** atende conversas. Esses papéis valem **só** naquela account. (user guide: [https://www.chatwoot.com/hc/user-guide/en/categories/chatwoot-101](https://www.chatwoot.com/hc/user-guide/en/categories/chatwoot-101?utm_source=chatgpt.com) ; adding agents: [https://www.chatwoot.com/hc/user-guide/articles/1677482414-adding-agents](https://www.chatwoot.com/hc/user-guide/articles/1677482414-adding-agents?utm_source=chatgpt.com) ; contexto de roles: [https://github.com/chatwoot/chatwoot/issues/4216](https://github.com/chatwoot/chatwoot/issues/4216?utm_source=chatgpt.com)) [Chatwoot+2Chatwoot+2](https://www.chatwoot.com/hc/user-guide/en/categories/chatwoot-101?utm_source=chatgpt.com)
- ### 4) Inbox (canais)
  
  “Inbox” é a porta de entrada (WhatsApp, E-mail, Website, IG, etc.). Você cria/gerencia inboxes **por account**. (API ref criar/listar inbox: [https://developers.chatwoot.com/api-reference/inboxes/create-an-inbox](https://developers.chatwoot.com/api-reference/inboxes/create-an-inbox?utm_source=chatgpt.com) , [https://developers.chatwoot.com/api-reference/inboxes/get-an-inbox](https://developers.chatwoot.com/api-reference/inboxes/get-an-inbox?utm_source=chatgpt.com) ; user guide: [https://www.chatwoot.com/hc/user-guide/articles/1677492191-adding-inboxes](https://www.chatwoot.com/hc/user-guide/articles/1677492191-adding-inboxes?utm_source=chatgpt.com)) [Chatwoot Docs+2Chatwoot Docs+2](https://developers.chatwoot.com/api-reference/inboxes/create-an-inbox?utm_source=chatgpt.com)
- ### 5) Entidades de atendimento
  
  **Contacts → Conversations → Messages**: um contato pode ter várias conversas; cada conversa tem mensagens. (API: contacts→conversations [https://developers.chatwoot.com/api-reference/contacts/contact-conversations](https://developers.chatwoot.com/api-reference/contacts/contact-conversations?utm_source=chatgpt.com) ; messages API overview [https://developers.chatwoot.com/api-reference/introduction](https://developers.chatwoot.com/api-reference/introduction?utm_source=chatgpt.com)) [Chatwoot Docs+1](https://developers.chatwoot.com/api-reference/contacts/contact-conversations?utm_source=chatgpt.com)
- ### 6) Camadas de API
- **Application APIs**: agem **dentro da account** (agents, inboxes, contacts, conversations, messages). (docs: [https://developers.chatwoot.com/contributing-guide/chatwoot-apis](https://developers.chatwoot.com/contributing-guide/chatwoot-apis?utm_source=chatgpt.com)) [Chatwoot Docs](https://developers.chatwoot.com/contributing-guide/chatwoot-apis?utm_source=chatgpt.com)
- **Platform APIs**: para **admins da instalação** (users, accounts, roles) — automação/provisionamento. (docs: [https://developers.chatwoot.com/contributing-guide/chatwoot-platform-apis](https://developers.chatwoot.com/contributing-guide/chatwoot-platform-apis?utm_source=chatgpt.com)) [Chatwoot Docs](https://developers.chatwoot.com/contributing-guide/chatwoot-platform-apis?utm_source=chatgpt.com)
  
  Regras de ouro: 
  **Cliente = uma Account + papéis (Admin/Agent) dentro dela; Super Admin só para você.**
- **Um Cliente pode pertencer a N empresas**
- Deve haver um usuário Administrador para a ImpulsoCore que está em todas as empresas
-
- Tutorial para criar Account/Empresa:
- Logar com a conta Principal da ImpulsoCore
- Login: ascii01000000@gmail.com
- Senha: 2025_Mat_Senior
- ![Untitled.png](../assets/Untitled_1760895107064_0.png)
-
- Vai em Account e dps em New Account:
- ![Untitled.png](../assets/Untitled_1760895285932_0.png)
- Usuario s[o tem Role quando esta dentro de uma empresa
- dar destroy num usuario so destroi ele dentro da empresa, nao destroi o usuario em si
- Usuario por si so, so tem o type, e ai deixamos em branco (ou deixamos SuperAdmin ou nao deixamos nada)
-
-