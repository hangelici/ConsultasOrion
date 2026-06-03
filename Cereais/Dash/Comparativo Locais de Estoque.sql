with maxdata as (
    SELECT
    i.estab,i.codigosaldo,i.local,i.item,
    MAX(TO_DATE('01/' || LPAD(COALESCE(i.MES, 1), 2, '0') || '/' || COALESCE(i.ANO, 1), 'DD/MM/YYYY')) AS DATA_MAX
    from itemsaldo i
    inner join u_tempresa e on e.estab = i.estab
    where i.codigosaldo in (:CODIGOSALDO) and e.GRAOS = 'S'
    AND (TO_DATE('01/' || LPAD(COALESCE(i.MES, 1), 2, '0') || '/' || COALESCE(i.ANO, 1), 'DD/MM/YYYY')) <= :DATA
    group by i.estab,i.codigosaldo,i.local,i.item
),
base as (
    select
    t.estab,
    t.item,
    itemsaldo.local,
    sum(itemsaldo.SALDOQUANTIDADE) saldo
    from itemagroestab t
    left join itemsaldo on
        itemsaldo.estab = t.estab
        and itemsaldo.item = t.item
    inner join maxdata m on
        m.estab = itemsaldo.estab
        and m.item = itemsaldo.ITEM
        and m.local = itemsaldo.local
        and m.codigosaldo = itemsaldo.codigosaldo
        and m.DATA_MAX = TO_DATE('01/' || LPAD(COALESCE(itemsaldo.MES, 1), 2, '0') || '/' || COALESCE(itemsaldo.ANO, 1), 'DD/MM/YYYY')
    group by t.estab,t.item,itemsaldo.local
)
SELECT  FILIAL.ESTAB AS ESTABORIGEM,
        LOCALEST.LOCAL AS LOCALORIGEM,
        LOCEQUI_U.ESTAB AS ESTABDESTINO,
        LOCEQUI_U.LOCAL AS LOCALDESTINO,    
        ITEMAGRO.DESCRICAO||' - '||FILIAL.ESTAB||'-'||LOCALEST.DESCRICAO||' / '||LOCEQUI.ESTAB||'-'||LOCEQUI.DESCRICAO AS LOCALXLOCAL,        
        nvl(baseori.saldo,0) as SALDOORIGEM,
        nvl(baseeq.saldo,0) as SALDOEQUIVALENTE
        --SALDOITEM(LOCALEST.ESTAB, ITEMAGROESTAB.ITEM, :CODIGOSALDO, LOCALEST.LOCAL, LOCALEST.LOCAL,:DATA,NULL,NULL,NULL,NULL) AS SALDOORIGEM,
        --SALDOITEM(LOCEQUI_U.ESTAB, ITEMAGROESTAB.ITEM, :CODIGOSALDO, LOCEQUI_U.LOCAL, LOCEQUI_U.LOCAL,:DATA,NULL,NULL,NULL,NULL) AS SALDOEQUIVALENTE
FROM FILIAL
INNER JOIN LOCALEST
  ON FILIAL.ESTAB = LOCALEST.ESTAB
INNER JOIN LOCALEST_U
  ON LOCALEST.ESTAB = LOCALEST_U.ESTAB
  AND LOCALEST.LOCAL = LOCALEST_U.LOCAL
INNER JOIN LOCALEST_U LOCEQUI_U
  ON LOCALEST_U.ESTAB = LOCEQUI_U.NUMEROCM
  AND LOCALEST_U.NUMEROCM = LOCEQUI_U.ESTAB
  AND LOCEQUI_U.ESTAB <> LOCALEST.ESTAB
INNER JOIN LOCALEST LOCEQUI
  ON LOCEQUI_U.ESTAB = LOCEQUI.ESTAB
  AND LOCEQUI_U.LOCAL = LOCEQUI.LOCAL
INNER JOIN ITEMAGROESTAB
  ON ITEMAGROESTAB.ESTAB = FILIAL.ESTAB
INNER JOIN ITEMAGRO
  ON ITEMAGROESTAB.ITEM = ITEMAGRO.ITEM
LEFT JOIN ITEMGRUPO
  ON ITEMAGRO.GRUPO = ITEMGRUPO.GRUPO

left join base baseori on
    baseori.estab = LOCALEST.ESTAB
    and baseori.item = ITEMAGROESTAB.ITEM
    and baseori.local = LOCALEST.LOCAL

left join base baseeq on
    baseeq.estab = LOCEQUI_U.ESTAB
    and baseeq.item = ITEMAGROESTAB.ITEM
    and baseeq.local = LOCEQUI_U.LOCAL

WHERE 0=0
 <#if ESTABORIGEM?has_content>
    AND FILIAL.ESTAB IN ( :ESTABORIGEM )
  </#if>
  <#if ESTABDESTINO?has_content>
    AND LOCEQUI_U.ESTAB IN ( :ESTABDESTINO )
  </#if>
  <#if GRUPO?has_content>
    AND ITEMAGRO.GRUPO IN ( :GRUPO )
  </#if>
  <#if MARCA?has_content>
    AND ITEMAGRO.MARCA IN ( :MARCA )
  </#if>
  <#if GRUPOCONTABIL?has_content>
    AND ITEMGRUPO.GRUPOCONTABIL IN ( :GRUPOCONTABIL )
  </#if>
  <#if ITEM?has_content>
    AND ITEMAGRO.ITEM IN ( :ITEM)
  </#if>