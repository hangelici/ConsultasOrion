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
        AND lcd."Descarga" NOT IN ('infinity', '-infinity')

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
              AND sw."WorkflowAcaoId" IN (12, 13, 19, 14)
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
        WHERE sw."Referencia" = cf."Guid"
          AND sw."WorkflowAcaoId" = 5
        ORDER BY sw."Id" DESC
        LIMIT 1
    ) sw ON true
)

SELECT
    cf."Id",
    swa."Descricao" AS "Status",
    emp."NomeFantasia" AS "Filial",
    si."Descricao" AS "Produto",
    lv."Placa",
    cf."DataCriacao",
    cf."DescrLocalEmbarque" AS "Embarque",
    sem."Nome" || '-' || se."UF" AS "Desembarque",
    cf."Descarga",

    CASE
        WHEN (cf."Descarga"::date - CURRENT_DATE) >= 3 THEN 'D3'
        WHEN (cf."Descarga"::date - CURRENT_DATE) = 2 THEN 'D2'
        WHEN (cf."Descarga"::date - CURRENT_DATE) = 1 THEN 'D1'
        WHEN (cf."Descarga"::date - CURRENT_DATE) = 0 THEN 'D0'
        ELSE 'D-'
    END AS "Descarga_regra",

    (
        EXTRACT(
            EPOCH FROM (
                CURRENT_TIMESTAMP - wf5."DataCriacao"
            )
        ) / 60
    )::int AS "Min",

    ROUND(
        EXTRACT(
            EPOCH FROM (
                CURRENT_TIMESTAMP -
                COALESCE(
                    ag16."DataCriacao",
                    ag."DataCriacao"
                )
            )
        ) / 60,
        0
    ) AS "Min_Total",

    EXTRACT(
        DAY FROM (
            cf."Descarga" - CURRENT_TIMESTAMP
        )
    ) AS "Dias",

    CASE
        WHEN CURRENT_DATE >= cf."Descarga"::date
            THEN 'vermelho'
        WHEN cf."Descarga"::date - CURRENT_DATE < 2
            THEN 'amarelo'
        ELSE 'verde'
    END AS cor,

    lcdo."Distancia",

    ROUND(
        NULLIF(lcdo."Distancia", 0) / 30,
        0
    ) AS "TempoHora"

FROM cargas_filtradas cf

LEFT JOIN workflow_atual wa
    ON wa."Guid" = cf."Guid"

LEFT JOIN workflow_5 wf5
    ON wf5."Guid" = cf."Guid"

LEFT JOIN "sys_WorkflowAcao" swa
    ON swa."Id" = wa."WorkflowAcaoId"

LEFT JOIN "sys_Pessoa" sp
    ON sp."Id" = cf."DestinoId"

LEFT JOIN "sys_EstadoMunicipio" sem
    ON sem."Id" = sp."MunicipioId"

LEFT JOIN "sys_Estado" se
    ON se."Id" = sem."EstadoId"

LEFT JOIN "log_CargaTran" lct
    ON lct."CargaDadoId" = cf."Id"

LEFT JOIN "log_Veiculo" lv
    ON lv."Id" = lct."VeiculoId"

LEFT JOIN "log_CargaItem" lci
    ON lci."CargaDadoId" = cf."Id"

LEFT JOIN "sys_Item" si
    ON si."Id" = lci."ProdutoId"

LEFT JOIN "sys_Empresa" emp
    ON emp."Id" = cf."EmpresaId"

-- OTIMIZACAO 1:
-- Primeiro workflow com acao 16 ou 18
-- Equivalente ao DISTINCT ON anterior com Id ASC

LEFT JOIN LATERAL (
    SELECT
        sw."DataCriacao"
    FROM "sys_Workflow" sw
    WHERE sw."Referencia" = cf."Guid"
      AND sw."WorkflowAcaoId" IN (16, 18)
    ORDER BY sw."Id" ASC
    LIMIT 1
) ag ON true

-- OTIMIZACAO 2:
-- Ultimo workflow com acao 16
-- Equivalente ao DISTINCT ON anterior com Id DESC

LEFT JOIN LATERAL (
    SELECT
        sw."DataCriacao"
    FROM "sys_Workflow" sw
    WHERE sw."Referencia" = cf."Guid"
      AND sw."WorkflowAcaoId" = 16
    ORDER BY sw."Id" DESC
    LIMIT 1
) ag16 ON true

LEFT JOIN "log_CargaDemandaLote" lcdl
    ON lcdl."Id" = cf."CargaDemandaLoteId"

LEFT JOIN "log_CargaDemandaOportunidade" lcdo
    ON lcdo."Id" = lcdl."CargaDemandaOportunidadeId";