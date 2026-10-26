/* =====================================================================
   GRC-INS-002 | PRODUTO PRÓXIMO DO VENCIMENTO + BAIXO GIRO  (MVP)
   ---------------------------------------------------------------------
   Parâmetros analíticos configuráveis (bloco PARAM):
     DIAS_VENCIMENTO = 90  -> lotes que vencem em até 90 dias (inclui os já
                              vencidos que ainda têm saldo)
     DIAS_GIRO       = 90  -> janela das saídas para o giro

   Indicadores (definidos pelo cliente):
     MEDIA_DIARIA_SAIDA   = saídas dos últimos DIAS_GIRO dias / DIAS_GIRO
                            (MOVITEMAGRO com SOMADIMINUI = 'D')
     DIAS_COBERTURA       = estoque atual do produto na unidade / MEDIA_DIARIA
     DIAS_PARA_VENCER     = validade do lote - hoje
     SINAL: 'SEM SAIDA NO PERIODO'  quando não há saída na janela;
            'COBERTURA > VALIDADE'  quando DIAS_COBERTURA > DIAS_PARA_VENCER.
   Só entram produtos que controlam lote (existem em LOTEAGRO) e lotes com
   saldo maior que zero.

   Extra (estimativa, FEFO): QTD_EM_RISCO = parcela do saldo do lote que NÃO
   seria consumida até o vencimento, supondo que as saídas retiram primeiro
   os lotes que vencem antes:
     LEAST(saldo do lote, GREATEST(0, saldo acumulado até o lote
                                      - média diária * dias para vencer)).
   Sem saída no período, o saldo inteiro do lote está em risco.

   >>> AJUSTAR ANTES DE RODAR (2 colunas, nomes ainda não confirmados): <<<
       DT_VALIDADE  = coluna de validade de LOTEAGRO       (marcada [AJUSTAR 1])
       SALDO_LOTE   = coluna de saldo de LOTEAGROSALDO     (marcada [AJUSTAR 2])
   ===================================================================== */
WITH PARAM AS (
    SELECT 90 AS DIAS_VENCIMENTO,
           90 AS DIAS_GIRO,
           TRUNC(SYSDATE) AS HOJE
      FROM DUAL
),
/* saldo por lote (LOTEAGROSALDO ligado a LOTEAGRO por estab+item+lote+seqlote+tipo) */
LOTES AS (
    SELECT L.ESTAB,
           L.ITEM,
           L.LOTE,
           L.SEQLOTE,
           L.TIPO,
           L.VALIDADE          AS DT_VALIDADE,   -- [AJUSTAR 1] coluna de validade
           SUM(S.SALDO) AS SALDO_LOTE    -- [AJUSTAR 2] coluna de saldo
      FROM LOTEAGRO L
     INNER JOIN LOTEAGROSALDO S
        ON S.ESTAB   = L.ESTAB
       AND S.ITEM    = L.ITEM
       AND S.LOTE    = L.LOTE
       AND S.SEQLOTE = L.SEQLOTE
       AND S.TIPO    = L.TIPO
     -- INNER JOIN U_TEMPRESA E ON E.ESTAB = L.ESTAB AND E.INSUMOS = 'S'   -- opcional: só filiais de insumos
     GROUP BY L.ESTAB, L.ITEM, L.LOTE, L.SEQLOTE, L.TIPO, L.VALIDADE
    HAVING SUM(S.SALDO) > 0
),
/* saídas (SOMADIMINUI = 'D') dos últimos DIAS_GIRO dias, por unidade + produto */
SAIDAS AS (
    SELECT M.ESTAB,
           M.ITEM,
           SUM(M.QUANTIDADE) AS QTD_SAIDAS
      FROM MOVITEMAGRO M
     CROSS JOIN PARAM P
     WHERE M.SOMADIMINUI = 'D'
       AND M.DATAMOVIM  >= P.HOJE - P.DIAS_GIRO
       AND M.DATAMOVIM   < P.HOJE + 1
       AND EXISTS (SELECT 1
                     FROM LOTES X
                    WHERE X.ESTAB = M.ESTAB
                      AND X.ITEM  = M.ITEM)
     GROUP BY M.ESTAB, M.ITEM
),
ANALISE AS (
    SELECT L.ESTAB,
           L.ITEM,
           L.LOTE,
           L.SEQLOTE,
           L.TIPO,
           L.DT_VALIDADE,
           L.SALDO_LOTE,
           /* estoque atual do produto na unidade (todos os lotes com saldo) */
           SUM(L.SALDO_LOTE) OVER (PARTITION BY L.ESTAB, L.ITEM)  AS ESTOQUE_ITEM,
           /* saldo acumulado por validade (FEFO), incluindo este lote */
           SUM(L.SALDO_LOTE) OVER (PARTITION BY L.ESTAB, L.ITEM
                                   ORDER BY L.DT_VALIDADE, L.LOTE, L.SEQLOTE
                                   ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS SALDO_ACUM_FEFO,
           NVL(S.QTD_SAIDAS, 0)                                   AS QTD_SAIDAS
      FROM LOTES L
      LEFT JOIN SAIDAS S
        ON S.ESTAB = L.ESTAB
       AND S.ITEM  = L.ITEM
),
CALCULO AS (
    SELECT A.*,
           P.DIAS_GIRO,
           TRUNC(A.DT_VALIDADE) - P.HOJE                          AS DIAS_PARA_VENCER,
           A.QTD_SAIDAS / P.DIAS_GIRO                             AS MEDIA_DIARIA_SAIDA
      FROM ANALISE A
     CROSS JOIN PARAM P
     WHERE TRUNC(A.DT_VALIDADE) <= P.HOJE + P.DIAS_VENCIMENTO
)
SELECT C.ESTAB                                  AS ESTAB_UNIDADE,
       F.REDUZIDO                               AS UNIDADE,
       C.ITEM,
       I.DESCRICAO                              AS PRODUTO,
       I.UNIDADE                                AS UNIDADE_MEDIDA,
       C.LOTE,
       C.SEQLOTE,
       C.TIPO,
       C.DT_VALIDADE,
       C.DIAS_PARA_VENCER,
       C.SALDO_LOTE,
       C.ESTOQUE_ITEM,
       C.QTD_SAIDAS                             AS SAIDAS_PERIODO,
       ROUND(C.MEDIA_DIARIA_SAIDA, 4)           AS MEDIA_DIARIA_SAIDA,
       CASE WHEN C.MEDIA_DIARIA_SAIDA > 0
            THEN ROUND(C.ESTOQUE_ITEM / C.MEDIA_DIARIA_SAIDA, 1)
       END                                      AS DIAS_COBERTURA,
       CASE WHEN C.MEDIA_DIARIA_SAIDA = 0
            THEN 'SEM SAIDA NO PERIODO'
            WHEN C.ESTOQUE_ITEM / C.MEDIA_DIARIA_SAIDA > C.DIAS_PARA_VENCER
            THEN 'COBERTURA > VALIDADE'
       END                                      AS SINAL,
       /* estimativa FEFO da quantidade que não seria consumida até vencer */
       ROUND(CASE WHEN C.MEDIA_DIARIA_SAIDA = 0
                  THEN C.SALDO_LOTE
                  ELSE LEAST(C.SALDO_LOTE,
                             GREATEST(0, C.SALDO_ACUM_FEFO
                                         - C.MEDIA_DIARIA_SAIDA * GREATEST(C.DIAS_PARA_VENCER, 0)))
             END, 2)                            AS QTD_EM_RISCO
  FROM CALCULO C
  JOIN FILIAL F
    ON F.ESTAB = C.ESTAB
  JOIN ITEMAGRO I
    ON I.ITEM = C.ITEM
 WHERE C.MEDIA_DIARIA_SAIDA = 0
    OR C.ESTOQUE_ITEM / C.MEDIA_DIARIA_SAIDA > C.DIAS_PARA_VENCER
 ORDER BY QTD_EM_RISCO DESC, C.DIAS_PARA_VENCER, C.ESTAB, C.ITEM, C.LOTE
;