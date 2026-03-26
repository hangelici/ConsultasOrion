SELECT DISTINCT
FILIAL.REDUZIDO|| ' - ' ||DADOS1.OSESTAB as REDUZIDO,
DADOS1.OSPRODUTO,
DADOS1.PRODUTO,
DADOS1.DESC_LOCAL,
--DADOS1.CIDADE,
DADOS1.UF,
DADOS1.MACROREG,
DADOS1.CIDLOCAL,
SUM(DADOS1.SALDO_COMP) - sum(SALDO_EXPORT) as SALDO_COMP,
SUM(DADOS1.SALDO_RET)SALDO_RET,
SUM(DADOS1.SALDO_COMPDISP)SALDO_COMPDISP,
SUM(DADOS1.SALDOFIS)SALDOFIS,
sum(SALDO_EXPORT) as SALDO_EXPORT,
coalesce(sum(ordem.qtd_ordem),0)qtd_ordem,
'https://www.google.com/maps?q='||REPLACE(DADOS1.LATITUDE,',','.')||',+'||REPLACE(DADOS1.LONGITUDE,',','.')||'&'||'uact=5'||'&'||'gs_lcp=Cgxnd3Mtd2l6LXNlcnAQA0oECEEYAEoECEYYAFAAWIU7YIBBaAFwAHgAgAHTBYgBvQqSAQkzLjEuMS42LTGYAQCgAQHAAQE'||'&'||'um=1'||'&'||'ie=UTF-8'||'&'||'sa=X'||'&'||'ved=2ahUKEwiIxrrR3fH8AhVxpZUCHQM8ByAQ_AUoBHoECAUQBg' AS LATI_LONG

FROM(




SELECT   DADOS.OSESTAB,
         DADOS.OSPRODUTO,
         dados.produto,
          DADOS.LOCAL,
        DADOS.OSLOCAL,
       
        DADOS.DESCRICAO as desc_local,
       --DADOS.REDUZIDO AS FILIAL,
       DADOS.CIDADE,
       DADOS.UF,
    DADOS.MACROREG,
    DADOS.CIDLOCAL,
        SUM(DADOS.SALDO_COMP)SALDO_COMP,
        SUM(DADOS.QTDSALDORET)SALDO_RET,
        CASE WHEN DADOS.LOCAL = 1  THEN ARREDONDAR(DIVIDE(SUM(DADOS.SALDOFIS),60),2) ELSE
        SUM(DADOS.SALDO_COMP)+SUM(DADOS.QTDSALDORET) END SALDO_COMPDISP,
                ARREDONDAR(DIVIDE(SUM(DADOS.SALDOFIS),60),0)SALDOFIS,
                sum(SALDO_EXPORT) as  SALDO_EXPORT,
                DADOS.LATITUDE,
                DADOS.LONGITUDE

FROM (

SELECT   DADOS.estab OSESTAB,
        DADOS.REDUZIDO,
        DADOS.CIDADE,
        DADOS.UF,
        DADOS.MACROREG,
        DADOS.CIDLOCAL,
         DADOS.ITEM OSPRODUTO,
         dados.produto,
         DADOS.LOCAL,
        DADOS.estab||'#'||DADOS.local as OSLOCAL,
       DADOS.DESCRICAO,
        ARREDONDAR(SUM((saldodisp)/60),2)SALDO_COMP,
        0 QTDSALDORET,
        0  SALDOFIS,
        SUM(SALDO_EXPORT) AS  SALDO_EXPORT,
        DADOS.LATITUDE,
        DADOS.LONGITUDE


FROM (

SELECT DISTINCT
       ITEMSALDOINI.ESTAB,
      u_agrprodgr.u_agrprodgr_id AS ITEM,
       u_agrprodgr.descagrupa as PRODUTO,
       ITEMSALDOINI.LOCAL,
       LOCALEST.DESCRICAO AS DESCRICAO,
      -- CASE WHEN ITEMSALDOINI.LOCAL=1 THEN  LOCALEST.DESCRICAO||'-'||ITEMSALDOINI.LOCAL ELSE LOCALEST.DESCRICAO  END    DESCRICAO     ,
       FILIAL.REDUZIDO,
       COALESCE(CIDADE.NOME,FILIAL.REDUZIDO) AS CIDADE,
       COALESCE(CIDADE.UF,'XX')UF,
       COALESCE(MESORREGIAO.DESCRICAO,CIDADE.NOME) AS MACROREG,
       COALESCE(CID.NOME,CIDADE.NOME)AS CIDLOCAL,
      sum(SALDOITEM(ITEMSALDOINI.ESTAB, ITEMSALDOINI.ITEM,1,
                 ITEMSALDOINI.LOCAL, ITEMSALDOINI.LOCAL, CURRENT_DATE, NULL, NULL, NULL)) SALDODISP,
                  0 SALDOFIS,
                  0 DEPOSTOPROD,
       0 QTDSALDO,
       0 QTDSALDOCF,
       0 QTDSALDOVD,
       0 QTDSALDOVF,
       0 SALDO_EXPORT,
       LOCALEST_U.LATITUDE,
       LOCALEST_U.LONGITUDE

FROM ITEMSALDOINI

INNER JOIN u_tempresa ON u_tempresa.estab=ITEMSALDOINI.ESTAB

INNER JOIN LOCALEST ON LOCALEST.LOCAL= ITEMSALDOINI.LOCAL
                   AND LOCALEST.LOCAL > 1
                   AND LOCALEST.ESTAB=ITEMSALDOINI.ESTAB

INNER JOIN LOCALEST_U ON LOCALEST_U.ESTAB = LOCALEST.ESTAB
                        AND LOCALEST_U.LOCAL = LOCALEST.LOCAL

INNER JOIN ITEMAGRO ON ITEMAGRO.ITEM=ITEMSALDOINI.ITEM

INNER JOIN itemagro_u on itemagro_u.item = itemagro.item
-- Materia Prima
LEFT JOIN ITEMCOMPOS ON ITEMCOMPOS.ESTAB = ITEMSALDOINI.ESTAB
                    AND ITEMCOMPOS.ITEM = ITEMSALDOINI.ITEM

LEFT JOIN itemagro_u AGRO_U on AGRO_U.item = ITEMCOMPOS.ITEMMATERIAPRIMA
-- alterando agrupamento de prod
 
INNER JOIN u_agrprodgr ON u_agrprodgr.u_agrprodgr_id = --COALESCE(itemagro_u.u_agrprodgr_id,AGRO_U.u_agrprodgr_id) 
                                                        (case 
                                                            when AGRO_U.ITEM IN (40,41) THEN 1 
                                                            when AGRO_U.u_agrprodgr_id IS NULL THEN itemagro_u.u_agrprodgr_id
                                                            ELSE itemagro_u.u_agrprodgr_id END )
                                                        
INNER JOIN FILIAL ON FILIAL.ESTAB = ITEMSALDOINI.ESTAB

LEFT JOIN CIDADE ON CIDADE.CIDADE = FILIAL.CIDADE

LEFT JOIN CIDADE CID ON CID.CIDADE = LOCALEST.CIDADE

LEFT JOIN microrregiao ON MICRORREGIAO.IDMICRORREGIAO = CID.IDMICRORREGIAO

LEFT JOIN MESORREGIAO ON MESORREGIAO.IDMESORREGIAO = MICRORREGIAO.IDMESORREGIAO



WHERE  u_agrprodgr.u_agrprodgr_id in (1,2,3,4,5,6,7,8,9,10,11,24)
    AND u_tempresa.graos='S'
    AND ITEMSALDOINI.CODIGOSALDO = 1
    AND LOCALEST.LOCAL < 899
   AND (LOCALEST.DESCRICAO not like '%OURO SAFRA%')

GROUP BY  ITEMSALDOINI.ESTAB,
     u_agrprodgr.u_agrprodgr_id,
     --ITEMAGRO.ITEM,
       ITEMSALDOINI.LOCAL,LOCALEST.DESCRICAO,FILIAL.REDUZIDO,CIDADE.NOME,CIDADE.UF,u_agrprodgr.descagrupa,MESORREGIAO.DESCRICAO, CID.NOME,LOCALEST_U.LATITUDE,
       LOCALEST_U.LONGITUDE
       
union all

SELECT
  FILIAL.ESTAB,
      u_agrprodgr.u_agrprodgr_id AS ITEM,
       u_agrprodgr.descagrupa as PRODUTO,
       CONTRATOITE.LOCAL,
       LOCALEST.DESCRICAO AS DESCRICAO,
      -- CASE WHEN ITEMSALDOINI.LOCAL=1 THEN  LOCALEST.DESCRICAO||'-'||ITEMSALDOINI.LOCAL ELSE LOCALEST.DESCRICAO  END    DESCRICAO     ,
       FILIAL.REDUZIDO,
       COALESCE(CIDADE.NOME,FILIAL.REDUZIDO) AS CIDADE,
       COALESCE(CIDADE.UF,'XX')UF,
       COALESCE(MESORREGIAO.DESCRICAO,CIDADE.NOME) AS MACROREG,
       COALESCE(CID.NOME,CIDADE.NOME)AS CIDLOCAL,
      0 SALDODISP,
                  0 SALDOFIS,
                  0 DEPOSTOPROD,
       0 QTDSALDO,
       0 QTDSALDOCF,
       0 QTDSALDOVD,
       0 QTDSALDOVF,
       
       ARREDONDAR(DIVIDE(PSALDO.NQTDSALDO,60),2) AS SALDO_EXPORT,
       LOCALEST_U.LATITUDE,
       LOCALEST_U.LONGITUDE
FROM CONTRATO

  INNER JOIN CONTRATOITE ON
     (CONTRATOITE.ESTAB = CONTRATO.ESTAB)
     AND (CONTRATOITE.CONTRATO = CONTRATO.CONTRATO)
     
    INNER JOIN TABLE (PCONTRATOSALDO( CONTRATO.ESTAB,
                 CURRENT_DATE, CONTRATO.CONTRATO, CONTRATO.CONTRATO,
                 CONTRATOITE.SEQITEM, CONTRATOITE.SEQITEM, NULL, NULL, NULL,
                 NULL, NULL)) PSALDO
    ON (0=0)
    
    INNER JOIN LOCALEST ON LOCALEST.LOCAL= CONTRATOITE.LOCAL
                   AND LOCALEST.LOCAL > 1
                   AND LOCALEST.ESTAB=CONTRATOITE.ESTAB
                   
INNER JOIN LOCALEST_U ON LOCALEST_U.ESTAB = LOCALEST.ESTAB
                        AND LOCALEST_U.LOCAL = LOCALEST.LOCAL
                   
    INNER JOIN ITEMAGRO ON ITEMAGRO.ITEM=CONTRATOITE.ITEM

INNER JOIN itemagro_u on itemagro_u.item = itemagro.item
-- Materia Prima
LEFT JOIN ITEMCOMPOS ON ITEMCOMPOS.ESTAB = CONTRATOITE.ESTAB
                    AND ITEMCOMPOS.ITEM = CONTRATOITE.ITEM

LEFT JOIN itemagro_u AGRO_U on AGRO_U.item = ITEMCOMPOS.ITEMMATERIAPRIMA
-- alterando agrupamento de prod
 
INNER JOIN u_agrprodgr ON u_agrprodgr.u_agrprodgr_id = --COALESCE(itemagro_u.u_agrprodgr_id,AGRO_U.u_agrprodgr_id) 
                                                        (case 
                                                            when AGRO_U.ITEM IN (40,41) THEN 1 
                                                            when AGRO_U.u_agrprodgr_id IS NULL THEN itemagro_u.u_agrprodgr_id
                                                            ELSE itemagro_u.u_agrprodgr_id END )
                                                        
INNER JOIN FILIAL ON FILIAL.ESTAB = CONTRATO.ESTAB

LEFT JOIN CIDADE ON CIDADE.CIDADE = FILIAL.CIDADE

LEFT JOIN CIDADE CID ON CID.CIDADE = LOCALEST.CIDADE

LEFT JOIN microrregiao ON MICRORREGIAO.IDMICRORREGIAO = CID.IDMICRORREGIAO

LEFT JOIN MESORREGIAO ON MESORREGIAO.IDMESORREGIAO = MICRORREGIAO.IDMESORREGIAO

INNER JOIN u_tempresa ON u_tempresa.estab=FILIAL.ESTAB

where
CONTRATO.CONTCONF = 7
AND u_agrprodgr.u_agrprodgr_id in (1,2,3,4,5,6,7,8,9,10,11,24)
    AND u_tempresa.graos='S'
    AND LOCALEST.LOCAL < 899
   AND (LOCALEST.DESCRICAO not like '%OURO SAFRA%')
   AND PSALDO.NQTDSALDO > 0
  AND CONTRATO.DTMOVSALDO <= LAST_DAY(CURRENT_DATE)
   
union all

select
  FILIAL.ESTAB,
      u_agrprodgr.u_agrprodgr_id AS ITEM,
       u_agrprodgr.descagrupa as PRODUTO,
       localest.LOCAL,
       LOCALEST.DESCRICAO AS DESCRICAO,
      -- CASE WHEN ITEMSALDOINI.LOCAL=1 THEN  LOCALEST.DESCRICAO||'-'||ITEMSALDOINI.LOCAL ELSE LOCALEST.DESCRICAO  END    DESCRICAO     ,
       FILIAL.REDUZIDO,
       COALESCE(CIDADE.NOME,FILIAL.REDUZIDO) AS CIDADE,
       COALESCE(CIDADE.UF,'XX')UF,
       COALESCE(MESORREGIAO.DESCRICAO,CIDADE.NOME) AS MACROREG,
       COALESCE(CID.NOME,CIDADE.NOME)AS CIDLOCAL,
      0 SALDODISP,
                  0 SALDOFIS,
                  0 DEPOSTOPROD,
       0 QTDSALDO,
       0 QTDSALDOCF,
       0 QTDSALDOVD,
       0 QTDSALDOVF,
       
       ARREDONDAR(DIVIDE(sum(nfitem.quantidade) - coalesce(apartirde.bx,0),60),2)  SALDO_EXPORT,
       LOCALEST_U.LATITUDE,
       LOCALEST_U.LONGITUDE
from nfcab

inner join nfitem on
    nfitem.estab = nfcab.estab
    and nfitem.seqnota = nfcab.seqnota
    
left join (
    select
    estaborigem,
    seqnotaorigem,
    seqnotaitemorigem,
    sum(quantidade) as bx
    from nfitemapartirde
    
    group by
    estaborigem,seqnotaorigem,seqnotaitemorigem
)apartirde on
apartirde.estaborigem = nfitem.estab
and apartirde.seqnotaorigem = nfitem.seqnota
and   apartirde.seqnotaitemorigem = nfitem.seqnotaitem

 INNER JOIN LOCALEST ON LOCALEST.LOCAL= nfitem.LOCAL
                   AND LOCALEST.LOCAL > 1
                   AND LOCALEST.ESTAB=nfitem.ESTAB
                   
INNER JOIN LOCALEST_U ON LOCALEST_U.ESTAB = LOCALEST.ESTAB
                        AND LOCALEST_U.LOCAL = LOCALEST.LOCAL
                   
    INNER JOIN ITEMAGRO ON ITEMAGRO.ITEM=nfitem.ITEM

INNER JOIN itemagro_u on itemagro_u.item = itemagro.item
-- Materia Prima
LEFT JOIN ITEMCOMPOS ON ITEMCOMPOS.ESTAB = nfitem.ESTAB
                    AND ITEMCOMPOS.ITEM = nfitem.ITEM

LEFT JOIN itemagro_u AGRO_U on AGRO_U.item = ITEMCOMPOS.ITEMMATERIAPRIMA
-- alterando agrupamento de prod
 
INNER JOIN u_agrprodgr ON u_agrprodgr.u_agrprodgr_id = --COALESCE(itemagro_u.u_agrprodgr_id,AGRO_U.u_agrprodgr_id) 
                                                        (case 
                                                            when AGRO_U.ITEM IN (40,41) THEN 1 
                                                            when AGRO_U.u_agrprodgr_id IS NULL THEN itemagro_u.u_agrprodgr_id
                                                            ELSE itemagro_u.u_agrprodgr_id END )
                                                        
INNER JOIN FILIAL ON FILIAL.ESTAB = NFCAB.ESTAB

LEFT JOIN CIDADE ON CIDADE.CIDADE = FILIAL.CIDADE

LEFT JOIN CIDADE CID ON CID.CIDADE = LOCALEST.CIDADE

LEFT JOIN microrregiao ON MICRORREGIAO.IDMICRORREGIAO = CID.IDMICRORREGIAO

LEFT JOIN MESORREGIAO ON MESORREGIAO.IDMESORREGIAO = MICRORREGIAO.IDMESORREGIAO

INNER JOIN u_tempresa ON u_tempresa.estab=FILIAL.ESTAB

where
coalesce(nfcab.status,'X') <> 'C'
and nfcab.notaconf in (392,397)
AND u_agrprodgr.u_agrprodgr_id in (1,2,3,4,5,6,7,8,9,10,11,24)
    AND u_tempresa.graos='S'
    AND LOCALEST.LOCAL < 899
   AND (LOCALEST.DESCRICAO not like '%OURO SAFRA%')

group by
 FILIAL.ESTAB,
      u_agrprodgr.u_agrprodgr_id,
       u_agrprodgr.descagrupa ,
       localest.LOCAL,
       LOCALEST.DESCRICAO ,
      -- CASE WHEN ITEMSALDOINI.LOCAL=1 THEN  LOCALEST.DESCRICAO||'-'||ITEMSALDOINI.LOCAL ELSE LOCALEST.DESCRICAO  END    DESCRICAO     ,
       FILIAL.REDUZIDO,
       CIDADE.NOME,
       FILIAL.REDUZIDO,
       CIDADE.UF,
      MESORREGIAO.DESCRICAO,
       CID.NOME,
       apartirde.bx,
       LOCALEST_U.LATITUDE,
       LOCALEST_U.LONGITUDE
       
       having (sum(nfitem.quantidade) - coalesce(apartirde.bx,0)) >0


UNION ALL

select u_ajlocalest.estab,
u_ajlocalest.u_agrprodgr_id,
u_agrprodgr.descagrupa as PRODUTO,
u_ajlocalest.local,
LOCALEST.DESCRICAO AS DESCRICAO,
--CASE WHEN u_ajlocalest.local=1 THEN LOCALEST.DESCRICAO ||'-'||u_ajlocalest.local ELSE LOCALEST.DESCRICAO  END DESCRICAO,
FILIAL.REDUZIDO,
       COALESCE(CIDADE.NOME,FILIAL.REDUZIDO) AS CIDADE,
       COALESCE(CIDADE.UF,'XX')UF,
        COALESCE(MESORREGIAO.DESCRICAO,CIDADE.NOME) AS MACROREG,
         COALESCE(CID.NOME,CIDADE.NOME)AS CIDLOCAL,
quantidade*-1 saldodisp,
0 SALDOFIS,
                  0 DEPOSTOPROD,
       0 QTDSALDO,
       0 QTDSALDOCF,
       0 QTDSALDOVD,
       0 QTDSALDOVF,
       0 SALDO_EXPORT,
       LOCALEST_U.LATITUDE,
       LOCALEST_U.LONGITUDE
       from u_ajlocalest

INNER JOIN LOCALEST ON LOCALEST.LOCAL= u_ajlocalest.LOCAL
                   AND LOCALEST.ESTAB=u_ajlocalest.ESTAB

INNER JOIN LOCALEST_U ON LOCALEST_U.ESTAB = LOCALEST.ESTAB
                        AND LOCALEST_U.LOCAL = LOCALEST.LOCAL

INNER JOIN FILIAL ON FILIAL.ESTAB =  u_ajlocalest.ESTAB             

LEFT JOIN CIDADE ON CIDADE.CIDADE = FILIAL.CIDADE  

INNER JOIN u_agrprodgr ON u_agrprodgr.u_agrprodgr_id=u_ajlocalest.u_agrprodgr_id

LEFT JOIN CIDADE CID ON CID.CIDADE = LOCALEST.CIDADE

LEFT JOIN microrregiao ON MICRORREGIAO.IDMICRORREGIAO = CID.IDMICRORREGIAO

LEFT JOIN MESORREGIAO ON MESORREGIAO.IDMESORREGIAO = MICRORREGIAO.IDMESORREGIAO

where datamov >= current_date
AND LOCALEST.LOCAL > 1
AND LOCALEST.LOCAL < 899
 AND (LOCALEST.DESCRICAO not like '%OURO SAFRA%')

)DADOS

INNER JOIN LOCALEST_U ON LOCALEST_U.ESTAB=DADOS.ESTAB
                     AND LOCALEST_U.LOCAL=DADOS.LOCAL
                     AND LOCALEST_U.LOCAL > 1
                     AND LOCALEST_U.LOCFILIAL <> 'S'  
                     
WHERE (DADOS.DESCRICAO not like '%OURO SAFRA%' )--AND DADOS.LOCAL <> 1)   
AND DADOS.LOCAL < 899

GROUP BY DADOS.estab,
        DADOS.ITEM,
        DADOS.local,DADOS.DESCRICAO,DADOS.REDUZIDO,DADOS.CIDADE,DADOS.UF,dados.produto, DADOS.MACROREG,DADOS.CIDLOCAL,DADOS.LATITUDE,
                DADOS.LONGITUDE
        


union all

SELECT
     CONTRATO.ESTAB AS OSESTAB,  
        FILIAL.REDUZIDO,
    COALESCE(CIDADE.NOME,FILIAL.REDUZIDO) AS CIDADE,
       COALESCE(CIDADE.UF,'XX')UF,
        COALESCE(MESORREGIAO.DESCRICAO,CIDADE.NOME) AS MACROREG,
          COALESCE(CID.NOME,CIDADE.NOME)AS CIDLOCAL,
      u_agrprodgr.u_agrprodgr_id as OSPRODUTO,
       u_agrprodgr.descagrupa as PRODUTO,
       LOCALEST_U.LOCAL,
       CONTRATO.ESTAb||'#'||LOCALEST_U.LOCAL as OSLOCAL,
       LOCALEST.DESCRICAO AS DESCRICAO,
      --CASE WHEN  LOCALEST_U.LOCAL=1 THEN  LOCALEST.DESCRICAO||'-'|| LOCALEST_U.LOCAL ELSE LOCALEST.DESCRICAO END DESCRICAO,
    
       0 SALDO_COMP,
       ARREDONDAR(CAST((COALESCE(SUM(PSALDO.NQTDSALDO),0)/60)AS DECIMAL(18,2))*-1,0) AS QTDSALDORET,0 SALDOFIS,0 SALDO_EXPORT,
        LOCALEST_U.LATITUDE,
        LOCALEST_U.LONGITUDE
FROM CONTRATO

      INNER JOIN FILIAL ON
      (FILIAL.ESTAB = CONTRATO.ESTAB)

      INNER JOIN CONTAMOV ON
     (CONTAMOV.NUMEROCM = CONTRATO.NUMEROCM)

      INNER JOIN CONTRATOCFG ON
     (CONTRATOCFG.CONTCONF = CONTRATO.CONTCONF)


      INNER JOIN CONTRATOITE ON
     (CONTRATOITE.ESTAB = CONTRATO.ESTAB)
     AND (CONTRATOITE.CONTRATO = CONTRATO.CONTRATO)

    LEFT JOIN TABLE (PCONTRATOSALDO( CONTRATO.ESTAB,
                 CURRENT_DATE, CONTRATO.CONTRATO, CONTRATO.CONTRATO,
                 CONTRATOITE.SEQITEM, CONTRATOITE.SEQITEM, NULL, NULL, NULL,
                 NULL, NULL)) PSALDO
    ON (0=0)
    
    LEFT JOIN LOCALEST_U ON  LOCALEST_U.NUMEROCM=contrato.pessretirada
                         AND LOCALEST_U.LOCAL > 1
                         AND LOCALEST_U.SEQENDERECO = coalesce(contrato.seqendretirada,0)
                         AND LOCALEST_U.LOCFILIAL <> 'S'
                         AND LOCALEST_U.ESTAB = CONTRATO.ESTAB


    LEFT JOIN LOCALEST ON LOCALEST.ESTAB = LOCALEST_U.ESTAB
                    AND LOCALEST.LOCAL = LOCALEST_U.LOCAL

LEFT JOIN CIDADE ON CIDADE.CIDADE = FILIAL.CIDADE

INNER JOIN ITEMAGRO ON ITEMAGRO.ITEM=CONTRATOITE.ITEM

INNER JOIN itemagro_u on itemagro_u.item = itemagro.item

-- Materia Prima
LEFT JOIN ITEMCOMPOS ON ITEMCOMPOS.ESTAB = CONTRATOITE.ESTAB
                    AND ITEMCOMPOS.ITEM = CONTRATOITE.ITEM

LEFT JOIN itemagro_u AGRO_U on AGRO_U.item = ITEMCOMPOS.ITEMMATERIAPRIMA

-- alterando agrupamento de prod
INNER JOIN u_agrprodgr ON u_agrprodgr.u_agrprodgr_id = --COALESCE(itemagro_u.u_agrprodgr_id,AGRO_U.u_agrprodgr_id) 
                                                        (case 
                                                            when AGRO_U.ITEM IN (40,41) THEN 1 
                                                            when AGRO_U.u_agrprodgr_id IS NULL THEN itemagro_u.u_agrprodgr_id
                                                            ELSE itemagro_u.u_agrprodgr_id END )



LEFT JOIN CIDADE CID ON CID.CIDADE = LOCALEST.CIDADE

LEFT JOIN microrregiao ON MICRORREGIAO.IDMICRORREGIAO = CID.IDMICRORREGIAO

LEFT JOIN MESORREGIAO ON MESORREGIAO.IDMESORREGIAO = MICRORREGIAO.IDMESORREGIAO

 where CONTRATO.DTMOVSALDO <= LAST_DAY(CURRENT_DATE)
  
AND contratocfg.entradasaida ='S'
 AND FILIAL.INATIVA='N'
and contrato.contconf NOT IN(51)
-- and contrato.pessretirada > 0
 and PSALDO.NQTDSALDO > 0
 AND LOCALEST_U.LOCAL > 1
 AND LOCALEST.LOCAL < 899
 and (localest.descricao not like '%OURO SAFRA%')
 
 group by CONTRATO.ESTAB,       
       CONTAMOV.NOME,
        LOCALEST.DESCRICAO,
   FILIAL.REDUZIDO,
          CIDADE.NOME ,
       CIDADE.UF,MESORREGIAO.DESCRICAO,
      u_agrprodgr.u_agrprodgr_id,
      -- CONTRATOITE.ITEM,
         u_agrprodgr.descagrupa,
       contratoite.local,
       LOCALEST_U.LOCAL,CID.NOME,LOCALEST_U.LATITUDE,
        LOCALEST_U.LONGITUDE
       

UNION ALL

------------------------------------------ FISICO


SELECT
       DADOS.ESTAB AS OSESTAB,
       DADOS.REDUZIDO AS FILIAL,
          DADOS.CIDADE,
              DADOS.UF,
              DADOS.MACROREG,
              DADOS.CIDLOCAL,
       DADOS.ITEM AS OSPRODUTO,
       DADOS.produto,
       DADOS.LOCAL,
       DADOS.ESTAB||'#'||DADOS.LOCAL AS OSLOCAL,
    DADOS.DESCRICAO as local,
       
    
   
       0 as SALDO_COMP,
       0 AS SALDO_RET,
     --  0 AS SALDO_COMPDISP,
       SUM(DADOS.SALDODFIS2+SALDODFIS4+SALDODFIS6+SALDODFIS23+SALDODFIS27+SALDOFISAJ)SALDOFIS,
       0 SALDO_EXPORT,

       ''LATITUDE,
        ''LONGITUDE
    
       FROM(
SELECT
       ITEMSALDOINI.ESTAB,
        u_agrprodgr.u_agrprodgr_id AS ITEM,      
       ITEMSALDOINI.LOCAL,
        LOCALEST.DESCRICAO AS DESCRICAO,
       --CASE WHEN     ITEMSALDOINI.LOCAL=1 THEN      LOCALEST.DESCRICAO||'-'||  ITEMSALDOINI.LOCAL ELSE   LOCALEST.DESCRICAO END DESCRICAO,
       FILIAL.REDUZIDO,
       COALESCE(CIDADE.NOME,FILIAL.REDUZIDO) AS CIDADE,
       COALESCE(CIDADE.UF,'XX')UF,
        COALESCE(MESORREGIAO.DESCRICAO,CIDADE.NOME) AS MACROREG,
        COALESCE(CID.NOME,CIDADE.NOME)AS CIDLOCAL,
        u_agrprodgr.descagrupa as produto,
  SUM(SALDOITEM(ITEMSALDOINI.ESTAB, ITEMSALDOINI.ITEM,2,
                 ITEMSALDOINI.LOCAL, ITEMSALDOINI.LOCAL, CURRENT_DATE, NULL, NULL, NULL)) SALDODFIS2,
                 0 SALDODFIS4,
                 0 SALDODFIS6,
                 0 SALDODFIS23,
                 0 SALDODFIS27,
                  0 SALDOFISAJ,
                       ''LATITUDE,
                       ''LONGITUDE
                           

FROM ITEMSALDOINI

INNER JOIN u_tempresa ON u_tempresa.estab=ITEMSALDOINI.ESTAB

INNER JOIN LOCALEST ON LOCALEST.LOCAL= ITEMSALDOINI.LOCAL
                   AND LOCALEST.LOCAL > 1
                   AND LOCALEST.ESTAB=ITEMSALDOINI.ESTAB

INNER JOIN ITEMAGRO ON ITEMAGRO.ITEM=ITEMSALDOINI.ITEM

INNER JOIN itemagro_u on itemagro_u.item = itemagro.item

-- Materia Prima
LEFT JOIN ITEMCOMPOS ON ITEMCOMPOS.ESTAB = ITEMSALDOINI.ESTAB
                    AND ITEMCOMPOS.ITEM = ITEMSALDOINI.ITEM

LEFT JOIN itemagro_u AGRO_U on AGRO_U.item = ITEMCOMPOS.ITEMMATERIAPRIMA

-- alterando agrupamento de prod
INNER JOIN u_agrprodgr ON u_agrprodgr.u_agrprodgr_id = --COALESCE(itemagro_u.u_agrprodgr_id,AGRO_U.u_agrprodgr_id) 
                                                        (case 
                                                            when AGRO_U.ITEM IN (40,41) THEN 1 
                                                            when AGRO_U.u_agrprodgr_id IS NULL THEN itemagro_u.u_agrprodgr_id
                                                            ELSE itemagro_u.u_agrprodgr_id END )

INNER JOIN FILIAL ON FILIAL.ESTAB = ITEMSALDOINI.ESTAB

LEFT JOIN CIDADE ON CIDADE.CIDADE = FILIAL.CIDADE

LEFT JOIN CIDADE CID ON CID.CIDADE = LOCALEST.CIDADE

LEFT JOIN microrregiao ON MICRORREGIAO.IDMICRORREGIAO = CID.IDMICRORREGIAO

LEFT JOIN MESORREGIAO ON MESORREGIAO.IDMESORREGIAO = MICRORREGIAO.IDMESORREGIAO

WHERE   u_agrprodgr.u_agrprodgr_id <=50
    AND u_tempresa.graos='S'
    AND ITEMSALDOINI.CODIGOSALDO = 2
    AND LOCALEST.LOCAL < 899
    

GROUP BY  ITEMSALDOINI.ESTAB,
      u_agrprodgr.u_agrprodgr_id, 
       ITEMSALDOINI.LOCAL, u_agrprodgr.descagrupa, FILIAL.REDUZIDO,CIDADE.NOME,CIDADE.UF, LOCALEST.DESCRICAO,MESORREGIAO.DESCRICAO,CID.NOME

UNION ALL

SELECT
       ITEMSALDOINI.ESTAB,
       u_agrprodgr.u_agrprodgr_id AS ITEM,      
       ITEMSALDOINI.LOCAL,
     LOCALEST.DESCRICAO AS DESCRICAO,
     --   CASE WHEN     ITEMSALDOINI.LOCAL=1 THEN      LOCALEST.DESCRICAO||'-'||  ITEMSALDOINI.LOCAL ELSE   LOCALEST.DESCRICAO END DESCRICAO,
       FILIAL.REDUZIDO,
       COALESCE(CIDADE.NOME,FILIAL.REDUZIDO) AS CIDADE,
       COALESCE(CIDADE.UF,'XX')UF,
        COALESCE(MESORREGIAO.DESCRICAO,CIDADE.NOME) AS MACROREG,
        COALESCE(CID.NOME,CIDADE.NOME)AS CIDLOCAL,
         u_agrprodgr.descagrupa as produto,
       0 SALDODFIS2,
        
  SUM(SALDOITEM(ITEMSALDOINI.ESTAB, ITEMSALDOINI.ITEM,4,
                 ITEMSALDOINI.LOCAL, ITEMSALDOINI.LOCAL, CURRENT_DATE, NULL, NULL, NULL)) SALDODFIS4,
                 0 SALDODFIS6,
                 0 SALDODFIS23,
                 0 SALDODFIS27,
                  0 SALDOFISAJ,
                  ''LATITUDE,
                  ''LONGITUDE
                           
FROM ITEMSALDOINI

INNER JOIN u_tempresa ON u_tempresa.estab=ITEMSALDOINI.ESTAB

INNER JOIN LOCALEST ON LOCALEST.LOCAL= ITEMSALDOINI.LOCAL
                   AND LOCALEST.LOCAL > 1
                   AND LOCALEST.ESTAB=ITEMSALDOINI.ESTAB

INNER JOIN ITEMAGRO ON ITEMAGRO.ITEM=ITEMSALDOINI.ITEM

INNER JOIN itemagro_u on itemagro_u.item = itemagro.item

-- Materia Prima
LEFT JOIN ITEMCOMPOS ON ITEMCOMPOS.ESTAB = ITEMSALDOINI.ESTAB
                    AND ITEMCOMPOS.ITEM = ITEMSALDOINI.ITEM

LEFT JOIN itemagro_u AGRO_U on AGRO_U.item = ITEMCOMPOS.ITEMMATERIAPRIMA

-- alterando agrupamento de prod
INNER JOIN u_agrprodgr ON u_agrprodgr.u_agrprodgr_id = --COALESCE(itemagro_u.u_agrprodgr_id,AGRO_U.u_agrprodgr_id) 
                                                        (case 
                                                            when AGRO_U.ITEM IN (40,41) THEN 1
                                                            when AGRO_U.u_agrprodgr_id IS NULL THEN itemagro_u.u_agrprodgr_id
                                                            ELSE itemagro_u.u_agrprodgr_id END )

INNER JOIN FILIAL ON FILIAL.ESTAB = ITEMSALDOINI.ESTAB

LEFT JOIN CIDADE ON CIDADE.CIDADE = FILIAL.CIDADE

LEFT JOIN CIDADE CID ON CID.CIDADE = LOCALEST.CIDADE

LEFT JOIN microrregiao ON MICRORREGIAO.IDMICRORREGIAO = CID.IDMICRORREGIAO

LEFT JOIN MESORREGIAO ON MESORREGIAO.IDMESORREGIAO = MICRORREGIAO.IDMESORREGIAO

WHERE  u_agrprodgr.u_agrprodgr_id <=50
    AND u_tempresa.graos='S'
    AND ITEMSALDOINI.CODIGOSALDO = 4
    AND LOCALEST.LOCAL < 899

GROUP BY  ITEMSALDOINI.ESTAB,
      u_agrprodgr.u_agrprodgr_id, 
       ITEMSALDOINI.LOCAL, u_agrprodgr.descagrupa, FILIAL.REDUZIDO,CIDADE.NOME,CIDADE.UF, LOCALEST.DESCRICAO,MESORREGIAO.DESCRICAO,CID.NOME

UNION ALL

SELECT
       ITEMSALDOINI.ESTAB,
      u_agrprodgr.u_agrprodgr_id AS ITEM,      
       ITEMSALDOINI.LOCAL,
      LOCALEST.DESCRICAO AS DESCRICAO,
      --  CASE WHEN     ITEMSALDOINI.LOCAL=1 THEN      LOCALEST.DESCRICAO||'-'||  ITEMSALDOINI.LOCAL ELSE   LOCALEST.DESCRICAO END DESCRICAO,
       FILIAL.REDUZIDO,
       COALESCE(CIDADE.NOME,FILIAL.REDUZIDO) AS CIDADE,
       COALESCE(CIDADE.UF,'XX')UF,
        COALESCE(MESORREGIAO.DESCRICAO,CIDADE.NOME) AS MACROREG,
        COALESCE(CID.NOME,CIDADE.NOME)AS CIDLOCAL,
         u_agrprodgr.descagrupa as produto,
       0 SALDODFIS2,
       0 SALDODFIS4,
        
  SUM(SALDOITEM(ITEMSALDOINI.ESTAB, ITEMSALDOINI.ITEM,6,
                 ITEMSALDOINI.LOCAL, ITEMSALDOINI.LOCAL, CURRENT_DATE, NULL, NULL, NULL)) SALDODFIS6,
                 0 SALDODFIS23,
                 0 SALDODFIS27,
                  0 SALDOFISAJ,
                  ''LATITUDE,
                  ''LONGITUDE
                           
FROM ITEMSALDOINI

INNER JOIN u_tempresa ON u_tempresa.estab=ITEMSALDOINI.ESTAB

INNER JOIN LOCALEST ON LOCALEST.LOCAL= ITEMSALDOINI.LOCAL
                   AND LOCALEST.LOCAL > 1
                   AND LOCALEST.ESTAB=ITEMSALDOINI.ESTAB

INNER JOIN ITEMAGRO ON ITEMAGRO.ITEM=ITEMSALDOINI.ITEM

INNER JOIN itemagro_u on itemagro_u.item = itemagro.item

-- Materia Prima
LEFT JOIN ITEMCOMPOS ON ITEMCOMPOS.ESTAB = ITEMSALDOINI.ESTAB
                    AND ITEMCOMPOS.ITEM = ITEMSALDOINI.ITEM

LEFT JOIN itemagro_u AGRO_U on AGRO_U.item = ITEMCOMPOS.ITEMMATERIAPRIMA

-- alterando agrupamento de prod
INNER JOIN u_agrprodgr ON u_agrprodgr.u_agrprodgr_id = --COALESCE(itemagro_u.u_agrprodgr_id,AGRO_U.u_agrprodgr_id) 
                                                        (case 
                                                            when AGRO_U.ITEM IN (40,41) THEN 1
                                                            when AGRO_U.u_agrprodgr_id IS NULL THEN itemagro_u.u_agrprodgr_id
                                                            ELSE itemagro_u.u_agrprodgr_id END )

INNER JOIN FILIAL ON FILIAL.ESTAB = ITEMSALDOINI.ESTAB

LEFT JOIN CIDADE ON CIDADE.CIDADE = FILIAL.CIDADE

LEFT JOIN CIDADE CID ON CID.CIDADE = LOCALEST.CIDADE

LEFT JOIN microrregiao ON MICRORREGIAO.IDMICRORREGIAO = CID.IDMICRORREGIAO

LEFT JOIN MESORREGIAO ON MESORREGIAO.IDMESORREGIAO = MICRORREGIAO.IDMESORREGIAO

WHERE u_agrprodgr.u_agrprodgr_id <=50
    AND u_tempresa.graos='S'
    AND ITEMSALDOINI.CODIGOSALDO = 6
    AND LOCALEST.LOCAL < 899

GROUP BY  ITEMSALDOINI.ESTAB,
      u_agrprodgr.u_agrprodgr_id, 
       ITEMSALDOINI.LOCAL, u_agrprodgr.descagrupa, FILIAL.REDUZIDO,CIDADE.NOME,CIDADE.UF, LOCALEST.DESCRICAO,MESORREGIAO.DESCRICAO,CID.NOME



UNION ALL

SELECT
       ITEMSALDOINI.ESTAB,
       u_agrprodgr.u_agrprodgr_id AS ITEM,      
       ITEMSALDOINI.LOCAL,
       LOCALEST.DESCRICAO AS DESCRICAO,
       --  CASE WHEN     ITEMSALDOINI.LOCAL=1 THEN      LOCALEST.DESCRICAO||'-'||  ITEMSALDOINI.LOCAL ELSE   LOCALEST.DESCRICAO END DESCRICAO,
       FILIAL.REDUZIDO,
       COALESCE(CIDADE.NOME,FILIAL.REDUZIDO) AS CIDADE,
       COALESCE(CIDADE.UF,'XX')UF,
        COALESCE(MESORREGIAO.DESCRICAO,CIDADE.NOME) AS MACROREG,
        COALESCE(CID.NOME,CIDADE.NOME)AS CIDLOCAL,
         u_agrprodgr.descagrupa as produto,
         0 SALDODFIS2,
         0 SALDODFIS4,
         0 SALDODFIS6,
  SUM(SALDOITEM(ITEMSALDOINI.ESTAB, ITEMSALDOINI.ITEM,23,
                 ITEMSALDOINI.LOCAL, ITEMSALDOINI.LOCAL, CURRENT_DATE, NULL, NULL, NULL)) SALDODFIS23,
                                  0 SALDODFIS27,
                                   0 SALDOFISAJ,
                                   ''LATITUDE,
                                   ''LONGITUDE
                           
FROM ITEMSALDOINI

INNER JOIN u_tempresa ON u_tempresa.estab=ITEMSALDOINI.ESTAB

INNER JOIN LOCALEST ON LOCALEST.LOCAL= ITEMSALDOINI.LOCAL
                   AND LOCALEST.LOCAL > 1
                   AND LOCALEST.ESTAB=ITEMSALDOINI.ESTAB

INNER JOIN ITEMAGRO ON ITEMAGRO.ITEM=ITEMSALDOINI.ITEM

INNER JOIN itemagro_u on itemagro_u.item = itemagro.item

-- Materia Prima
LEFT JOIN ITEMCOMPOS ON ITEMCOMPOS.ESTAB = ITEMSALDOINI.ESTAB
                    AND ITEMCOMPOS.ITEM = ITEMSALDOINI.ITEM

LEFT JOIN itemagro_u AGRO_U on AGRO_U.item = ITEMCOMPOS.ITEMMATERIAPRIMA

-- alterando agrupamento de prod
INNER JOIN u_agrprodgr ON u_agrprodgr.u_agrprodgr_id = --COALESCE(itemagro_u.u_agrprodgr_id,AGRO_U.u_agrprodgr_id) 
                                                        (case 
                                                            when AGRO_U.ITEM IN (40,41) THEN 1 
                                                            when AGRO_U.u_agrprodgr_id IS NULL THEN itemagro_u.u_agrprodgr_id
                                                            ELSE itemagro_u.u_agrprodgr_id END )

INNER JOIN FILIAL ON FILIAL.ESTAB = ITEMSALDOINI.ESTAB

LEFT JOIN CIDADE ON CIDADE.CIDADE = FILIAL.CIDADE

LEFT JOIN CIDADE CID ON CID.CIDADE = LOCALEST.CIDADE

LEFT JOIN microrregiao ON MICRORREGIAO.IDMICRORREGIAO = CID.IDMICRORREGIAO

LEFT JOIN MESORREGIAO ON MESORREGIAO.IDMESORREGIAO = MICRORREGIAO.IDMESORREGIAO

WHERE u_agrprodgr.u_agrprodgr_id <=50
    AND u_tempresa.graos='S'
    AND ITEMSALDOINI.CODIGOSALDO = 23
    AND LOCALEST.LOCAL < 899

GROUP BY  ITEMSALDOINI.ESTAB,
      u_agrprodgr.u_agrprodgr_id, 
      ITEMSALDOINI.LOCAL, u_agrprodgr.descagrupa, FILIAL.REDUZIDO,CIDADE.NOME,CIDADE.UF, LOCALEST.DESCRICAO,MESORREGIAO.DESCRICAO,CID.NOME

UNION ALL

SELECT
       ITEMSALDOINI.ESTAB,
       u_agrprodgr.u_agrprodgr_id AS ITEM,      
       ITEMSALDOINI.LOCAL,
        LOCALEST.DESCRICAO AS DESCRICAO,
       --   CASE WHEN     ITEMSALDOINI.LOCAL=1 THEN      LOCALEST.DESCRICAO||'-'||  ITEMSALDOINI.LOCAL ELSE   LOCALEST.DESCRICAO END DESCRICAO,
       FILIAL.REDUZIDO,
       COALESCE(CIDADE.NOME,FILIAL.REDUZIDO) AS CIDADE,
       COALESCE(CIDADE.UF,'XX')UF,
        COALESCE(MESORREGIAO.DESCRICAO,CIDADE.NOME) AS MACROREG,
        COALESCE(CID.NOME,CIDADE.NOME)AS CIDLOCAL,
        u_agrprodgr.descagrupa as produto,
         0 SALDODFIS2,
         0 SALDODFIS4,
          0 SALDODFIS23,
          0 SALDODFIS6,
  SUM(SALDOITEM(ITEMSALDOINI.ESTAB, ITEMSALDOINI.ITEM,27,
                 ITEMSALDOINI.LOCAL, ITEMSALDOINI.LOCAL, CURRENT_DATE, NULL, NULL, NULL)) SALDODFIS27,
                 0 SALDOFISAJ,
                 ''LATITUDE,
                 ''LONGITUDE
                           
FROM ITEMSALDOINI

INNER JOIN u_tempresa ON u_tempresa.estab=ITEMSALDOINI.ESTAB

INNER JOIN LOCALEST ON LOCALEST.LOCAL= ITEMSALDOINI.LOCAL
                   AND LOCALEST.LOCAL > 1
                   AND LOCALEST.ESTAB=ITEMSALDOINI.ESTAB

INNER JOIN ITEMAGRO ON ITEMAGRO.ITEM=ITEMSALDOINI.ITEM

INNER JOIN itemagro_u on itemagro_u.item = itemagro.item

-- Materia Prima
LEFT JOIN ITEMCOMPOS ON ITEMCOMPOS.ESTAB = ITEMSALDOINI.ESTAB
                    AND ITEMCOMPOS.ITEM = ITEMSALDOINI.ITEM

LEFT JOIN itemagro_u AGRO_U on AGRO_U.item = ITEMCOMPOS.ITEMMATERIAPRIMA

-- alterando agrupamento de prod
INNER JOIN u_agrprodgr ON u_agrprodgr.u_agrprodgr_id = --COALESCE(itemagro_u.u_agrprodgr_id,AGRO_U.u_agrprodgr_id) 
                                                        (case 
                                                            when AGRO_U.ITEM IN (40,41) THEN 1 
                                                            when AGRO_U.u_agrprodgr_id IS NULL THEN itemagro_u.u_agrprodgr_id
                                                            ELSE itemagro_u.u_agrprodgr_id END )

INNER JOIN FILIAL ON FILIAL.ESTAB = ITEMSALDOINI.ESTAB

LEFT JOIN CIDADE ON CIDADE.CIDADE = FILIAL.CIDADE

LEFT JOIN CIDADE CID ON CID.CIDADE = LOCALEST.CIDADE

LEFT JOIN microrregiao ON MICRORREGIAO.IDMICRORREGIAO = CID.IDMICRORREGIAO

LEFT JOIN MESORREGIAO ON MESORREGIAO.IDMESORREGIAO = MICRORREGIAO.IDMESORREGIAO

WHERE  u_agrprodgr.u_agrprodgr_id <=50
    AND u_tempresa.graos='S'
    AND ITEMSALDOINI.CODIGOSALDO = 27
    AND LOCALEST.LOCAL < 899

GROUP BY  ITEMSALDOINI.ESTAB,
      u_agrprodgr.u_agrprodgr_id, 
      ITEMSALDOINI.LOCAL, u_agrprodgr.descagrupa, FILIAL.REDUZIDO,CIDADE.NOME,CIDADE.UF, LOCALEST.DESCRICAO,MESORREGIAO.DESCRICAO,CID.NOME
      
 union all
 
 select 
 u_ajlocalest.estab,
 u_agrprodgr.u_agrprodgr_id AS ITEM,
  u_ajlocalest.local,
 LOCALEST.DESCRICAO AS DESCRICAO,
 -- CASE WHEN  u_ajlocalest.local=1 THEN LOCALEST.DESCRICAO||'-'|| u_ajlocalest.local ELSE LOCALEST.DESCRICAO END DESCRICAO,
           --     LOCALEST.DESCRICAO,
       FILIAL.REDUZIDO,
       COALESCE(CIDADE.NOME,FILIAL.REDUZIDO) AS CIDADE,
       COALESCE(CIDADE.UF,'XX')UF,
        COALESCE(MESORREGIAO.DESCRICAO,CIDADE.NOME) AS MACROREG,
        COALESCE(CID.NOME,CIDADE.NOME)AS CIDLOCAL,
    u_agrprodgr.descagrupa as produto,
    
   0 SALDODFIS2,
         0 SALDODFIS4,
          0 SALDODFIS23,
          0 SALDODFIS6,
          0 SALDODFIS27,
 
 quantidade*-1 SALDOFISAJ,
  ''LATITUDE,
  ''LONGITUDE
       from u_ajlocalest
       
INNER JOIN u_agrprodgr ON u_agrprodgr.u_agrprodgr_id=u_ajlocalest.u_agrprodgr_id

INNER JOIN LOCALEST ON LOCALEST.LOCAL= u_ajlocalest.LOCAL
                   AND LOCALEST.ESTAB=u_ajlocalest.ESTAB

INNER JOIN FILIAL ON FILIAL.ESTAB =  u_ajlocalest.ESTAB             

LEFT JOIN CIDADE ON CIDADE.CIDADE = FILIAL.CIDADE  

LEFT JOIN CIDADE CID ON CID.CIDADE = LOCALEST.CIDADE

LEFT JOIN microrregiao ON MICRORREGIAO.IDMICRORREGIAO = CID.IDMICRORREGIAO

LEFT JOIN MESORREGIAO ON MESORREGIAO.IDMESORREGIAO = MICRORREGIAO.IDMESORREGIAO

where datamov >= current_date AND  u_ajlocalest.local> 1
AND  u_ajlocalest.local < 899
      
      )DADOS
      
      INNER JOIN LOCALEST_U ON LOCALEST_U.ESTAB=DADOS.ESTAB
                     AND LOCALEST_U.LOCAL=DADOS.LOCAL
                     AND LOCALEST_U.LOCAL > 1
                   --  AND LOCALEST_U.LOCFILIAL <> 'S'  

      WHERE (DADOS.DESCRICAO not like '%OURO SAFRA%')
      AND DADOS.LOCAL < 899


GROUP BY DADOS.ESTAB,
       DADOS.ITEM,
       DADOS.LOCAL,DADOS.produto,DADOS.DESCRICAO,DADOS.REDUZIDO,DADOS.CIDADE,DADOS.UF,DADOS.MACROREG,DADOS.CIDLOCAL



       )DADOS
       
       
       
    
WHERE dados.uf in (:UF) 
 AND DADOS.OSPRODUTO IN (:ITEM)
    
    GROUP BY  DADOS.OSESTAB,
         DADOS.OSPRODUTO,
        DADOS.OSLOCAL,
        DADOS.DESCRICAO,
        DADOS.REDUZIDO,
        DADOS.CIDADE,DADOS.UF,dados.produto,DADOS.LOCAL,DADOS.MACROREG,DADOS.CIDLOCAL,DADOS.LATITUDE,
                DADOS.LONGITUDE
        
     
 /*HAVING  --SUM(DADOS.SALDO_COMP)+SUM(DADOS.QTDSALDORET)  <> 0
        --OR SUM(DADOS.SALDOFIS) <> 0
 SUM(DADOS.SALDO_COMP) >= 0
 AND (
    --OR 
    SUM(DADOS.SALDO_COMP)+SUM(DADOS.QTDSALDORET)  <> 0
        OR SUM(DADOS.SALDOFIS) <> 0)*/
 HAVING
 SUM(DADOS.SALDO_COMP) <> 0
 OR SUM(DADOS.QTDSALDORET)  <> 0
   OR SUM(DADOS.SALDO_EXPORT)  <> 0
        
 ORDER BY DADOS.OSPRODUTO,DADOS.MACROREG,DADOS.CIDLOCAL
 
 )DADOS1
 
  LEFT JOIN FILIAL ON DADOS1.OSESTAB = FILIAL.ESTAB
  
  LEFT JOIN
  (
                select 
                  --ORDEMCARGACAB.config,
                  --  ORDEMCARGACAB.idcarga,
                 --   contamov.nome as cliente,
                 FILIAL.REDUZIDO|| ' - ' ||FILIAL.ESTAB AS FILIAL,
                    ordemcargafrete.localestoque,
                   localest.descricao as local,
                    
                   ( 
                   coalesce((sum((SELECT count(veiculos.placa)qtdp FROM ORDEMCARGACAB ORDEMCARGACAB1
                    inner join ORDEMCARGAFRETE ON ORDEMCARGACAB1.ESTAB = ORDEMCARGAFRETE.ESTAB
                                    AND ORDEMCARGACAB1.IDCARGA=ORDEMCARGAFRETE.IDCARGA
             
            left join ordemcargatransp on ordemcargatransp.idcarga=ordemcargaCAB1.idcarga
            
            left join veiculos on veiculos.placa=ordemcargatransp.placa
                                AND veiculos.estabveiculo BETWEEN 1 AND 100
                                
                                 WHERE ORDEMCARGACAB1.ESTAB=ORDEMCARGACAB.ESTAB
                                    AND ORDEMCARGACAB1.IDCARGA=ORDEMCARGACAB.IDCARGA
                                    AND ORDEMCARGACAB1.CONFIG=ORDEMCARGACAB1.CONFIG
                                 and ORDEMCARGACAB1.statuscarreg = 1))),0)
                                    +
            coalesce((sum((SELECT count(ordemcargatransp.placa)qtdp FROM ORDEMCARGACAB ORDEMCARGACAB1
                    inner join ORDEMCARGAFRETE ON ORDEMCARGACAB1.ESTAB = ORDEMCARGAFRETE.ESTAB
                                    AND ORDEMCARGACAB1.IDCARGA=ORDEMCARGAFRETE.IDCARGA
             
            INNER join ordemcargatransp on ordemcargatransp.idcarga=ordemcargaCAB1.idcarga
                                        AND ordemcargatransp.PRESTADOR > 100
            
                                
                                 WHERE ORDEMCARGACAB1.ESTAB=ORDEMCARGACAB.ESTAB
                                    AND ORDEMCARGACAB1.IDCARGA=ORDEMCARGACAB.IDCARGA
                                    AND ORDEMCARGACAB1.CONFIG=ORDEMCARGACAB1.CONFIG
                           and ORDEMCARGACAB1.statuscarreg = 1
                          ))),0)
            
                   )qtd_ordem,
                    --ordemcargacab.descricao,
                    --TO_CHAR(ordemcargafrete.dtvalidade,'DD/MM/YYYY')dtvalidade,
                    ordemcargafrete.item,  
                    ORDEMCARGACAB.estab
                  
                    --ordemcargafrete.localcarregamento,
                  --  SUM(ordemcargafrete.pesoliquido) QTDPREVISTA,
                    
                    /*coalesce((SUM((SELECT SUM(nfitem.quantidade)QUANTIDADE  FROM ORDEMCARGACAB ORDEMCARGACAB1
                    
                                    left join ORDEMCARGADOC ON ORDEMCARGACAB1.ESTAB = ORDEMCARGADOC.ESTABNOTA
                                    AND ORDEMCARGACAB1.IDCARGA=ORDEMCARGADOC.IDCARGA
            
                                    left JOIN ORDEMCARGAITEM
                                    ON (ORDEMCARGADOC.IDDOC = ORDEMCARGAITEM.IDDOC)    
             
                                    left JOIN NFITEM
                                     ON (NFITEM.ESTAB       = ORDEMCARGAITEM.ESTABNOTA)
                                   AND (NFITEM.SEQNOTA     = ORDEMCARGAITEM.SEQNOTA)
                                  AND (NFITEM.SEQNOTAITEM = ORDEMCARGAITEM.SEQITEMNOTA)   
            
                                    left JOIN NFCAB
                                    ON (NFCAB.ESTAB   = NFITEM.ESTAB)
                                    AND (NFCAB.SEQNOTA = NFITEM.SEQNOTA)
                                    
                                    WHERE ORDEMCARGACAB1.ESTAB=ORDEMCARGACAB.ESTAB
                                    AND ORDEMCARGACAB1.IDCARGA=ORDEMCARGACAB.IDCARGA
                                    AND ORDEMCARGACAB1.CONFIG=ORDEMCARGACAB1.CONFIG
                                    ))),0)QTDCARREGADA*/
                   
            FROM ORDEMCARGACAB
            
            inner join ORDEMCARGAFRETE ON ORDEMCARGACAB.ESTAB = ORDEMCARGAFRETE.ESTAB
                                    AND ORDEMCARGACAB.IDCARGA=ORDEMCARGAFRETE.IDCARGA
             
            left join ordemcargatransp on ordemcargatransp.idcarga=ordemcargaCAB.idcarga
            
            left join veiculos on veiculos.placa=ordemcargatransp.placa
            
            LEFT JOIN localest on localest.estab=ORDEMCARGACAB.ESTAB
                                and localest.local= ordemcargafrete.localestoque
                                
            -- left join contamov on contamov.numerocm = coalesce(ordemcargafrete.localdescarga,ordemcargafrete.localcarregamento)                   
                                
            left join filial on filial.estab = ORDEMCARGACAB.estab
            where ordemcargafrete.dtvalidade BETWEEN :DTINI AND :DTFIM
             and ORDEMCARGACAB.config in (2,3)
             and ordemcargafrete.dtvalidade is not null
            --AND ORDEMCARGACAB.ESTAB = 30
            
            GROUP BY  --ORDEMCARGACAB.config,
                  --  ORDEMCARGACAB.idcarga,
                    ordemcargafrete.localestoque,
                    localest.descricao,
                   --veiculos.estabveiculo,        
                    ordemcargafrete.item,  
                    ORDEMCARGACAB.estab,FILIAL.REDUZIDO,FILIAL.ESTAB
        )ordem on
        ordem.estab = DADOS1.osestab AND
        ordem.local = dados1.desc_local AND 
        ordem.item = dados1.OSPRODUTO
  
 GROUP BY
 FILIAL.REDUZIDO,
 DADOS1.OSESTAB,
 DADOS1.OSPRODUTO,
DADOS1.PRODUTO,
DADOS1.DESC_LOCAL,
--DADOS1.CIDADE,
DADOS1.UF,
DADOS1.MACROREG,
DADOS1.CIDLOCAL,
DADOS1.LATITUDE,
DADOS1.LONGITUDE

ORDER BY  DADOS1.OSPRODUTO,DADOS1.MACROREG,DADOS1.DESC_LOCAL
