SELECT
    CAST(abm."Id" AS INTEGER) AS "ID",
    CAST(se."Integra" AS INTEGER) AS "ESTAB",
    CAST(abm."Integra" AS INTEGER) AS "TICKET",
    CAST(abc."Integra" AS INTEGER) AS "ROMANEIOCONFIG",
    CAST(coalesce(sy."Integra",0) AS INTEGER) AS "ITEM",
    bc."DataCriacao" as "DATACRIACAO",
    
    -- Conversão explícita para TIMESTAMP
    
    CASE
        WHEN abm."DataEntrada" = '-infinity' THEN null
        when extract(year from abm."DataEntrada") < 2000 then null
        ELSE CAST(abm."DataEntrada" AS TIMESTAMP)
    END AS "DATAENTRADA",
    
    CASE
        WHEN abm."DataEncEntrada" = '-infinity' THEN null
        when extract(year from abm."DataEncEntrada") < 2000 then null 
        when abc."BalancaOperacaoId" = 2 then CAST(abm."DataEncEntrada" AS TIMESTAMP)
        ELSE "movimenta"."DataC"--CAST(abm."DataEncEntrada" AS TIMESTAMP)
    END AS "DATAENCENTRADA",
    
    CASE
        WHEN abm."DataSaida" = '-infinity' THEN null
        -- p/ carregamento
        when abc."BalancaOperacaoId" = 2 and "saida_16"."DataCriacao" < abm."DataSaida" then "saida_16"."DataCriacao"
        when abc."BalancaOperacaoId" = 2 and "saida_16"."DataCriacao" > abm."DataSaida" then abm."DataSaida"
        ELSE CAST(abm."DataSaida" AS TIMESTAMP)
    END AS "DATASAIDA",
    
    CASE
        WHEN abm."DataEncSaida" = '-infinity' THEN NULL
        -- p/ carregamento
        when abc."BalancaOperacaoId" = 2 and "saida"."DataCriacao" is not null then "saida"."DataCriacao"
        ELSE CAST(abm."DataEncSaida" AS TIMESTAMP)
    END AS "DATAENCSAIDA",
    
    CASE
        WHEN abm."DataChamada" = '-infinity' THEN NULL
        ELSE CAST(abm."DataChamada" AS TIMESTAMP)
    END AS "DATACHAMADA",
    
    CASE
        WHEN abm."CheckIn" = '-infinity' THEN NULL
        ELSE CAST(abm."CheckIn" AS TIMESTAMP)
    END AS "CHECKIN",
    
   /* case
    	when "saida_50"."DataCriacao" is null  and abm."DataSaida" = '-infinity' then null
    	when "saida_50"."DataCriacao" is null  and abm."DataSaida" <> '-infinity' then CAST(abm."DataSaida" AS TIMESTAMP)
    	when "saida_50"."DataCriacao" > abm."DataEncSaida" and  abm."DataEncSaida" <>  '-infinity'  then CAST(abm."DataSaida" AS TIMESTAMP)
    	else "saida_50"."DataCriacao"
    end
      "DATAFECHAPESO", */
    
    NULLIF(
    CASE
        when "saida_50"."DataCriacao" is null  
             and abm."DataSaida" = '-infinity' then null

        when "saida_50"."DataCriacao" is null  
             and abm."DataSaida" <> '-infinity' then CAST(abm."DataSaida" AS TIMESTAMP)

        when "saida_50"."DataCriacao" > abm."DataEncSaida" 
             and abm."DataEncSaida" <> '-infinity' then CAST(abm."DataSaida" AS TIMESTAMP)

        else "saida_50"."DataCriacao"
    end,
    '-infinity'
) AS "DATAFECHAPESO",
    
    CASE
        WHEN abm."DataEncSaida" = '-infinity' THEN NULL
        ELSE CAST(abm."DataEncSaida" AS TIMESTAMP)
    END as "DATAENCFECHAPESO"
    
FROM "aut_BalancaMovimento" abm
LEFT JOIN "sys_Empresa" se ON se."Id" = abm."EmpresaId"
LEFT JOIN "aut_BalancaConfiguracao" abc ON abc."Id" = abm."BalancaConfiguracaoId"
left join "sys_Item" sy on sy."Id" = abm."ProdutoId"
left join (
	select
	"BalancaMovimentoId",
	max(abc."DataCriacao") as "DataC"
	from
	"aut_BalancaClassificacao" abc
	group by "BalancaMovimentoId"
)"movimenta" on
"movimenta"."BalancaMovimentoId" = abm."Id"
left join "log_CargaDado" lcd on lcd."Id" = abm."CargaDadoId"
left join (
		select
		sw."Referencia",
		sw."DataCriacao"
		from "sys_Workflow" sw
		inner join (
			select
			sw1."Referencia",
			min(sw1."Id") as "idmax"
			from "sys_Workflow" sw1
			where
			sw1."WorkflowAcaoId" = 46
			-- Aguardando Aprovar Classificação
			group by sw1."Referencia"
		)"maximo" on
		"maximo"."Referencia" = sw."Referencia"
		and "maximo"."idmax" = sw."Id"
	)"saida" on
	"saida"."Referencia" = lcd."Guid"
left join (
		select
		sw."Referencia",
		sw."DataCriacao"
		from "sys_Workflow" sw
		inner join (
			select
			sw1."Referencia",
			min(sw1."Id") as "idmax"
			from "sys_Workflow" sw1
			where
			sw1."WorkflowAcaoId" = 16
			-- Aguardando Classificação
			group by sw1."Referencia"
		)"maximo" on
		"maximo"."Referencia" = sw."Referencia"
		and "maximo"."idmax" = sw."Id"
	)"saida_16" on
	"saida_16"."Referencia" = lcd."Guid"
left join (
		select
		sw."Referencia",
		sw."DataCriacao"
		from "sys_Workflow" sw
		inner join (
			select
			sw1."Referencia",
			min(sw1."Id") as "idmax"
			from "sys_Workflow" sw1
			where
			sw1."WorkflowAcaoId" = 50
			-- Classificação Aprovada- Aguardando Fechar Peso
			group by sw1."Referencia"
		)"maximo" on
		"maximo"."Referencia" = sw."Referencia"
		and "maximo"."idmax" = sw."Id"
	)"saida_50" on
	"saida_50"."Referencia" = lcd."Guid"
	
left join (
    SELECT DISTINCT ON ("BalancaMovimentoId")
        "BalancaMovimentoId",
        "DataCriacao",
        "DataOperacao",
        "DataConclusao"
    FROM "aut_BalancaClassificacao"
    ORDER BY "BalancaMovimentoId", "DataOperacao" DESC NULLS LAST, "DataConclusao" DESC NULLS LAST
) bc
    ON bc."BalancaMovimentoId" = abm."Id"
	
	
WHERE
   --  CAST(abm."DataCriacao" AS DATE) >= '2024-07-01'
   -- AND abm."DataCriacao" >= '2025-07-01 00:00:00'::timestamp
      abm."DataEntrada" IS NOT NULL
  AND abm."DataEntrada" <> '-infinity'
 -- AND abm."DataEntrada" >= '2025-07-01 00:00:00'::timestamp
 -- AND abm."DataEntrada" >= NOW() - INTERVAL '2 months'
 -- AND abm."DataEntrada" >= date_trunc('day', CURRENT_DATE - INTERVAL '3 months')  
AND abm."Cancelado" = false
AND abm."DataEntrada" >= DATE '2026-01-01'


