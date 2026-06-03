SELECT
DADOS1.*,
ARREDONDAR(         DADOS1.SALDOFIS*(DIVIDE(DADOS1.DIFUMID,100)),          2) RET,
DADOS1.SAIDA -  coalesce((ARREDONDAR(DADOS1.SALDOFIS*(DIVIDE(DADOS1.DIFUMID,100)),2)),0) AS SAIDA_REAL,
SOBRA.QTDSOBRA
FROM(
SELECT  dados.estab,
		dados.uf,
        dados.reduzido,
        dados.item,
        --entrada
       sum(dados.pbruto)pbruto,
       sum(arredondar(dados.pbrutosc,2))pbrutosc,
       sum(dados.umid)umid,
       sum(dados.imp)imp,
       arredondar(divide(sum(PBRUTOUM),sum(dados.pbruto)),2)medu,
       arredondar(divide(sum(PBRUTOIMP),SUM(dados.pbruto)),2)medi,
  arredondar(divide(sum(PBRUTOAVAR),sum(dados.pbruto)),2)MEDAVAR,
  avg(ph) as ph, 
  --    arredondar(divide(sum(ph), sum(dados.pbruto)),2) as ph,
avg(fn) as fn,
  --       arredondar(divide(sum(fn), sum(dados.pbruto)),2) as fn,
      ARREDONDAR( DIVIDE(SUM(DADOS.DESCUMID),60),2)DESCUMIUDSC,
     -- ajuste umidade
     --- APLICAR SEMPRE 1 NESSE DESCONTO
      ARREDONDAR((FISICO.SALDOFIS),2)SALDOFIS,
  --ajuste confrome ticket 359462. Retirar fator zero nos casos negativos
  -- ajuste ticket 673867 para considerar 0 quando dif < 0
  CASE WHEN ( arredondar(divide(sum(PBRUTOUM),sum(dados.pbruto)),2) - 13.5) <0  THEN 0-- ( arredondar(divide(sum(PBRUTOUM),sum(dados.pbruto)),2) - 13.5) 
  --  CASE WHEN ( arredondar(divide(sum(PBRUTOUM),sum(dados.pbruto)),2) - 13.5) <0  THEN 0
      when ( arredondar(divide(sum(PBRUTOUM),sum(dados.pbruto)),2) - 13.5) >0 and ARREDONDAR((FISICO.SALDOFIS),2) <0 then 0
      ELSE ( arredondar(divide(sum(PBRUTOUM),sum(dados.pbruto)),2) - 13.5)*1.5
      END DIFUMID,
       --saida
       sum(PBRUTOS)pbrutos,
       sum(arredondar(PBRUTOSCS,2))pbrutoscs,
       sum(UMIDS)umids,
       sum(IMPS)imps,
       arredondar(divide(sum(PBRUTOUMS),sum(dados.pbrutos)),2)medus,
       arredondar(divide(sum(PBRUTOIMPS),SUM(dados.pbrutos)),2)medis,
       SUM(DADOS.DESCUMIDS)DESCUMIDS,
   arredondar(divide(sum(PBRUTOAVARS),sum(dados.pbrutos)),2)MEDAVARS,
  avg(phs) as phs,    
  -- arredondar(divide(sum(phs), sum(dados.pbrutos)),2) as phs,
avg(fns) as fns,
  --       arredondar(divide(sum(fns), sum(dados.pbrutos)),2) as fns,
      (arredondar(divide(sum(PBRUTOUMS),sum(dados.pbrutos)),2) -  arredondar(divide(sum(PBRUTOUM),sum(dados.pbruto)),2))DIF,
(DIVIDE( 1 * (arredondar(divide(sum(PBRUTOUMS),sum(dados.pbrutos)),2) -  arredondar(divide(sum(PBRUTOUM),sum(dados.pbruto)),2)),100)* sum(arredondar(PBRUTOSCS,2)) ) TESTE,
       :FATOR AS FATOR,
       ---- quando a diferença das umidades for positiva, FATOR = 1, se for negativo FATOR = 1,5
      --ARREDONDAR( (DIVIDE( :FATOR * (arredondar(divide(sum(PBRUTOUMS),sum(dados.pbrutos)),2) -  arredondar(divide(sum(PBRUTOUM),sum(dados.pbruto)),2)),100)* sum(arredondar(PBRUTOSCS,2)))+DIVIDE(SUM(DADOS.DESCUMID),60)+DIVIDE(SUM(DADOS.DESCSEC),60),2)SAIDA
CASE WHEN (arredondar(divide(sum(PBRUTOUMS),sum(dados.pbrutos)),2) -  arredondar(divide(sum(PBRUTOUM),sum(dados.pbruto)),2)) > 0 THEN
            ARREDONDAR( (DIVIDE( 1 * (arredondar(divide(sum(PBRUTOUMS),sum(dados.pbrutos)),2) -  arredondar(divide(sum(PBRUTOUM),sum(dados.pbruto)),2)),100)* sum(arredondar(PBRUTOSCS,2)) )+DIVIDE(SUM(DADOS.DESCUMID),60)+DIVIDE(SUM(DADOS.DESCSEC),60),2)     
ELSE
        ARREDONDAR( (DIVIDE( 1.5 * (arredondar(divide(sum(PBRUTOUMS),sum(dados.pbrutos)),2) -  arredondar(divide(sum(PBRUTOUM),sum(dados.pbruto)),2)),100)* sum(arredondar(PBRUTOSCS,2)))+DIVIDE(SUM(DADOS.DESCUMID),60)+DIVIDE(SUM(DADOS.DESCSEC),60),2)

END SAIDA

FROM(
SELECT
ROMA.ESTAB,
CIDADE.UF,
FILIAL.REDUZIDO,
u_agrprodgr.u_agrprodgr_id as item,
  --ROMA.ITEM,
     COALESCE(ROMA.PESOTOTAL,0) - COALESCE(ROMA.TARA,0) AS PBRUTO,
     (COALESCE(ROMA.PESOTOTAL,0) - COALESCE(ROMA.TARA,0))*  COALESCE((SELECT SUM(UMID.REFTABELA) FROM ROMADESC UMID
                    WHERE UMID.ESTAB        = ROMA.ESTAB
                      AND UMID.ROMANEIO     = ROMA.ROMANEIO
                      AND UMID.ENTRADASAIDA = ROMA.ENTRADASAIDA
                      AND UMID.NUMEROCM     = ROMA.NUMEROCM
                      AND UMID.ROMADESC     IN (2)),0) AS PBRUTOUM,
    (COALESCE(ROMA.PESOTOTAL,0) - COALESCE(ROMA.TARA,0))/60 AS PBRUTOSC,
    

    COALESCE((SELECT SUM(UMID.REFTABELA) FROM ROMADESC UMID
                    WHERE UMID.ESTAB        = ROMA.ESTAB
                      AND UMID.ROMANEIO     = ROMA.ROMANEIO
                      AND UMID.ENTRADASAIDA = ROMA.ENTRADASAIDA
                      AND UMID.NUMEROCM     = ROMA.NUMEROCM
                      AND UMID.ROMADESC     IN (2)),0) AS UMID,
    
       (COALESCE(ROMA.PESOTOTAL,0) - COALESCE(ROMA.TARA,0))*  COALESCE((SELECT SUM(IMP.REFTABELA) FROM ROMADESC IMP
                    WHERE IMP.ESTAB        = ROMA.ESTAB
                      AND IMP.ROMANEIO     = ROMA.ROMANEIO
                      AND IMP.ENTRADASAIDA = ROMA.ENTRADASAIDA
                      AND IMP.NUMEROCM     = ROMA.NUMEROCM
                      AND IMP.ROMADESC     IN (1)),0) AS PBRUTOIMP,
                      
      COALESCE((SELECT SUM(IMP.REFTABELA) FROM ROMADESC IMP
                    WHERE IMP.ESTAB        = ROMA.ESTAB
                      AND IMP.ROMANEIO     = ROMA.ROMANEIO
                      AND IMP.ENTRADASAIDA = ROMA.ENTRADASAIDA
                      AND IMP.NUMEROCM     = ROMA.NUMEROCM
                      AND IMP.ROMADESC     IN (1)),0) AS IMP,
                      
       CASE WHEN ROMA.ROMANEIOCONFIG IN (10,51,61,52) AND (NFITEM.QUANTIDADE = ROMA.PESOORIGEM OR NFITEM.QUANTIDADE = (ROMA.PESOTOTAL - ROMA.TARA)) THEN 0
       ELSE 
       COALESCE((SELECT SUM(UMID.PESOCALCULADO) FROM ROMADESC UMID
                    WHERE UMID.ESTAB        = ROMA.ESTAB
                      AND UMID.ROMANEIO     = ROMA.ROMANEIO
                      AND UMID.ENTRADASAIDA = ROMA.ENTRADASAIDA
                      AND UMID.NUMEROCM     = ROMA.NUMEROCM
                      AND UMID.ROMADESC     IN (2)),0) END DESCUMID,
                      
      COALESCE((SELECT SUM(SEC.REFTABELA) FROM ROMADESC SEC
                    WHERE SEC.ESTAB        = ROMA.ESTAB
                      AND SEC.ROMANEIO     = ROMA.ROMANEIO
                      AND SEC.ENTRADASAIDA = ROMA.ENTRADASAIDA
                      AND SEC.NUMEROCM     = ROMA.NUMEROCM
                      AND SEC.ROMADESC     IN (11)),0) AS SEC,
                      
      
      CASE WHEN ROMA.ROMANEIOCONFIG IN (10,51,61,52) AND (NFITEM.QUANTIDADE = ROMA.PESOORIGEM OR NFITEM.QUANTIDADE = (ROMA.PESOTOTAL - ROMA.TARA)) THEN 0
      ELSE
       COALESCE((SELECT SUM(SEC.PESOCALCULADO) FROM ROMADESC SEC
                    WHERE SEC.ESTAB        = ROMA.ESTAB
                      AND SEC.ROMANEIO     = ROMA.ROMANEIO
                      AND SEC.ENTRADASAIDA = ROMA.ENTRADASAIDA
                      AND SEC.NUMEROCM     = ROMA.NUMEROCM
                      AND SEC.ROMADESC     IN (11)),0) END DESCSEC,
  (COALESCE(ROMA.PESOTOTAL,0) - COALESCE(ROMA.TARA,0))*  COALESCE((SELECT SUM(AVAR.REFTABELA) FROM ROMADESC AVAR
                    WHERE AVAR.ESTAB        = ROMA.ESTAB
                      AND AVAR.ROMANEIO     = ROMA.ROMANEIO
                      AND AVAR.ENTRADASAIDA = ROMA.ENTRADASAIDA
                      AND AVAR.NUMEROCM     = ROMA.NUMEROCM
                      AND AVAR.ROMADESC     IN (6)),0) AS PBRUTOAVAR,
        romaclass.ph,
        roma.fn,
 
  0 PBRUTOS,
        0 PBRUTOUMS,
        0 PBRUTOSCS,
        0 UMIDS,
        0 PBRUTOIMPS,
        0 IMPS,
        0 DESCUMIDS,
        0 SECS,
        0 DESCSECS,
  0 PBRUTOAVARS,
        0 phs,
        0 fns
  
  
  
  

FROM ROMA
    INNER JOIN FILIAL ON
    FILIAL.ESTAB            = ROMA.ESTAB

inner join cidade on cidade.cidade=filial.cidade
                                --and cidade.uf='SP'

    INNER JOIN PEMPRESA ON
    PEMPRESA.EMPRESA        = FILIAL.EMPRESA

    INNER JOIN CIDADE FILCID ON
    FILCID.CIDADE           = FILIAL.CIDADE

    INNER JOIN ROMACFG ON
    ROMACFG.ROMANEIOCONFIG  = ROMA.ROMANEIOCONFIG

    INNER JOIN CONTAMOV ON
    CONTAMOV.NUMEROCM       = ROMA.NUMEROCM

    LEFT JOIN ENDERECO ON
    ENDERECO.NUMEROCM       = ROMA.NUMEROCM AND
    ENDERECO.SEQENDERECO    = ROMA.SEQENDERECO

    LEFT JOIN PPESSPRE ON
    PPESSPRE.PRESTADOR      = ROMA.PRESTADOR

    INNER JOIN ROMACLASS ON
    ROMACLASS.ESTAB         = ROMA.ESTAB AND
    ROMACLASS.ROMANEIO      = ROMA.ROMANEIO AND
    ROMACLASS.ENTRADASAIDA  = ROMA.ENTRADASAIDA AND
    ROMACLASS.NUMEROCM      = ROMA.NUMEROCM AND
    ROMACLASS.PERCENTUAL    > 0

    INNER JOIN ROMACLASSNOME ON
    ROMACLASSNOME.CLASSIFICACAO = ROMACLASS.CLASSIFICACAO

    INNER JOIN ITEMAGRO ON
    ITEMAGRO.ITEM           = CASE WHEN ROMACLASS.ITEM IS NULL or (ROMACLASS.ITEM = 0) THEN ROMA.ITEM ELSE ROMACLASS.ITEM END

    LEFT JOIN NFCABROMA ON
    NFCABROMA.ESTAB         = ROMACLASS.ESTAB AND
    NFCABROMA.ROMANEIO      = ROMACLASS.ROMANEIO AND
    NFCABROMA.ENTRADASAIDA  = ROMACLASS.ENTRADASAIDA AND
    NFCABROMA.NUMEROCM      = ROMACLASS.NUMEROCM

    LEFT JOIN NFCAB ON
    NFCAB.ESTAB             = NFCABROMA.ESTAB AND
    NFCAB.SEQNOTA           = NFCABROMA.SEQNOTA

    LEFT JOIN NFITEM ON
    NFCAB.ESTAB             = NFITEM.ESTAB AND
    NFCAB.SEQNOTA           = NFITEM.SEQNOTA AND
    ROMA.ROMANEIO           = NFITEM.ROMANEIO
    
    LEFT JOIN U_DTSOBRA SOBRA ON
    SOBRA.ESTAB = ROMA.ESTAB  AND
    SOBRA.ITEM = ROMA.ITEM
  
      LEFT JOIN ITEMAGRO_U ON ITEMAGRO_U.ITEM = ROMA.ITEM
   left join u_agrprodgr on u_agrprodgr.u_agrprodgr_id=itemagro_u.u_agrprodgr_id
WHERE /*ROMA.DTEMISSAO BETWEEN :DTINI AND :DTFIM
AND */roma.estornado <> 'S'
--AND ROMA.ITEM = 3
AND ((0 IN (:ITEM)) OR (U_AGRPRODGR.U_AGRPRODGR_ID in (:ITEM)))
--AND ROMA.ESTAB =:ESTAB
--AND ((0 IN (:ESTAB)) OR (ROMA.ESTAB IN (:ESTAB)))
AND ROMACFG.ROMANEIOCONFIG IN (1,2,3,4,5,6,7,10,51,61,52)
   -- AND ROMA.ESTAB NOT IN (47)
    
    AND ROMA.DTEMISSAO > SOBRA.DATALANC

UNION ALL

SELECT
ROMA.ESTAB,
CIDADE.UF,
FILIAL.REDUZIDO,
u_agrprodgr.u_agrprodgr_id as item,
  --ROMA.ITEM,
 0 PBRUTO,
       0 PBRUTOUM,
        0 PBRUTOSC,
        0 UMID,
        0 PBRUTOIMP,
        0 IMP,
        0 DESCUMID,
        0 SEC,
        0 DESCSEC,
          0 PBRUTOAVAR,
        0 ph,
        0 fn,
     COALESCE(ROMA.PESOTOTAL,0) - COALESCE(ROMA.TARA,0) AS PBRUTO,
     
     (COALESCE(ROMA.PESOTOTAL,0) - COALESCE(ROMA.TARA,0))*  COALESCE((SELECT SUM(UMID.REFTABELA) FROM ROMADESC UMID
                    WHERE UMID.ESTAB        = ROMA.ESTAB
                      AND UMID.ROMANEIO     = ROMA.ROMANEIO
                      AND UMID.ENTRADASAIDA = ROMA.ENTRADASAIDA
                      AND UMID.NUMEROCM     = ROMA.NUMEROCM
                      AND UMID.ROMADESC     IN (32)),0) AS PBRUTOUMS,
                      
    (COALESCE(ROMA.PESOTOTAL,0) - COALESCE(ROMA.TARA,0))/60 AS PBRUTOSCS,
    

    COALESCE((SELECT SUM(UMID.REFTABELA) FROM ROMADESC UMID
                    WHERE UMID.ESTAB        = ROMA.ESTAB
                      AND UMID.ROMANEIO     = ROMA.ROMANEIO
                      AND UMID.ENTRADASAIDA = ROMA.ENTRADASAIDA
                      AND UMID.NUMEROCM     = ROMA.NUMEROCM
                      AND UMID.ROMADESC     IN (32)),0) AS UMIDS,
    
       (COALESCE(ROMA.PESOTOTAL,0) - COALESCE(ROMA.TARA,0))*  COALESCE((SELECT SUM(IMP.REFTABELA) FROM ROMADESC IMP
                    WHERE IMP.ESTAB        = ROMA.ESTAB
                      AND IMP.ROMANEIO     = ROMA.ROMANEIO
                      AND IMP.ENTRADASAIDA = ROMA.ENTRADASAIDA
                      AND IMP.NUMEROCM     = ROMA.NUMEROCM
                      AND IMP.ROMADESC     IN (31)),0) AS PBRUTOIMPS,
                      
      COALESCE((SELECT SUM(IMP.REFTABELA) FROM ROMADESC IMP
                    WHERE IMP.ESTAB        = ROMA.ESTAB
                      AND IMP.ROMANEIO     = ROMA.ROMANEIO
                      AND IMP.ENTRADASAIDA = ROMA.ENTRADASAIDA
                      AND IMP.NUMEROCM     = ROMA.NUMEROCM
                      AND IMP.ROMADESC     IN (31)),0) AS IMPS,

      0 DESCUMIDS,
              0 SECS,
        0 DESCSECS,
  (COALESCE(ROMA.PESOTOTAL,0) - COALESCE(ROMA.TARA,0))*  COALESCE((SELECT SUM(AVAR.REFTABELA) FROM ROMADESC AVAR
                    WHERE AVAR.ESTAB        = ROMA.ESTAB
                      AND AVAR.ROMANEIO     = ROMA.ROMANEIO
                      AND AVAR.ENTRADASAIDA = ROMA.ENTRADASAIDA
                      AND AVAR.NUMEROCM     = ROMA.NUMEROCM
                      AND AVAR.ROMADESC     IN (36)),0) AS PBRUTOAVARS
        ,romaclass.ph as phs
        ,roma.fn as fns
FROM ROMA
    INNER JOIN FILIAL ON
    FILIAL.ESTAB            = ROMA.ESTAB
    
    INNER JOIN CIDADE ON CIDADE.CIDADE=FILIAL.CIDADE
                                      --AND CIDADE.UF='SP'
   	

    INNER JOIN PEMPRESA ON
    PEMPRESA.EMPRESA        = FILIAL.EMPRESA

    INNER JOIN CIDADE FILCID ON
    FILCID.CIDADE           = FILIAL.CIDADE

    INNER JOIN ROMACFG ON
    ROMACFG.ROMANEIOCONFIG  = ROMA.ROMANEIOCONFIG

    INNER JOIN CONTAMOV ON
    CONTAMOV.NUMEROCM       = ROMA.NUMEROCM

    LEFT JOIN ENDERECO ON
    ENDERECO.NUMEROCM       = ROMA.NUMEROCM AND
    ENDERECO.SEQENDERECO    = ROMA.SEQENDERECO

    LEFT JOIN PPESSPRE ON
    PPESSPRE.PRESTADOR      = ROMA.PRESTADOR

    INNER JOIN ROMACLASS ON
    ROMACLASS.ESTAB         = ROMA.ESTAB AND
    ROMACLASS.ROMANEIO      = ROMA.ROMANEIO AND
    ROMACLASS.ENTRADASAIDA  = ROMA.ENTRADASAIDA AND
    ROMACLASS.NUMEROCM      = ROMA.NUMEROCM AND
    ROMACLASS.PERCENTUAL    > 0

    INNER JOIN ROMACLASSNOME ON
    ROMACLASSNOME.CLASSIFICACAO = ROMACLASS.CLASSIFICACAO

    INNER JOIN ITEMAGRO ON
    ITEMAGRO.ITEM           = CASE WHEN ROMACLASS.ITEM IS NULL or (ROMACLASS.ITEM = 0) THEN ROMA.ITEM ELSE ROMACLASS.ITEM END
    
    LEFT JOIN U_DTSOBRA SOBRA ON
    SOBRA.ESTAB = ROMA.ESTAB AND 
    SOBRA.ITEM = ROMA.ITEM
  
      LEFT JOIN ITEMAGRO_U ON ITEMAGRO_U.ITEM = ROMA.ITEM
left join u_agrprodgr on u_agrprodgr.u_agrprodgr_id=itemagro_u.u_agrprodgr_id
WHERE /*ROMA.DTEMISSAO BETWEEN :DTINI AND :DTFIM
AND*/ roma.estornado <> 'S'
--AND ROMA.ITEM = 3
AND ((0 IN (:ITEM)) OR (U_AGRPRODGR.U_AGRPRODGR_ID in (:ITEM)))
and romacfg.entradasaida='S'
  --AND ROMA.ESTAB NOT IN (47)
  AND ROMA.DTEMISSAO > SOBRA.DATALANC

)dados

LEFT JOIN 
(SELECT
DADOS4.ESTAB,
DADOS4.ITEM,
----- JA ESTA EM SACACAS
ARREDONDAR(SUM(DADOS4.SALDOFIS),2)SALDOFIS
FROM(
SELECT  DADOS3.TIPO,
        DADOS3.ESTAB,
        DADOS3.ESTADO,
        DADOS3.DESCESTAB,
        DADOS3.ITEM,
       DADOS3.DESCITEM,
       DADOS3.LOCAL,
       DADOS3.DESCLOCAL,
      SUM(DADOS3.SALDOFIS)SALDOFIS
FROM(
select DADOS2.TIPO,
        DADOS2.ESTAB,
        DADOS2.ESTADO,
        DADOS2.DESCESTAB,
        DADOS2.ITEM,
       DADOS2.DESCITEM,
       DADOS2.LOCAL,
       DADOS2.DESCLOCAL,
      SUM((DADOS2.SALDOFIS)+(DADOS2.SALDOROMA))SALDOFIS

from (

SELECT 'O'as TIPO,
        DADOS.ESTAB,
      CASE WHEN CIDADE.UF='SP' AND DADOS.ESTAB = 5 THEN 'SP - VJ'
        ELSE CIDADE.UF END AS ESTADO,

        FILIAL.REDUZIDO AS DESCESTAB,
       case WHEN DADOS.ITEM=40 then 1 else DADOS.ITEM end  ITEM,
       DADOS.ITEM||'-'||itemagro.descricao as DESCITEM,
       DADOS.LOCAL,
       DADOS.LOCAL||'-'||LOCALEST.DESCRICAO AS DESCLOCAL,
       SUM((DADOS.SALDOFIS)/60)SALDOFIS,
       SUM((DADOS.SALDOROMA)/60)SALDOROMA


FROM (

--SELECT * FROM  BI_SALDOCEREAISFIS
SELECT
    
       DADOS.ESTAB,
       DADOS.ITEM,
       DADOS.LOCAL,
       SUM(DADOS.SALDODFIS2+SALDODFIS4+SALDODFIS6+SALDODFIS23+SALDODFIS27+SALDOFISAJ)SALDOFIS,
       0 SALDOROMA
       FROM(
SELECT
       ITEMSALDOINI.ESTAB,
        u_agrprodgr.u_agrprodgr_id AS ITEM,      
       ITEMSALDOINI.LOCAL,
        
  SUM(SALDOITEM(ITEMSALDOINI.ESTAB, ITEMSALDOINI.ITEM,2,
                 ITEMSALDOINI.LOCAL, ITEMSALDOINI.LOCAL, CURRENT_DATE, NULL, NULL, NULL)) SALDODFIS2,
                 0 SALDODFIS4,
                 0 SALDODFIS6,
                 0 SALDODFIS23,
                 0 SALDODFIS27,
                  0 SALDOFISAJ
                           

FROM ITEMSALDOINI

INNER JOIN u_tempresa ON u_tempresa.estab=ITEMSALDOINI.ESTAB

INNER JOIN ITEMAGRO ON ITEMAGRO.ITEM=ITEMSALDOINI.ITEM

INNER JOIN itemagro_u on itemagro_u.item = itemagro.item

INNER JOIN u_agrprodgr ON u_agrprodgr.u_agrprodgr_id=itemagro_u.u_agrprodgr_id

WHERE   u_agrprodgr.u_agrprodgr_id <=50
    AND u_tempresa.graos='S'
    AND ITEMSALDOINI.CODIGOSALDO = 2
    AND ITEMSALDOINI.LOCAL = 1

GROUP BY  ITEMSALDOINI.ESTAB,
      u_agrprodgr.u_agrprodgr_id, 
       ITEMSALDOINI.LOCAL

UNION ALL

SELECT
       ITEMSALDOINI.ESTAB,
       u_agrprodgr.u_agrprodgr_id AS ITEM,      
       ITEMSALDOINI.LOCAL,
       0 SALDODFIS2,
        
  SUM(SALDOITEM(ITEMSALDOINI.ESTAB, ITEMSALDOINI.ITEM,4,
                 ITEMSALDOINI.LOCAL, ITEMSALDOINI.LOCAL, CURRENT_DATE, NULL, NULL, NULL)) SALDODFIS4,
                 0 SALDODFIS6,
                 0 SALDODFIS23,
                 0 SALDODFIS27,
                  0 SALDOFISAJ
                           
FROM ITEMSALDOINI

INNER JOIN u_tempresa ON u_tempresa.estab=ITEMSALDOINI.ESTAB

INNER JOIN ITEMAGRO ON ITEMAGRO.ITEM=ITEMSALDOINI.ITEM

INNER JOIN itemagro_u on itemagro_u.item = itemagro.item

INNER JOIN u_agrprodgr ON u_agrprodgr.u_agrprodgr_id=itemagro_u.u_agrprodgr_id

WHERE  u_agrprodgr.u_agrprodgr_id <=50
    AND u_tempresa.graos='S'
    AND ITEMSALDOINI.CODIGOSALDO = 4
    AND ITEMSALDOINI.LOCAL = 1

GROUP BY  ITEMSALDOINI.ESTAB,
      u_agrprodgr.u_agrprodgr_id, 
       ITEMSALDOINI.LOCAL

UNION ALL

SELECT
       ITEMSALDOINI.ESTAB,
      u_agrprodgr.u_agrprodgr_id AS ITEM,      
       ITEMSALDOINI.LOCAL,
       0 SALDODFIS2,
       0 SALDODFIS4,
        
  SUM(SALDOITEM(ITEMSALDOINI.ESTAB, ITEMSALDOINI.ITEM,6,
                 ITEMSALDOINI.LOCAL, ITEMSALDOINI.LOCAL, CURRENT_DATE, NULL, NULL, NULL)) SALDODFIS6,
                 0 SALDODFIS23,
                 0 SALDODFIS27,
                  0 SALDOFISAJ
                           
FROM ITEMSALDOINI

INNER JOIN u_tempresa ON u_tempresa.estab=ITEMSALDOINI.ESTAB

INNER JOIN ITEMAGRO ON ITEMAGRO.ITEM=ITEMSALDOINI.ITEM

INNER JOIN itemagro_u on itemagro_u.item = itemagro.item

INNER JOIN u_agrprodgr ON u_agrprodgr.u_agrprodgr_id=itemagro_u.u_agrprodgr_id

WHERE u_agrprodgr.u_agrprodgr_id <=50
    AND u_tempresa.graos='S'
    AND ITEMSALDOINI.CODIGOSALDO = 6
    AND ITEMSALDOINI.LOCAL = 1

GROUP BY  ITEMSALDOINI.ESTAB,
      u_agrprodgr.u_agrprodgr_id, 
       ITEMSALDOINI.LOCAL



UNION ALL

SELECT
       ITEMSALDOINI.ESTAB,
       u_agrprodgr.u_agrprodgr_id AS ITEM,      
       ITEMSALDOINI.LOCAL,
         0 SALDODFIS2,
         0 SALDODFIS4,
         0 SALDODFIS6,
  SUM(SALDOITEM(ITEMSALDOINI.ESTAB, ITEMSALDOINI.ITEM,23,
                 ITEMSALDOINI.LOCAL, ITEMSALDOINI.LOCAL, CURRENT_DATE, NULL, NULL, NULL)) SALDODFIS23,
                                  0 SALDODFIS27,
                                   0 SALDOFISAJ
                           
FROM ITEMSALDOINI

INNER JOIN u_tempresa ON u_tempresa.estab=ITEMSALDOINI.ESTAB

INNER JOIN ITEMAGRO ON ITEMAGRO.ITEM=ITEMSALDOINI.ITEM

INNER JOIN itemagro_u on itemagro_u.item = itemagro.item

INNER JOIN u_agrprodgr ON u_agrprodgr.u_agrprodgr_id=itemagro_u.u_agrprodgr_id

WHERE u_agrprodgr.u_agrprodgr_id <=50
    AND u_tempresa.graos='S'
    AND ITEMSALDOINI.CODIGOSALDO = 23
    AND ITEMSALDOINI.LOCAL = 1

GROUP BY  ITEMSALDOINI.ESTAB,
      u_agrprodgr.u_agrprodgr_id, 
      ITEMSALDOINI.LOCAL

UNION ALL

SELECT
       ITEMSALDOINI.ESTAB,
       u_agrprodgr.u_agrprodgr_id AS ITEM,      
       ITEMSALDOINI.LOCAL,
         0 SALDODFIS2,
         0 SALDODFIS4,
          0 SALDODFIS23,
          0 SALDODFIS6,
  SUM(SALDOITEM(ITEMSALDOINI.ESTAB, ITEMSALDOINI.ITEM,27,
                 ITEMSALDOINI.LOCAL, ITEMSALDOINI.LOCAL, CURRENT_DATE, NULL, NULL, NULL)) SALDODFIS27,
                 0 SALDOFISAJ
                           
FROM ITEMSALDOINI

INNER JOIN u_tempresa ON u_tempresa.estab=ITEMSALDOINI.ESTAB

INNER JOIN ITEMAGRO ON ITEMAGRO.ITEM=ITEMSALDOINI.ITEM

INNER JOIN itemagro_u on itemagro_u.item = itemagro.item

INNER JOIN u_agrprodgr ON u_agrprodgr.u_agrprodgr_id=itemagro_u.u_agrprodgr_id

WHERE  u_agrprodgr.u_agrprodgr_id <=50
    AND u_tempresa.graos='S'
    AND ITEMSALDOINI.CODIGOSALDO = 27
    AND ITEMSALDOINI.LOCAL = 1

GROUP BY  ITEMSALDOINI.ESTAB,
      u_agrprodgr.u_agrprodgr_id, 
      ITEMSALDOINI.LOCAL
      
 union all
 
 select estab,
 u_agrprodgr_id,
 local,
   0 SALDODFIS2,
         0 SALDODFIS4,
          0 SALDODFIS23,
          0 SALDODFIS6,
          0 SALDODFIS27,
 
 quantidade*-1 SALDOFISAJ
    
       
       from u_ajlocalest

where datamov >= current_date
AND u_ajlocalest.LOCAL = 1
      
      )DADOS

GROUP BY DADOS.ESTAB,
       DADOS.ITEM,
       DADOS.LOCAL



----------------- SALDO ROMANEIO 
UNION ALL

SELECT DADOS.ESTAB,
       DADOS.ITEM,
       DADOS.LOCAL,
       0 SALDOFIS,
       SUM(DADOS.ROMAABERTO)SALDOROMA



FROM (
SELECT

    FILIAL.ESTAB,

     u_agrprodgr.u_agrprodgr_id AS ITEM,
    LOCALEST.LOCAL,

    ITEMAGRO.DESCRICAO AS PRODUTO,

    ((SUM(COALESCE(ROMA.PESOLIQUIDO,0)) -
    SUM(COALESCE((SELECT SUM(COALESCE(ROMATXSERVICOPG.QTDEPAGO,0)) FROM ROMATXSERVICOPG
                            WHERE ROMATXSERVICOPG.ESTAB         = ROMA.ESTAB
                              AND ROMATXSERVICOPG.ROMANEIO      = ROMA.ROMANEIO
                              AND ROMATXSERVICOPG.ENTRADASAIDA  = ROMA.ENTRADASAIDA
                              AND ROMATXSERVICOPG.NUMEROCM      = ROMA.NUMEROCM),0)))) AS ROMAABERTO


FROM ROMA
    INNER JOIN FILIAL ON
    FILIAL.ESTAB    = ROMA.ESTAB

    INNER JOIN u_tempresa ON u_tempresa.estab=FILIAL.ESTAB

    INNER JOIN ROMACFG ON
    ROMACFG.ROMANEIOCONFIG  = ROMA.ROMANEIOCONFIG AND
    ROMACFG.ENTRADASAIDA    = ROMA.ENTRADASAIDA AND
    ROMACFG.ENTRADASAIDA    = 'E'

    INNER JOIN ROMACLASS ON
    ROMACLASS.ESTAB         = ROMA.ESTAB AND
    ROMACLASS.ROMANEIO      = ROMA.ROMANEIO AND
    ROMACLASS.ENTRADASAIDA  = ROMA.ENTRADASAIDA AND
    ROMACLASS.NUMEROCM      = ROMA.NUMEROCM AND
    ROMACLASS.PERCENTUAL    > 0

    INNER JOIN ITEMAGRO ON
    ITEMAGRO.ITEM           = CASE WHEN ROMACLASS.ITEM IS NULL THEN ROMA.ITEM ELSE ROMACLASS.ITEM END

      INNER JOIN itemagro_u on itemagro_u.item = itemagro.item

    INNER JOIN u_agrprodgr ON u_agrprodgr.u_agrprodgr_id=itemagro_u.u_agrprodgr_id

    INNER JOIN LOCALEST ON
    LOCALEST.ESTAB      = ROMA.ESTAB AND
    LOCALEST.LOCAL      = ROMA.LOCAL
    
    LEFT JOIN U_DTSOBRA SOBRA ON
    SOBRA.ESTAB = ROMA.ESTAB AND
    SOBRA.ITEM = ROMA.ITEM

    WHERE NOT EXISTS (SELECT ROMA.ROMANEIO FROM NFCABROMA
        WHERE NFCABROMA.ESTAB         = ROMACLASS.ESTAB
          AND NFCABROMA.ROMANEIO      = ROMACLASS.ROMANEIO
          AND NFCABROMA.ENTRADASAIDA  = ROMACLASS.ENTRADASAIDA
          AND NFCABROMA.NUMEROCM      = ROMACLASS.NUMEROCM)
          --AND NFCABROMA.CLASSIFICACAO = ROMACLASS.CLASSIFICACAO)
          AND ROMA.ESTORNADO            = 'N'
         AND u_tempresa.graos='S'
         AND ROMA.LOCAL = 1
         AND ROMA.DTEMISSAO > SOBRA.DATALANC

GROUP BY
    FILIAL.ESTAB,
    FILIAL.REDUZIDO,
  --  ROMA.ROMANEIO,
    LOCALEST.LOCAL,
    u_agrprodgr.u_agrprodgr_id,
    ITEMAGRO.DESCRICAO

UNION ALL

SELECT

    FILIAL.ESTAB,

    u_agrprodgr.u_agrprodgr_id AS ITEM,
    LOCALEST.LOCAL,

    ITEMAGRO.DESCRICAO AS PRODUTO,

    ((SUM(COALESCE(ROMA.PESOLIQUIDO,0)) -
    SUM(COALESCE((SELECT SUM(COALESCE(ROMATXSERVICOPG.QTDEPAGO,0)) FROM ROMATXSERVICOPG
                            WHERE ROMATXSERVICOPG.ESTAB         = ROMA.ESTAB
                              AND ROMATXSERVICOPG.ROMANEIO      = ROMA.ROMANEIO
                              AND ROMATXSERVICOPG.ENTRADASAIDA  = ROMA.ENTRADASAIDA
                              AND ROMATXSERVICOPG.NUMEROCM      = ROMA.NUMEROCM),0))))*-1 AS ROMAABERTO

FROM ROMA
    INNER JOIN FILIAL ON
    FILIAL.ESTAB    = ROMA.ESTAB

    INNER JOIN u_tempresa ON u_tempresa.estab=FILIAL.ESTAB

    INNER JOIN ROMACFG ON
    ROMACFG.ROMANEIOCONFIG  = ROMA.ROMANEIOCONFIG AND
    ROMACFG.ENTRADASAIDA    = ROMA.ENTRADASAIDA AND
    ROMACFG.ENTRADASAIDA    = 'S'

    INNER JOIN ROMACLASS ON
    ROMACLASS.ESTAB         = ROMA.ESTAB AND
    ROMACLASS.ROMANEIO      = ROMA.ROMANEIO AND
    ROMACLASS.ENTRADASAIDA  = ROMA.ENTRADASAIDA AND
    ROMACLASS.NUMEROCM      = ROMA.NUMEROCM AND
    ROMACLASS.PERCENTUAL    > 0

    INNER JOIN ITEMAGRO ON
    ITEMAGRO.ITEM           = CASE WHEN ROMACLASS.ITEM IS NULL THEN ROMA.ITEM ELSE ROMACLASS.ITEM END

      INNER JOIN itemagro_u on itemagro_u.item = itemagro.item

    INNER JOIN u_agrprodgr ON u_agrprodgr.u_agrprodgr_id=itemagro_u.u_agrprodgr_id

    INNER JOIN LOCALEST ON
    LOCALEST.ESTAB      = ROMA.ESTAB AND
    LOCALEST.LOCAL      = ROMA.LOCAL
    
    LEFT JOIN U_DTSOBRA SOBRA ON
    SOBRA.ESTAB = ROMA.ESTAB AND
    SOBRA.ITEM = ROMA.ITEM

    WHERE NOT EXISTS (SELECT ROMA.ROMANEIO FROM NFCABROMA
        WHERE NFCABROMA.ESTAB         = ROMACLASS.ESTAB
          AND NFCABROMA.ROMANEIO      = ROMACLASS.ROMANEIO
          AND NFCABROMA.ENTRADASAIDA  = ROMACLASS.ENTRADASAIDA
          AND NFCABROMA.NUMEROCM      = ROMACLASS.NUMEROCM)
          --AND NFCABROMA.CLASSIFICACAO = ROMACLASS.CLASSIFICACAO)
          AND ROMA.ESTORNADO            = 'N'
          AND u_tempresa.graos='S'
         AND ROMA.LOCAL = 1
        AND ROMA.DTEMISSAO > SOBRA.DATALANC
        
        
GROUP BY
    FILIAL.ESTAB,
    FILIAL.REDUZIDO,
  --  ROMA.ROMANEIO,
    LOCALEST.LOCAL,
   u_agrprodgr.u_agrprodgr_id,
    ITEMAGRO.DESCRICAO 
    
    )DADOS

     GROUP BY DADOS.ESTAB,
       DADOS.ITEM,
       DADOS.LOCAL



   )DADOS



inner join FILIAL ON FILIAL.ESTAB=DADOS.ESTAB

inner join cidade on cidade.cidade=filial.cidade

INNER JOIN u_tempresa ON u_tempresa.estab=FILIAL.ESTAB

inner join itemagro on itemagro.item=dados.item

    LEFT JOIN localest on localest.estab = DADOS.estab
                 and localest.local =DADOS.local

/*WHERE 
DADOS.ITEM = 3 AND DADOS.ESTAB  = 12*/

       GROUP BY DADOS.ESTAB,
       FILIAL.REDUZIDO,
       DADOS.ITEM,
       itemagro.descricao,
         DADOS.LOCAL,
       LOCALEST.DESCRICAO,
CIDADE.UF



HAVING   SUM(DADOS.SALDOFIS)<> 0
       
       OR SUM(DADOS.SALDOROMA)<> 0

ORDER BY DADOS.ITEM,DADOS.ESTAB,DADOS.LOCAL)dados2

GROUP BY  DADOS2.TIPO,
        DADOS2.ESTAB,
        DADOS2.ESTADO,
        DADOS2.DESCESTAB,
        DADOS2.ITEM,
       DADOS2.DESCITEM,
       DADOS2.LOCAL,
       DADOS2.DESCLOCAL)DADOS3

GROUP BY  DADOS3.TIPO,
        DADOS3.ESTAB,
        DADOS3.ESTADO,
        DADOS3.DESCESTAB,
        DADOS3.ITEM,
       DADOS3.DESCITEM,
       DADOS3.LOCAL,
       DADOS3.DESCLOCAL

HAVING    
      SUM(DADOS3.SALDOFIS) <> 0
     

ORDER BY DADOS3.ITEM,DADOS3.ESTADO DESC,DADOS3.ESTAB,DADOS3.LOCAL

)DADOS4

GROUP BY

DADOS4.ESTAB,DADOS4.ITEM


        )FISICO
ON FISICO.ESTAB = DADOS.ESTAB
AND FISICO.ITEM = DADOS.ITEM


--WHERE DADOS.ESTAB = 10
WHERE 0=0 AND ('X' IN (:UF) OR DADOS.UF IN (:UF))
 group by dados.estab,dados.uf,  dados.reduzido,DADOS.ITEM,FISICO.SALDOFIS
     
     order by dados.estab

)DADOS1

LEFT JOIN U_DTSOBRA SOBRA ON
    SOBRA.ESTAB = DADOS1.ESTAB AND
    SOBRA.ITEM = DADOS1.ITEM