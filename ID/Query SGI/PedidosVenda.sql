SELECT 
                CASE WHEN PEDIDO.ACAO = 'B'
                        THEN 'BLOQUEADO'
                        ELSE 'N-BLOQUEADO'
                END ACAO,
                DADOS.ESTAB||'-'||DADOS.FILIAL AS filial,
                CASE WHEN (DADOS.ETAPA = 1) THEN '1 - Comercial'
                    WHEN (DADOS.ETAPA = 2) THEN '2 - Financeira'
                    WHEN (DADOS.ETAPA = 3) THEN '3 - Faturamento'
                    WHEN (DADOS.ETAPA = 4) THEN '4 - Pedido Liberado'
                    WHEN (DADOS.ETAPA = 5) THEN '5 - Pedido Atendido'
                    ELSE  'Sem Etapa'
                END ETAPA,
                TO_CHAR(DADOS.DTEMISSAO,'DD/MM/YYYY') AS DTEMISSAO,
                DADOS.NUMERO || ' - ' ||  DADOS.SERIE AS PEDIDO,
                PEDIDO.MOTIVO,
                COALESCE(PEDIDO.HORAALTERACAO,'  ') AS HORA,
                UPPER(COALESCE(PEDIDO.HISTORICO,'Em Branco')) AS HISTORICO,
            -- ## Começo Coluna de Tempo
                COALESCE(CASE
                WHEN PEDIDO.DTALTERACAO IS NULL
                    THEN EXTRACT(DAY FROM (CURRENT_TIMESTAMP - DADOS.ULTALT))
                ELSE EXTRACT(DAY FROM (CURRENT_TIMESTAMP - PEDIDO.DTALTERACAO))
                        END,0) || ' Dias, ' ||
                COALESCE(CASE
                WHEN PEDIDO.DTALTERACAO IS  NULL
                    THEN EXTRACT(HOUR FROM (CURRENT_TIMESTAMP - DADOS.ULTALT))
                ELSE EXTRACT(HOUR FROM (CURRENT_TIMESTAMP - (CAST(PEDIDO.DTALTERACAO||' '||PEDIDO.HORAALTERACAO AS TIMESTAMP DEFAULT NULL ON CONVERSION ERROR, 'DD/MM/YYYY HH24:MI:SS'))))
                END,0) || ' Horas e ' ||
                COALESCE(CASE
                WHEN PEDIDO.DTALTERACAO IS  NULL
                    THEN EXTRACT(MINUTE FROM (CURRENT_TIMESTAMP - DADOS.ULTALT))
                ELSE EXTRACT(MINUTE FROM (CURRENT_TIMESTAMP - (CAST(PEDIDO.DTALTERACAO||' '||PEDIDO.HORAALTERACAO AS TIMESTAMP DEFAULT NULL ON CONVERSION ERROR, 'DD/MM/YYYY HH24:MI:SS'))))
                END,0) || ' Minutos' AS TEMPO,
            -- ## Fim Coluna de Tempo
            -- ## Inicio coluna de tempo em minutos
            COALESCE(CASE
                WHEN PEDIDO.DTALTERACAO IS NULL AND PEDIDO.HORAALTERACAO IS NULL
                    THEN EXTRACT(DAY FROM (CURRENT_TIMESTAMP - DADOS.ULTALT)) * 1440
                    +  EXTRACT(HOUR FROM (CURRENT_TIMESTAMP - DADOS.ULTALT)) * 60
                    +  EXTRACT(MINUTE FROM (CURRENT_TIMESTAMP - DADOS.ULTALT))
                ELSE
                    EXTRACT(MINUTE FROM (CURRENT_TIMESTAMP - (CAST(PEDIDO.DTALTERACAO||' '||PEDIDO.HORAALTERACAO AS TIMESTAMP DEFAULT NULL ON CONVERSION ERROR, 'DD/MM/YYYY HH24:MI:SS'))))
                    + EXTRACT(HOUR FROM (CURRENT_TIMESTAMP - (CAST(PEDIDO.DTALTERACAO||' '||PEDIDO.HORAALTERACAO AS TIMESTAMP DEFAULT NULL ON CONVERSION ERROR, 'DD/MM/YYYY HH24:MI:SS')))) * 60
                    + (EXTRACT(DAY FROM CURRENT_DATE) - EXTRACT(DAY FROM PEDIDO.DTALTERACAO)) * 1440
            END,0) DIF_MIN, 
                DADOS.CLIENTE,
                DADOS.VALOR,
                DADOS.REPRESENTANTE,
                CLIENTELJ
            FROM (
                SELECT /*+ DYNAMIC_SAMPLING(PEDCAB 4) */ DISTINCT
                    HIST.IDAPRVPEDCABHIST,
                    FILIAL.ESTAB,
                    FILIAL.REDUZIDO AS FILIAL,
                    PEDCAB.ETAPA,
                    PEDCAB.DTEMISSAO AS DTEMISSAO,
                    CAST (PEDCAB.ULTALT AS TIMESTAMP) AS ULTALT,
                    PEDCAB.NUMERO,
                    PEDCAB.SERIE,
                    CONCEITO.DESCRICAO||'-'||CLIENTE.NOME||' - '||CLIENTE.NUMEROCM AS CLIENTE,
                    PEDCAB.VALORMERCADORIA AS VALOR,
                    REP.NOME||' - '||REP.NUMEROCM AS REPRESENTANTE,
                    COALESCE(PEDCAB_U.CLIENTELJ,'N') AS CLIENTELJ
                FROM PEDCAB
                INNER JOIN FILIAL
                    ON FILIAL.ESTAB = PEDCAB.ESTAB
                INNER JOIN U_TEMPRESA
                    ON U_TEMPRESA.ESTAB = FILIAL.ESTAB
                INNER JOIN CONTAMOV CLIENTE
                    ON CLIENTE.NUMEROCM = PEDCAB.PESSOA
                LEFT JOIN CONTAMOV REP
                    ON REP.NUMEROCM = PEDCAB.REPRESENT
                LEFT JOIN CONCEITOPESSOA ON
                    CONCEITOPESSOA.NUMEROCM = CLIENTE.NUMEROCM
                LEFT JOIN CONCEITO ON
                    CONCEITO.CONCEITO = CONCEITOPESSOA.CONCEITO
                INNER JOIN PEDITEM
                    ON PEDITEM.ESTAB = PEDCAB.ESTAB
                    AND PEDITEM.SERIE = PEDCAB.SERIE
                    AND PEDITEM.NUMERO = PEDCAB.NUMERO
                LEFT JOIN PEDCAB_U
                    ON PEDCAB_U.ESTAB = PEDCAB.ESTAB
                    AND PEDCAB_U.SERIE = PEDCAB.SERIE
                    AND PEDCAB_U.NUMERO = PEDCAB.NUMERO
                INNER JOIN ITEMAGRO
                    ON ITEMAGRO.ITEM = PEDITEM.ITEM
                -- ## BAIXAS DO PEDIDO
                LEFT JOIN (
                    SELECT
                        PEDITEMNFITEM.ESTAB,
                        PEDITEMNFITEM.SERIE,
                        PEDITEMNFITEM.NUMERO,
                        PEDITEMNFITEM.SEQPEDITE,
                        SUM(PEDITEMNFITEM.QUANTIDADE) AS QUANTIDADE
                    FROM PEDITEMNFITEM
                    WHERE SERIE = 'PV'
                    GROUP BY
                        PEDITEMNFITEM.ESTAB,
                        PEDITEMNFITEM.SERIE,
                        PEDITEMNFITEM.NUMERO,
                        PEDITEMNFITEM.SEQPEDITE
                ) BAIXADO
                ON BAIXADO.ESTAB = PEDITEM.ESTAB
                AND BAIXADO.SERIE = PEDITEM.SERIE
                AND BAIXADO.NUMERO = PEDITEM.NUMERO
                AND BAIXADO.SEQPEDITE = PEDITEM.SEQPEDITE
                -- ## HISTORICO DO PEDIDO
                LEFT JOIN (
                    SELECT
                        MAX(IDAPRVPEDCABHIST) AS IDAPRVPEDCABHIST,
                        APRVPEDCABHIST.ESTAB,
                        APRVPEDCABHIST.SERIE,
                        APRVPEDCABHIST.NUMERO
                    FROM APRVPEDCABHIST
                    GROUP BY
                        APRVPEDCABHIST.ESTAB,
                        APRVPEDCABHIST.SERIE,
                        APRVPEDCABHIST.NUMERO
                ) HIST
                ON HIST.ESTAB = PEDCAB.ESTAB
                AND HIST.SERIE = PEDCAB.SERIE
                AND HIST.NUMERO = PEDCAB.NUMERO
                WHERE U_TEMPRESA.INSUMOS = 'S'
                AND PEDCAB.SERIE IN ('PV','PVM')
                AND PEDCAB.STATUS NOT IN ('C','B')  
                AND (PEDITEM.QUANTIDADE - COALESCE(BAIXADO.QUANTIDADE,0)) > 0
            )DADOS
            LEFT JOIN APRVPEDCABHIST PEDIDO
                ON PEDIDO.ESTAB = DADOS.ESTAB
                AND PEDIDO.SERIE = DADOS.SERIE
                AND PEDIDO.NUMERO = DADOS.NUMERO
                AND PEDIDO.IDAPRVPEDCABHIST = DADOS.IDAPRVPEDCABHIST
                --WHERE DADOS.NUMERO = 61987 AND DADOS.ESTAB = 13
            ORDER BY 1 DESC