WITH SALDO_INI AS
    (SELECT
        MOVIT.ESTAB,
        MOVIT.ITEM,
        SUM(CASE
                WHEN MOVIT.SOMADIMINUI = 'D' THEN ((MOVIT.QUANTIDADE/COALESCE(ITEMPREMB.MULTIPLIC,1)) * (-1))
                ELSE (MOVIT.QUANTIDADE/COALESCE(ITEMPREMB.MULTIPLIC,1))
            END
            ) AS SALDOINI,
        PCUSTO(MOVIT.ESTAB, MOVIT.ITEM, 3, :DTINI, NULL, NULL) AS CUSTOINI,
        (   SUM(CASE
                    WHEN MOVIT.SOMADIMINUI = 'D' THEN ((MOVIT.QUANTIDADE/COALESCE(ITEMPREMB.MULTIPLIC,1)) * (-1))
                    ELSE (MOVIT.QUANTIDADE/COALESCE(ITEMPREMB.MULTIPLIC,1))
                END
                ) *
            PCUSTO(MOVIT.ESTAB, MOVIT.ITEM, 3, :DTINI, NULL, NULL)
        ) AS CUSTOTOTINI
    FROM MOVITEMAGRO MOVIT
        LEFT JOIN ITEMPREMB
            ON  MOVIT.ESTAB = ITEMPREMB.ESTAB
            AND MOVIT.ITEM = ITEMPREMB.ITEM
    WHERE
            MOVIT.DATAMOVIM <= TO_DATE(:DTINI, 'DD/MM/YY')
        AND MOVIT.CODIGOSALDO = (:COD_SALDO)
        AND (   0 IN (:ESTAB)
            OR  MOVIT.ESTAB IN (:ESTAB)
            )
        AND (   0 IN (:ITEM)
            OR  MOVIT.ITEM IN (:ITEM)
            )
    GROUP BY
        MOVIT.ESTAB,
        MOVIT.ITEM
    ),
MOVS AS
    (SELECT
        MOVIT.ESTAB,
        MOVIT.ITEM,
        MOVIT.NATUREZA,
        MOVIT.DOC,
        MOVIT.SEQ,
        MOVIT.DATAMOVIM,
        MOVIT.HORAMOVIM,
        MOVIT.CODIGOSALDO,
        MOVIT.SOMADIMINUI,
        MOVIT.LOCAL,
        (MOVIT.QUANTIDADE/COALESCE(ITEMPREMB.MULTIPLIC,1)) AS QUANTIDADE,
        MOVIT.SEQTRANSFITEM,
        MOVIT.ORDEM_CRONOLOGICA,
        MOVIT.ORIGEM,
        MOVIT.CHAVE,
        MOVIT.ESTABORIGEM,
        MOVIT.ITEMORIGEM,
        --
        ITEMAGRO.DESCRICAO,
        ITEMAGRO.GRUPO,
        ITEMAGRO.UNIDADE,
        ITEMGRUPO.DESCRICAO AS DESCGRUPO,
        NFITEM.VALORUNITARIO,
        ROW_NUMBER() OVER(PARTITION BY MOVIT.ESTAB, MOVIT.ITEM ORDER BY MOVIT.DATAMOVIM, MOVIT.HORAMOVIM, MOVIT.SEQ) AS RN
    FROM MOVITEMAGRO MOVIT
        LEFT JOIN ITEMPREMB
            ON  MOVIT.ESTAB = ITEMPREMB.ESTAB
            AND MOVIT.ITEM = ITEMPREMB.ITEM
        INNER JOIN ITEMAGRO
            ON  MOVIT.ITEM = ITEMAGRO.ITEM
            LEFT JOIN ITEMGRUPO
                ON  ITEMAGRO.GRUPO = ITEMGRUPO.GRUPO
        LEFT JOIN NFITEM
            ON  MOVIT.ESTAB = NFITEM.ESTAB
            AND MOVIT.SEQ = NFITEM.SEQNOTA
            AND TO_NUMBER(REGEXP_SUBSTR(MOVIT.ORDEM_CRONOLOGICA, '([0-9]{5})$', 1, 1, NULL, 1)) = NFITEM.SEQNOTAITEM
    WHERE
            MOVIT.DATAMOVIM BETWEEN (:DTINI) AND (:DTFIM)
        AND MOVIT.CODIGOSALDO = (:COD_SALDO)
        AND (   0 IN (:ESTAB)
            OR  MOVIT.ESTAB IN (:ESTAB)
            )
        AND (   0 IN (:ITEM)
            OR  MOVIT.ITEM IN (:ITEM)
            )
    ),
/* v1: 1 linha por item com movimento; sem histórico = saldo/custo 0 */
INI AS
    (SELECT
        M.ESTAB,
        M.ITEM,
        NVL(SI.SALDOINI, 0)    AS SALDOINI,
        NVL(SI.CUSTOINI, 0)    AS CUSTOINI,
        NVL(SI.CUSTOTOTINI, 0) AS CUSTOTOTINI
    FROM (SELECT DISTINCT ESTAB, ITEM FROM MOVS) M
        LEFT JOIN SALDO_INI SI
            ON  SI.ESTAB = M.ESTAB
            AND SI.ITEM  = M.ITEM
    ),

RECURSIVO   (ESTAB, ITEM, DESCRICAO, GRUPO, DESCGRUPO, UNIDADE, SALDOINI, CUSTOINI, CUSTOTOTINI, DATAMOVIM, HORAMOVIM,
             DOC, NATUREZA, TIPODCTO, SOMADIMINUI, QUANTIDADE, VALORUNITARIO, RN, SALDO_QTD, SALDO_TOTAL, SALDO_UNIT
            ) AS
    (--------------------------------------------------- PRIMEIRA LINHA (âncora)
    SELECT
        M.ESTAB,
        M.ITEM,
        M.DESCRICAO,
        M.GRUPO,
        M.DESCGRUPO,
        M.UNIDADE,
        SI.SALDOINI,
        SI.CUSTOINI,
        SI.CUSTOTOTINI,
        M.DATAMOVIM,
        M.HORAMOVIM,
        M.DOC,
        M.NATUREZA,
        TO_CHAR(N.TIPODCTO) AS TIPODCTO,
        M.SOMADIMINUI,
        M.QUANTIDADE,
        M.VALORUNITARIO,
        M.RN,
        (SI.SALDOINI + CASE
                           WHEN M.SOMADIMINUI = 'S' THEN NVL(M.QUANTIDADE, 0)
                           ELSE -NVL(M.QUANTIDADE, 0)
                       END
        ) AS SALDO_QTD,
        (SI.CUSTOTOTINI +   CASE
                                WHEN M.SOMADIMINUI = 'S' THEN (M.QUANTIDADE * M.VALORUNITARIO)
                                ELSE -(M.QUANTIDADE * SI.CUSTOINI)
                            END
        ) AS SALDO_TOTAL,
        (   (SI.CUSTOTOTINI +   CASE
                                    WHEN M.SOMADIMINUI = 'S' THEN (M.QUANTIDADE * M.VALORUNITARIO)
                                    ELSE -(M.QUANTIDADE * SI.CUSTOINI)
                                END
            ) /
            COALESCE(NULLIF(SI.SALDOINI + CASE
                                              WHEN M.SOMADIMINUI = 'S' THEN NVL(M.QUANTIDADE, 0)
                                              ELSE -NVL(M.QUANTIDADE, 0)
                                          END, 0), 1)
        ) AS SALDO_UNIT
    FROM MOVS M
        JOIN INI SI
            ON  M.ESTAB = SI.ESTAB
            AND M.ITEM  = SI.ITEM
        LEFT JOIN NFCAB
            ON  M.ESTAB = NFCAB.ESTAB
            AND M.SEQ = NFCAB.SEQNOTA
            LEFT JOIN NFCFG
                ON  NFCAB.NOTACONF = NFCFG.NOTACONF
                LEFT JOIN NATOPERACAO N
                    ON  NFCFG.NATUREZADAOPERACAO = N.NATUREZADAOPERACAO
                    AND NFCFG.ENTRADASAIDA = N.ENTRADASAIDA
    WHERE M.RN = 1
    
    UNION ALL
    
    -------------------------------------------------------------- DEMAIS LINHAS
    SELECT
        M.ESTAB,
        M.ITEM,
        M.DESCRICAO,
        M.GRUPO,
        M.DESCGRUPO,
        M.UNIDADE,
        R.SALDOINI,
        R.CUSTOINI,
        R.CUSTOTOTINI,
        M.DATAMOVIM,
        M.HORAMOVIM,
        M.DOC,
        M.NATUREZA,
        TO_CHAR(N.TIPODCTO) AS TIPODCTO,
        M.SOMADIMINUI,
        M.QUANTIDADE,
        M.VALORUNITARIO,
        M.RN,
        (CASE
            WHEN M.SOMADIMINUI = 'S' THEN (R.SALDO_QTD + M.QUANTIDADE)
            ELSE (R.SALDO_QTD - M.QUANTIDADE)
        END
        ) AS SALDO_QTD,
        (CASE
            WHEN M.SOMADIMINUI = 'S' AND (M.NATUREZA <>'PI' AND N.TIPODCTO <>'D')
                THEN (R.SALDO_TOTAL + (M.QUANTIDADE * M.VALORUNITARIO))
            WHEN M.SOMADIMINUI = 'S' AND (M.NATUREZA = 'PI' OR N.TIPODCTO = 'D')
                THEN (R.SALDO_TOTAL + (M.QUANTIDADE * R.SALDO_UNIT))
            ELSE (R.SALDO_TOTAL - (M.QUANTIDADE * R.SALDO_UNIT))
        END
        ) AS SALDO_TOTAL,
        (CASE
            WHEN M.SOMADIMINUI = 'S' AND (M.NATUREZA <>'PI' AND N.TIPODCTO <>'D')
                THEN    (CASE
                            WHEN (R.SALDO_QTD + M.QUANTIDADE) = 0
                                THEN R.SALDO_UNIT
                            ELSE    (   (R.SALDO_TOTAL + (M.QUANTIDADE * M.VALORUNITARIO)) /
                                        COALESCE(NULLIF(R.SALDO_QTD + M.QUANTIDADE, 0), 1)
                                    )
                        END
                        )
            WHEN M.SOMADIMINUI = 'S' AND (M.NATUREZA = 'PI' OR N.TIPODCTO = 'D')
                THEN    (CASE
                            WHEN (R.SALDO_QTD + M.QUANTIDADE) = 0
                                THEN R.SALDO_UNIT
                            ELSE    (   (R.SALDO_TOTAL + (M.QUANTIDADE * R.SALDO_UNIT)) /
                                        COALESCE(NULLIF(R.SALDO_QTD + M.QUANTIDADE, 0), 1)
                                    )
                        END
                        )
            ELSE    (CASE
                        WHEN (R.SALDO_QTD - M.QUANTIDADE) = 0
                            THEN R.SALDO_UNIT
                        ELSE    (   (R.SALDO_TOTAL - (M.QUANTIDADE * R.SALDO_UNIT)) /
                                    COALESCE(NULLIF(R.SALDO_QTD - M.QUANTIDADE, 0), 1)
                                )
                    END
                    )
        END
        ) AS SALDO_UNIT
    FROM RECURSIVO R
        JOIN MOVS M
            ON  M.ESTAB = R.ESTAB      /* v1: casa também o item */
            AND M.ITEM  = R.ITEM
            AND M.RN    = (R.RN + 1)
            LEFT JOIN NFCAB
                ON  M.ESTAB = NFCAB.ESTAB
                AND M.SEQ = NFCAB.SEQNOTA
                LEFT JOIN NFCFG
                    ON  NFCAB.NOTACONF = NFCFG.NOTACONF
                    LEFT JOIN NATOPERACAO N
                        ON  NFCFG.NATUREZADAOPERACAO = N.NATUREZADAOPERACAO
                        AND NFCFG.ENTRADASAIDA = N.ENTRADASAIDA
    )
SELECT
    ESTABELECIMENTO,
    ITEM,
    GRUPO,
    UNIDADE,
    ROUND(SALDO_INICIAL, 2) AS SALDO_INICIAL,
    ROUND(CUSTO_UNIT, 2) AS CUSTO_UNIT,
    ROUND(CUSTO_INICIAL_TOTAL, 2) AS CUSTO_INICIAL_TOTAL,
    DATA_HORA,
    NUM_DOCTO,
    NAT,
    ROUND(QUANT_ENTRADA, 2) AS QUANT_ENTRADA,
    ROUND(VALORUNIT_ENTRADA, 2) AS VALORUNIT_ENTRADA,
    ROUND(VALORTOTAL_ENTRADA, 2) AS VALORTOTAL_ENTRADA,
    ROUND(QUANT_SAIDA, 2) AS QUANT_SAIDA,
    ROUND(VALORUNIT_SAIDA, 2) AS VALORUNIT_SAIDA,
    ROUND(VALORTOTAL_SAIDA, 2) AS VALORTOTAL_SAIDA,
    ROUND(QUANT_SALDO, 2) AS QUANT_SALDO,
    ROUND(VALORUNIT_SALDO, 2) AS VALORUNIT_SALDO,
    ROUND(VALORTOTAL_SALDO, 2) AS VALORTOTAL_SALDO
FROM
    (SELECT
        ESTAB AS ESTABELECIMENTO,
        (ITEM || '-' || DESCRICAO) AS ITEM,
        (GRUPO || '-' || DESCGRUPO) AS GRUPO,
        UNIDADE,
        SALDOINI AS SALDO_INICIAL,
        CUSTOINI AS CUSTO_UNIT,
        CUSTOTOTINI AS CUSTO_INICIAL_TOTAL,
        (DATAMOVIM || '-' || HORAMOVIM) AS DATA_HORA,
        DOC AS NUM_DOCTO,
        NATUREZA AS NAT,
        (CASE
            WHEN SOMADIMINUI = 'S' THEN QUANTIDADE
            ELSE 0
        END
        ) AS QUANT_ENTRADA,
        (CASE
            WHEN SOMADIMINUI = 'S' AND (NATUREZA <>'PI' AND TIPODCTO <>'D') THEN VALORUNITARIO
            WHEN SOMADIMINUI = 'S' AND (NATUREZA = 'PI' OR TIPODCTO = 'D') THEN R.SALDO_UNIT
            ELSE 0
        END
        ) AS VALORUNIT_ENTRADA,
        (CASE
            WHEN SOMADIMINUI = 'S' AND (NATUREZA <>'PI' AND TIPODCTO <>'D') THEN (QUANTIDADE * VALORUNITARIO)
            WHEN SOMADIMINUI = 'S' AND (NATUREZA = 'PI' OR TIPODCTO = 'D') THEN (QUANTIDADE * R.SALDO_UNIT)
            ELSE 0
        END
        ) AS VALORTOTAL_ENTRADA,
        (CASE
            WHEN SOMADIMINUI = 'D' THEN QUANTIDADE
            ELSE 0
        END
        ) AS QUANT_SAIDA,
        --------------------------------------------- NOVO: saída usa saldo anterior
        (CASE
            WHEN SOMADIMINUI = 'D' THEN R.SALDO_UNIT
            ELSE 0
        END
        ) AS VALORUNIT_SAIDA,
        (CASE
            WHEN SOMADIMINUI = 'D' THEN (QUANTIDADE * R.SALDO_UNIT)
            ELSE 0
        END
        ) AS VALORTOTAL_SAIDA,
        ----------------------------------------------------------------- NOVO SALDO
        R.SALDO_QTD AS QUANT_SALDO,
        R.SALDO_UNIT AS VALORUNIT_SALDO,
        R.SALDO_TOTAL AS VALORTOTAL_SALDO
    FROM RECURSIVO R
    ORDER BY
        DATAMOVIM,
        HORAMOVIM
    ) DADOS