WITH ultimo_workflow_id AS MATERIALIZED (
    SELECT
        sw."Referencia",
        MAX(sw."Id") AS "MaxId"
    FROM "sys_Workflow" sw
    GROUP BY sw."Referencia"
),

cargas_status AS MATERIALIZED (
    SELECT
        lcd."Id",
        lcd."Guid",
        lcd."EmpresaId",
        lcd."DestinoId",
        lcd."DataCriacao",
        lcd."DescrLocalEmbarque",
        lcd."Descarga",

        sw."WorkflowAcaoId" AS "IdFlow",
        sw."DataCriacao" AS "DataWorkflow"

    FROM ultimo_workflow_id ult

    INNER JOIN "sys_Workflow" sw
        ON sw."Id" = ult."MaxId"
       AND sw."Referencia" = ult."Referencia"

    INNER JOIN "log_CargaDado" lcd
        ON lcd."Guid" = ult."Referencia"

    WHERE
        sw."WorkflowAcaoId" IN (
            4, 15, 22, 23, 42, 49, 51
        )

        AND lcd."CargaTipoStatusId" <> 7

        AND lcd."DataCriacao" >= DATE '2025-01-01'
),

dados AS (
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
                    CURRENT_TIMESTAMP - flowinicio."DataCriacao"
                )
            ) / 60,
            0
        ) AS "Min_Total"

    FROM cargas_status c

    -- TRANSPORTE E VEICULO
    LEFT JOIN "log_CargaTran" lct
        ON lct."CargaDadoId" = c."Id"

    LEFT JOIN "log_Veiculo" lv
        ON lv."Id" = lct."VeiculoId"

    -- PRODUTO
    LEFT JOIN "log_CargaItem" lci
        ON lci."CargaDadoId" = c."Id"

    LEFT JOIN "sys_Item" si
        ON si."Id" = lci."ProdutoId"

    -- EMPRESA
    LEFT JOIN "sys_Empresa" emp
        ON emp."Id" = c."EmpresaId"

    LEFT JOIN "sys_EstadoMunicipio" sem
        ON sem."Id" = emp."MunicipioId"

    LEFT JOIN "sys_Estado" se
        ON se."Id" = sem."EstadoId"

    -- DESCRICAO DO STATUS
    LEFT JOIN "sys_WorkflowAcao" acao
        ON acao."Id" = c."IdFlow"

    -- PRIMEIRO WORKFLOW COM ACAO 16 OU 18
    LEFT JOIN LATERAL (
        SELECT
            sw."DataCriacao"
        FROM "sys_Workflow" sw
        WHERE sw."Referencia" = c."Guid"
          AND sw."WorkflowAcaoId" IN (16, 18)
        ORDER BY sw."Id" ASC
        LIMIT 1
    ) flowinicio ON true
)

SELECT
    dados.*,

    CASE
        WHEN "Min" BETWEEN 5 AND 7
             AND "IdFlow" = 5
            THEN 'amarelo'

        WHEN "Min" > 7
             AND "IdFlow" = 5
            THEN 'vermelho'

        WHEN "IdFlow" IN (22, 36, 41, 42, 49, 51)
            THEN 'vermelho'

        WHEN "Min" BETWEEN 7 AND 10
             AND "IdFlow" = 15
            THEN 'amarelo'

        WHEN "Min" > 10
             AND "IdFlow" = 15
            THEN 'vermelho'

        WHEN "Min" BETWEEN 5 AND 7
             AND "IdFlow" = 23
            THEN 'amarelo'

        WHEN "Min" > 7
             AND "IdFlow" = 23
            THEN 'vermelho'

        ELSE 'verde'
    END AS cor_status

FROM dados