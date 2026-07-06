WITH BASE
     AS (  SELECT DISTINCT
                  'VALIDAÇÃO DENTRO DO MÊS' AS TIPO,
                  DADOS.ESTAB,
                  DADOS.NOTA AS NOTA,
                  NULL AS NOTA_ANTERIOR,
                     'PULOU '
                  || (LAGG - 1)
                  || ' NOTAS ATÉ CHEGAR NA NOTA '
                  || NOTA
                  || ': ULTIMA NOTA FOI: '
                  || (DADOS.NOTA - (LAGG))
                     AS INFO,
                  (LAGG - 1) AS QTD,
                  DADOS.NOTA - (LAGG) AS INI,
                  DADOS.NOTA AS FIN
             FROM (  SELECT DISTINCT
                            ESTAB,
                            TO_CHAR (DTENTSAI, 'DD/MM/YYYY') AS DTENTSAI,
                            NOTA,
                            NOTA - LAG(NOTA) OVER (PARTITION BY ESTAB ORDER BY NOTA) AS LAGG
                       FROM NFCAB
                            INNER JOIN NFCFG ON NFCFG.NOTACONF = NFCAB.NOTACONF
                      WHERE     NFCAB.SERIE = '1'
                            AND NFCFG.EMITENFE = 'S'
                            AND NFCAB.ESTAB <= 100
                   ORDER BY NOTA ASC) DADOS
            WHERE LAGG <> 1 AND LAGG < 110 AND (LAGG - 1) > 0
         ORDER BY 2, 3),
     DB
     AS (SELECT TIPO,
                ESTAB,
                NOTA,
                INFO,
                QTD,
                (SELECT LISTAGG (NOTA, ',')
                           WITHIN GROUP (ORDER BY ESTAB, NOTA)
                   FROM (    SELECT INI + LEVEL AS NOTA
                               FROM DUAL
                         CONNECT BY LEVEL <= FIN - INI - 1))
                   AS LISTA
           FROM BASE),
     LISTA
     AS (SELECT *
           FROM (    SELECT TIPO,
                            ESTAB,
                            NOTA,
                            INFO,
                            QTD,
                            TRIM (REGEXP_SUBSTR (LISTA,
                                                 '[^,]+',
                                                 1,
                                                 LEVEL))
                               AS LT
                       FROM DB
                 CONNECT BY REGEXP_SUBSTR (LISTA,
                                           '[^,]+',
                                           1,
                                           LEVEL)
                               IS NOT NULL))
  SELECT TIPO,
         ESTAB,
         NOTA,
         INFO,
         QTD,
         LISTAGG (LT, ',') WITHIN GROUP (ORDER BY ESTAB, NOTA) AS LISTA
    FROM LISTA
    WHERE 
    (ESTAB NOT IN (24) AND NOTA NOT IN (13812) AND LT NOT IN (13811))
GROUP BY TIPO,
         ESTAB,
         NOTA,
         INFO,
         QTD