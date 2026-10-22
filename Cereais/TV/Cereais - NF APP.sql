WITH referencias_validas AS MATERIALIZED (
    SELECT DISTINCT
        sw."Referencia"
    FROM "sys_Workflow" sw
    WHERE sw."WorkflowAcaoId" IN (18, 16)

      AND NOT EXISTS (
          SELECT 1
          FROM "sys_Workflow" sw2
          WHERE sw2."Referencia" = sw."Referencia"
            AND sw2."WorkflowAcaoId" IN (5, 12, 13, 14, 9)
      )
),

cargas_filtradas AS MATERIALIZED (
    SELECT
        lcd."Id",
        lcd."Guid",
        lcd."EmpresaId",
        lcd."DestinoId",
        lcd."DataCriacao",
        lcd."DescrLocalEmbarque"
    FROM referencias_validas rv

    INNER JOIN "log_CargaDado" lcd
        ON lcd."Guid" = rv."Referencia"

    WHERE lcd."CargaTipoStatusId" <> 7
)

SELECT DISTINCT
    cf."Id",

    swa."Descricao" AS "Status",

    emp."NomeFantasia" AS "Filial",

    si."Descricao" AS "Produto",

    lv."Placa",

    cf."DataCriacao",

    cf."DescrLocalEmbarque" AS "Embarque",

    sem."Nome" || '-' || se."UF" AS "Desembarque",

    (
        EXTRACT(
            EPOCH FROM (
                CURRENT_TIMESTAMP - wa."DataCriacao"
            )
        ) / 60
    )::int AS "Min",

    (
        EXTRACT(
            EPOCH FROM (
                CURRENT_TIMESTAMP - wf."DataCriacao"
            )
        ) / 60
    )::int AS "Min_Total"

FROM cargas_filtradas cf

-- Workflow mais recente da carga
LEFT JOIN LATERAL (
    SELECT
        sw."WorkflowAcaoId",
        sw."DataCriacao"
    FROM "sys_Workflow" sw
    WHERE sw."Referencia" = cf."Guid"
    ORDER BY sw."Id" DESC
    LIMIT 1
) wa ON true

-- Ultimo workflow com acao 16 ou 18
LEFT JOIN LATERAL (
    SELECT
        sw."DataCriacao"
    FROM "sys_Workflow" sw
    WHERE sw."Referencia" = cf."Guid"
      AND sw."WorkflowAcaoId" IN (18, 16)
    ORDER BY sw."Id" DESC
    LIMIT 1
) wf ON true

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

WHERE
    swa."Id" NOT IN (54, 3, 1, 2, 45)
    AND si."ItemGrupoId" = 2;