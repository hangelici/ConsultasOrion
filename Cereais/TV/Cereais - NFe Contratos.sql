--- ### Responsavel Contratos
WITH workflow_candidato AS MATERIALIZED (
    SELECT DISTINCT ON (sw."Referencia")
        sw."Referencia",
        sw."Id",
        sw."WorkflowAcaoId",
        sw."DataCriacao"

    FROM "sys_Workflow" sw

    WHERE sw."WorkflowAcaoId" IN (24, 25)
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

        w."WorkflowAcaoId" AS "IdFlow",
        w."DataCriacao" AS "DataWorkflow"

    FROM workflow_candidato w

    INNER JOIN "log_CargaDado" lcd
        ON lcd."Guid" = w."Referencia"

    WHERE lcd."CargaTipoStatusId" <> 7
      AND lcd."DataCriacao" >= DATE '2025-01-01'

      -- A acao 24/25 precisa ser a ultima
      AND NOT EXISTS (
          SELECT 1
          FROM "sys_Workflow" sw2
          WHERE sw2."Referencia" = w."Referencia"
            AND sw2."Id" > w."Id"
      )
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
                    CURRENT_TIMESTAMP - c."DataCriacao"
                )
            ) / 60,
            0
        ) AS "Min_Total"

    FROM cargas_status c

    -- TRANSPORTE
    LEFT JOIN "log_CargaTran" lct
        ON lct."CargaDadoId" = c."Id"

    -- VEICULO
    LEFT JOIN "log_Veiculo" lv
        ON lv."Id" = lct."VeiculoId"

    -- ITENS
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

    -- DESCRICAO DO WORKFLOW
    LEFT JOIN "sys_WorkflowAcao" acao
        ON acao."Id" = c."IdFlow"
)

SELECT
    dados.*,

    CASE
        WHEN "IdFlow" IN (7)
            THEN 'vermelho'

        WHEN "Min" > 10
             AND "IdFlow" = 46
            THEN 'vermelho'

        WHEN "Min" BETWEEN 7 AND 10
             AND "IdFlow" = 46
            THEN 'amarelo'

        WHEN "Min" > 7
             AND "IdFlow" IN (16, 47)
            THEN 'vermelho'

        WHEN "Min" BETWEEN 5 AND 7
             AND "IdFlow" IN (16, 47)
            THEN 'amarelo'

        ELSE 'verde'
    END AS cor_status

FROM dados