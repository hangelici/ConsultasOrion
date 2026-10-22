--- ### Responsavel Fiscal
WITH workflow_26 AS MATERIALIZED (
    SELECT DISTINCT ON (sw."Referencia")
        sw."Referencia",
        sw."Id",
        sw."DataCriacao"
    FROM "sys_Workflow" sw
    WHERE
        sw."WorkflowAcaoId" = 26
        AND sw."Referencia" IS NOT NULL
    ORDER BY
        sw."Referencia",
        sw."Id" DESC
),

cargas_status AS MATERIALIZED (
    SELECT
        lcd."Id",
        lcd."Guid",
        lcd."EmpresaId",
        lcd."DataCriacao",
        lcd."DescrLocalEmbarque",
        lcd."Descarga",

        26 AS "IdFlow",
        w."DataCriacao" AS "DataWorkflow"

    FROM workflow_26 w

    INNER JOIN "log_CargaDado" lcd
        ON lcd."Guid" = w."Referencia"

    WHERE
        lcd."CargaTipoStatusId" <> 7

        AND lcd."DataCriacao" >= DATE '2025-01-01'

        -- A acao 26 deve ser a ultima do workflow
        AND NOT EXISTS (
            SELECT 1
            FROM "sys_Workflow" sw2
            WHERE
                sw2."Referencia" = w."Referencia"
                AND sw2."Id" > w."Id"
        )
)

SELECT
    c."Id",

    emp."NomeFantasia" AS "Filial",

    se."UF",

    si."Descricao" AS "Produto",

    lv."Placa",

    c."DataCriacao",

    acao."Descricao" AS "Status",

    c."IdFlow",

    c."DescrLocalEmbarque" AS "Embarque",

    sem."Nome" || '-' || se."UF" AS "Desembarque",

    c."Descarga",

    ROUND(
        EXTRACT(
            EPOCH FROM (
                CURRENT_TIMESTAMP - c."DataWorkflow"
            )
        ) / 60,
        0
    ) AS "Min",

    ROUND(
        EXTRACT(
            EPOCH FROM (
                CURRENT_TIMESTAMP - c."DataCriacao"
            )
        ) / 60,
        0
    ) AS "Min_Total",

    'vermelho' AS cor_status

FROM cargas_status c

-- TRANSPORTE
LEFT JOIN "log_CargaTran" lct
    ON lct."CargaDadoId" = c."Id"

-- VEICULO
LEFT JOIN "log_Veiculo" lv
    ON lv."Id" = lct."VeiculoId"

-- ITENS DA CARGA
LEFT JOIN "log_CargaItem" lci
    ON lci."CargaDadoId" = c."Id"

-- PRODUTO
LEFT JOIN "sys_Item" si
    ON si."Id" = lci."ProdutoId"

-- EMPRESA
LEFT JOIN "sys_Empresa" emp
    ON emp."Id" = c."EmpresaId"

-- MUNICIPIO
LEFT JOIN "sys_EstadoMunicipio" sem
    ON sem."Id" = emp."MunicipioId"

-- ESTADO
LEFT JOIN "sys_Estado" se
    ON se."Id" = sem."EstadoId"

-- DESCRICAO DO STATUS
LEFT JOIN "sys_WorkflowAcao" acao
    ON acao."Id" = c."IdFlow"