SELECT DADOS.ESTAB as codi_rev,
       DADOS.MARCA as codi_fab,
       DADOS.ITEM as codi_pro,
       SUBSTR(dados.descricao,1,60) as desc_pro,
       DADOS.UNIDADE as unid_pro,
       '' as barr_pro,
	   RPAD(to_char(CURRENT_DATE,'YYYY/MM/DD'),19,' 00:00:00') as date_pro,
       ''lote_pro,	  
	   SUM(FISICO*DADOS.KGLT)qtde_pro,
       SUM(DISPONIVEL*DADOS.KGLT)qtdi_pro,
       SUM(EMTRANSITO*DADOS.KGLT)qttr_pro,
       0 qtbl_pro,
       DADOS.CUSTOCMV cmed_pro,
       DADOS.CUSTOCMV cuen_pro
       

FROM(

SELECT 
    DADOS.ESTAB,
    COALESCE(ITEMSALDO.SALDOQUANTIDADE,0) AS DISPONIVEL,
	0 as EMTRANSITO,
	0 as FISICO,
    ARREDONDAR(ITEMAGROESTAB.PRECOVENDA,2) AS PRECOVENDA,
    
 ARREDONDAR(ITEMAGROESTAB.CUSTOGERENCIAL,2) AS CUSTOGERENCIAL,
 PCUSTO(ITEMAGROESTAB.ESTAB,ITEMAGROESTAB.ITEM,3,CURRENT_DATE,NULL)CUSTOCMV,
  ITEMAGROESTAB.MARGEMLUCRO AS MARGEM,
  
    DADOS.ITEM,
	itemagro.pesoliquido KGLT,
    ITEMAGRO.DESCRICAO,
    itemagro.unidade,
     -- u_gestoque.u_gestoque_id||'-'||u_gestoque.DESCRICAO GRUPO,
       --ITEMAGRO.GRUPO||'-'||ITEMGRUPO.descricao SUBGR,
       ITEMMARCA.MARCA,
       --ITEMAGROESTAB.LOCALIZACAO LOCAL,
      -- u_principioativo.u_principioativo_id||'-'||u_principioativo.nomeprincipio as PRINCIPIO,
       ITEMAGRO.ATIVO,

    EXTRACT(YEAR FROM DADOS.DATA) AS ANO,
    EXTRACT(MONTH FROM DADOS.DATA) AS MES

FROM (
  SELECT 
    ITEMAGROESTAB.ESTAB,
    ITEMAGROESTAB.ITEM,
    MAX(CAST('01/'||LPAD( coalesce(ITEMSALDO.MES,1),2,'0') || '/' || coalesce(ITEMSALDO.ANO,1) AS DATE)) AS DATA    from ITEMAGROESTAB
      LEFT JOIN ITEMSALDO 
        ON ITEMSALDO.ITEM=ITEMAGROESTAB.ITEM 
        AnD itemsaldo.estab = iTemAGROestab.eSTaB
    WHERE ITEMSALDO.codigosaldo=1 
     -- AND ITEMAGROESTAB.ESTAB IN (2,4,5,8,9,10,13,15,19,28,29) 
    GROUP BY ITEMAGROESTAB.ESTAB, ITEMAGROESTAB.ITEM
) DADOS           
INNER JOIN ITEMAGROESTAB 
  ON ITEMAGROESTAB.ESTAB = DADOS.ESTAB 
  AND ITEMAGROESTAB.ITEM = DADOS.ITEM
LEFT JOIN ITEMSALDO 
  ON ITEMSALDO.ITEM = dados.ITEM 
  anD iTEMsaLDo.EstaB = dados.Estab
  anD itemsaldo.codigosaldo = 1
  AnD ITEMSALDO.ANo = EXTRACT(YEAR FROM DADOS.DATA)
  AnD ITEMSALDO.meS = EXTRACT(moNtH FROM DADOS.DATA)
  
INNER JOIN ITEMAGRO 
  ON ITEMAGRO.ITEM = DADOS.ITEM
  AND ITEMAGRO.ATIVO='S'
  
LEFT JOIN ITEMAGRO_U ON  itemagro_u.item = ITEMAGRO.ITEM

LEFT JOIN u_principioativo ON u_principioativo.u_principioativo_id = itemagro_u.u_principioativo_id
  
INNER JOIN ITEMGRUPO 
  ON ITEMGRUPO.GRUPO = ITEMAGRO.GRUPO

  
INNER JOIN ITEMMARCA ON ITEMMARCA.MARCA=ITEMAGRO.MARCA
                    AND ITEMMARCA.MARCA=210

INNER JOIN ITEMGRUPO_U 
  ON itemgrupo_u.grupo=ITEMGRUPO.GRUPO

INNER JOIN u_gestoque 
  ON u_gestoque.u_gestoque_id = itemgrupo_u.u_gestoque_id
  AND u_gestoque.u_gestoque_id IN (1,2,3,4,5,6,7,8,9,10,12,13,14,15,16,17)

inner join u_tempresa on u_tempresa.estab = dados.estab

inner join filial on filial.estab = dados.estab

inner join cidade on cidade.cidade = filial.cidade

WHERE  
--DADOS.ESTAB in (2,4,5,8,9,10,13,15,19,28,29)
--and dados.item=35163
cidade.uf = 'SP'
AND
(
(u_tempresa.insumos ='S' OR U_TEMPRESA.ESTOQUE ='S' )
OR
(u_tempresa.insumos ='S' OR U_TEMPRESA.ESTOQUE ='N' )
OR
(u_tempresa.insumos ='N' OR U_TEMPRESA.ESTOQUE ='S' )
)
UNION ALL


SELECT 
    DADOS.ESTAB,
    0 AS DISPONIVEL,
	COALESCE(ITEMSALDO.SALDOQUANTIDADE,0) as EMTRANSITO,
	0 as FISICO,
    ARREDONDAR(ITEMAGROESTAB.PRECOVENDA,2) AS PRECOVENDA,
    
 ARREDONDAR(ITEMAGROESTAB.CUSTOGERENCIAL,2) AS CUSTOGERENCIAL,
 PCUSTO(ITEMAGROESTAB.ESTAB,ITEMAGROESTAB.ITEM,3,CURRENT_DATE,NULL)CUSTOCMV,
  ITEMAGROESTAB.MARGEMLUCRO AS MARGEM,
  
    DADOS.ITEM,
	itemagro.pesoliquido KGLT,
    ITEMAGRO.DESCRICAO,
    itemagro.unidade,
     -- u_gestoque.u_gestoque_id||'-'||u_gestoque.DESCRICAO GRUPO,
       --ITEMAGRO.GRUPO||'-'||ITEMGRUPO.descricao SUBGR,
       ITEMMARCA.MARCA,
       --ITEMAGROESTAB.LOCALIZACAO LOCAL,
      -- u_principioativo.u_principioativo_id||'-'||u_principioativo.nomeprincipio as PRINCIPIO,
       ITEMAGRO.ATIVO,

    EXTRACT(YEAR FROM DADOS.DATA) AS ANO,
    EXTRACT(MONTH FROM DADOS.DATA) AS MES

FROM (
  SELECT 
    ITEMAGROESTAB.ESTAB,
    ITEMAGROESTAB.ITEM,
    MAX(CAST('01/'||LPAD( coalesce(ITEMSALDO.MES,1),2,'0') || '/' || coalesce(ITEMSALDO.ANO,1) AS DATE)) AS DATA    from ITEMAGROESTAB
      LEFT JOIN ITEMSALDO 
        ON ITEMSALDO.ITEM=ITEMAGROESTAB.ITEM 
        AnD itemsaldo.estab = iTemAGROestab.eSTaB
    WHERE ITEMSALDO.codigosaldo=20 
      AND ITEMAGROESTAB.ESTAB IN (2,4,5,8,9,10,13,15,19,28,29) 
    GROUP BY ITEMAGROESTAB.ESTAB, ITEMAGROESTAB.ITEM
) DADOS           
INNER JOIN ITEMAGROESTAB 
  ON ITEMAGROESTAB.ESTAB = DADOS.ESTAB 
  AND ITEMAGROESTAB.ITEM = DADOS.ITEM
LEFT JOIN ITEMSALDO 
  ON ITEMSALDO.ITEM = dados.ITEM 
  anD iTEMsaLDo.EstaB = dados.Estab
  anD itemsaldo.codigosaldo = 20
  AnD ITEMSALDO.ANo = EXTRACT(YEAR FROM DADOS.DATA)
  AnD ITEMSALDO.meS = EXTRACT(moNtH FROM DADOS.DATA)
  
INNER JOIN ITEMAGRO 
  ON ITEMAGRO.ITEM = DADOS.ITEM
  AND ITEMAGRO.ATIVO='S'
  
LEFT JOIN ITEMAGRO_U ON  itemagro_u.item = ITEMAGRO.ITEM

LEFT JOIN u_principioativo ON u_principioativo.u_principioativo_id = itemagro_u.u_principioativo_id
  
INNER JOIN ITEMGRUPO 
  ON ITEMGRUPO.GRUPO = ITEMAGRO.GRUPO
  
INNER JOIN ITEMMARCA ON ITEMMARCA.MARCA=ITEMAGRO.MARCA
                        AND ITEMMARCA.MARCA=210

INNER JOIN ITEMGRUPO_U 
  ON itemgrupo_u.grupo=ITEMGRUPO.GRUPO

INNER JOIN u_gestoque 
  ON u_gestoque.u_gestoque_id = itemgrupo_u.u_gestoque_id
  AND u_gestoque.u_gestoque_id IN (1,2,3,4,5,6,7,8,9,10,12,13,14,15,16,17)
inner join u_tempresa on u_tempresa.estab = dados.estab
inner join filial on filial.estab = dados.estab

inner join cidade on cidade.cidade = filial.cidade
WHERE  
--DADOS.ESTAB in (2,4,5,8,9,10,13,15,19,28,29)
--and dados.item=35163
cidade.uf = 'SP'
and((u_tempresa.insumos ='S' OR U_TEMPRESA.ESTOQUE ='S' )
OR
(u_tempresa.insumos ='S' OR U_TEMPRESA.ESTOQUE ='N' )
OR
(u_tempresa.insumos ='N' OR U_TEMPRESA.ESTOQUE ='S' ))

UNION ALL

SELECT 
    DADOS.ESTAB,
    0 AS DISPONIVEL,
	0 as EMTRANSITO,
	COALESCE(ITEMSALDO.SALDOQUANTIDADE,0) as FISICO,
    ARREDONDAR(ITEMAGROESTAB.PRECOVENDA,2) AS PRECOVENDA,
    
 ARREDONDAR(ITEMAGROESTAB.CUSTOGERENCIAL,2) AS CUSTOGERENCIAL,
 PCUSTO(ITEMAGROESTAB.ESTAB,ITEMAGROESTAB.ITEM,3,CURRENT_DATE,NULL)CUSTOCMV,
  ITEMAGROESTAB.MARGEMLUCRO AS MARGEM,
  
    DADOS.ITEM,
	itemagro.pesoliquido KGLT,
    ITEMAGRO.DESCRICAO,
    itemagro.unidade,
     -- u_gestoque.u_gestoque_id||'-'||u_gestoque.DESCRICAO GRUPO,
       --ITEMAGRO.GRUPO||'-'||ITEMGRUPO.descricao SUBGR,
       ITEMMARCA.MARCA,
       --ITEMAGROESTAB.LOCALIZACAO LOCAL,
      -- u_principioativo.u_principioativo_id||'-'||u_principioativo.nomeprincipio as PRINCIPIO,
       ITEMAGRO.ATIVO,

    EXTRACT(YEAR FROM DADOS.DATA) AS ANO,
    EXTRACT(MONTH FROM DADOS.DATA) AS MES

FROM (
  SELECT 
    ITEMAGROESTAB.ESTAB,
    ITEMAGROESTAB.ITEM,
    MAX(CAST('01/'||LPAD( coalesce(ITEMSALDO.MES,1),2,'0') || '/' || coalesce(ITEMSALDO.ANO,1) AS DATE)) AS DATA    from ITEMAGROESTAB
      LEFT JOIN ITEMSALDO 
        ON ITEMSALDO.ITEM=ITEMAGROESTAB.ITEM 
        AnD itemsaldo.estab = iTemAGROestab.eSTaB
    WHERE ITEMSALDO.codigosaldo=2 
      AND ITEMAGROESTAB.ESTAB IN (2,4,5,8,9,10,13,15,19,28,29) 
    GROUP BY ITEMAGROESTAB.ESTAB, ITEMAGROESTAB.ITEM
) DADOS           
INNER JOIN ITEMAGROESTAB 
  ON ITEMAGROESTAB.ESTAB = DADOS.ESTAB 
  AND ITEMAGROESTAB.ITEM = DADOS.ITEM
LEFT JOIN ITEMSALDO 
  ON ITEMSALDO.ITEM = dados.ITEM 
  anD iTEMsaLDo.EstaB = dados.Estab
  anD itemsaldo.codigosaldo = 2
  AnD ITEMSALDO.ANo = EXTRACT(YEAR FROM DADOS.DATA)
  AnD ITEMSALDO.meS = EXTRACT(moNtH FROM DADOS.DATA)
  
INNER JOIN ITEMAGRO 
  ON ITEMAGRO.ITEM = DADOS.ITEM
  AND ITEMAGRO.ATIVO='S'
  
LEFT JOIN ITEMAGRO_U ON  itemagro_u.item = ITEMAGRO.ITEM

LEFT JOIN u_principioativo ON u_principioativo.u_principioativo_id = itemagro_u.u_principioativo_id
  
INNER JOIN ITEMGRUPO 
  ON ITEMGRUPO.GRUPO = ITEMAGRO.GRUPO
  
INNER JOIN ITEMMARCA ON ITEMMARCA.MARCA=ITEMAGRO.MARCA
                    AND ITEMMARCA.MARCA=210

INNER JOIN ITEMGRUPO_U 
  ON itemgrupo_u.grupo=ITEMGRUPO.GRUPO

INNER JOIN u_gestoque 
  ON u_gestoque.u_gestoque_id = itemgrupo_u.u_gestoque_id
  AND u_gestoque.u_gestoque_id IN (1,2,3,4,5,6,7,8,9,10,12,13,14,15,16,17)
inner join u_tempresa on u_tempresa.estab = dados.estab
inner join filial on filial.estab = dados.estab

inner join cidade on cidade.cidade = filial.cidade
WHERE  
--DADOS.ESTAB in (2,4,5,8,9,10,13,15,19,28,29)
--and dados.item=35163
CIDADE.UF = 'SP'
AND((u_tempresa.insumos ='S' OR U_TEMPRESA.ESTOQUE ='S' )
OR
(u_tempresa.insumos ='S' OR U_TEMPRESA.ESTOQUE ='N' )
OR
(u_tempresa.insumos ='N' OR U_TEMPRESA.ESTOQUE ='S' ))
)DADOS

WHERE  DADOS.DISPONIVEL <> 0
  OR DADOS.FISICO <> 0
  OR DADOS.EMTRANSITO <> 0



GROUP BY DADOS.ESTAB,
       DADOS.ITEM,
       DADOS.DESCRICAO,
       DADOS.MARCA,
       DADOS.UNIDADE,
	   DADOS.KGLT,
	   DADOS.CUSTOCMV
	   
