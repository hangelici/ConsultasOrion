SELECT DADOS.*,
       --((DADOS.SALDOLIQ +DADOS.QTDDEV)- DADOS.SALDOENT) AS SALDOAENT,
       ARREDONDAR(DIVIDE(((DADOS.SALDOLIQ_KG +DADOS.QTDDEV_KG)- DADOS.SALDOENT_KG),60),0) AS SALDOAENT,
        CASE WHEN DADOS.PESSENTREGA IS NOT NULL THEN SUBSTR(DADOS.NOME,0,10)||' - '||DADOS.CIDENTREGA
            WHEN DADOS.PESSENTREGA IS NULL AND DADOS.pessretirada IS NOT NULL THEN 'FOB'
            ELSE 'S/Local' end LOCALRET,
            
        CASE WHEN DADOS.CIDENTREGA = 'Guarujá' OR DADOS.CIDENTREGA = 'Paranaguá' or DADOS.CIDENTREGA = 'Santos' THEN '1'
            WHEN DADOS.PESSENTREGA IS NULL AND DADOS.pessretirada IS NOT NULL THEN '1'
            WHEN DADOS.CIDENTREGA IS NULL THEN '1'
            ELSE '0' end ELOCAL 
            
FROM(

SELECT
       CONTRATO.ESTAB,
  SUBSTR(FILIAL.REDUZIDO,13,400)as REDUZIDO,
       contratocfg.entradasaida ES,
       contrato.contconf,contratocfg.descricao,
       CONTRATO.NUMEROCM, 
    SUBSTR(CONTAMOV.NOME,0,10)as NOME,
       CONTRATO.CONTRATO,
       contrato.numcomprador,
       contrato.numintermediario,
       TO_CHAR(contrato.dtemissao,'DD/MM/YYYY')dtemissao,
       TO_CHAR(contrato.dtvencto,'DD/MM/YYYY') AS DtVencto,
       TO_CHAR(contrato.dtlimentimp,'DD/MM/YYYY') AS DTLIMITE,
        -- TO_CHAR(NFCAB.DTEMISSAO, 'DD')DIA,
        TO_CHAR(contrato.dtlimentimp, 'MM')||'-'||TO_CHAR(contrato.dtlimentimp, 'MON')MESENT,
       contrato.safra,
       contrato.dtmovsaldo,
       CONTRATOITE.ITEM,
       contratoite.local,
       COALESCE(CIDEND.NOME,CID.NOME)CIDENTREGA,
       CONTRATO.PESSENTREGA,
       contrato.pessretirada,
       ARREDONDAR(DIVIDE(contratoite.quantidade,60),0) as qtdcontrato,
       contratoite.valorunit,
       contratoite.valortotal,
       COALESCE(ARREDONDAR(DIVIDE(PSALDO.NQTDSALDO,60),0),0) AS QTDSALDO,
       COALESCE(ARREDONDAR(DIVIDE(PSALDO.NQTDDEV,60),0),0) AS QTDDEV,
       COALESCE(ARREDONDAR(DIVIDE(PSALDO.NQTDCANC,60),0),0) AS QTDCANC,
        
       ARREDONDAR(DIVIDE((COALESCE(contratoite.quantidade,0) - (COALESCE(PSALDO.NQTDDEV,0) + COALESCE(NQTDCANC,0))),60),0)SALDOLIQ,
       ARREDONDAR(DIVIDE((COALESCE(PSALDO.nqtd,0) - (COALESCE(PSALDO.nqtdcanc,0) + COALESCE(PSALDO.NQTDSALDO,0))),60),0)SALDOENT,
  
      COALESCE(PSALDO.NQTDDEV,0) AS QTDDEV_KG,  
      COALESCE(contratoite.quantidade,0) - (COALESCE(PSALDO.NQTDDEV,0) + COALESCE(NQTDCANC,0))SALDOLIQ_KG,
      COALESCE(PSALDO.nqtd,0) - (COALESCE(PSALDO.nqtdcanc,0) + COALESCE(PSALDO.NQTDSALDO,0))SALDOENT_KG,
       
	

       --COALESCE(PSALDO.NVLR,0) AS VLR,
     --  COALESCE(PSALDO.NVLRCANC,0) AS VLRCANC,
      --  COALESCE(PSALDO.NVLRDEV,0) AS VLRDEV,
       --COALESCE(PSALDO.NVLRBX,0) AS VLRBX,
       COALESCE(PSALDO.NVLRSALDO,0) AS VLRSALDO,
       contrato_u.statusass,
       contrato_u.statusaprov,
       contrato_u.statusfat,
       contrato.userid 

FROM CONTRATO
      INNER JOIN FILIAL ON
      (FILIAL.ESTAB = CONTRATO.ESTAB)
  
   inner join cidade on cidade.cidade=filial.cidade
                      

      INNER JOIN CONTAMOV ON
     (CONTAMOV.NUMEROCM = CONTRATO.NUMEROCM)

      INNER JOIN CONTRATOCFG ON
     (CONTRATOCFG.CONTCONF = CONTRATO.CONTCONF)

     left join contrato_u on contrato_u.estab=contrato.estab
                        and contrato_u.contrato=contrato.contrato

      INNER JOIN CONTRATOITE ON
     (CONTRATOITE.ESTAB = CONTRATO.ESTAB)
     AND (CONTRATOITE.CONTRATO = CONTRATO.CONTRATO)

    inner JOIN TABLE (PCONTRATOSALDO( CONTRATO.ESTAB,
                 CURRENT_DATE, CONTRATO.CONTRATO, CONTRATO.CONTRATO,
                 CONTRATOITE.SEQITEM, CONTRATOITE.SEQITEM, NULL, NULL, NULL,
                 NULL, NULL)) PSALDO
    ON (0=0)

    LEFT JOIN CONTAMOV PESSRET ON PESSRET.NUMEROCM = CONTRATO.PESSENTREGA
    
    LEFT JOIN CIDADE CID ON CID.CIDADE = PESSRET.CIDADE
    
    LEFT JOIN ENDERECO ON ENDERECO.NUMEROCM = CONTRATO.PESSENTREGA
                        AND ENDERECO.SEQENDERECO = CONTRATO.SEQENDENTREGA
                        
    LEFT JOIN CIDADE CIDEND ON CIDEND.CIDADE = ENDERECO.CIDADE

LEFT JOIN ITEMAGRO_U ON ITEMAGRO_U.ITEM = CONTRATOITE.ITEM
  
  left join u_agrprodgr on u_agrprodgr.u_agrprodgr_id=itemagro_u.u_agrprodgr_id
  
  -- incluido
  
   INNER JOIN CONTRATOCFG ON CONTRATOCFG.CONTCONF = CONTRATO.CONTCONF
 INNER JOIN CONTRATOCFG_U ON CONTRATOCFG_U.CONTCONF = CONTRATOCFG.CONTCONF
INNER JOIN U_TIPOCTR ON U_TIPOCTR.U_TIPOCTR_ID = CONTRATOCFG_U.U_TIPOCTR_ID
  
where -- contrato.contconf in (20,21,22)
   TIPOCTR IN ('CTR-V','CTR-VF')
  and ('X' IN (:UF) OR CIDADE.UF IN (:UF))
      and contrato.dtemissao between :DTINIEMI AND :DTFIMEMI
  and contrato.DTLIMENTIMP BETWEEN :DTMINI AND :DTMFIM
 -- and CONTRATO.DTLIMENTIMP between :DTLIMINI AND :DTLIMFIM
     and contrato.estab <> 800
      --AND ((0 IN (:ITEM)) OR (U_AGRPRODGR.U_AGRPRODGR_ID in (:ITEM)))
AND (
    (0 IN (:ITEM))
    OR
    (9999 IN (:ITEM) AND U_AGRPRODGR.U_AGRPRODGR_ID <> 998)
    OR
    (U_AGRPRODGR.U_AGRPRODGR_ID IN (:ITEM))
)

)DADOS
    