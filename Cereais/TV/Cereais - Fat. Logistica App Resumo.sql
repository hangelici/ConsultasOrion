--- ### Responsavel Logistica
WITH workflow_candidato AS MATERIALIZED (
    SELECT DISTINCT ON (sw."Referencia")
        sw."Referencia",
        sw."Id",
        sw."WorkflowAcaoId"

    FROM "sys_Workflow" sw

    WHERE sw."WorkflowAcaoId" IN (18, 27, 28, 50)
      AND sw."Referencia" IS NOT NULL

    ORDER BY
        sw."Referencia",
        sw."Id" DESC
),

cargas_filtradas AS MATERIALIZED (
    SELECT
        lcd."Id",
        w."WorkflowAcaoId"

    FROM workflow_candidato w

    INNER JOIN "log_CargaDado" lcd
        ON lcd."Guid" = w."Referencia"

    WHERE
        lcd."CargaTipoStatusId" <> 7
        AND lcd."DataCriacao" >= DATE '2025-01-01'

        -- A acao candidata precisa ser o ultimo workflow
        AND NOT EXISTS (
            SELECT 1
            FROM "sys_Workflow" sw2
            WHERE sw2."Referencia" = w."Referencia"
              AND sw2."Id" > w."Id"
        )
)

SELECT
    acao."Descricao" AS "Status",

    COUNT(c."Id") AS "Min",

    COUNT(c."Id") AS "Min_Total"

FROM cargas_filtradas c

LEFT JOIN "sys_WorkflowAcao" acao
    ON acao."Id" = c."WorkflowAcaoId"

GROUP BY
    acao."Descricao"