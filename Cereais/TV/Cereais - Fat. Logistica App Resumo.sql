--- ### Responsavel Logistica
WITH workflow_max AS (
    SELECT
        sw."Referencia",
        MAX(sw."Id") as maxid
    FROM "sys_Workflow" sw
    GROUP BY sw."Referencia"
),
workflow_filtrado AS (
    SELECT
        sw."Referencia",
        sw."WorkflowAcaoId",
        sw."DataCriacao"
    FROM workflow_max w
    JOIN "sys_Workflow" sw
        ON sw."Id" = w.maxid
       AND sw."Referencia" = w."Referencia"
    WHERE sw."WorkflowAcaoId" IN (18,27,28,50)
)
SELECT
acao."Descricao" as "Status",
count(lcd."Id") as "Min",
count(lcd."Id") as "Min_Total"
FROM "log_CargaDado" lcd
JOIN workflow_filtrado flow ON flow."Referencia" = lcd."Guid"
LEFT JOIN "sys_WorkflowAcao" acao ON acao."Id" = flow."WorkflowAcaoId"
WHERE
    lcd."CargaTipoStatusId" <> 7
    AND lcd."DataCriacao" >= DATE '2025-01-01'
 group by
 acao."Descricao"