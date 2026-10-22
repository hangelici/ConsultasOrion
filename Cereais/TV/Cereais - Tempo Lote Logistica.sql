-- ### LOTES DE DEMANDA LOGISTICA
WITH empresa_uf AS MATERIALIZED (
    SELECT
        se."Id" AS "EmpresaId",
        est."UF"

    FROM "sys_Empresa" se

    LEFT JOIN "sys_EstadoMunicipio" mun
        ON mun."Id" = se."MunicipioId"

    LEFT JOIN "sys_Estado" est
        ON est."Id" = mun."EstadoId"
),

lotes_calculados AS MATERIALIZED (
    SELECT
        lcdl."StatusId",
        lcdl."DataCriacao",
        lcdl."Validade",
        lcdl."InicioEmbarque",
        lcdl."Id",
        lcdl."Usuario",
        lcdl."EmpresaId",
        lcdl."Excluido",

        CASE
            WHEN lcdl."Valor" = 0 THEN 'FOB'
            ELSE 'CIF'
        END AS "TipoFrete",

        FLOOR(
            EXTRACT(
                EPOCH FROM (
                    NOW() - lcdl."DataCriacao"
                )
            ) / 86400
        ) AS "Tempo",

        ROUND(
            FLOOR(
                EXTRACT(
                    EPOCH FROM (
                        NOW() - lcdl."InicioEmbarque"
                    )
                ) / 86400
            ),
            0
        ) AS "Vencimento"

    FROM "log_CargaDemandaLote" lcdl

    WHERE lcdl."StatusId" = 1

      AND lcdl."DataCriacao" >= DATE '2025-01-01'

      AND lcdl."DataCriacao" <= CURRENT_DATE
),

lotes_filtrados AS (
    SELECT
        l.*
    FROM lotes_calculados l
    WHERE
        (
            l."TipoFrete" = 'FOB'
            AND l."Vencimento" >= 0
        )
        OR
        (
            l."TipoFrete" = 'CIF'
            AND l."Tempo" > 15
        )
),

dados AS (
    SELECT
        l."StatusId",

        TO_CHAR(
            l."DataCriacao",
            'DD/MM/YYYY'
        ) AS "DataCriacao",

        TO_CHAR(
            l."Validade",
            'DD/MM/YYYY'
        ) AS "Validade",

        l."Tempo",

        l."Vencimento",

        l."Id",

        eu."UF",

        vu.username AS "AgenteLogistico",

        l."Excluido",

        l."TipoFrete"

    FROM lotes_filtrados l

    LEFT JOIN vw_users vu
        ON vu.userid = l."Usuario"

    LEFT JOIN empresa_uf eu
        ON eu."EmpresaId" = l."EmpresaId"
)

SELECT
    dados.*,

    RANK() OVER (
        ORDER BY
            "Vencimento" ASC NULLS LAST
    ) AS "Rank",

    CASE

        -- FOB
        WHEN "TipoFrete" = 'FOB'
             AND "Vencimento" > 0
            THEN 'VERMELHO'

        WHEN "TipoFrete" = 'FOB'
             AND "Vencimento" = 0
            THEN 'AMARELO'

        -- CIF
        WHEN "TipoFrete" = 'CIF'
             AND "Tempo" > 25
            THEN 'VERMELHO'

        WHEN "TipoFrete" = 'CIF'
             AND "Tempo" > 15
            THEN 'AMARELO'

        ELSE NULL

    END AS "CorStatus"

FROM dados

ORDER BY
    "TipoFrete",
    "Tempo" DESC