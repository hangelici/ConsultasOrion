WITH cargas_filtradas AS (
    SELECT
        lcd."Id",
        lcd."Guid",
        lcd."EmpresaId",
        lcd."DestinoId",
        lcd."DataCriacao",
        lcd."DescrLocalEmbarque"
    FROM "log_CargaDado" lcd
    WHERE
        lcd."CargaTipoStatusId" <> 7
        AND EXISTS (
            SELECT 1
            FROM "sys_Workflow" sw
            WHERE sw."Referencia" = lcd."Guid"
            AND sw."WorkflowAcaoId" IN (18,16)
        )
        AND NOT EXISTS (
            SELECT 1
            FROM "sys_Workflow" sw
            WHERE sw."Referencia" = lcd."Guid"
            AND sw."WorkflowAcaoId" IN (5,12,13,14,9)
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
workflow_16_18 AS (
    SELECT
        cf."Guid",
        sw."DataCriacao"
    FROM cargas_filtradas cf
    LEFT JOIN LATERAL (
        SELECT
            sw."DataCriacao"
        FROM "sys_Workflow" sw
        WHERE sw."Referencia" = cf."Guid"
        AND sw."WorkflowAcaoId" IN (18,16)
        ORDER BY sw."Id" DESC
        LIMIT 1
    ) sw ON true
)
SELECT DISTINCT
    cf."Id",
    swa."Descricao" as "Status",
    emp."NomeFantasia" as "Filial",
    si."Descricao" as "Produto",
    lv."Placa",
    cf."DataCriacao",
    cf."DescrLocalEmbarque" as "Embarque",
    sem."Nome"||'-'||se."UF" as "Desembarque",
    (EXTRACT(EPOCH FROM (current_timestamp - wa."DataCriacao")) / 60)::int as "Min",
    (EXTRACT(EPOCH FROM (current_timestamp - wf."DataCriacao")) / 60)::int as "Min_Total"
FROM cargas_filtradas cf
LEFT JOIN workflow_atual wa ON wa."Guid" = cf."Guid"
LEFT JOIN workflow_16_18 wf ON wf."Guid" = cf."Guid"
LEFT JOIN "sys_WorkflowAcao" swa ON swa."Id" = wa."WorkflowAcaoId"
LEFT JOIN "sys_Pessoa" sp ON sp."Id" = cf."DestinoId"
LEFT JOIN "sys_EstadoMunicipio" sem ON sem."Id" = sp."MunicipioId"
LEFT JOIN "sys_Estado" se ON se."Id" = sem."EstadoId"
LEFT JOIN "log_CargaTran" lct ON lct."CargaDadoId" = cf."Id"
LEFT JOIN "log_Veiculo" lv ON lv."Id" = lct."VeiculoId"
LEFT JOIN "log_CargaItem" lci ON lci."CargaDadoId" = cf."Id"
LEFT JOIN "sys_Item" si ON si."Id" = lci."ProdutoId"
LEFT JOIN "sys_Empresa" emp ON emp."Id" = cf."EmpresaId"
WHERE
swa."Id" not  (54,3,1,2,45)
AND si."ItemGrupoId" = 2