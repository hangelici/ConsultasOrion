SELECT
       CONTRATO.ESTAB,
       contratocfg.entradasaida ES,
       contrato.contconf,contratocfg.descricao,
       CONTRATO.NUMEROCM, CONTAMOV.NOME,
       CONTRATO.CONTRATO,
       contrato.numcomprador,
       contrato.safra,
       contrato.numintermediario,
       TO_CHAR(contrato.dtemissao,'DD/MM/YYYY') AS dtemissao,
        TO_CHAR(contrato.dtvencto,'DD/MM/YYYY') AS DtVencto,
        TO_CHAR(contrato.dtlimentimp,'DD/MM/YYYY') AS LimEnt,    
        TO_CHAR(contrato.dtmovsaldo,'DD/MM/YYYY') AS dtmovsaldo,
       CONTRATOITE.ITEM,
       contratoite.local,
       contrato_u.qtdori as qtdoriginal,
       contratoite.quantidade as qtdcontrato,
        contrato_u.qtdori *  contratoite.valorunit/60 As vlroriginal,
       contratoite.valorunit,
       contratoite.valortotal,
       CAST(COALESCE(PSALDO.NQTDSALDO,0)AS DECIMAL(18,2)) AS QTDSALDO,
       COALESCE(PSALDO.NQTDDEV,0) AS QTDDEV,
       ARREDONDAR(COALESCE(PSALDO.NQTDCANC,0),2) AS QTDCANC,
       (COALESCE(PSALDO.nqtd,0) - (COALESCE(PSALDO.nqtdcanc,0) + COALESCE(PSALDO.NQTDSALDO,0)))SALDOENT,
       COALESCE(PSALDO.NVLRSALDO,0) AS VLRSALDO,
       contrato_u.statusass,
       contrato_u.statusaprov,
       contrato_u.statusfat,
       contrato.userid,  
       case when contrato.safra >=2223 then sum(rtporto.pesodescarregamento) else  sum(rtporto.pesodescarregamento) - (PSALDO.NQTDDEV) end pesodescarregamento,
    case when contrato.safra >= 2223 then sum(rtporto.pesoretencao) else sum(rtporto.pesoretencao) - (PSALDO.NQTDDEV) end pesoretencao,
   --    sum(rtporto.pesoretencao) - (PSALDO.NQTDDEV)pesoretencao,
        coalesce(VLRREC.RECEBIDO,0)VLR_RECEBIDO

FROM CONTRATO

      INNER JOIN FILIAL ON
      (FILIAL.ESTAB = CONTRATO.ESTAB)

      INNER JOIN CONTAMOV ON
     (CONTAMOV.NUMEROCM = CONTRATO.NUMEROCM)

      INNER JOIN CONTRATOCFG ON
     (CONTRATOCFG.CONTCONF = CONTRATO.CONTCONF)

     left join contrato_u on contrato_u.estab=contrato.estab
                        and contrato_u.contrato=contrato.contrato
                        
    INNER JOIN U_TEMPRESA ON (U_TEMPRESA.ESTAB = CONTRATO.ESTAB)
    
      INNER JOIN CONTRATOITE ON
     (CONTRATOITE.ESTAB = CONTRATO.ESTAB)
     AND (CONTRATOITE.CONTRATO = CONTRATO.CONTRATO)

    INNER JOIN TABLE (PCONTRATOSALDO( CONTRATO.ESTAB,
                 CURRENT_DATE, CONTRATO.CONTRATO, CONTRATO.CONTRATO,
                 CONTRATOITE.SEQITEM, CONTRATOITE.SEQITEM, NULL, NULL, NULL,
                 NULL, NULL)) PSALDO
    ON (0=0)

left join (
select nfitem.contrato,
       nfitem.estab,
       retenporto.pesodescarregamento,
     retenporto.pesoretencao  from nfcab

inner join nfitem on nfitem.estab=nfcab.estab
                and nfitem.seqnota=nfcab.seqnota

inner join retenporto on  retenporto.estab=nfitem.estab
                    and   retenporto.seqnota=nfitem.seqnota
                    and   retenporto.seqnotaitem=nfitem.seqnotaitem


                    WHERE  NOT exists (SELECT * FROM NFITEMAPARTIRDE

                                       INNER JOIN NFITEM NFI ON
                                       NFI.ESTAB = NFITEMAPARTIRDE.ESTAB AND
                                       NFI.SEQNOTA = NFITEMAPARTIRDE.SEQNOTA AND
                                       NFI.SEQNOTAITEM = NFITEMAPARTIRDE.SEQNOTAITEM

                                       INNER JOIN NFCAB NFDV ON
                                       NFDV.ESTAB = NFI.ESTAB AND
                                       NFDV.SEQNOTA = NFI.SEQNOTA

                                       INNER JOIN NFCFG NFCFGDV ON
                                       NFCFGDV.NOTACONF = NFDV.NOTACONF
                                        AND NFCFGDV.NOTACONF IN (271)

                                        LEFT join ctrcnfcab ctrcnfcabdv
                                        on ctrcnfcabdv.estab = NFITEMAPARTIRDE.ESTABORIGEM
                                        and ctrcnfcabdv.seqnota =  NFITEMAPARTIRDE.SEQNOTAORIGEM

                                        LEFT JOIN CTRC CTRCDV ON
                                        (CTRCDV.SEQCTRC = CTRCNFCABDV.SEQCTRC)

                                        LEFT JOIN CTRCCFG CTRCCFGDV  ON
                                        (CTRCCFGDV.ESTAB = CTRCDV.ESTAB)
                                        AND (CTRCCFGDV.CODIGOCFG = CTRCDV.CODIGOCFG)

                                       INNER JOIN NATOPERACAO NATDV ON
                                       NATDV.NATUREZADAOPERACAO = NFCFGDV.NATUREZADAOPERACAO AND
                                       NATDV.ENTRADASAIDA = NFCFGDV.ENTRADASAIDA 

                                       WHERE NFITEM.ESTAB = NFITEMAPARTIRDE.ESTABORIGEM
                                         AND NFITEM.SEQNOTA = NFITEMAPARTIRDE.SEQNOTAORIGEM
                                         AND NFITEM.SEQNOTAITEM = NFITEMAPARTIRDE.SEQNOTAITEMORIGEM
                                         --AND COALESCE(ctrcnfcabDV.valorfrete,0)= 0
										 ))rtporto

                    on contrato.estab=rtporto.estab
                    and contrato.contrato=rtporto.contrato

left join (SELECT CONTRATO.ESTAB,CONTRATO.CONTRATO,
  SUM(VDUPREC.VALOR - VDUPREC.SALDO)AS RECEBIDO

FROM CONTRATONFITE

INNER JOIN NFCAB
ON (NFCAB.ESTAB = CONTRATONFITE.ESTABNOTA)
AND (NFCAB.SEQNOTA = CONTRATONFITE.SEQNOTA)
AND (NFCAB.STATUS <> 'C')

inner join nfitem on nfitem.estab=nfcab.estab
                and nfitem.seqnota=nfcab.seqnota

INNER JOIN CONTRATO
ON  (CONTRATO.ESTAB    = CONTRATONFITE.ESTAB)
AND (CONTRATO.CONTRATO = CONTRATONFITE.CONTRATO) 

inner JOIN NFCABAGRFIN
ON (NFCAB.ESTAB = NFCABAGRFIN.ESTAB)
AND (NFCAB.SEQNOTA = NFCABAGRFIN.SEQNOTA)

inner JOIN AGRFINDUPREC
ON (AGRFINDUPREC.ESTAB = NFCABAGRFIN.ESTAB)
AND (AGRFINDUPREC.SEQPAGAMENTO = NFCABAGRFIN.SEQPAGAMENTO)

inner JOIN VDUPREC
ON (VDUPREC.EMPRESA = AGRFINDUPREC.ESTAB)
AND (VDUPREC.DUPREC = AGRFINDUPREC.DUPREC)

 WHERE  NOT exists (SELECT * FROM NFITEMAPARTIRDE

                                       INNER JOIN NFITEM NFI ON
                                       NFI.ESTAB = NFITEMAPARTIRDE.ESTAB AND
                                       NFI.SEQNOTA = NFITEMAPARTIRDE.SEQNOTA AND
                                       NFI.SEQNOTAITEM = NFITEMAPARTIRDE.SEQNOTAITEM

                                       INNER JOIN NFCAB NFDV ON
                                       NFDV.ESTAB = NFI.ESTAB AND
                                       NFDV.SEQNOTA = NFI.SEQNOTA

                                       INNER JOIN NFCFG NFCFGDV ON
                                       NFCFGDV.NOTACONF = NFDV.NOTACONF
                                        AND NFCFGDV.NOTACONF IN (271)

                                        LEFT join ctrcnfcab ctrcnfcabdv
                                        on ctrcnfcabdv.estab = NFITEMAPARTIRDE.ESTABORIGEM
                                        and ctrcnfcabdv.seqnota =  NFITEMAPARTIRDE.SEQNOTAORIGEM

                                        LEFT JOIN CTRC CTRCDV ON
                                        (CTRCDV.SEQCTRC = CTRCNFCABDV.SEQCTRC)

                                        LEFT JOIN CTRCCFG CTRCCFGDV  ON
                                        (CTRCCFGDV.ESTAB = CTRCDV.ESTAB)
                                        AND (CTRCCFGDV.CODIGOCFG = CTRCDV.CODIGOCFG)

                                       INNER JOIN NATOPERACAO NATDV ON
                                       NATDV.NATUREZADAOPERACAO = NFCFGDV.NATUREZADAOPERACAO AND
                                       NATDV.ENTRADASAIDA = NFCFGDV.ENTRADASAIDA 

                                       WHERE NFITEM.ESTAB = NFITEMAPARTIRDE.ESTABORIGEM
                                         AND NFITEM.SEQNOTA = NFITEMAPARTIRDE.SEQNOTAORIGEM
                                         AND NFITEM.SEQNOTAITEM = NFITEMAPARTIRDE.SEQNOTAITEMORIGEM)
                                         --AND COALESCE(ctrcnfcabDV.valorfrete,0)= 0)

GROUP BY CONTRATO.ESTAB,CONTRATO.CONTRATO


)VLRREC

     on contrato.estab=VLRREC.estab
    and contrato.contrato=VLRREC.contrato


where
 /*contrato.estab IN (12,52,30,34,26,31,54,25)

 and*/ contratoite.item IN(1,3,2,6)

 AND U_TEMPRESA.EXVENDA = 'S'
    
 AND U_TEMPRESA.GRAOS = 'S'

 and contrato.contconf IN(20,21,23)

and contrato.dtmovsaldo > ='01/01/2021' 

 group by CONTRATO.ESTAB,
       contratocfg.entradasaida,
       contrato.contconf,contratocfg.descricao,
       CONTRATO.NUMEROCM, CONTAMOV.NOME,
       CONTRATO.CONTRATO,
       contrato.numcomprador,
       contrato.safra,
       contrato.numintermediario,
       contrato.dtemissao,
       contrato.dtvencto,
       contrato.dtlimentimp,    
       contrato.dtmovsaldo,
       CONTRATOITE.ITEM,
       contratoite.local,
       contrato_u.qtdori,
       contratoite.quantidade,
        contrato_u.qtdori,
       contratoite.valorunit,
       contratoite.valortotal,
       PSALDO.NQTDSALDO,
       PSALDO.NQTDDEV,
       PSALDO.NQTDCANC,
       PSALDO.nqtd,
       PSALDO.NVLRSALDO,       
       contrato_u.statusass,
       contrato_u.statusaprov,
       contrato_u.statusfat,
       contrato.userid,
       VLRREC.RECEBIDO

       order by  CONTRATO.ESTAB,
       CONTRATO.CONTRATO
