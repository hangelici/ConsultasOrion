SELECT  DISTINCT'Duplicatas a Receber' AS TIPO,
          'RECEBER' AS RECDESP,
          PPORTADO.DESCRICAO AS PORTADOR,
          FILIAL.REDUZIDO AS FILIAL,
         FILIAL.ESTAB,
         CASE WHEN  U_TEMPRESA.INSUMOS = 'N' AND U_TEMPRESA.GRAOS = 'S' AND U_TEMPRESA.OUTROS='S' THEN 'O'
           WHEN  U_TEMPRESA.INSUMOS = 'S' AND U_TEMPRESA.GRAOS = 'S' AND U_TEMPRESA.OUTROS='N' THEN 'C'
          WHEN  U_TEMPRESA.INSUMOS = 'S' THEN 'I'
           WHEN   U_TEMPRESA.GRAOS = 'S' THEN 'C'
           WHEN U_TEMPRESA.OUTROS='S' THEN 'O'
           ELSE 'O' END TPESTAB,
         
          CONTAMOV.NOME AS CLIENTE,
          CONTAMOV.NUMEROCM AS NUMEROCM,
          PANALITI.DESCRICAO AS TRANSACAO,
          PSALDODUPREC.PNSALDODUPREC AS SALDO,
          
          CASE WHEN CAST(:DTPOSICAO AS DATE) <  CAST(PDUPRECREAJ.DTREAJUSTE AS DATE) THEN PDUPRECREAJ.VALORATU 
         WHEN CAST(:DTPOSICAO AS DATE) >= CAST(PDUPRECREAJ.DTREAJUSTE AS DATE) THEN PDUPRECREAJ.VALORREAJ
         ELSE PDUPREC.VALOR
         END VALOR,
         
          (SELECT SUM(PRDUPREC.VALOR * CASE WHEN PRDUPREC.TIPOREC IN ('R','J') THEN 1 ELSE -1 END)
          FROM PRDUPREC
          WHERE PRDUPREC.EMPRESA = PDUPREC.EMPRESA
          AND PRDUPREC.DUPREC = PDUPREC.DUPREC
          AND PRDUPREC.DTRECBTO <= :DTPOSICAO
          ) AS VALORPAGO,
            (SELECT COALESCE(SUM(PRDUPREC.VALOR),0)
          FROM PRDUPREC
          WHERE  PRDUPREC.TIPOREC IN ('R')
          AND PRDUPREC.EMPRESA = PDUPREC.EMPRESA
          AND PRDUPREC.DUPREC = PDUPREC.DUPREC
          AND PRDUPREC.DTRECBTO <= :DTPOSICAO
          ) AS VALOR_REC_DPL,
          (SELECT COALESCE(SUM(PRDUPREC.VALOR),0)
          FROM PRDUPREC
          WHERE  PRDUPREC.TIPOREC IN ('J')
          AND PRDUPREC.EMPRESA = PDUPREC.EMPRESA
          AND PRDUPREC.DUPREC = PDUPREC.DUPREC
          AND PRDUPREC.DTRECBTO <= :DTPOSICAO
          ) AS VALOR_JUROS,
          PDUPREC.DTEMISSAO AS DTEMISSAO,
          PDUPREC.DTVENCTO AS DTVENCTO,
          PDUPREC.DTBASEJUROS AS DTBASEJUROS,
          PDUPREC.DTVENCTO AS DTJS,
          PDUPREC.DUPREC DOCUMENTO,
          COALESCE(CENCUSCE.cencuscod || ' - ' || CENCUSCE.centrocus || ' - ' || CENCUSCE.descricao, 'SEM CENTRO DE CUSTO') CENTROCUSTO,
          PSITUACA.DESCRICAO SITUACAO,
          PDUPREC.HISTORICO HISTORICO,
          CASE
            WHEN PSALDODUPREC.PNSALDODUPREC = 0
              THEN 'BAIXADA'
            WHEN PSALDODUPREC.PNSALDODUPREC = PDUPREC.VALOR
              THEN 'ABERTA'
            ELSE
              'PARCIALMENTE BAIXADA'
          END STATUS,
		  PREPRESE.REPRESENT || ' - ' || PREPRESE.DESCRICAO REPRESENTANTE,
          CASE WHEN nfitem.estabcontrato >0 AND NFITEM.CONTRATO > 0 THEN 'S' ELSE 'N' END ORIGEMCT

      FROM PDUPREC
      INNER JOIN CONTAMOV
      ON CONTAMOV.NUMEROCM = PDUPREC.CLIENTE
	LEFT JOIN PREPRESE
	  ON PREPRESE.represent = PDUPREC.represent
	 AND PREPRESE.empresa = PDUPREC.estabrepresent
  INNER JOIN FILIAL
  ON FILIAL.ESTAB = PDUPREC.EMPRESA
  inner join u_tempresa on u_tempresa.estab=filial.estab
  
  LEFT JOIN PANALITI
    ON PANALITI.ANALITICA = PDUPREC.ANALITICA
    AND PANALITI.EMPRESA = PDUPREC.ESTABANALITICA
  LEFT JOIN PPORTADO
  ON PPORTADO.PORTADOR = PDUPREC.PORTADOR
  AND PPORTADO.EMPRESA = PDUPREC.EMPRESA
  INNER JOIN TABLE(PSALDODUPREC_TESTE(PDUPREC.EMPRESA, PDUPREC.DUPREC, NULL, :DTPOSICAO)) PSALDODUPREC
  ON 0 = 0
  LEFT JOIN CENCUSCE
  ON CENCUSCE.cencuscod = PDUPREC.cencuscod
  AND CENCUSCE.centrocus = PDUPREC.centrocus
  LEFT JOIN PSITUACA
  ON PSITUACA.SITUACAO = PDUPREC.SITUACAO
    LEFT JOIN AGRFINDUPREC
            ON (PDUPREC.EMPRESA = AGRFINDUPREC.ESTAB)
            AND (PDUPREC.DUPREC = AGRFINDUPREC.DUPREC)
       LEFT JOIN NFCABAGRFIN
            ON (AGRFINDUPREC.ESTAB = NFCABAGRFIN.ESTAB)
       AND (AGRFINDUPREC.SEQPAGAMENTO = NFCABAGRFIN.SEQPAGAMENTO)
       LEFT JOIN NFITEM
            ON (NFCABAGRFIN.ESTAB = NFITEM.ESTAB)
            AND (NFCABAGRFIN.SEQNOTA = NFITEM.SEQNOTA)
            
LEFT JOIN 
          (SELECT
              ESTAB,
              DUPREC,
              MAX(DTREAJUSTE) AS DTREAJUSTE,
              VALORATU,
              VALORREAJ
              FROM
              PDUPRECREAJ REAJ
              WHERE
              /*CAST(DTREAJUSTE AS DATE) <= CAST(:DTPOSICAO AS DATE)
              AND ESTAB = 19 AND DUPREC = '22372-1'
              AND ROWNUM = 1*/
                  (
                        (CAST(DTREAJUSTE AS DATE) < CAST(:DTPOSICAO AS DATE) AND CAST(DTREAJUSTE AS DATE) = (SELECT MAX(CAST(DTREAJUSTE AS DATE)) FROM PDUPRECREAJ WHERE ESTAB = REAJ.ESTAB AND DUPREC = REAJ.DUPREC))
                        OR
                        (CAST(DTREAJUSTE AS DATE) >= CAST(:DTPOSICAO AS DATE) AND CAST(DTREAJUSTE AS DATE) = (SELECT MIN(CAST(DTREAJUSTE AS DATE)) FROM PDUPRECREAJ WHERE ESTAB = REAJ.ESTAB AND DUPREC = REAJ.DUPREC))
                   )
              GROUP BY 
              ESTAB,
              DUPREC,
              VALORATU,
              VALORREAJ
              ORDER BY 
              DTREAJUSTE 
              DESC
              )PDUPRECREAJ ON 
              PDUPRECREAJ.ESTAB = PDUPREC.EMPRESA AND 
              PDUPRECREAJ.DUPREC = PDUPREC.DUPREC              
  WHERE 0=0 
    --AND PDUPREC.DTVENCTO BETWEEN CAST('01/01/2000' AS DATE) AND ADD_MONTHS(CURRENT_DATE, 6)
    AND PDUPREC.DTEMISSAO BETWEEN :DTINI AND :DTFIM
    AND PSALDODUPREC.PNSALDODUPREC > 0
    and COALESCE(PDUPREC.situacao,0) <> 39
    and FILIAL.estab in (:ESTAB)