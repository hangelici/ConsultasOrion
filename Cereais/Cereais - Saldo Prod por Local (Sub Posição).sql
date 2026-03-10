SELECT  DADOS3.TIPO,
        DADOS3.ESTAB,
        DADOS3.ESTADO,
        DADOS3.DESCESTAB,
        DADOS3.ITEM,
       DADOS3.DESCITEM,
       DADOS3.LOCAL,
       DADOS3.DESCLOCAL,
     SUM(DADOS3.SALDOEMP)SALDOEMP,
     SUM(DADOS3.SALDOCAMPO)SALDOCAMP,
     SUM(DADOS3.SALDODISP)SALDODIP,
      SUM(DADOS3.SALDOFIS)SALDOFIS,
      SUM(DADOS3.SALDOPROD)SALDOPROD
FROM(
select DADOS2.TIPO,
        DADOS2.ESTAB,
        DADOS2.ESTADO,
        DADOS2.DESCESTAB,
        DADOS2.ITEM,
       DADOS2.DESCITEM,
       DADOS2.LOCAL,
       DADOS2.DESCLOCAL,
     SUM((DADOS2.SALDODISP)-(DADOS2.QTDSALDO))SALDOEMP,
     SUM((DADOS2.QTDSALDO))SALDOCAMPO,
     SUM((DADOS2.SALDODISP))SALDODISP,
      SUM((DADOS2.SALDOFIS)+(DADOS2.SALDOROMA))SALDOFIS,
      SUM((DADOS2.SALDOROMA)+(DADOS2.DEPOSTOPROD))SALDOPROD


from (
SELECT 'O'as TIPO,
        DADOS.ESTAB,
      CASE WHEN CIDADE.UF='SP' AND DADOS.ESTAB = 5 THEN 'SP - VJ'
                WHEN DADOS.ESTAB = 79 THEN 'TR'
        ELSE CIDADE.UF END AS ESTADO,

        FILIAL.REDUZIDO AS DESCESTAB,
       case WHEN DADOS.ITEM=40 then 1 else DADOS.ITEM end  ITEM,
       DADOS.ITEM||'-'||itemagro.descricao as DESCITEM,
       DADOS.LOCAL,
       DADOS.LOCAL||'-'||LOCALEST.DESCRICAO AS DESCLOCAL,
       SUM((DADOS.SALDODISP)/60)SALDODISP,
       SUM((DADOS.SALDOFIS)/60)SALDOFIS,
       SUM((DADOS.DEPOSTOPROD)/60)DEPOSTOPROD,
       SUM((DADOS.QTDSALDO)/60)QTDSALDO,
       SUM((DADOS.QTDSALDOCF)/60)QTDSALDOCF,
       SUM((DADOS.QTDSALDOVD)/60)QTDSALDOVD,
       SUM((DADOS.QTDSALDOVF)/60)QTDSALDOVF,
       SUM((DADOS.SALDOROMA)/60)SALDOROMA


FROM (

SELECT BI_SALDOCEREAISDISP.* FROM BI_SALDOCEREAISDISP
inner join filial on filial.estab = BI_SALDOCEREAISDISP.estab
inner join cidade on cidade.cidade  = filial.cidade
where
BI_SALDOCEREAISDISP.item = $P{ITEM}
AND CIDADE.UF = $P{UF}
and (filial.estab = $P{ESTAB} or 0 = $P{ESTAB} ) and filial.estab <> 800


UNION ALL

SELECT BI_SALDOCEREAISFIS.* FROM  BI_SALDOCEREAISFIS
inner join filial on filial.estab = BI_SALDOCEREAISFIS.estab
inner join cidade on cidade.cidade  = filial.cidade
where
BI_SALDOCEREAISFIS.item = $P{ITEM}
AND CIDADE.UF = $P{UF}
and (filial.estab = $P{ESTAB} or 0 = $P{ESTAB} ) and filial.estab <> 800

UNION ALL

SELECT bi_saldodeposito.* FROM bi_saldodeposito
inner join filial on filial.estab = bi_saldodeposito.estab
inner join cidade on cidade.cidade  = filial.cidade
where
bi_saldodeposito.item = $P{ITEM}
AND CIDADE.UF = $P{UF}
and (filial.estab = $P{ESTAB} or 0 = $P{ESTAB} ) and filial.estab <> 800

UNION ALL

SELECT
       CONTRATO.ESTAB,
       u_agrprodgr.u_agrprodgr_id AS ITEM,
       localest.local,
       0 AS "SALDODISP",
       0 AS SALDOFIS,
        0 DEPOSTOPROD,
       sum(CAST(COALESCE(PSALDO.NQTDSALDO,0)AS DECIMAL(18,2))) AS QTDSALDO,
       0 QTDSALDOCF,
       0 QTDSALDOVD,
       0 QTDSALDOVF,
       0 SALDOROMA,
       0 SALDOFIXAR,
       0 PEDIDO,
       0 SALDOVF


FROM CONTRATO
      LEFT OUTER JOIN FILIAL ON
     (FILIAL.ESTAB = CONTRATO.ESTAB)

     INNER JOIN u_tempresa ON u_tempresa.estab=FILIAL.ESTAB

      LEFT OUTER JOIN CONTAMOV ON
     (CONTAMOV.NUMEROCM = CONTRATO.NUMEROCM)

      LEFT OUTER JOIN CONTRATOCFG ON
     (CONTRATOCFG.CONTCONF = CONTRATO.CONTCONF)

      LEFT OUTER JOIN CONTRATOITE ON
     (CONTRATOITE.ESTAB = CONTRATO.ESTAB)
      AND (CONTRATOITE.CONTRATO = CONTRATO.CONTRATO)

        INNER JOIN ITEMAGRO ON ITEMAGRO.ITEM=CONTRATOITE.ITEM

      INNER JOIN itemagro_u on itemagro_u.item = itemagro.item

    INNER JOIN u_agrprodgr ON u_agrprodgr.u_agrprodgr_id=itemagro_u.u_agrprodgr_id

      LEFT JOIN localest on localest.estab = contratoite.estab
                        and localest.local = contratoite.local
                        
        inner join cidade on cidade.cidade = filial.cidade

    LEFT JOIN TABLE (PCONTRATOSALDO( CONTRATO.ESTAB,
                 CURRENT_DATE, CONTRATO.CONTRATO, CONTRATO.CONTRATO,
                 CONTRATOITE.SEQITEM, CONTRATOITE.SEQITEM, NULL, NULL, NULL,
                 NULL, NULL)) PSALDO
    ON (0=0)

    INNER JOIN CONTRATOCFG_U ON CONTRATOCFG_U.CONTCONF = CONTRATO.CONTCONF
    LEFT JOIN U_TIPOCTR ON u_tipoctr.u_tipoctr_id = contratocfg_u.u_tipoctr_id
where u_tempresa.graos='S'
and u_tipoctr.u_tipoctr_id in (2,7,12)
--and contrato.contconf in (1,2,6,50) 
and PSALDO.NQTDSALDO > 0
AND contrato.dtmovsaldo <= last_day(current_date)
 and u_agrprodgr.u_agrprodgr_id = $P{ITEM}
AND CIDADE.UF = $P{UF}
and (filial.estab = $P{ESTAB} or 0 = $P{ESTAB} ) and filial.estab <> 800

group by  CONTRATO.ESTAB,
       u_agrprodgr.u_agrprodgr_id,
       localest.local

UNION ALL
----------------------------------------------------------------------------------------
select   dados.ESTAB,
         dados.ITEM,
         dados.local,
         sum(dados.SALDODISP)SALDODISP,
         sum(dados.SALDOFIS)SALDOFIS,
         sum(dados.DEPOSTOPROD)DEPOSTOPROD,
         sum(dados.QTDSALDO)QTDSALDO,
         sum(dados.QTDSALDOCF)QTDSALDOCF,
         sum(dados.QTDSALDOVD)QTDSALDOVD,
         sum(dados.QTDSALDOVF)QTDSALDOVF,
         sum(dados.SALDOROMA)SALDOROMA,
         sum(dados.SALDOFIXAR)SALDOFIXAR,
         0 PEDIDO,
         0 SALDOVF


from(

SELECT
       CONTRATO.ESTAB,
        u_agrprodgr.u_agrprodgr_id AS ITEM,
       localest.local,
       0 AS "SALDODISP",
       0 AS SALDOFIS,
       0 DEPOSTOPROD,
        0 AS QTDSALDO,
      sum(CAST(COALESCE(PSALDO.NQTDSALDO,0)AS DECIMAL(18,2))) AS QTDSALDOCF,
       0 QTDSALDOVD,
       0 QTDSALDOVF,
       0 SALDOROMA,
       0 SALDOFIXAR,
       0 PEDIDO,
       0 SALDOVF


FROM CONTRATO
      LEFT OUTER JOIN FILIAL ON
     (FILIAL.ESTAB = CONTRATO.ESTAB)

     INNER JOIN u_tempresa ON u_tempresa.estab=FILIAL.ESTAB

      LEFT OUTER JOIN CONTAMOV ON
     (CONTAMOV.NUMEROCM = CONTRATO.NUMEROCM)

      LEFT OUTER JOIN CONTRATOCFG ON
     (CONTRATOCFG.CONTCONF = CONTRATO.CONTCONF)

      LEFT OUTER JOIN CONTRATOITE ON
     (CONTRATOITE.ESTAB = CONTRATO.ESTAB)
      AND (CONTRATOITE.CONTRATO = CONTRATO.CONTRATO)

         INNER JOIN ITEMAGRO ON ITEMAGRO.ITEM=CONTRATOITE.ITEM

      INNER JOIN itemagro_u on itemagro_u.item = itemagro.item

    INNER JOIN u_agrprodgr ON u_agrprodgr.u_agrprodgr_id=itemagro_u.u_agrprodgr_id

      LEFT JOIN localest on localest.estab = contratoite.estab
                        and localest.local = contratoite.local

    LEFT JOIN TABLE (PCONTRATOSALDO( CONTRATO.ESTAB,
                 CURRENT_DATE, CONTRATO.CONTRATO, CONTRATO.CONTRATO,
                 CONTRATOITE.SEQITEM, CONTRATOITE.SEQITEM, NULL, NULL, NULL,
                 NULL, NULL)) PSALDO
    ON (0=0)
 inner join cidade on cidade.cidade = filial.cidade
     INNER JOIN CONTRATOCFG_U ON CONTRATOCFG_U.CONTCONF = CONTRATO.CONTCONF
    LEFT JOIN U_TIPOCTR ON u_tipoctr.u_tipoctr_id = contratocfg_u.u_tipoctr_id

where  u_tempresa.ESTAB=12
and u_tipoctr.u_tipoctr_id in (2,7,12)--and contrato.contconf in (1,2,6,50)
 and PSALDO.NQTDSALDO > 0
and contrato.dtmovsaldo > last_day(current_date)
 and u_agrprodgr.u_agrprodgr_id = $P{ITEM}
AND CIDADE.UF = $P{UF}
and (filial.estab = $P{ESTAB} or 0 = $P{ESTAB} ) and filial.estab <> 800

group by  CONTRATO.ESTAB,
        u_agrprodgr.u_agrprodgr_id,
       localest.local

union all

select u_ajlocalest.estab,
u_ajlocalest.u_agrprodgr_id,
u_ajlocalest.local,
0 saldodisp, 0 SALDOFIS,
                  0 DEPOSTOPROD,
       0 QTDSALDO,
       quantidade QTDSALDOCF,
       0 QTDSALDOVD,
       0 QTDSALDOVF,
       0 SALDOROMA,
  0 SALDOFIXAR,
  0 PEDIDO,
  0 SALDOVF
 from u_ajlocalest
 
 inner join filial on filial.estab = u_ajlocalest.estab
 inner join cidade on cidade.cidade = filial.cidade
where datamov >= last_day(current_date)
 and u_ajlocalest.u_agrprodgr_id = $P{ITEM}
AND CIDADE.UF = $P{UF}
and (filial.estab = $P{ESTAB} or 0 = $P{ESTAB} ) and filial.estab <> 800

)dados

group by  dados.ESTAB,
         dados.ITEM,
         dados.local


---------------------------------------------------------------------------------------------------------------
union all

SELECT
       CONTRATO.ESTAB,
        u_agrprodgr.u_agrprodgr_id AS ITEM,
       localest.local,
        0 AS SALDOFIS,
       0 as "SALDODISP",

       0 DEPOSTOPROD,
          0 AS QTDSALDO,
       0 AS  QTDSALDOCF,

        sum(CAST(COALESCE(PSALDO.NQTDSALDO,0)AS DECIMAL(18,2))) QTDSALDOVD,
       0 QTDSALDOVF,
       0 SALDOROMA,
       0 SALDOFIXAR,
       0 PEDIDO,
       0 SALDOVF




FROM CONTRATO
      LEFT OUTER JOIN FILIAL ON
     (FILIAL.ESTAB = CONTRATO.ESTAB)

     INNER JOIN u_tempresa ON u_tempresa.estab=FILIAL.ESTAB

      LEFT OUTER JOIN CONTAMOV ON
     (CONTAMOV.NUMEROCM = CONTRATO.NUMEROCM)

      LEFT OUTER JOIN CONTRATOCFG ON
     (CONTRATOCFG.CONTCONF = CONTRATO.CONTCONF)

      LEFT OUTER JOIN CONTRATOITE ON
     (CONTRATOITE.ESTAB = CONTRATO.ESTAB)
      AND (CONTRATOITE.CONTRATO = CONTRATO.CONTRATO)

       INNER JOIN ITEMAGRO ON ITEMAGRO.ITEM=CONTRATOITE.ITEM

      INNER JOIN itemagro_u on itemagro_u.item = itemagro.item

    INNER JOIN u_agrprodgr ON u_agrprodgr.u_agrprodgr_id=itemagro_u.u_agrprodgr_id

      LEFT JOIN localest on localest.estab = contratoite.estab
                        and localest.local = contratoite.local

    LEFT JOIN TABLE (PCONTRATOSALDO( CONTRATO.ESTAB,
                 CURRENT_DATE, CONTRATO.CONTRATO, CONTRATO.CONTRATO,
                 CONTRATOITE.SEQITEM, CONTRATOITE.SEQITEM, NULL, NULL, NULL,
                 NULL, NULL)) PSALDO
    ON (0=0)

 inner join cidade on cidade.cidade = filial.cidade
      INNER JOIN CONTRATOCFG_U ON CONTRATOCFG_U.CONTCONF = CONTRATO.CONTCONF
    LEFT JOIN U_TIPOCTR ON u_tipoctr.u_tipoctr_id = contratocfg_u.u_tipoctr_id
where u_tempresa.graos='S'
and u_tipoctr.u_tipoctr_id in (1,3,6,8,13) --and contrato.contconf in (20,21,22,23,24,51) 
and PSALDO.NQTDSALDO > 0
AND contrato.dtmovsaldo <= last_day(current_date)
 and u_agrprodgr.u_agrprodgr_id = $P{ITEM}
AND CIDADE.UF = $P{UF}
and (filial.estab = $P{ESTAB} or 0 = $P{ESTAB} ) and filial.estab <> 800


group by  CONTRATO.ESTAB,
       u_agrprodgr.u_agrprodgr_id,
       localest.local


union all

SELECT
       CONTRATO.ESTAB,
        u_agrprodgr.u_agrprodgr_id AS ITEM,
      localest.local,
        0 AS SALDOFIS,
       0 as "SALDODISP",

        0 DEPOSTOPROD,
          0 AS QTDSALDO,
       0 AS  QTDSALDOCF,
       0 QTDSALDOVD,
       sum(CAST(COALESCE(PSALDO.NQTDSALDO,0)AS DECIMAL(18,2))) QTDSALDOVF,
       0 SALDOROMA,
        0 SALDOFIXAR,
        0 PEDIDO,
        0 SALDOVF


FROM CONTRATO
      LEFT OUTER JOIN FILIAL ON
     (FILIAL.ESTAB = CONTRATO.ESTAB)

     INNER JOIN u_tempresa ON u_tempresa.estab=FILIAL.ESTAB

      LEFT OUTER JOIN CONTAMOV ON
     (CONTAMOV.NUMEROCM = CONTRATO.NUMEROCM)

      LEFT OUTER JOIN CONTRATOCFG ON
     (CONTRATOCFG.CONTCONF = CONTRATO.CONTCONF)

      LEFT OUTER JOIN CONTRATOITE ON
     (CONTRATOITE.ESTAB = CONTRATO.ESTAB)
      AND (CONTRATOITE.CONTRATO = CONTRATO.CONTRATO)

       INNER JOIN ITEMAGRO ON ITEMAGRO.ITEM=CONTRATOITE.ITEM

      INNER JOIN itemagro_u on itemagro_u.item = itemagro.item

    INNER JOIN u_agrprodgr ON u_agrprodgr.u_agrprodgr_id=itemagro_u.u_agrprodgr_id

      LEFT JOIN localest on localest.estab = contratoite.estab
                        and localest.local = contratoite.local

    LEFT JOIN TABLE (PCONTRATOSALDO( CONTRATO.ESTAB,
                 CURRENT_DATE, CONTRATO.CONTRATO, CONTRATO.CONTRATO,
                 CONTRATOITE.SEQITEM, CONTRATOITE.SEQITEM, NULL, NULL, NULL,
                 NULL, NULL)) PSALDO
    ON (0=0)
    
     inner join cidade on cidade.cidade = filial.cidade
      INNER JOIN CONTRATOCFG_U ON CONTRATOCFG_U.CONTCONF = CONTRATO.CONTCONF
    LEFT JOIN U_TIPOCTR ON u_tipoctr.u_tipoctr_id = contratocfg_u.u_tipoctr_id
where u_tempresa.graos='S'
and contrato.contconf in (1,3,6,8,13) and PSALDO.NQTDSALDO > 0
and contrato.dtmovsaldo > last_day(current_date)
 and u_agrprodgr.u_agrprodgr_id = $P{ITEM}
AND CIDADE.UF = $P{UF}
and (filial.estab = $P{ESTAB} or 0 = $P{ESTAB} ) and filial.estab <> 800




group by  CONTRATO.ESTAB,
      u_agrprodgr.u_agrprodgr_id,
       localest.local

UNION ALL

SELECT DADOS.ESTAB,
       DADOS.ITEM,
       DADOS.LOCAL,
       0 SALDODISP,
       0 SALDOFIS,
       0 DEPOSTOPROD,
       0 QTDSALDO,
       0 QTDSALDOCF,
       0 QTDSALDOVD,
       0 QTDSALDOVF,
       SUM(DADOS.ROMAABERTO)SALDOROMA,
        0 SALDOFIXAR,
        0 PEDIDO,
       0 SALDOVF



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
    
     inner join cidade on cidade.cidade = filial.cidade
     

    WHERE NOT EXISTS (SELECT ROMA.ROMANEIO FROM NFCABROMA
        WHERE NFCABROMA.ESTAB         = ROMACLASS.ESTAB
          AND NFCABROMA.ROMANEIO      = ROMACLASS.ROMANEIO
          AND NFCABROMA.ENTRADASAIDA  = ROMACLASS.ENTRADASAIDA
          AND NFCABROMA.NUMEROCM      = ROMACLASS.NUMEROCM)
          --AND NFCABROMA.CLASSIFICACAO = ROMACLASS.CLASSIFICACAO)
          AND ROMA.ESTORNADO            = 'N'
         AND u_tempresa.graos='S'
          and u_agrprodgr.u_agrprodgr_id = $P{ITEM}
AND CIDADE.UF = $P{UF}
and (filial.estab = $P{ESTAB} or 0 = $P{ESTAB} ) and filial.estab <> 800

         

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
    
     inner join cidade on cidade.cidade = filial.cidade
     

    WHERE NOT EXISTS (SELECT ROMA.ROMANEIO FROM NFCABROMA
        WHERE NFCABROMA.ESTAB         = ROMACLASS.ESTAB
          AND NFCABROMA.ROMANEIO      = ROMACLASS.ROMANEIO
          AND NFCABROMA.ENTRADASAIDA  = ROMACLASS.ENTRADASAIDA
          AND NFCABROMA.NUMEROCM      = ROMACLASS.NUMEROCM)
          --AND NFCABROMA.CLASSIFICACAO = ROMACLASS.CLASSIFICACAO)
          AND ROMA.ESTORNADO            = 'N'
          AND u_tempresa.graos='S'
           and u_agrprodgr.u_agrprodgr_id = $P{ITEM}
AND CIDADE.UF = $P{UF}
and (filial.estab = $P{ESTAB} or 0 = $P{ESTAB} ) and filial.estab <> 800


GROUP BY
    FILIAL.ESTAB,
    FILIAL.REDUZIDO,
  --  ROMA.ROMANEIO,
    LOCALEST.LOCAL,
   u_agrprodgr.u_agrprodgr_id,
    ITEMAGRO.DESCRICAO )DADOS

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

WHERE 0=0


       GROUP BY DADOS.ESTAB,
       FILIAL.REDUZIDO,
       DADOS.ITEM,
       itemagro.descricao,
         DADOS.LOCAL,
       LOCALEST.DESCRICAO,
CIDADE.UF



HAVING  SUM(DADOS.SALDODISP)<> 0
       OR SUM(DADOS.SALDOFIS)<> 0
       OR SUM(DADOS.DEPOSTOPROD)<> 0
       OR SUM(DADOS.QTDSALDO)<> 0
       --OR SUM(DADOS.QTDSALDOCF)<> 0
       --OR SUM(DADOS.QTDSALDOVD)<> 0
       OR SUM(DADOS.QTDSALDOVF)<> 0
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

HAVING    SUM(DADOS3.SALDOEMP) <> 0
      OR SUM(DADOS3.SALDOCAMPO) <> 0
     OR SUM(DADOS3.SALDODISP) <> 0
      OR SUM(DADOS3.SALDOFIS) <> 0
      OR SUM(DADOS3.SALDOPROD) <> 0

ORDER BY DADOS3.ITEM,DADOS3.ESTADO DESC,DADOS3.ESTAB,DADOS3.LOCAL