WITH cargas_filtradas AS MATERIALIZED (
    SELECT
        lcd."Id",
        lcd."Guid",
        lcd."EmpresaId",
        lcd."DestinoId",
        lcd."DataCriacao",
        lcd."DescrLocalEmbarque",
        lcd."Descarga",

        wa."WorkflowAcaoId",
        wa."DataCriacao" AS "DataWorkflow"

    FROM "log_CargaDado" lcd

    INNER JOIN LATERAL (
        SELECT
            sw."WorkflowAcaoId",
            sw."DataCriacao"
        FROM "sys_Workflow" sw
        WHERE sw."Referencia" = lcd."Guid"
        ORDER BY sw."Id" DESC
        LIMIT 1
    ) wa
        ON wa."WorkflowAcaoId" IN (
            4, 15, 22, 23, 42,
            49, 51, 52, 17, 66
        )

    WHERE
        lcd."CargaTipoStatusId" <> 7
        AND lcd."DataCriacao" >= DATE '2025-01-01'
)

SELECT
    c."Id",
    c."Guid",

    emp."NomeFantasia" AS "Filial",

    se."UF",

    si."Descricao" AS "Produto",

    c."DataWorkflow" AS "DataCriacao",

    acao."Descricao" AS "Status",

    c."DescrLocalEmbarque" AS "Embarque",

    CASE
        WHEN c."WorkflowAcaoId" IN (
            4, 15, 22, 23, 42, 49, 51, 66
        )
            THEN sem."Nome" || '-' || se."UF"
        ELSE
            semp."Nome" || '-' || sep."UF"
    END AS "Desembarque",

    c."Descarga",

    ROUND(
        EXTRACT(
            EPOCH FROM (
                CURRENT_TIMESTAMP -
                COALESCE(
                    ag18."DataCriacao",
                    ag16."DataCriacao"
                )
            )
        ) / 60,
        0
    ) AS "Min",

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

    CASE
        WHEN ROUND(
            EXTRACT(
                EPOCH FROM (
                    CURRENT_TIMESTAMP - ag18."DataCriacao"
                )
            ) / 60,
            0
        ) BETWEEN 10 AND 15
            THEN 'amarelo'

        WHEN ROUND(
            EXTRACT(
                EPOCH FROM (
                    CURRENT_TIMESTAMP - ag18."DataCriacao"
                )
            ) / 60,
            0
        ) > 15
            THEN 'vermelho'

        ELSE 'verde'
    END AS cor_status

FROM cargas_filtradas c

-- EMPRESA
INNER JOIN "sys_Empresa" emp
    ON emp."Id" = c."EmpresaId"

-- MUNICIPIO / ESTADO DA EMPRESA
INNER JOIN "sys_EstadoMunicipio" sem
    ON sem."Id" = emp."MunicipioId"

INNER JOIN "sys_Estado" se
    ON se."Id" = sem."EstadoId"

-- PRODUTO
INNER JOIN "log_CargaItem" lci
    ON lci."CargaDadoId" = c."Id"

LEFT JOIN "sys_Item" si
    ON si."Id" = lci."ProdutoId"

-- DESCRICAO DO STATUS
INNER JOIN "sys_WorkflowAcao" acao
    ON acao."Id" = c."WorkflowAcaoId"

-- DESTINO DA CARGA
LEFT JOIN "sys_Pessoa" sp
    ON sp."Id" = c."DestinoId"

LEFT JOIN "sys_EstadoMunicipio" semp
    ON semp."Id" = sp."MunicipioId"

LEFT JOIN "sys_Estado" sep
    ON sep."Id" = semp."EstadoId"

-- PRIMEIRO WORKFLOW COM ACAO 16 OU 18
LEFT JOIN LATERAL (
    SELECT
        sw."DataCriacao"
    FROM "sys_Workflow" sw
    WHERE sw."Referencia" = c."Guid"
      AND sw."WorkflowAcaoId" IN (16, 18)
    ORDER BY sw."Id" ASC
    LIMIT 1
) ag ON true

-- ULTIMO WORKFLOW COM ACAO 18
LEFT JOIN LATERAL (
    SELECT
        sw."DataCriacao"
    FROM "sys_Workflow" sw
    WHERE sw."Referencia" = c."Guid"
      AND sw."WorkflowAcaoId" = 18
    ORDER BY sw."Id" DESC
    LIMIT 1
) ag18 ON true

-- ULTIMO WORKFLOW COM ACAO 16
LEFT JOIN LATERAL (
    SELECT
        sw."DataCriacao"
    FROM "sys_Workflow" sw
    WHERE sw."Referencia" = c."Guid"
      AND sw."WorkflowAcaoId" = 16
    ORDER BY sw."Id" DESC
    LIMIT 1
) ag16 ON true