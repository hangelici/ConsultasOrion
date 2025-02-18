WITH DPL AS (
    SELECT
    EMPRESA,
    DUPREC,
    SEQRECBTO,
    (VALOR) AS VALOR
    FROM PRDUPRED

    UNION ALL
    
    SELECT
    EMPRESA,
    DUPREC,
    SEQRECBTO,
    (VLRCHEQREC) AS VALOR
    FROM PRDURECH
    
    
    UNION ALL
    
    SELECT
    EMPRESA,
    DUPREC,
    SEQRECBTO,
    VALOR
    FROM PRDUREDUP
    
    UNION ALL
    
    SELECT
    EMPRESA,
    DUPREC,
    SEQRECBTO,
    VALOR
    FROM PRDURECAR
    
    UNION ALL
    
    SELECT
    EMPRESA,
    DUPREC,
    SEQRECBTO,
    VALOR
    FROM PRDUREOUT
    
    UNION ALL
    
    SELECT
    EMPRESA,
    DUPREC,
    SEQRECBTO,
    VALOR
    FROM PRDURECM
    WHERE TROCO = 'N'
    
),

BAIXAS_DPL AS (

    SELECT
    EMPRESA,
    DUPREC,
    SEQRECBTO,
    SUM(VALOR) AS VALOR
    FROM DPL

    GROUP BY EMPRESA,DUPREC,SEQRECBTO

), 

BAIXAS AS (
    SELECT
    PRDUPREC.EMPRESA,
    PRDUPREC.DUPREC,
    SUM(BAIXAS_DPL.VALOR) AS VLR,
    SUM(PRDUPREC.VALOR * CASE WHEN PRDUPREC.TIPOREC IN ('R','J') THEN 1 ELSE -1 END) AS PAGO,
    SUM(CASE WHEN PRDUPREC.TIPOREC IN ('J') THEN BAIXAS_DPL.VALOR ELSE 0 END) JUROS,
    SUM(CASE WHEN PRDUPREC.TIPOREC IN ('R') THEN BAIXAS_DPL.VALOR ELSE 0 END) REC
    FROM PRDUPREC
    
    INNER JOIN BAIXAS_DPL ON 
        BAIXAS_DPL.EMPRESA = PRDUPREC.EMPRESA
        AND BAIXAS_DPL.DUPREC = PRDUPREC.DUPREC
        and BAIXAS_DPL.SEQRECBTO= PRDUPREC.SEQRECBTO

    WHERE TIPOREC IN ('R','J')
    AND DTRECBTO <= :DTPOSICAO
   
    GROUP BY PRDUPREC.EMPRESA,PRDUPREC.DUPREC
),

CTRNOTA AS
    (
    SELECT DISTINCT
    AGRFINDUPREC.ESTAB,
    AGRFINDUPREC.DUPREC,
    NFITEM.ESTABCONTRATO,
    NFITEM.CONTRATO
    FROM AGRFINDUPREC
    
     LEFT JOIN NFCABAGRFIN
        ON (AGRFINDUPREC.ESTAB = NFCABAGRFIN.ESTAB)
       AND (AGRFINDUPREC.SEQPAGAMENTO = NFCABAGRFIN.SEQPAGAMENTO)
       
    LEFT JOIN NFITEM
        ON (NFCABAGRFIN.ESTAB = NFITEM.ESTAB)
        AND (NFCABAGRFIN.SEQNOTA = NFITEM.SEQNOTA)
),
REAJ_ANT AS (
    SELECT
        ESTAB,
        DUPREC,
        DTREAJUSTE,
        VALORATU,
        VALORREAJ,
        ROW_NUMBER() OVER (PARTITION BY ESTAB, DUPREC ORDER BY DTREAJUSTE DESC) AS RN
    FROM
        PDUPRECREAJ
    WHERE
        CAST(DTREAJUSTE AS DATE) <= CAST(:DTPOSICAO AS DATE) 
),

REAJ_MAX AS (
    SELECT
        ESTAB,
        DUPREC,
        DTREAJUSTE,
        VALORATU,
        VALORREAJ,
        ROW_NUMBER() OVER (PARTITION BY ESTAB, DUPREC ORDER BY DTREAJUSTE DESC) AS RN
    FROM
        PDUPRECREAJ
    WHERE
        CAST(DTREAJUSTE AS DATE) >= CAST(:DTPOSICAO AS DATE) 
),

DUP_REAJ AS (
   SELECT 
      RM.ESTAB,
      RM.DUPREC,
      CASE 
         -- Se a data de posição for menor que a data do reajuste, e não houver registro em REAJ_ANT,
         -- usa o VALORATU (valor antes do reajuste) de RM; caso haja RA, você pode optar por usar
         -- o VALORREAJ de RA se isso for o desejado. Aqui, por exemplo, usamos NVL para usar RA.VALORREAJ se existir;
         -- se não, usamos RM.VALORATU.
         WHEN CAST(:DTPOSICAO AS DATE) < RM.DTREAJUSTE THEN NVL(RA.VALORREAJ, RM.VALORATU)
         ELSE RM.VALORREAJ
      END AS VALORREAJ
   FROM 
      (SELECT * FROM REAJ_MAX WHERE RN = 1) RM
   LEFT JOIN
      (SELECT * FROM REAJ_ANT WHERE RN = 1) RA
      ON RM.ESTAB = RA.ESTAB AND RM.DUPREC = RA.DUPREC
)

select
'Duplicatas a Receber' AS TIPO,
'DPL-R' AS TIPO_DOC,
'RECEBER' AS RECDESP,
FILIAL.REDUZIDO AS FILIAL,
FILIAL.ESTAB, 
CONTAMOV.NOME AS CLIENTE,
CONTAMOV.NUMEROCM AS NUMEROCM,
PPORTADO.DESCRICAO AS PORTADOR,
--case when quitada = 'S' then 0 else PSALDODUPREC.PNSALDODUPREC end SALDO,
COALESCE(VALORREAJ,PDUPREC.VALOR) - COALESCE(BAIXAS.REC,0) AS SALDO,

coalesce(PDUPREC.DUPREC,'SD-01') AS DOCUMENTO,

COALESCE(VALORREAJ,PDUPREC.VALOR) AS VALOR,
         
COALESCE(BAIXAS.PAGO,0) AS VALORPAGO,
COALESCE(BAIXAS.REC,0) AS VALOR_REC_DPL,
COALESCE(BAIXAS.JUROS,0) AS VALOR_JUROS,
          
 PDUPREC.DTEMISSAO AS DTEMISSAO,
PDUPREC.DTVENCTO AS DTVENCTO,
PDUPREC.DTBASEJUROS AS DTBASEJUROS,
PDUPREC.DTVENCTO AS DTJS,
PSITUACA.DESCRICAO SITUACAO,
PDUPREC.HISTORICO HISTORICO,
         
         CASE WHEN  U_TEMPRESA.INSUMOS = 'N' AND U_TEMPRESA.GRAOS = 'S' AND U_TEMPRESA.OUTROS='S' THEN 'O'
           WHEN  U_TEMPRESA.INSUMOS = 'S' AND U_TEMPRESA.GRAOS = 'S' AND U_TEMPRESA.OUTROS='N' THEN 'C'
          WHEN  U_TEMPRESA.INSUMOS = 'S' THEN 'I'
           WHEN   U_TEMPRESA.GRAOS = 'S' THEN 'C'
           WHEN U_TEMPRESA.OUTROS='S' THEN 'O'
           ELSE 'O' END TPESTAB,
           
PREPRESE.REPRESENT || ' - ' || PREPRESE.DESCRICAO REPRESENTANTE,
CASE WHEN CTRNOTA.CONTRATO > 0 THEN 'S' ELSE 'N' END ORIGEMCT,

COALESCE(PANALITI.DESCRICAO,'Duplicatas a Receber') AS TRANSACAO


from PDUPREC

INNER JOIN FILIAL ON FILIAL.ESTAB = PDUPREC.EMPRESA

LEFT JOIN BAIXAS ON
    BAIXAS.EMPRESA = PDUPREC.EMPRESA
    AND BAIXAS.DUPREC = PDUPREC.DUPREC
    
INNER JOIN CONTAMOV ON CONTAMOV.NUMEROCM = PDUPREC.CLIENTE
      
LEFT JOIN PREPRESE ON 
        PREPRESE.represent = PDUPREC.represent
        AND PREPRESE.empresa = PDUPREC.estabrepresent
  
INNER JOIN FILIAL ON FILIAL.ESTAB = PDUPREC.EMPRESA
inner join u_tempresa on u_tempresa.estab=filial.estab
  
LEFT JOIN PANALITI
    ON PANALITI.ANALITICA = PDUPREC.ANALITICA
    AND PANALITI.EMPRESA = PDUPREC.ESTABANALITICA
 
LEFT JOIN PPORTADO
  ON PPORTADO.PORTADOR = PDUPREC.PORTADOR
  AND PPORTADO.EMPRESA = PDUPREC.EMPRESA

LEFT JOIN PSITUACA
  ON PSITUACA.SITUACAO = PDUPREC.SITUACAO
  
LEFT JOIN CTRNOTA ON
        CTRNOTA.ESTAB = PDUPREC.EMPRESA
        AND CTRNOTA.DUPREC = PDUPREC.DUPREC
        
LEFT JOIN DUP_REAJ ON
    DUP_REAJ.ESTAB = PDUPREC.EMPRESA
    AND DUP_REAJ.DUPREC = PDUPREC.DUPREC
    
WHERE 
--PDUPREC.DUPREC = '3955-1-1' AND 
--PDUPREC.EMPRESA = 57
--DUPREC = '212413-1-1'
ARREDONDAR(COALESCE(VALORREAJ,PDUPREC.VALOR) - COALESCE(BAIXAS.REC,0),0) > 0
AND coalesce(PDUPREC.SITUACAO,0) <> 39
AND PDUPREC.DTEMISSAO BETWEEN :DTINI AND :DTFIM
AND FILIAL.EMPRESA = 1
AND (0 IN (:ESTAB) OR FILIAL.ESTAB IN (:ESTAB))
--AND PDUPREC.CLIENTE = 75916
AND (PDUPREC.INCMANUT <> 'S'	or pduprec.analitica = 336 OR PDUPREC.ANALITICA = 97)
--AND PDUPREC.DUPREC = '169123-1' AND PDUPREC.CLIENTE = 1714