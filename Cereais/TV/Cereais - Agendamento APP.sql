-- ### AGENDAMENTO - PAINEL
WITH cargas_filtradas AS (
    SELECT
        lcd."Id",
        lcd."Guid",
        lcd."EmpresaId",
        lcd."DestinoId",
        lcd."Descarga",
        lcd."DataCriacao",
        lcd."DescrLocalEmbarque",
        lcd."CargaDemandaLoteId"
    FROM "log_CargaDado" lcd
    WHERE
        lcd."CargaTipoStatusId" <> 7
        AND lcd."Descarga"::date < CURRENT_DATE + 5
        AND lcd."Descarga" NOT IN ('infinity','-infinity')

        AND EXISTS (
            SELECT 1
            FROM "sys_Workflow" sw
            WHERE sw."Referencia" = lcd."Guid"
            AND sw."WorkflowAcaoId" = 5
        )

        AND NOT EXISTS (
            SELECT 1
            FROM "sys_Workflow" sw
            WHERE sw."Referencia" = lcd."Guid"
            AND sw."WorkflowAcaoId" IN (12,13,19,14)
        )
),
workflow_atual AS (
    SELECT
        cf."Guid",
        sw."WorkflowAcaoId",
        sw."DataCriacao"
    FROM cargas_filtradas cf
    LEFT JOIN LATERAL (
        SELECT
            sw."WorkflowAcaoId",
            sw."DataCriacao"
        FROM "sys_Workflow" sw
        WHERE sw."Referencia" = cf."Guid"
        ORDER BY sw."Id" DESC
        LIMIT 1
    ) sw ON true
),
workflow_5 AS (
    SELECT
        cf."Guid",
        sw."DataCriacao"
    FROM cargas_filtradas cf
    LEFT JOIN LATERAL (
        SELECT
            sw."DataCriacao"
        FROM "sys_Workflow" sw
        WHERE
            sw."Referencia" = cf."Guid"
            AND sw."WorkflowAcaoId" = 5
        ORDER BY sw."Id" DESC
        LIMIT 1
    ) sw ON true
),
workflow_ag16 AS (
    SELECT DISTINCT ON (sw."Referencia")
        sw."Referencia",
        sw."WorkflowAcaoId",
        sw."DataCriacao"
    FROM "sys_Workflow" sw
    WHERE sw."WorkflowAcaoId" IN (16)
    ORDER BY sw."Referencia", sw."Id" DESC
),
workflow_ag AS (
    SELECT DISTINCT ON (sw."Referencia")
        sw."Referencia",
        sw."WorkflowAcaoId",
        sw."DataCriacao"
    FROM "sys_Workflow" sw
    WHERE sw."WorkflowAcaoId" IN (16,18)
    ORDER BY sw."Referencia", sw."Id" ASC
)
SELECT 
    cf."Id",
    swa."Descricao" as "Status",
    emp."NomeFantasia" as "Filial",
    si."Descricao" as "Produto",
    lv."Placa",
    cf."DataCriacao",
    cf."DescrLocalEmbarque" as "Embarque",
    sem."Nome"||'-'||se."UF" as "Desembarque",
    cf."Descarga",
    case
    	when (cf."Descarga"::date - current_date) >= 3 then 'D3'
    	when (cf."Descarga"::date - current_date) = 2 then 'D2'
    	when (cf."Descarga"::date - current_date) = 1 then 'D1'
    	when (cf."Descarga"::date - current_date)  = 0 then 'D0'
    	else 'D-'
    end "Descarga_regra",
    (EXTRACT(EPOCH FROM (current_timestamp - wf5."DataCriacao")) / 60)::int as "Min",
    ROUND(EXTRACT(EPOCH from (current_timestamp - coalesce(ag16."DataCriacao",ag."DataCriacao"))) / 60,0) as "Min_Total",
    EXTRACT(DAY FROM (cf."Descarga" - current_timestamp)) as "Dias",
    case
        when current_date >= cf."Descarga"::date then 'vermelho'
        when cf."Descarga"::date - current_date < 2 then 'amarelo'
        else 'verde'
    end cor,
    lcdo."Distancia",
    round(nullif(lcdo."Distancia",0)/30,0) as "TempoHora"
FROM cargas_filtradas cf
LEFT JOIN workflow_atual wa ON wa."Guid" = cf."Guid"
LEFT JOIN workflow_5 wf5 ON wf5."Guid" = cf."Guid"
LEFT JOIN "sys_WorkflowAcao" swa ON swa."Id" = wa."WorkflowAcaoId"
LEFT JOIN "sys_Pessoa" sp ON sp."Id" = cf."DestinoId"
LEFT JOIN "sys_EstadoMunicipio" sem ON sem."Id" = sp."MunicipioId"
LEFT JOIN "sys_Estado" se ON se."Id" = sem."EstadoId"
LEFT JOIN "log_CargaTran" lct ON lct."CargaDadoId" = cf."Id"
LEFT JOIN "log_Veiculo" lv ON lv."Id" = lct."VeiculoId"
LEFT JOIN "log_CargaItem" lci ON lci."CargaDadoId" = cf."Id"
LEFT JOIN "sys_Item" si ON si."Id" = lci."ProdutoId"
LEFT JOIN "sys_Empresa" emp ON emp."Id" = cf."EmpresaId"
LEFT JOIN workflow_ag ag on ag."Referencia" = cf."Guid"
LEFT JOIN workflow_ag16 ag16 on ag16."Referencia" = cf."Guid"
LEFT JOIN "log_CargaDemandaLote" lcdl on lcdl."Id" = cf."CargaDemandaLoteId"
LEFT JOIN "log_CargaDemandaOportunidade" lcdo on lcdo."Id" = lcdl."CargaDemandaOportunidadeId"