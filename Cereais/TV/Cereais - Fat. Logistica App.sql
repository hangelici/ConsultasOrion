--- ### Responsavel Logistica
WITH workflow_max AS MATERIALIZED (
    SELECT
        sw."Referencia",
        MAX(sw."Id") AS maxid
    FROM "sys_Workflow" sw
    GROUP BY sw."Referencia"
),

cargas_status AS MATERIALIZED (
    SELECT
        lcd."Id",
        lcd."Guid",
        lcd."EmpresaId",
        lcd."DestinoId",
        lcd."CargaDemandaLoteId",
        lcd."DataCriacao",
        lcd."DescrLocalEmbarque",
        lcd."Descarga",

        sw."WorkflowAcaoId",
        sw."DataCriacao" AS "DataWorkflow"

    FROM workflow_max w

    INNER JOIN "sys_Workflow" sw
        ON sw."Id" = w.maxid
       AND sw."Referencia" = w."Referencia"

    INNER JOIN "log_CargaDado" lcd
        ON lcd."Guid" = w."Referencia"

    WHERE
        sw."WorkflowAcaoId" IN (18, 27, 28, 50)

        AND lcd."CargaTipoStatusId" <> 7

        AND lcd."DataCriacao" >= DATE '2025-01-01'
),

usuarios AS MATERIALIZED (
    SELECT
        vu.username,
        vu.dispname
    FROM vw_users vu
)

SELECT
    c."Id",

    emp."NomeFantasia" AS "Filial",

    se."UF",

    item."Descricao" AS "Produto",

    lv."Placa",

    c."DataCriacao",

    acao."Descricao" AS "Status",

    c."WorkflowAcaoId" AS "IdFlow",

    c."DescrLocalEmbarque" AS "Embarque",

    sem."Nome" || '-' || se."UF" AS "Desembarque",

    c."Descarga",

    vu.dispname AS "AgLog",

    (
        EXTRACT(
            EPOCH FROM (
                CURRENT_TIMESTAMP - c."DataWorkflow"
            )
        ) / 60
    )::int AS "Min",

    (
        EXTRACT(
            EPOCH FROM (
                CURRENT_TIMESTAMP - c."DataCriacao"
            )
        ) / 60
    )::int AS "Min_Total",

    CASE
        WHEN c."WorkflowAcaoId" IN (27, 28)
            THEN 'vermelho'

        WHEN c."WorkflowAcaoId" = 18
             AND (
                 EXTRACT(
                     EPOCH FROM (
                         CURRENT_TIMESTAMP - c."DataWorkflow"
                     )
                 ) / 60
             ) > 10
            THEN 'vermelho'

        WHEN c."WorkflowAcaoId" = 18
             AND (
                 EXTRACT(
                     EPOCH FROM (
                         CURRENT_TIMESTAMP - c."DataWorkflow"
                     )
                 ) / 60
             ) >= 7
            THEN 'amarelo'

        WHEN c."WorkflowAcaoId" = 50
             AND (
                 EXTRACT(
                     EPOCH FROM (
                         CURRENT_TIMESTAMP - c."DataWorkflow"
                     )
                 ) / 60
             ) > 30
            THEN 'vermelho'

        WHEN c."WorkflowAcaoId" = 50
             AND (
                 EXTRACT(
                     EPOCH FROM (
                         CURRENT_TIMESTAMP - c."DataWorkflow"
                     )
                 ) / 60
             ) >= 25
            THEN 'amarelo'

        ELSE 'verde'
    END AS cor_status

FROM cargas_status c

-- DESCRICAO DO STATUS
LEFT JOIN "sys_WorkflowAcao" acao
    ON acao."Id" = c."WorkflowAcaoId"

-- EMPRESA
LEFT JOIN "sys_Empresa" emp
    ON emp."Id" = c."EmpresaId"

LEFT JOIN "sys_EstadoMunicipio" sem
    ON sem."Id" = emp."MunicipioId"

LEFT JOIN "sys_Estado" se
    ON se."Id" = sem."EstadoId"

-- TRANSPORTE E VEICULO
LEFT JOIN "log_CargaTran" lct
    ON lct."CargaDadoId" = c."Id"

LEFT JOIN "log_Veiculo" lv
    ON lv."Id" = lct."VeiculoId"

-- PRIMEIRO PRODUTO DA CARGA
LEFT JOIN LATERAL (
    SELECT
        si."Descricao"
    FROM "log_CargaItem" lci

    INNER JOIN "sys_Item" si
        ON si."Id" = lci."ProdutoId"

    WHERE lci."CargaDadoId" = c."Id"

    LIMIT 1
) item ON true

-- DEMANDA / LOTE
LEFT JOIN "log_CargaDemandaLote" lcdl
    ON lcdl."Id" = c."CargaDemandaLoteId"

-- OPORTUNIDADE
LEFT JOIN "log_CargaDemandaOportunidade" lcdo
    ON lcdo."Id" = lcdl."CargaDemandaOportunidadeId"

-- USUARIOS MATERIALIZADOS
LEFT JOIN usuarios vu
    ON vu.username = COALESCE(
        lcdo."Usuario",
        lcdl."Usuario"
    )