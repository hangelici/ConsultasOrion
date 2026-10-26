/* =====================================================================
   NOTAS DE ENTRADA REPETIDAS EM ATÉ 7 DIAS
   Chave: CNPJ do fornecedor + CENTROCUS + ITEM
   ---------------------------------------------------------------------
   Para cada nota (por item), conta quantas OUTRAS notas da mesma chave
   foram emitidas:
     - nos 7 dias seguintes (inclusive o 7º dia: 01/07 -> até 08/07), e
     - nos 7 dias anteriores.
   Emissões no MESMO dia também contam (nas duas contagens).
   Retorna só as notas que fazem parte de uma repetição (alguma das duas
   contagens maior que zero).

   Ajustes em relação à consulta base (resultado das linhas de nota igual):
   - NFCABAGRFIN + AGRFINDUPPAG viraram um único EXISTS: o INNER JOIN com
     NFCABAGRFIN repetiria a linha da nota se houver mais de uma
     NFCABAGRFIN por nota, e isso inflaria as contagens. O filtro
     (fornecedor com título em AGRFINDUPPAG) é o mesmo.
   - Uma linha por (nota, item), com VALORTOTAL somado: uma nota que traz o
     mesmo item em duas linhas não conta como "duas emissões".
   - DTEMISSAO truncada (sem hora): a regra é por dia.
   - Excluídas notas sem CNPJ (sem CNPJ, fornecedores diferentes seriam
     agrupados como se fossem o mesmo).
   - Incluídos ESTAB e SEQNOTA para localizar a nota no sistema.
   Para mudar o intervalo, trocar os dois "7" das janelas (RANGE).
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
    WHERE NFCAB.STATUS <> 'C'
      AND NFCFG.ENTRADASAIDA = 'E'
      AND NFCAB.CENTROCUS IS NOT NULL
      AND NVL(ENDERECO.CNPJF, CONTAMOV.CNPJF) IS NOT NULL
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
        NFITEM.ITEM
),
JANELA AS (
    SELECT
        N.*,
        /* outras emissões da mesma chave nos 7 dias anteriores (e no mesmo dia) */
        COUNT(*) OVER (PARTITION BY N.CNPJF, N.CENTROCUS, N.ITEM
                       ORDER BY N.DTEMISSAO
                       RANGE BETWEEN 7 PRECEDING AND CURRENT ROW) - 1 AS QTD_ANTERIORES_7D,
        /* outras emissões da mesma chave nos 7 dias seguintes (e no mesmo dia) */
        COUNT(*) OVER (PARTITION BY N.CNPJF, N.CENTROCUS, N.ITEM
                       ORDER BY N.DTEMISSAO
                       RANGE BETWEEN CURRENT ROW AND 7 FOLLOWING) - 1 AS QTD_POSTERIORES_7D,
        MAX(N.DTEMISSAO) OVER (PARTITION BY N.CNPJF, N.CENTROCUS, N.ITEM
                       ORDER BY N.DTEMISSAO
                       RANGE BETWEEN CURRENT ROW AND 7 FOLLOWING)     AS DT_ULTIMA_JANELA
    FROM NOTAS N
)
SELECT
    J.CNPJF,
    J.PESSOA,
    J.CENTROCUS,
    J.CENCUSCOD,
    J.ITEM,
    J.ESTAB,
    J.SEQNOTA,
    J.NOTA,
    J.SERIE,
    J.DTEMISSAO,
    J.VALORTOTAL,
    J.QTD_ANTERIORES_7D,
    J.QTD_POSTERIORES_7D,
    CASE WHEN J.QTD_POSTERIORES_7D > 0 THEN J.DT_ULTIMA_JANELA END AS DT_ULTIMA_EMISSAO_7D,
    CASE WHEN J.QTD_ANTERIORES_7D = 0 THEN 'PRIMEIRA' ELSE 'REPETIDA' END AS SITUACAO
FROM JANELA J
WHERE J.QTD_ANTERIORES_7D > 0
   OR J.QTD_POSTERIORES_7D > 0
ORDER BY J.CNPJF, J.CENTROCUS, J.ITEM, J.DTEMISSAO, J.NOTA
;