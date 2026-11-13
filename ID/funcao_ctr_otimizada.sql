/* =====================================================================
   funcao_ctr_otimizada.sql
   Versão otimizada de funcao_ctr.sql (original NÃO alterado) para validação.

   DIAGNÓSTICO DO PLANO (SQL_ID 7q8u84c65jstw, plan hash 1434285772)
   ---------------------------------------------------------------------
   - Tempo total: 4,06 s. Quase todo o custo está no CTE BAIXAS:
       Id 56  HASH JOIN CONTRATONFITE x NFCAB ..... 2,63 s / 120 MB de workarea
              (build 1,16 mi linhas; probe com 3,94 mi linhas de NFCAB via
               INDEX FAST FULL SCAN IDX_NFCAB_ESTAB_NOTA_CONF)
       Id 53  HASH JOIN com CLASSE ................ +0,3 s
       Id 51  HASH GROUP BY (1,16 mi linhas) ...... +0,4 s
   - O restante (CLASSE, CANC, contratos, filiais) soma < 0,5 s.
   - A-Rows = 250 no topo: o cliente buscou só a 1ª página. Como o GROUP BY
     é bloqueante, os 4 s já incluem montar BAIXAS inteiro, mas o fetch completo
     (~142 mil linhas) ainda soma NL em CONTAMOV/ITEMAGRO/U_AGRPRODGR e
     142 mil chamadas da função PL/SQL ARREDONDAR.
   - GATHER_PLAN_STATISTICS / statistics_level=ALL inflam o tempo de operações
     com muitas linhas. Meça o tempo real sem o hint.

   O QUE MUDOU (todas as mudanças preservam o resultado; validar abaixo)
   ---------------------------------------------------------------------
   1. CLASSE filtrada: pares (NOTACONF, CONTCONF) com os 3 flags = 0 só somam
      zero. Removê-los não altera BAIXADO/DEVOLIDO/CANCELADO/QTDSALDO (o NVL
      já transforma "sem linha" em 0) e reduz as linhas que passam pelo
      join/GROUP BY.
   2. Pré-filtro em NFCAB por NOTACONF relevante (semi-join com CLASSE):
      permite descartar notas antes do hash join de 3,9 mi linhas.
   3. CTRNOTA + BAIXAS fundidos num único SELECT ... GROUP BY.
   4. Join com CONTRATOITE removido de CTRNOTA: o otimizador já o eliminava
      (FK validada), então é só limpeza.
   5. CANC agrega apenas CONTRATOCANC: os filtros de contrato
      (CONTRATOCFG E/S, CONTRATOCFG_U) já são aplicados na consulta externa,
      que é a única que consome CANC. Economiza o scan de CONTRATO03 e joins.
   6. LEFT JOIN U_TIPOCTR (sem colunas usadas, já eliminado no plano)
      removido. LEFT JOIN FILIAL virou INNER (o WHERE FILIAL.INATIVA='N' já
      o tornava inner).
   ===================================================================== */

WITH
CLASSE AS (
    SELECT /*+ MATERIALIZE */
           NOTACONF, CONTCONF, F_BAIXADO, F_DEVOLIDO, F_CANCELADO
    FROM (
        SELECT
        NFCFG.NOTACONF,
        CONTRATOCFG.CONTCONF,
        CASE
            WHEN (NAT.TIPODCTO IN ('N','X','A','T') and NFCFG.NOTACONF not IN (1041)) AND NATAPARTIRDE.TIPOBAIXA IN ('A','Q') AND NFCFG.NOTACONF NOT IN (291) AND NATAPARTIRDE.OPERACAO NOT IN ('N','R') THEN 1
            WHEN NAT.TIPODCTO IN ('D') AND NATAPARTIRDE.TIPOBAIXA IN ('A','Q') AND NAT.ENTRADASAIDA = 'E' AND CONTRATOCFG.ENTRADASAIDA = 'E' AND NATAPARTIRDE.OPERACAO NOT IN ('N','R') THEN 1
            WHEN NAT.TIPODCTO IN ('D') AND NATAPARTIRDE.TIPOBAIXA IN ('A','Q') AND NAT.ENTRADASAIDA = 'S' AND CONTRATOCFG.ENTRADASAIDA = 'S' AND NATAPARTIRDE.OPERACAO NOT IN ('N','R') THEN 1
            ELSE 0
        END F_BAIXADO,
        CASE
            WHEN NAT.TIPODCTO IN ('D') AND NATAPARTIRDE.TIPOBAIXA IN ('A','Q') AND NAT.ENTRADASAIDA = 'E' AND CONTRATOCFG.ENTRADASAIDA = 'E' AND NATAPARTIRDE.OPERACAO NOT IN ('N','R') THEN 0
            WHEN NAT.TIPODCTO IN ('D') AND NATAPARTIRDE.TIPOBAIXA IN ('A','Q') AND NAT.ENTRADASAIDA = 'S' AND CONTRATOCFG.ENTRADASAIDA = 'S' AND NATAPARTIRDE.OPERACAO NOT IN ('N','R') THEN 0
            WHEN (NAT.TIPODCTO = 'D' OR NFCFG.NOTACONF IN (1041)) AND NATAPARTIRDE.TIPOBAIXA IN ('A','Q') AND NATAPARTIRDE.OPERACAO NOT IN ('N','R') THEN 1
            ELSE 0
        END F_DEVOLIDO,
        CASE
            WHEN NAT.TIPODCTO IN ('N','X','A') AND NATAPARTIRDE.TIPOBAIXA IN ('A','Q') AND NFCFG.NOTACONF IN (291) AND NATAPARTIRDE.OPERACAO NOT IN ('N','R') THEN 1
            ELSE 0
        END F_CANCELADO
        FROM NFCFG
        INNER JOIN NATOPERACAO NAT ON NAT.NATUREZADAOPERACAO = NFCFG.NATUREZADAOPERACAO AND NAT.ENTRADASAIDA = NFCFG.ENTRADASAIDA
        CROSS JOIN CONTRATOCFG
        INNER JOIN CONTRATOCFG_U ON CONTRATOCFG_U.CONTCONF = CONTRATOCFG.CONTCONF
        LEFT JOIN NATAPARTIRDE ON
            NATAPARTIRDE.NATUREZADAOPERACAO = NAT.NATUREZADAOPERACAO
            AND NATAPARTIRDE.ENTRADASAIDA = NAT.ENTRADASAIDA
            AND NATAPARTIRDE.NATOPERORIGEM = CONTRATOCFG.NATUREZA
            AND NATAPARTIRDE.ENTRADASAIDAORIGEM = CONTRATOCFG.ENTRADASAIDA
        WHERE CONTRATOCFG.ENTRADASAIDA IN ('E','S')
    )
    WHERE F_BAIXADO + F_DEVOLIDO + F_CANCELADO > 0          -- (1) só pares que somam algo
),
BAIXAS AS (                                                  -- (3) CTRNOTA + BAIXAS
    SELECT
    CNI.ESTAB,
    CNI.CONTRATO,
    CNI.SEQITEM,
    SUM(CASE WHEN CL.F_BAIXADO   = 1 THEN CNI.QUANTIDADE ELSE 0 END) AS BAIXADO,
    SUM(CASE WHEN CL.F_DEVOLIDO  = 1 THEN CNI.QUANTIDADE ELSE 0 END) AS DEVOLIDO,
    SUM(CASE WHEN CL.F_CANCELADO = 1 THEN CNI.QUANTIDADE ELSE 0 END) AS CANCELADO
    FROM CONTRATONFITE CNI
    INNER JOIN CONTRATO C  ON C.ESTAB = CNI.ESTAB AND C.CONTRATO = CNI.CONTRATO
    INNER JOIN NFCAB    NF ON NF.ESTAB = CNI.ESTABNOTA AND NF.SEQNOTA = CNI.SEQNOTA
    INNER JOIN CLASSE   CL ON CL.NOTACONF = NF.NOTACONF AND CL.CONTCONF = C.CONTCONF
    -- (2) pré-filtro por NOTACONF REMOVIDO após a rodada 2: 99% das notas
    --     vinculadas a contrato são relevantes (1.157K de 1.165K); o semi-join
    --     só adicionava custo.
    GROUP BY CNI.ESTAB, CNI.CONTRATO, CNI.SEQITEM
),
CANC AS (                                                    -- (5) só a tabela de cancelamento
    SELECT
    CONTRATOCANC.ESTAB,
    CONTRATOCANC.CONTRATO,
    CONTRATOCANC.SEQITEM,
    SUM(CONTRATOCANC.QUANTIDADE) AS CANC
    FROM CONTRATOCANC
    GROUP BY CONTRATOCANC.ESTAB, CONTRATOCANC.CONTRATO, CONTRATOCANC.SEQITEM
),
SALDO_MANUAL AS (
SELECT
    CONTRATO.ESTAB,
    CONTRATO.CONTRATO,
    U_AGRPRODGR.U_AGRPRODGR_ID AS ITEM,
    NVL(BAIXAS.BAIXADO,0)  as BAIXADO,
    NVL(BAIXAS.CANCELADO,0)  +NVL(CANC.CANC,0) as CANCELADO,
    NVL(BAIXAS.DEVOLIDO,0) as DEVOLIDO,
    ARREDONDAR(CONTRATOITE.QUANTIDADE - NVL(BAIXAS.BAIXADO,0) - NVL(BAIXAS.CANCELADO,0) + NVL(BAIXAS.DEVOLIDO,0) - NVL(CANC.CANC,0), 0) QTDSALDO
FROM CONTRATO
INNER JOIN CONTRATOCFG   ON CONTRATOCFG.CONTCONF = CONTRATO.CONTCONF
INNER JOIN CONTRATOCFG_U ON CONTRATOCFG_U.CONTCONF = CONTRATO.CONTCONF
INNER JOIN U_TEMPRESA U  ON U.ESTAB = CONTRATO.ESTAB
INNER JOIN CONTAMOV      ON CONTAMOV.NUMEROCM = CONTRATO.NUMEROCM
INNER JOIN FILIAL        ON FILIAL.ESTAB = CONTRATO.ESTAB                -- (6)
INNER JOIN CIDADE        ON CIDADE.CIDADE = FILIAL.CIDADE
LEFT JOIN CONTRATOITE ON
    CONTRATOITE.ESTAB = CONTRATO.ESTAB
    AND CONTRATOITE.CONTRATO = CONTRATO.CONTRATO
LEFT JOIN BAIXAS ON
    BAIXAS.ESTAB = CONTRATOITE.ESTAB
    AND BAIXAS.CONTRATO = CONTRATOITE.CONTRATO
    AND BAIXAS.SEQITEM = CONTRATOITE.SEQITEM
LEFT JOIN CANC ON
    CANC.ESTAB = CONTRATOITE.ESTAB
    AND CANC.CONTRATO = CONTRATOITE.CONTRATO
    AND CANC.SEQITEM = CONTRATOITE.SEQITEM
LEFT JOIN ITEMAGRO    ON ITEMAGRO.ITEM = CONTRATOITE.ITEM
LEFT JOIN ITEMAGRO_U  ON ITEMAGRO_U.ITEM = ITEMAGRO.ITEM
LEFT JOIN U_AGRPRODGR ON U_AGRPRODGR.U_AGRPRODGR_ID = ITEMAGRO_U.U_AGRPRODGR_ID
WHERE
CONTRATOCFG.ENTRADASAIDA IN ('E','S')
AND U.GRAOS='S'
AND FILIAL.INATIVA = 'N'
)
SELECT /*+ GATHER_PLAN_STATISTICS */ * FROM SALDO_MANUAL;
alter session set statistics_level = all;
-- Plano real da última execução (rodar na mesma sessão, logo após o SELECT acima).
-- Para medir de forma justa, busque TODAS as linhas (ex.: exportar / "fetch all")
-- tanto na original quanto nesta versão.
SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST +PREDICATE'));


/* =====================================================================
   VALIDAÇÃO DE EQUIVALÊNCIA
   ===================================================================== */

-- V1) Checksum: rodar com a consulta ORIGINAL e com esta; os 6 valores devem bater.
--     Substitua o "SELECT * FROM SALDO_MANUAL" final por:
--
--   SELECT COUNT(*), COUNT(DISTINCT ESTAB||'-'||CONTRATO),
--          SUM(BAIXADO), SUM(CANCELADO), SUM(DEVOLIDO), SUM(QTDSALDO)
--   FROM SALDO_MANUAL;

-- V2) BAIXAS original x nova, linha a linha (deve retornar 0 linhas).
--     Linhas da original com tudo zero são descartadas da comparação, pois na
--     consulta final elas equivalem a "sem linha" (NVL -> 0).
WITH
CLASSE_O AS (
    SELECT /*+ MATERIALIZE */ NFCFG.NOTACONF, CONTRATOCFG.CONTCONF,
    CASE
        WHEN (NAT.TIPODCTO IN ('N','X','A','T') and NFCFG.NOTACONF not IN (1041)) AND NATAPARTIRDE.TIPOBAIXA IN ('A','Q') AND NFCFG.NOTACONF NOT IN (291) AND NATAPARTIRDE.OPERACAO NOT IN ('N','R') THEN 1
        WHEN NAT.TIPODCTO IN ('D') AND NATAPARTIRDE.TIPOBAIXA IN ('A','Q') AND NAT.ENTRADASAIDA = 'E' AND CONTRATOCFG.ENTRADASAIDA = 'E' AND NATAPARTIRDE.OPERACAO NOT IN ('N','R') THEN 1
        WHEN NAT.TIPODCTO IN ('D') AND NATAPARTIRDE.TIPOBAIXA IN ('A','Q') AND NAT.ENTRADASAIDA = 'S' AND CONTRATOCFG.ENTRADASAIDA = 'S' AND NATAPARTIRDE.OPERACAO NOT IN ('N','R') THEN 1
        ELSE 0 END F_BAIXADO,
    CASE
        WHEN NAT.TIPODCTO IN ('D') AND NATAPARTIRDE.TIPOBAIXA IN ('A','Q') AND NAT.ENTRADASAIDA = 'E' AND CONTRATOCFG.ENTRADASAIDA = 'E' AND NATAPARTIRDE.OPERACAO NOT IN ('N','R') THEN 0
        WHEN NAT.TIPODCTO IN ('D') AND NATAPARTIRDE.TIPOBAIXA IN ('A','Q') AND NAT.ENTRADASAIDA = 'S' AND CONTRATOCFG.ENTRADASAIDA = 'S' AND NATAPARTIRDE.OPERACAO NOT IN ('N','R') THEN 0
        WHEN (NAT.TIPODCTO = 'D' OR NFCFG.NOTACONF IN (1041)) AND NATAPARTIRDE.TIPOBAIXA IN ('A','Q') AND NATAPARTIRDE.OPERACAO NOT IN ('N','R') THEN 1
        ELSE 0 END F_DEVOLIDO,
    CASE
        WHEN NAT.TIPODCTO IN ('N','X','A') AND NATAPARTIRDE.TIPOBAIXA IN ('A','Q') AND NFCFG.NOTACONF IN (291) AND NATAPARTIRDE.OPERACAO NOT IN ('N','R') THEN 1
        ELSE 0 END F_CANCELADO
    FROM NFCFG
    INNER JOIN NATOPERACAO NAT ON NAT.NATUREZADAOPERACAO = NFCFG.NATUREZADAOPERACAO AND NAT.ENTRADASAIDA = NFCFG.ENTRADASAIDA
    CROSS JOIN CONTRATOCFG
    INNER JOIN CONTRATOCFG_U ON CONTRATOCFG_U.CONTCONF = CONTRATOCFG.CONTCONF
    LEFT JOIN NATAPARTIRDE ON NATAPARTIRDE.NATUREZADAOPERACAO = NAT.NATUREZADAOPERACAO
        AND NATAPARTIRDE.ENTRADASAIDA = NAT.ENTRADASAIDA
        AND NATAPARTIRDE.NATOPERORIGEM = CONTRATOCFG.NATUREZA
        AND NATAPARTIRDE.ENTRADASAIDAORIGEM = CONTRATOCFG.ENTRADASAIDA
    WHERE CONTRATOCFG.ENTRADASAIDA IN ('E','S')
),
CLASSE_N AS (
    SELECT /*+ MATERIALIZE */ * FROM CLASSE_O WHERE F_BAIXADO + F_DEVOLIDO + F_CANCELADO > 0
),
B_O AS (
    SELECT CNI.ESTAB, CNI.CONTRATO, CNI.SEQITEM,
    NVL(SUM(CASE WHEN CL.F_BAIXADO   = 1 THEN CNI.QUANTIDADE ELSE 0 END),0) BAIXADO,
    NVL(SUM(CASE WHEN CL.F_DEVOLIDO  = 1 THEN CNI.QUANTIDADE ELSE 0 END),0) DEVOLIDO,
    NVL(SUM(CASE WHEN CL.F_CANCELADO = 1 THEN CNI.QUANTIDADE ELSE 0 END),0) CANCELADO
    FROM CONTRATONFITE CNI
    JOIN CONTRATO C ON C.ESTAB = CNI.ESTAB AND C.CONTRATO = CNI.CONTRATO
    JOIN CONTRATOITE CI ON CI.ESTAB = CNI.ESTAB AND CI.CONTRATO = CNI.CONTRATO AND CI.SEQITEM = CNI.SEQITEM
    JOIN NFCAB NF ON NF.ESTAB = CNI.ESTABNOTA AND NF.SEQNOTA = CNI.SEQNOTA
    JOIN CLASSE_O CL ON CL.NOTACONF = NF.NOTACONF AND CL.CONTCONF = C.CONTCONF
    GROUP BY CNI.ESTAB, CNI.CONTRATO, CNI.SEQITEM
),
B_N AS (
    SELECT CNI.ESTAB, CNI.CONTRATO, CNI.SEQITEM,
    NVL(SUM(CASE WHEN CL.F_BAIXADO   = 1 THEN CNI.QUANTIDADE ELSE 0 END),0) BAIXADO,
    NVL(SUM(CASE WHEN CL.F_DEVOLIDO  = 1 THEN CNI.QUANTIDADE ELSE 0 END),0) DEVOLIDO,
    NVL(SUM(CASE WHEN CL.F_CANCELADO = 1 THEN CNI.QUANTIDADE ELSE 0 END),0) CANCELADO
    FROM CONTRATONFITE CNI
    JOIN CONTRATO C ON C.ESTAB = CNI.ESTAB AND C.CONTRATO = CNI.CONTRATO
    JOIN NFCAB NF ON NF.ESTAB = CNI.ESTABNOTA AND NF.SEQNOTA = CNI.SEQNOTA
    JOIN CLASSE_N CL ON CL.NOTACONF = NF.NOTACONF AND CL.CONTCONF = C.CONTCONF
    WHERE NF.NOTACONF IN (SELECT NOTACONF FROM CLASSE_N)
    GROUP BY CNI.ESTAB, CNI.CONTRATO, CNI.SEQITEM
),
DIF AS (
    (SELECT 'SO_ORIGINAL' ORIGEM, x.* FROM (SELECT * FROM B_O WHERE BAIXADO <> 0 OR DEVOLIDO <> 0 OR CANCELADO <> 0
                                            MINUS SELECT * FROM B_N) x)
    UNION ALL
    (SELECT 'SO_NOVA' ORIGEM, y.* FROM (SELECT * FROM B_N WHERE BAIXADO <> 0 OR DEVOLIDO <> 0 OR CANCELADO <> 0
                                        MINUS SELECT * FROM B_O) y)
)
SELECT * FROM DIF;


/* =====================================================================
   DIAGNÓSTICO: quanto o filtro (1)/(2) realmente corta
   (o ganho depende da distribuição dos dados; rodar antes de concluir)
   ===================================================================== */

-- D1) Pares em CLASSE: total x relevantes (original: 15.150)
--     Reaproveitar CLASSE_O acima:  SELECT COUNT(*), SUM(CASE WHEN F_BAIXADO+F_DEVOLIDO+F_CANCELADO>0 THEN 1 END) FROM CLASSE_O;

-- D2) % de NFCAB e de CONTRATONFITE com NOTACONF relevante
--     (se for próximo de 100%, o ganho do item (2) é pequeno e o caminho
--      passa a ser índice/paralelismo/MV, ver abaixo)
--   SELECT COUNT(*) TOTAL,
--          SUM(CASE WHEN NF.NOTACONF IN (SELECT NOTACONF FROM CLASSE_N) THEN 1 END) RELEVANTES
--   FROM CONTRATONFITE CNI
--   JOIN NFCAB NF ON NF.ESTAB = CNI.ESTABNOTA AND NF.SEQNOTA = CNI.SEQNOTA;


/* =====================================================================
   RODADA 2 (SQL_ID 27j616vpjsncn, plan hash 3022625078)
   ---------------------------------------------------------------------
   - 4,06 s -> 3,59 s (-12%). CLASSE caiu de 15.150 para 838 pares.
   - Mas as linhas que chegam ao GROUP BY só caíram de 1.165K para 1.157K:
     o gargalo continua sendo o HASH JOIN CONTRATONFITE x NFCAB (Id 49,
     2,43 s, 120 MB), que precisa ler 3,94 mi linhas de NFCAB em modo serial.
   - Conclusão: reescrita esgotou o ganho. Próximos testes abaixo.
   ===================================================================== */

-- T1) Tempo REAL (sem GATHER_PLAN_STATISTICS, que infla operações com milhões
--     de linhas). Rodar original e otimizada SEM o hint, buscando todas as
--     linhas, e depois:
--   SELECT SQL_ID, EXECUTIONS, ROUND(ELAPSED_TIME/1e6/EXECUTIONS,2) SEG_POR_EXEC,
--          ROUND(CPU_TIME/1e6/EXECUTIONS,2) CPU_SEG, BUFFER_GETS/EXECUTIONS BUFFERS
--   FROM V$SQL
--   WHERE SQL_TEXT LIKE 'WITH%CLASSE AS%' AND SQL_TEXT NOT LIKE '%V$SQL%'
--   ORDER BY LAST_ACTIVE_TIME DESC;

-- T2) Paralelismo só no trecho caro (trocar o cabeçalho do SELECT de BAIXAS):
--       SELECT /*+ PARALLEL(CNI 4) PARALLEL(NF 4) PARALLEL(C 4) */
--     É o teste com maior chance de ganho real (join CPU-bound, sem filtro
--     seletivo). Validar com DBA o grau permitido.

-- T3) Hash menor: montar o hash só com CONTRATONFITE (sem CONTRATO) e usar
--     NFCAB como probe, com bloom filter (descarta notas sem contrato,
--     ~2,8 mi das 3,9 mi, antes do probe):
--       SELECT /*+ LEADING(CNI NF C CL) USE_HASH(NF) USE_HASH(C) USE_HASH(CL)
--                  PX_JOIN_FILTER(NF) */
--     Ganho incerto; manter só se o T1 mostrar diferença consistente.


/* =====================================================================
   OPÇÕES ADICIONAIS (testar em homologação; validar com DBA)
   ===================================================================== */

-- O1) Hints para forçar a ordem "notas relevantes primeiro" no BAIXAS, caso o
--     otimizador continue fazendo o hash join de 3,9 mi linhas antes de filtrar:
--       SELECT /*+ LEADING(CL NF CNI C) USE_HASH(NF CNI C) */ ...
--     Use só se o plano da versão acima não mudar sozinho; hint fixo
--     envelhece mal quando os volumes mudam.

-- O2) Paralelismo (o hash join de 2,6 s é CPU-bound e paraleliza bem):
--       SELECT /*+ PARALLEL(4) */ * FROM SALDO_MANUAL;
--     Depende de política de recursos do banco: validar com DBA.

-- O3) Índice de cobertura em CONTRATONFITE (hoje TABLE ACCESS FULL, 6.930 buffers):
--       CREATE INDEX IX_CONTRATONFITE_SALDO ON CONTRATONFITE
--         (ESTABNOTA, SEQNOTA, ESTAB, CONTRATO, SEQITEM, QUANTIDADE);
--     Ganho marginal no tempo (o FULL custa 0,07 s); só vale se o plano
--     passar a usar NL por nota relevante. Impacta DML do ERP: DBA decide.

-- O4) ARREDONDAR é função PL/SQL chamada 1x por linha (~142 mil chamadas no
--     fetch completo). Se for equivalente a ROUND(x, 0), trocar elimina o
--     context switch SQL<->PL/SQL. Conferir antes:
--       SELECT x, ARREDONDAR(x,0), ROUND(x,0) FROM (SELECT 2.5 x FROM DUAL UNION ALL
--         SELECT -2.5 FROM DUAL UNION ALL SELECT 0.4999 FROM DUAL);
--     Alternativa sem mudar a regra: (SELECT ARREDONDAR(...) FROM DUAL)
--     para usar scalar subquery caching.

-- O5) Se a consulta roda com frequência (painel/BI): materializar BAIXAS
--     (MV ou tabela de staging com carga agendada). Elimina os ~3,4 s a cada
--     execução, ao custo de defasagem. Decisão de governança/BI.
