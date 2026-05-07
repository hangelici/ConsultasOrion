SELECT
       CONTRATO.ESTAB,
       FILIAL.REDUZIDO,
       CASE WHEN  CIDADE.UF='SP' AND CONTRATO.ESTAB = 5 THEN 'SP - VJ'
       WHEN CONTRATO.ESTAB = 79 THEN 'TR'
       ELSE CIDADE.UF END AS ESTADO,


       contratocfg.entradasaida ES,
       contrato.contconf,contratocfg.descricao,
       CONTRATO.NUMEROCM, CONTAMOV.NOME,
       CONTRATO.CONTRATO,
       contrato.dtemissao,
       CASE WHEN CONTRATODTVENCTO.NUMDIASPAGTO > 0 THEN '*'||to_char(CONTRATODTVENCTO.NUMDIASPAGTO)||'*'
            WHEN CONTRATODTVENCTO.NUMDIASPAGTO IS NULL OR CONTRATODTVENCTO.NUMDIASPAGTO = 0 THEN to_char(CONTRATODTVENCTO.DTVENCTO)
            WHEN CONTRATODTVENCTO.NUMDIASPAGTO > 0 AND CONTRATODTVENCTO.DTVENCTO IS NOT NULL THEN to_char(CONTRATODTVENCTO.DTVENCTO + CONTRATODTVENCTO.NUMDIASPAGTO)
       ELSE 'Não Preenchido' 
       END DtVencto,
       contrato.dtlimentimp AS LimEnt,
       contrato.safra,
       contrato_u.tipofretes,
       contrato.dtmovsaldo,


       u_agrprodgr.u_agrprodgr_id AS ITEM,
       --CONTRATOITE.ITEM,
       u_agrprodgr.u_agrprodgr_id||'-'|| descagrupa AS DESCITEM,
       contratoite.local,

       contratoite.quantidade as qtdcontrato,
       contratoite.valorunit,
       contratoite.valortotal,
       CAST(COALESCE(PSALDO.NQTDSALDO,0)AS DECIMAL(18,2)) AS QTDSALDO,
       COALESCE(PSALDO.NQTDDEV,0) AS QTDDEV,
         COALESCE(PSALDO.NQTDCANC,0) AS QTDCANC,
       (COALESCE(PSALDO.nqtd,0) - (COALESCE(PSALDO.nqtdcanc,0) + COALESCE(PSALDO.NQTDSALDO,0)))SALDOENT,


       --COALESCE(PSALDO.NVLR,0) AS VLR,
     --  COALESCE(PSALDO.NVLRCANC,0) AS VLRCANC,
      --  COALESCE(PSALDO.NVLRDEV,0) AS VLRDEV,
       --COALESCE(PSALDO.NVLRBX,0) AS VLRBX,
       COALESCE(PSALDO.NVLRSALDO,0) AS VLRSALDO,
       contrato.userid



FROM CONTRATO
     INNER JOIN FILIAL ON
     (FILIAL.ESTAB = CONTRATO.ESTAB)

     INNER JOIN CIDADE ON CIDADE.CIDADE=FILIAL.CIDADE

     INNER JOIN u_tempresa ON u_tempresa.estab=FILIAL.ESTAB

     INNER JOIN CONTAMOV ON
     (CONTAMOV.NUMEROCM = CONTRATO.NUMEROCM)

  INNER JOIN CONTRATOCFG ON
     (CONTRATOCFG.CONTCONF = CONTRATO.CONTCONF)


      left join contrato_u on contrato_u.estab=contrato.estab
                           and contrato_u.contrato=contrato.contrato

     INNER JOIN CONTRATOITE ON
     (CONTRATOITE.ESTAB = CONTRATO.ESTAB)
      AND (CONTRATOITE.CONTRATO = CONTRATO.CONTRATO)

    INNER JOIN ITEMAGRO ON ITEMAGRO.ITEM=CONTRATOITE.ITEM

      INNER JOIN itemagro_u on itemagro_u.item = itemagro.item

    INNER JOIN u_agrprodgr ON u_agrprodgr.u_agrprodgr_id=itemagro_u.u_agrprodgr_id
    
    LEFT JOIN CONTRATODTVENCTO ON CONTRATODTVENCTO.ESTAB = CONTRATO.ESTAB 
    															  AND CONTRATODTVENCTO.CONTRATO = CONTRATO.CONTRATO
    															  AND CONTRATODTVENCTO.SEQUENCIA = 1

    LEFT JOIN TABLE (PCONTRATOSALDO( CONTRATO.ESTAB,
                 CURRENT_DATE, CONTRATO.CONTRATO, CONTRATO.CONTRATO,
                 CONTRATOITE.SEQITEM, CONTRATOITE.SEQITEM, NULL, NULL, NULL,
                 NULL, NULL)) PSALDO
    ON (0=0)
    INNER JOIN CONTRATOCFG_U ON CONTRATOCFG_U.CONTCONF = CONTRATO.CONTCONF
    LEFT JOIN U_TIPOCTR ON u_tipoctr.u_tipoctr_id = contratocfg_u.u_tipoctr_id

where  PSALDO.NQTDSALDO > 1
AND u_agrprodgr.u_agrprodgr_id=$P{ITEM}
AND CIDADE.UF =$P{UF}
AND CONTRATO.DTLIMENTIMP between '01/01/2000' and $P{DTFIM}
AND CONTRATO.CONTCONF NOT IN (26,38)
AND u_tipoctr.u_tipoctr_id IN (1,3,13)

and (filial.estab = $P{ESTAB} OR 0=  $P{ESTAB}) AND filial.estab <> 800

ORDER BY u_agrprodgr.u_agrprodgr_id,CONTRATO.ESTAB,contrato.dtemissao