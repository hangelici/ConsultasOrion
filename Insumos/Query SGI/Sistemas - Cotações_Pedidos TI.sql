WITH
SOLMAT_FILTRADA AS (
    SELECT /*+ MATERIALIZE */
        SM.ESTAB,
        SM.IDSOLMAT

    FROM SOLMAT SM

    WHERE
        SM.USUARIOSOL IN (
            'LUA.MARTINS',
            'ELTON.SILVA',
            'MURILO.LEMES',
            'HENRI.GUARI'
        )

        OR EXISTS (
            SELECT 1
            FROM PUSUARIO PU
            INNER JOIN PGRUPOS PG
                ON PG.CODIGO = PU.GRUPO
            WHERE PU.USERID = SM.USUARIOSOL
              AND PG.CODIGO IN (59, 60, 61, 62)
        )
),

COTACOES_BASE AS (
    SELECT /*+ MATERIALIZE */
        DISTINCT
        CC.ESTAB,
        CC.IDCOTACAOCOMPRA,
        CC.STATUS

    FROM SOLMAT_FILTRADA SM

    INNER JOIN SOLMATDET SMD
        ON SMD.ESTAB = SM.ESTAB
       AND SMD.IDSOLMAT = SM.IDSOLMAT

    INNER JOIN SOLMATDETCOTACAO SDC
        ON SDC.ESTAB = SMD.ESTAB
       AND SDC.IDSOLMAT = SMD.IDSOLMAT
       AND SDC.IDSOLMATDET = SMD.IDSOLMATDET

    INNER JOIN COTACAOCOMPRA CC
        ON CC.ESTAB = SDC.ESTAB
       AND CC.IDCOTACAOCOMPRA =
           SDC.IDCOTACAOCOMPRA
),

COTACOES_VALIDAS AS (

    -- Regra 1:
    -- Status 0 e 1 entram independentemente
    -- da existencia de pedidos.

    SELECT
        CASE
            WHEN CB.STATUS = 0
                THEN 'Em Andamento'
            WHEN CB.STATUS = 1
                THEN 'Em Aprovação'
        END AS STATUS,

        CB.ESTAB || '#' ||
        CB.IDCOTACAOCOMPRA AS CHAVE

    FROM COTACOES_BASE CB

    WHERE CB.STATUS IN (0, 1)

    UNION ALL

    -- Regra 2:
    -- Outros status somente entram quando
    -- existe pedido com status diferente de B/C.

    SELECT
        'Pedido em Aberto' AS STATUS,

        CB.ESTAB || '#' ||
        CB.IDCOTACAOCOMPRA AS CHAVE

    FROM COTACOES_BASE CB

    WHERE
        (
            CB.STATUS NOT IN (0, 1)
            OR CB.STATUS IS NULL
        )

        AND EXISTS (
            SELECT 1

            FROM FORNECEDORESCOTACAO FC

            INNER JOIN ITENSCOTACAO IC
                ON IC.IDFORNECEDORES =
                   FC.IDFORNECEDORES

            INNER JOIN COTACAOPEDITEM CPI
                ON CPI.IDITEMCOTACAO =
                   IC.IDITEMCOTACAO

            INNER JOIN PEDITEM PI
                ON PI.ESTAB = CPI.ESTAB
               AND PI.SERIE = CPI.SERIE
               AND PI.NUMERO = CPI.NUMERO

            INNER JOIN PEDCAB PC
                ON PC.ESTAB = PI.ESTAB
               AND PC.SERIE = PI.SERIE
               AND PC.NUMERO = PI.NUMERO

            WHERE
                FC.IDCOTACAOCOMPRA =
                    CB.IDCOTACAOCOMPRA

                AND PC.STATUS NOT IN ('B', 'C')
        )
)

SELECT
    STATUS,
    COUNT(CHAVE) AS QUANTIDADE

FROM COTACOES_VALIDAS

GROUP BY STATUS

ORDER BY STATUS