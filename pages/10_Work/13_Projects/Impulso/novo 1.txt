Eu tenho uma logica lambda na aws para criar eventos

a entrada da api/api gateway é assim:

    {
      "eventId": "boas_vindas",
      "phoneNumbers": ["+5532999999999", "+5532988888888"],
      "daysOfWeek": ["MON","WED","FRI"],
      "time": "09:00",
      "messageTemplate": "Bem-vindo! Qualquer dúvida, responda este WhatsApp.",
      "enabled": true
    },
	
	Dropdown
		Msg Unica (Template de msg e Horario igual para um unico dia)
		Msg Lote (Template de msg e Horario para cada dia)
		*Dia de Inicio e Fim (Tá dentro do periodo + é o dia marcado ?)
		Anexo csv
		
		
	Na tela de cadastro do Evento
		registra um evento, dentro dele tem um upload e CSV com todos os leads
		1 
	