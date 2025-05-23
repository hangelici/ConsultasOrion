WITH 
ENTRADA AS 
(
SELECT
    NFCAB.ESTAB,
    NFCAB.SEQNOTA,
    NFITEM.SEQNOTAITEM,
    NFCAB.NOTA,
    NFCAB.DTEMISSAO,
    NFCAB.CHAVEACESSONFE,
    NFITEM.QUANTIDADE AS QUANTIDADE,
    NFITEM.VALORTOTAL AS VALOR
FROM
NFCAB
JOIN NFCFG ON NFCFG.NOTACONF = NFCAB.NOTACONF
JOIN NFITEM ON NFITEM.ESTAB = NFCAB.ESTAB AND
               NFITEM.SEQNOTA = NFCAB.SEQNOTA 
WHERE 
NFCFG.ENTRADASAIDA = 'E' AND NFCAB.ESTAB=36 AND NFCAB.DTEMISSAO BETWEEN '01/03/2024' AND CURRENT_DATE AND FISCAL = 'S'
),

SAIDA AS 
(
SELECT
    NFCAB.ESTAB,
    NFCAB.SEQNOTA,
    NFITEM.SEQNOTAITEM,
    NFCAB.NOTA,
    NFCAB.DTEMISSAO,
    NFCAB.CHAVEACESSONFE,
    NFITEM.QUANTIDADE AS QUANTIDADE,
    NFITEM.VALORTOTAL AS VALOR
FROM
NFCAB
JOIN NFCFG ON NFCFG.NOTACONF = NFCAB.NOTACONF
JOIN NFITEM ON NFITEM.ESTAB = NFCAB.ESTAB AND
               NFITEM.SEQNOTA = NFCAB.SEQNOTA 
WHERE 
NFCFG.ENTRADASAIDA = 'S' AND NFCAB.ESTAB=36 AND NFCAB.DTEMISSAO BETWEEN '01/03/2024' AND CURRENT_DATE AND FISCAL = 'S'
)

SELECT 
SAIDA.NOTA AS NF_SAIDA,
TO_CHAR(SAIDA.DTEMISSAO,'DD/MM/YYYY') AS DTEMISSAO_SAIDA,
SAIDA.CHAVEACESSONFE AS CHAVE_SAIDA,
SUM(SAIDA.QUANTIDADE) AS QUANTIDADE_SAIDA,
SUM(SAIDA.VALOR) AS VALOR_SAIDA,

ENTRADA.NOTA AS NF_ENTRADA,
TO_CHAR(ENTRADA.DTEMISSAO,'DD/MM/YYYY') AS DTEMISSAO_ENTRADA,
ENTRADA.CHAVEACESSONFE AS CHAVE_ENTRADA,
SUM(ENTRADA.QUANTIDADE) AS QUANTIDADE_ENTRADA,
SUM(ENTRADA.VALOR) AS VALOR_ENTRADA,
SAIDA.DTEMISSAO-ENTRADA.DTEMISSAO AS PERIODO
FROM
SAIDA
JOIN ENTRADA ON 1 = 1
JOIN NFITEMAPARTIRDE ON 
           NFITEMAPARTIRDE.ESTAB = SAIDA.ESTAB AND
           NFITEMAPARTIRDE.SEQNOTA = SAIDA.SEQNOTA AND
           NFITEMAPARTIRDE.SEQNOTAITEM = SAIDA.SEQNOTAITEM AND 

           NFITEMAPARTIRDE.ESTABORIGEM = ENTRADA.ESTAB AND
           NFITEMAPARTIRDE.SEQNOTAORIGEM = ENTRADA.SEQNOTA AND
           NFITEMAPARTIRDE.SEQNOTAITEMORIGEM = ENTRADA.SEQNOTAITEM 

GROUP BY 
SAIDA.NOTA,
SAIDA.DTEMISSAO,
SAIDA.CHAVEACESSONFE,
ENTRADA.NOTA,
ENTRADA.DTEMISSAO,
ENTRADA.CHAVEACESSONFE 

ORDER BY 2,1