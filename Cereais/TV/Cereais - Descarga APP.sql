-- ### DESCARGA - PAINEL
SELECT DISTINCT
    lcd."Id",
    swa."Descricao" AS "Status",
    emp."NomeFantasia" AS "Filial",
    si."Descricao" AS "Produto",
    lv."Placa",
    lcd."DataCriacao",
    lcd."DescrLocalEmbarque" AS "Embarque",
    sem."Nome" || '-' || se."UF" AS "Desembarque",
    lcd."Descarga",

    ROUND(
        EXTRACT(
            EPOCH FROM (
                CURRENT_TIMESTAMP - flow."DataCriacao"
            )
        ) / 60,
        0
    ) AS "Min",

    EXTRACT(
        DAY FROM (
            lcd."Descarga" - CURRENT_TIMESTAMP
        )
    ) AS "Dias",

    CASE
        WHEN CURRENT_DATE >= lcd."Descarga"::date
            THEN 'vermelho'

        WHEN lcd."Descarga"::date - CURRENT_DATE < 2
            THEN 'amarelo'

        WHEN lcd."Descarga"::date - CURRENT_DATE >= 2
            THEN 'verde'
    END AS cor

FROM "log_CargaDado" lcd

-- PESSOA / DESTINO
LEFT JOIN "sys_Pessoa" sp
    ON sp."Id" = lcd."DestinoId"

LEFT JOIN "sys_EstadoMunicipio" sem
    ON sem."Id" = sp."MunicipioId"

LEFT JOIN "sys_Estado" se
    ON se."Id" = sem."EstadoId"

-- TRANSPORTE / VEICULO
LEFT JOIN "log_CargaTran" lct
    ON lct."CargaDadoId" = lcd."Id"

LEFT JOIN "log_Veiculo" lv
    ON lv."Id" = lct."VeiculoId"

-- PRODUTO
LEFT JOIN "log_CargaItem" lci
    ON lci."CargaDadoId" = lcd."Id"

LEFT JOIN "sys_Item" si
    ON si."Id" = lci."ProdutoId"

-- EMPRESA
LEFT JOIN "sys_Empresa" emp
    ON emp."Id" = lcd."EmpresaId"

-- ULTIMO WORKFLOW COM ACAO 13
-- Substitui o GROUP BY + MAX(Id) original
LEFT JOIN LATERAL (
    SELECT
        sw."DataCriacao",
        sw."WorkflowAcaoId",
        sw."Referencia"
    FROM "sys_Workflow" sw
    WHERE sw."Referencia" = lcd."Guid"
      AND sw."WorkflowAcaoId" = 13
    ORDER BY sw."Id" DESC
    LIMIT 1
) flow ON true

-- ULTIMO WORKFLOW GERAL DA CARGA
-- Substitui o GROUP BY + MAX(Id) original
LEFT JOIN LATERAL (
    SELECT
        sw."DataCriacao",
        sw."WorkflowAcaoId",
        sw."Referencia"
    FROM "sys_Workflow" sw
    WHERE sw."Referencia" = lcd."Guid"
    ORDER BY sw."Id" DESC
    LIMIT 1
) maximo ON true

-- DESCRICAO DO STATUS ATUAL
LEFT JOIN "sys_WorkflowAcao" swa
    ON swa."Id" = maximo."WorkflowAcaoId"

WHERE
    -- PRECISA POSSUIR WORKFLOW 13
    lcd."Guid" IN (
        SELECT
            sw1."Referencia"
        FROM "sys_Workflow" sw1
        WHERE sw1."WorkflowAcaoId" = 13
    )

    -- NAO PODE POSSUIR WORKFLOW 12 OU 14
    AND lcd."Guid" NOT IN (
        SELECT
            sw2."Referencia"
        FROM "sys_Workflow" sw2
        WHERE sw2."WorkflowAcaoId" IN (12, 14)
    )

    -- EXCLUI STATUS 7
    AND lcd."CargaTipoStatusId" NOT IN (7)

    -- DESCARGAS ANTERIORES A D+2
    AND lcd."Descarga"::date - CURRENT_DATE < 2

    -- EXCLUI DATAS INFINITAS
    AND lcd."Descarga" NOT IN (
        'infinity',
        '-infinity'
    )