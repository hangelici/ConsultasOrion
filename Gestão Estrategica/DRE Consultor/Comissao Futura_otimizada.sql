/* =====================================================================
   COMISSAO FUTURA - versao otimizada
   Mudancas em relacao a "Comissao Futura.sql" (mesma regra de negocio):
   1) BAIXAS: soma direto DPL x PRDUPREC (PRDUPREC e unica por
      EMPRESA/DUPREC/SEQRECBTO), eliminando um HASH GROUP BY.
   2) DUP_ABERTAS: aplica o filtro de saldo em aberto ANTES dos joins
      com AGRFINDUPREC/NFCABAGRFIN/NFCAB/NFITEM (antes era aplicado
      depois, sobre 1,2 mi de linhas, para sobrar ~32 mil).
   3) Blocos empresa 5 / demais unificados (1 leitura de PDUPREC e
      PRDURECH em vez de 2). A regra de comissao por empresa vai em CASE.
   4) Removidos joins sem efeito no resultado: PPESCLI e ITEMGRUPO
      (chave unica, nenhuma coluna usada) e PREPRESE nos blocos
      empresa <> 5 (nao era usado).
   5) Margem/valor liquido calculados uma vez (antes eram repetidos
      dentro de cada WHEN do CASE).
   ===================================================================== */
WITH DPL AS (
    SELECT EMPRESA,DUPREC,SEQRECBTO,VALOR      AS VALOR FROM PRDUPRED
    UNION ALL
    SELECT EMPRESA,DUPREC,SEQRECBTO,VLRCHEQREC AS VALOR FROM PRDURECH
    UNION ALL
    SELECT EMPRESA,DUPREC,SEQRECBTO,VALOR      FROM PRDUREDUP
    UNION ALL
    SELECT EMPRESA,DUPREC,SEQRECBTO,VALOR      FROM PRDURECAR
    UNION ALL
    SELECT EMPRESA,DUPREC,SEQRECBTO,VALOR      FROM PRDUREOUT
    UNION ALL
    SELECT EMPRESA,DUPREC,SEQRECBTO,VALOR      FROM PRDURECM WHERE TROCO = 'N'
),
BAIXAS AS (
    SELECT
        PRDUPREC.EMPRESA,
        PRDUPREC.DUPREC,
        SUM(CASE WHEN PRDUPREC.TIPOREC = 'J' THEN DPL.VALOR ELSE 0 END) AS JUROS,
        SUM(CASE WHEN PRDUPREC.TIPOREC = 'R' THEN DPL.VALOR ELSE 0 END) AS REC,
        SUM(CASE WHEN PRDUPREC.TIPOREC = 'D' THEN DPL.VALOR ELSE 0 END) AS DESCTO
    FROM PRDUPREC
    INNER JOIN DPL ON
            DPL.EMPRESA   = PRDUPREC.EMPRESA
        AND DPL.DUPREC    = PRDUPREC.DUPREC
        AND DPL.SEQRECBTO = PRDUPREC.SEQRECBTO
    WHERE PRDUPREC.TIPOREC IN ('R','J','D')
    GROUP BY PRDUPREC.EMPRESA, PRDUPREC.DUPREC
),
/* ---------------------------------------------------------------------
   Duplicatas em aberto (todas as empresas) - filtro de saldo primeiro
   --------------------------------------------------------------------- */
DUP_ABERTAS AS (
    -- Ordem forcada: filtra saldo (PDUPREC x BAIXAS) e so depois valida CONTAMOV/REPRE
    -- (antes o REPRE era validado nas ~728 mil duplicatas, ~717 mil buffers)
    SELECT /*+ MATERIALIZE LEADING(PDUPREC BAIXAS CONTAMOV REPRE) USE_HASH(BAIXAS) USE_NL(CONTAMOV REPRE) */
        PDUPREC.EMPRESA,
        PDUPREC.DUPREC,
        PDUPREC.CLIENTE,
        PDUPREC.REPRESENT,
        PDUPREC.DTEMISSAO,
        PDUPREC.VALOR,
        COALESCE(BAIXAS.REC,0)    AS REC,
        COALESCE(BAIXAS.JUROS,0)  AS JUROS,
        COALESCE(BAIXAS.DESCTO,0) AS DESCTO
    FROM PDUPREC
    LEFT JOIN BAIXAS ON
            BAIXAS.EMPRESA = PDUPREC.EMPRESA
        AND BAIXAS.DUPREC  = PDUPREC.DUPREC
    INNER JOIN CONTAMOV      ON CONTAMOV.NUMEROCM = PDUPREC.CLIENTE
    INNER JOIN CONTAMOV REPRE ON REPRE.NUMEROCM   = PDUPREC.REPRESENT
    WHERE PDUPREC.REPRESENT > 100
      AND PDUPREC.DTEMISSAO <= CURRENT_DATE
      AND PDUPREC.VALOR - COALESCE(BAIXAS.REC,0) > 0
),
DUP AS (
    SELECT DISTINCT
        'DUP' AS TIPODOC,
        B.OSESTAB,
        B.NOTA,
        B.OSRTV,
        B.NUMEROCM,
        B.DTEMISSAO,
        B.DTVENCTO,
        B.OSPRODUTO,
        B.QUANTIDADE,
        B.VALORUNITARIO,
        B.VALORTOTAL,
        B.VALOR,
        B.SALDO,
        B.VALORLIQ,
        B.RECEBIDO,
        B.MARGEM,
        CASE
            WHEN B.OSESTAB = 5 THEN
                CASE
                    WHEN B.COMISCONF = 10 THEN ARREDONDAR(B.VALORLIQ_BRUTO * 0.003, 2)
                    WHEN B.COMISCONF = 11 THEN ARREDONDAR(B.VALORLIQ_BRUTO * 0.01 , 2)
                    ELSE                       ARREDONDAR(B.VALORLIQ_BRUTO * 0.005, 2)   -- 9 e demais
                END
            ELSE
                CASE
                    WHEN B.MARGEM BETWEEN 0  AND 19.99 THEN ARREDONDAR((B.VALORLIQ * DIVIDE(B.MARGEM,100)) * 0.05, 2)
                    WHEN B.MARGEM BETWEEN 20 AND 24.99 THEN ARREDONDAR((B.VALORLIQ * DIVIDE(B.MARGEM,100)) * 0.08, 2)
                    ELSE                                    ARREDONDAR((B.VALORLIQ * DIVIDE(B.MARGEM,100)) * 0.1 , 2)
                END
        END AS PROVISAOLIQ,
        B.CUSTOCMVP
    FROM (
        SELECT /*+ NO_MERGE LEADING(D) USE_NL(AGR NFA NFI IA NFC) */
            D.EMPRESA            AS OSESTAB,
            NFC.NOTA,
            D.REPRESENT          AS OSRTV,
            D.CLIENTE            AS NUMEROCM,
            D.DTEMISSAO,
            NFC.PRAZOPAGTO       AS DTVENCTO,
            IA.ITEM              AS OSPRODUTO,
            NFI.QUANTIDADE,
            NFI.VALORUNITARIO,
            NFI.VALORTOTAL,
            NFI.CUSTOCMVP,
            PR.COMISCONF,
            D.VALOR,
            D.VALOR - D.REC      AS SALDO,
            D.REC                AS RECEBIDO,
            (NFI.VALORTOTAL + D.JUROS - D.DESCTO - (DIVIDE(NFI.VALORTOTAL, D.VALOR) * D.REC))               AS VALORLIQ_BRUTO,
            ARREDONDAR((NFI.VALORTOTAL + D.JUROS - D.DESCTO - (DIVIDE(NFI.VALORTOTAL, D.VALOR) * D.REC)), 2) AS VALORLIQ,
            ARREDONDAR(DIVIDE(NFI.VALORTOTAL - (NFI.QUANTIDADE * NFI.CUSTOCMVP), NFI.VALORTOTAL) * 100, 2)  AS MARGEM
        FROM DUP_ABERTAS D
        LEFT JOIN AGRFINDUPREC AGR ON
                AGR.ESTAB  = D.EMPRESA
            AND AGR.DUPREC = D.DUPREC
        LEFT JOIN NFCABAGRFIN NFA ON
                NFA.ESTAB        = AGR.ESTAB
            AND NFA.SEQPAGAMENTO = AGR.SEQPAGAMENTO
        LEFT JOIN NFITEM NFI ON
                NFI.ESTAB   = NFA.ESTAB
            AND NFI.SEQNOTA = NFA.SEQNOTA
        LEFT JOIN ITEMAGRO IA ON
                IA.ITEM = NFI.ITEM
        LEFT JOIN NFCAB NFC ON
                NFC.ESTAB   = NFA.ESTAB
            AND NFC.SEQNOTA = NFA.SEQNOTA
        -- Regra original: empresa 5 liga PREPRESE apenas por REPRESENT (sem EMPRESA)
        LEFT JOIN PREPRESE PR ON
                PR.REPRESENT = D.REPRESENT
            AND D.EMPRESA    = 5
    ) B
),
/* ---------------------------------------------------------------------
   Cheques a compensar (todas as empresas)
   --------------------------------------------------------------------- */
CHQ AS (
    SELECT DISTINCT
        'CHQ' AS TIPODOC,
        B.OSESTAB,
        B.NOTA,
        B.OSRTV,
        B.NUMEROCM,
        B.DTEMISSAO,
        B.DTVENCTO,
        B.OSPRODUTO,
        B.QUANTIDADE,
        B.VALORUNITARIO,
        B.VALORTOTAL,
        B.VALOR,
        B.VALOR AS SALDO,
        B.VALORLIQ,
        0 AS RECEBIDO,
        B.MARGEM,
        CASE
            WHEN B.OSESTAB = 5 THEN
                CASE
                    WHEN B.COMISCONF = 10 THEN ARREDONDAR(B.VALORLIQ * 0.03, 2)
                    ELSE                       ARREDONDAR(B.VALORLIQ * 0.05, 2)   -- 9, 11 e demais
                END
            ELSE
                CASE
                    WHEN B.MARGEM BETWEEN 0  AND 19.99 THEN ARREDONDAR((B.VALORLIQ * DIVIDE(B.MARGEM,100)) * 0.05, 2)
                    WHEN B.MARGEM BETWEEN 20 AND 24.99 THEN ARREDONDAR((B.VALORLIQ * DIVIDE(B.MARGEM,100)) * 0.08, 2)
                    ELSE                                    ARREDONDAR((B.VALORLIQ * DIVIDE(B.MARGEM,100)) * 0.1 , 2)
                END
        END AS PROVISAOLIQ,
        B.CUSTOCMVP
    FROM (
        SELECT /*+ NO_MERGE */
            G.*,
            DIVIDE(G.VALOR * (DIVIDE(G.VALORTOTAL, G.VALOR) * 100), 100)                                AS VALORLIQ,
            ARREDONDAR(DIVIDE(G.VALORTOTAL - (G.QUANTIDADE * G.CUSTOCMVP), G.VALORTOTAL) * 100, 2)       AS MARGEM
        FROM (
            SELECT /*+ USE_NL(AGR NFA NFI IA NFC) */
                PDUPREC.EMPRESA          AS OSESTAB,
                NFC.NOTA,
                PDUPREC.REPRESENT        AS OSRTV,
                PDUPREC.CLIENTE          AS NUMEROCM,
                PRDURECH.DTLANCA         AS DTEMISSAO,
                PDUPREC.DTVENCTO         AS DTVENCTO,
                IA.ITEM                  AS OSPRODUTO,
                NFI.QUANTIDADE,
                NFI.VALORUNITARIO,
                NFI.VALORTOTAL,
                NFI.CUSTOCMVP,
                PR.COMISCONF,
                SUM(PRDURECH.VLRCHEQREC) AS VALOR
            FROM PCHEQREC
            INNER JOIN PRDURECH ON
                    PRDURECH.EMPRESA   = PCHEQREC.EMPRESA
                AND PRDURECH.CLIENTE   = PCHEQREC.CLIENTE
                AND PRDURECH.NROCHEQUE = PCHEQREC.NROCHEQUE
            INNER JOIN PRDUPREC ON
                    PRDUPREC.EMPRESA   = PRDURECH.EMPRESA
                AND PRDUPREC.DUPREC    = PRDURECH.DUPREC
                AND PRDUPREC.SEQRECBTO = PRDURECH.SEQRECBTO
            INNER JOIN PDUPREC ON
                    PDUPREC.EMPRESA = PRDUPREC.EMPRESA
                AND PDUPREC.DUPREC  = PRDUPREC.DUPREC
            INNER JOIN CONTAMOV       ON CONTAMOV.NUMEROCM = PDUPREC.CLIENTE
            INNER JOIN CONTAMOV REPRE ON REPRE.NUMEROCM    = PDUPREC.REPRESENT
            LEFT JOIN AGRFINDUPREC AGR ON
                    AGR.ESTAB  = PDUPREC.EMPRESA
                AND AGR.DUPREC = PDUPREC.DUPREC
            LEFT JOIN NFCABAGRFIN NFA ON
                    NFA.ESTAB        = AGR.ESTAB
                AND NFA.SEQPAGAMENTO = AGR.SEQPAGAMENTO
            LEFT JOIN NFITEM NFI ON
                    NFI.ESTAB   = NFA.ESTAB
                AND NFI.SEQNOTA = NFA.SEQNOTA
            LEFT JOIN ITEMAGRO IA ON
                    IA.ITEM = NFI.ITEM
            LEFT JOIN NFCAB NFC ON
                    NFC.ESTAB   = NFA.ESTAB
                AND NFC.SEQNOTA = NFA.SEQNOTA
            -- Regra original: so a empresa 5 usa COMISCONF (join por REPRESENT + EMPRESA)
            LEFT JOIN PREPRESE PR ON
                    PR.REPRESENT    = PDUPREC.REPRESENT
                AND PR.EMPRESA      = PDUPREC.EMPRESA
                AND PDUPREC.EMPRESA = 5
            WHERE PCHEQREC.DTLANCA IS NULL
              AND PCHEQREC.VALOR > 0
              AND PRDUPREC.DTRECBTO <= CURRENT_DATE
              AND PDUPREC.REPRESENT > 100
            GROUP BY
                PDUPREC.EMPRESA,
                NFC.NOTA,
                PDUPREC.REPRESENT,
                PR.COMISCONF,
                PDUPREC.CLIENTE,
                PRDURECH.DTLANCA,
                PDUPREC.DTVENCTO,
                IA.ITEM,
                NFI.QUANTIDADE,
                NFI.VALORUNITARIO,
                NFI.VALORTOTAL,
                PDUPREC.VALOR,
                NFI.CUSTOCMVP
            HAVING SUM(PRDURECH.VLRCHEQREC) > 0
        ) G
    ) B
)
SELECT /*+ GATHER_PLAN_STATISTICS */
    DADOS.OSESTAB     AS ESTAB,
    DADOS.OSRTV       AS REPRESENT,
    SUM(DADOS.PROVISAOLIQ) AS PROVISAOLIQ
FROM (
    SELECT OSESTAB, OSRTV, PROVISAOLIQ FROM CHQ
    UNION ALL
    SELECT OSESTAB, OSRTV, PROVISAOLIQ FROM DUP
) DADOS
GROUP BY
    DADOS.OSESTAB,
    DADOS.OSRTV
HAVING SUM(DADOS.PROVISAOLIQ) > 0;

/* Para medir (mesma sessao, logo apos executar a consulta acima):
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST +PREDICATE'));
*/
