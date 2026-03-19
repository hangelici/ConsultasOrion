-- ### AGENDAMENTO - PAINEL
WITH cargas_filtradas AS (
    SELECT
        lcd."Id",
        lcd."Guid",
        lcd."EmpresaId",
        lcd."DestinoId",
        lcd."Descarga",
        lcd."DataCriacao",
        lcd."DescrLocalEmbarque"
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
    end "descarga_regra",
    (EXTRACT(EPOCH FROM (current_timestamp - wf5."DataCriacao")) / 60)::int as "Min",
    EXTRACT(DAY FROM (cf."Descarga" - current_timestamp)) as "Dias",
    case
        when current_date >= cf."Descarga"::date then 'vermelho'
        when cf."Descarga"::date - current_date < 2 then 'amarelo'
        else 'verde'
    end cor
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