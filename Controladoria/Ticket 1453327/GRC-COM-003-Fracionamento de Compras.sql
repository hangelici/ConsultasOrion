/* =====================================================================
   COMPRAS REPETIDAS EM ATÉ 7 DIAS (fracionamento de compras) - v2
   Chave: CNPJ do fornecedor + ESTAB + CENTROCUS + ITEM
   ---------------------------------------------------------------------
   Retorna SOMENTE a nota que repete a compra: aquela para a qual existe uma
   emissão anterior da mesma chave com no máximo 7 dias de diferença
   (23/07 e 29/07 -> aparece só a nota de 29/07, com a data e a nota
   anterior para referência). A primeira nota não aparece mais.
   "Anterior" = a nota imediatamente anterior da chave, ordenada por data e
   por SEQNOTA (emissões no mesmo dia: a de maior SEQNOTA é a repetida).
   Como a nota imediatamente anterior é sempre a mais próxima, ela está
   dentro de 7 dias se e somente se existe QUALQUER nota anterior dentro de
   7 dias.
   Intervalo inclusivo: 01/07 -> até 08/07. Para mudar, trocar o 7 no WHERE.

   Ajustes em relação à consulta base (linhas de nota iguais):
   - NFCABAGRFIN + AGRFINDUPPAG viraram um único EXISTS (o INNER JOIN com
     NFCABAGRFIN repetiria a nota se houver mais de uma NFCABAGRFIN por nota).
   - Uma linha por (nota, item), com VALORTOTAL somado.
   - DTEMISSAO truncada (regra por dia); notas sem CNPJ excluídas.
   - Incluídos ESTAB e SEQNOTA para localizar a nota no sistema.
   ===================================================================== */
WITH NOTAS AS (
    SELECT
        NVL(ENDERECO.CNPJF, CONTAMOV.CNPJF) AS CNPJF,
        CONTAMOV.NOME                       AS PESSOA,
        NFCAB.ESTAB,
        NFCAB.SEQNOTA,
        NFCAB.NOTA,
        NFCAB.SERIE,
        TRUNC(NFCAB.DTEMISSAO)              AS DTEMISSAO,
        NFCAB.CENTROCUS,
        NFCAB.CENCUSCOD,
        NFITEM.ITEM,
        ITEMAGRO.DESCRICAO AS PRODUTO,
        SUM(NFITEM.VALORTOTAL)              AS VALORTOTAL
    FROM NFCAB
    INNER JOIN NFCFG
        ON NFCFG.NOTACONF = NFCAB.NOTACONF
    LEFT JOIN ENDERECO
        ON ENDERECO.NUMEROCM = NFCAB.NUMEROCM
       AND ENDERECO.SEQENDERECO = NFCAB.SEQENDERECO
    INNER JOIN CONTAMOV
        ON CONTAMOV.NUMEROCM = NFCAB.NUMEROCM
    INNER JOIN NFITEM
        ON NFITEM.ESTAB = NFCAB.ESTAB
       AND NFITEM.SEQNOTA = NFCAB.SEQNOTA
      INNER JOIN ITEMAGRO ON ITEMAGRO.ITEM = NFITEM.ITEM
    WHERE NFCAB.STATUS <> 'C'
      AND NFCFG.ENTRADASAIDA = 'E'
      AND NFCAB.CENTROCUS IS NOT NULL
      AND NVL(ENDERECO.CNPJF, CONTAMOV.CNPJF) IS NOT NULL
      AND NFCAB.DTEMISSAO > = '01/01/2025'
      AND EXISTS (SELECT 1
                    FROM NFCABAGRFIN
                   INNER JOIN AGRFINDUPPAG AGR
                      ON AGR.ESTAB = NFCABAGRFIN.ESTAB
                     AND AGR.SEQPAGAMENTO = NFCABAGRFIN.SEQPAGAMENTO
                     AND AGR.FORNECEDOR = NFCAB.NUMEROCM
                   WHERE NFCABAGRFIN.ESTAB = NFCAB.ESTAB
                     AND NFCABAGRFIN.SEQNOTA = NFCAB.SEQNOTA)
    GROUP BY
        NVL(ENDERECO.CNPJF, CONTAMOV.CNPJF),
        CONTAMOV.NOME,
        NFCAB.ESTAB,
        NFCAB.SEQNOTA,
        NFCAB.NOTA,
        NFCAB.SERIE,
        TRUNC(NFCAB.DTEMISSAO),
        NFCAB.CENTROCUS,
        NFCAB.CENCUSCOD,
        NFITEM.ITEM,
        ITEMAGRO.DESCRICAO
),
JANELA AS (
    SELECT
        N.*,
        LAG(N.DTEMISSAO) OVER (PARTITION BY N.CNPJF, N.ESTAB, N.CENTROCUS, N.ITEM
                               ORDER BY N.DTEMISSAO, N.SEQNOTA) AS DT_ANTERIOR,
        LAG(N.NOTA)      OVER (PARTITION BY N.CNPJF, N.ESTAB, N.CENTROCUS, N.ITEM
                               ORDER BY N.DTEMISSAO, N.SEQNOTA) AS NOTA_ANTERIOR
    FROM NOTAS N
)
SELECT
    J.CNPJF,
    J.PESSOA,
    J.CENTROCUS,
    J.CENCUSCOD,
    J.ITEM,
    J.PRODUTO,
    J.ESTAB,
    J.SEQNOTA,
    J.NOTA,
    J.SERIE,
    J.DTEMISSAO,
    J.VALORTOTAL,
    J.NOTA_ANTERIOR,
    J.DT_ANTERIOR,
    J.DTEMISSAO - J.DT_ANTERIOR AS DIAS_DESDE_ANTERIOR
FROM JANELA J
WHERE J.DT_ANTERIOR IS NOT NULL
  AND J.DTEMISSAO - J.DT_ANTERIOR <= 7
ORDER BY J.CNPJF, J.ESTAB, J.CENTROCUS, J.ITEM, J.DTEMISSAO, J.NOTA
;