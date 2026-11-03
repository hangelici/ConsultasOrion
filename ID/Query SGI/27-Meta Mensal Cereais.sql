WITH 
        META AS
        (
             SELECT 
        sum(T.QTD) AS META
    FROM U_METARTV T
        INNER JOIN
            (SELECT
                MAX(seqhist) AS maxhist,
                codconsultor,
                segmento,
                codestoque,
                safra,
                osestab
            FROM U_METARTV
            WHERE
                    ativo = 'S'
                AND segmento = 2 --cuidado aqui: se quer só segmento 2 na query, mantenha esse filtro
            GROUP BY
                codconsultor,
                segmento,
                codestoque,
                safra,
                osestab
            ) ultimo
            ON  ultimo.maxhist      = T.seqhist
            AND ultimo.codconsultor = T.codconsultor
            AND ultimo.segmento     = T.segmento
            AND ultimo.codestoque   = T.codestoque
            AND ultimo.safra        = T.safra
            AND ultimo.osestab      = T.osestab
        INNER JOIN FILIAL ON  FILIAL.ESTAB = T.OSESTAB
        INNER JOIN CIDADE ON  CIDADE.CIDADE = FILIAL.CIDADE
        INNER JOIN UF ON  CIDADE.UF = UF.UF
        INNER JOIN U_TEMPRESA ON U_TEMPRESA.ESTAB = FILIAL.ESTAB
    WHERE
    cast(t.data as date) BETWEEN CAST(TO_DATE(:startDate) AS DATE) AND CAST(TO_DATE(:endDate) AS DATE)
    AND U_TEMPRESA.TRADING <> 'S'
    AND T.ATIVO = 'S'
    AND T.SEGMENTO = 2
        ),
        COMPRADO AS
        (
            SELECT
                SUM(QTDSC) - SUM(QTDCANC) AS QTDSC,
                SUM(QTDMES_ACUMULADO) AS QTDMES_ACUMULADO
            FROM
            (
                -- COMPRA NORMAL
                SELECT
                    COALESCE(ROUND((CONTRATOITE.QUANTIDADE / 60), 2), 0) AS QTDSC,
                    0 AS QTDCANC, 
                    CASE 
                        WHEN CAST(CONTRATO.DTEMISSAO AS DATE) BETWEEN TRUNC(SYSDATE, 'MM') AND TRUNC(LAST_DAY(SYSDATE)) 
                        THEN COALESCE(ROUND((CONTRATOITE.QUANTIDADE / 60), 2), 0) 
                        ELSE 0 
                    END AS QTDMES_ACUMULADO
                FROM 
                    CONTRATO
                INNER JOIN
                    (SELECT DISTINCT
                        ESTAB,
                        CONTRATO,
                        NUMEROCM
                    FROM 
                        OS_CONTRATOCOM
                    WHERE 
                        META > 0
                    ) CONTRATOCOM ON CONTRATOCOM.CONTRATO = CONTRATO.CONTRATO AND CONTRATOCOM.ESTAB = CONTRATO.ESTAB
                INNER JOIN 
                    CONTRATOITE ON CONTRATOITE.ESTAB = CONTRATO.ESTAB AND CONTRATOITE.CONTRATO = CONTRATO.CONTRATO
                WHERE 
                    CAST(CONTRATO.DTEMISSAO AS DATE) BETWEEN CAST(TO_DATE(:startDate) AS DATE) AND CAST(TO_DATE(:endDate) AS DATE)
                    AND CONTRATO.CONTCONF IN (1, 2, 0)
                    AND CONTRATO.DTLIMENTIMP IS NOT NULL
                UNION ALL
                -- COMPRA LIMITE
                SELECT
                    COALESCE(ROUND((CONTRATOITE.QUANTIDADE / 60), 2), 0) AS QTDSC,
                    0 AS QTDCANC,
                    CASE 
                        WHEN CAST(CONTRATO.DTLIMENTIMP AS DATE) BETWEEN TRUNC(SYSDATE, 'MM') AND TRUNC(LAST_DAY(SYSDATE)) 
                        THEN COALESCE(ROUND((CONTRATOITE.QUANTIDADE / 60), 2), 0) 
                        ELSE 0 
                    END AS QTDMES_ACUMULADO
                FROM 
                    CONTRATO
                INNER JOIN
                    (SELECT DISTINCT
                        ESTAB,
                        CONTRATO,
                        NUMEROCM
                    FROM 
                        OS_CONTRATOCOM
                    WHERE 
                        META > 0
                    ) CONTRATOCOM ON CONTRATOCOM.CONTRATO = CONTRATO.CONTRATO AND CONTRATOCOM.ESTAB = CONTRATO.ESTAB
                INNER JOIN 
                    CONTRATOITE ON CONTRATOITE.ESTAB = CONTRATO.ESTAB AND CONTRATOITE.CONTRATO = CONTRATO.CONTRATO
                WHERE 
                    CAST(CONTRATO.DTLIMENTIMP AS DATE) BETWEEN CAST(TO_DATE(:startDate) AS DATE) AND CAST(TO_DATE(:endDate) AS DATE)
                    AND CAST(CONTRATO.DTEMISSAO AS DATE) < CAST(TO_DATE(:startDate) AS DATE)
                    AND CONTRATO.CONTCONF IN (1, 2, 0)
                UNION ALL
                -- CANCELADOS
                SELECT
                    DADOSX.QTDSC,
                    DADOSX.QTDCANC,
                    CASE 
                        WHEN CAST(LIMITEENT AS DATE) BETWEEN TRUNC(SYSDATE, 'MM') AND TRUNC(LAST_DAY(SYSDATE)) 
                        THEN DADOSX.QTDCANC * -1 
                        ELSE 0 
                    END AS QTDMES_ACUMULADO
                FROM
                (
                    SELECT
                        0 AS QTDSC,
                        CASE 
                            WHEN CONTRATO.DTLIMENTIMP > COALESCE(CONTRATOCANC.DTCANCELAMENTO, CONTRATOCANC.DATA) 
                            THEN CONTRATO.DTLIMENTIMP
                            ELSE COALESCE(CONTRATOCANC.DTCANCELAMENTO, CONTRATOCANC.DATA)
                        END AS LIMITEENT,
                        COALESCE(ROUND((CONTRATOCANC.QUANTIDADE / 60), 2), 0) AS QTDCANC
                    FROM 
                        CONTRATO
                    INNER JOIN 
                        CONTRATOITE ON CONTRATOITE.ESTAB = CONTRATO.ESTAB AND CONTRATOITE.CONTRATO = CONTRATO.CONTRATO
                    INNER JOIN
                        (SELECT DISTINCT
                            ESTAB,
                            CONTRATO,
                            NUMEROCM
                        FROM 
                            OS_CONTRATOCOM
                        WHERE 
                            META > 0
                        ) CONTRATOCOM ON CONTRATOCOM.CONTRATO = CONTRATO.CONTRATO AND CONTRATOCOM.ESTAB = CONTRATO.ESTAB
                    INNER JOIN 
                        CONTRATOCANC ON CONTRATOCANC.CONTRATO = CONTRATOITE.CONTRATO AND CONTRATOCANC.ESTAB = CONTRATOITE.ESTAB AND CONTRATOCANC.SEQITEM = CONTRATOITE.SEQITEM
                    LEFT JOIN 
                        LOCALEST ON LOCALEST.LOCAL = CONTRATOITE.LOCAL AND LOCALEST.ESTAB = CONTRATOITE.ESTAB
                    WHERE
                        CONTRATO.CONTCONF IN (1, 2, 0)
                ) DADOSX
                WHERE 
                    CAST(LIMITEENT AS DATE) BETWEEN CAST(TO_DATE(:startDate) AS DATE) AND CAST(TO_DATE(:endDate) AS DATE)
            )
        )
        SELECT
            META.META,
            COMPRADO.QTDSC AS COMPRADO,
            COMPRADO.QTDMES_ACUMULADO
        FROM
            META
        CROSS JOIN COMPRADO