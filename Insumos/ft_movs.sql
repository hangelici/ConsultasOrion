SELECT DADOS.ESTAB OSESTAB,
        --DADOS.REDUZIDO,
        DADOS.DTEMISSAO,
DADOS.dtentsai,
        DADOS.EMISSAO_ORIGEM,
		dados.dtautorizanfe,
		DADOS.DTENTREGA,
        DADOS.PRAZOPAGTO AS DTPAGTO,
        DADOS.PRAZOPAGTO - DADOS.DTEMISSAO  AS DIASPAGTO,
 CASE        WHEN  DADOS.DTEMISSAO BETWEEN '01/06/2019' AND '31/05/2020' THEN '19/20'
             WHEN  DADOS.DTEMISSAO BETWEEN '01/06/2020' AND '30/06/2021' THEN '20/21'
             WHEN  DADOS.DTEMISSAO BETWEEN '01/07/2021' AND '30/06/2022' THEN '21/22'
             WHEN  DADOS.DTEMISSAO BETWEEN '01/07/2022' AND '30/06/2023' THEN '22/23'
             WHEN  DADOS.DTEMISSAO BETWEEN '01/07/2023' AND '30/06/2024' THEN '23/24'
			 WHEN  DADOS.DTEMISSAO BETWEEN '01/07/2024' AND '30/06/2025' THEN '24/25'
             END OSSAFRA,

        DADOS.SEQNOTA,
         DADOS.NOTACONF AS COD_NOTACONF,
        DADOS.NOTA,
        ---DADOS.DIA,
        --DADOS.MES,
        --DADOS.ANO,
        DADOS.NUMEROCM||'#'|| COALESCE(DADOS.SEQENDERECO,0)OSPESSOA,
         DADOS.NUMEROCM,
        --DADOS.NOME_CLIENTE,  
        COALESCE(DADOS.SEQENDERECO,0)SEQENDERECO,
          DADOS.CODRTV OSRTV,
        --DADOS.CODMARCA,
       -- DADOS.DESCMARCA,
       -- DADOS.CODGESTOQUE,
       -- DADOS.DESCESTOQUE,
       --DADOS.CODSUBGR,
       -- DADOS.DESCSUBGR, 
      
        --DADOS.NOME_CIDADE,
        DADOS.SEQNOTAITEM ,
        DADOS.CODITEM OSPRODUTO,
		COALESCE(DADOS.OSCULTURA,0)OSCULTURA,
		COALESCE(DADOS.DIAGNOSTICOID,0)DIAGNOSTICOID,
        DADOS.OSCREDC,
		--COALESCE(DADOS.VENDAORBIA,'N')VENDAORBIA,
        --DADOS.DESCITEM,
       -- DADOS.UNIDADE UN,
        DADOS.CFOP,
        DADOS.QUANTIDADE,
        DADOS.QTDDEV,
        DADOS.QTDKGLT,
        DADOS.QTDDEVKGLT,
        DADOS.VALOR,
        DADOS.VLRDEV,
        DADOS.CUSTOCMV,
        DADOS.CUSTOCMVNOTA,
        DADOS.CUSTOCMVP,
        DADOS.CUSTOCMVPOR,
        DADOS.CUSTOCMVDEV,
        DADOS.CUSTOCMVPDEV,
        DADOS.VENDAORBIA,
        DADOS.IDORBIA
        ,DADOS.USER_ORIGEM,
        SYSDATE AS Data_At
        ,CANHOTORECEBIDO
       ,DADOS.TABPRCESTAB||'#'||DADOS.TABPRC AS CHAVE_TABPRC
                 
FROM(

SELECT
    FILIAL.ESTAB,
    
    FILIAL.REDUZIDO,
    NFCAB.DTEMISSAO,
	nfcab.dtentsai,
    COALESCE(ORIGEM.DTEMISSAO,NFCAB.DTEMISSAO) AS EMISSAO_ORIGEM,
	CAST(nfcab.dtautorizanfe AS TIMESTAMP) as dtautorizanfe,
	PED.DTENTREGA,
    NFCAB.PRAZOPAGTO,
      NFCAB.SEQNOTA,
       NFCAB.NOTACONF,
      NFCAB.NOTA,
   -- TO_CHAR(NFCAB.DTEMISSAO, 'DD')DIA,
  -- TO_CHAR(NFCAB.DTEMISSAO, 'MM')||'-'||TO_CHAR(NFCAB.DTEMISSAO, 'MON')MES,
    --  TO_CHAR(NFCAB.DTEMISSAO, 'YYYY')ANO,
     NFCAB.NUMEROCM,
    CONTAMOV.NOME AS "NOME_CLIENTE",  
    nfcab.seqendereco,
     itemmarca.marca AS CODMARCA,
     itemmarca.descricao AS DESCMARCA,
     u_gestoque.u_gestoque_id AS CODGESTOQUE,
     u_gestoque.descricao AS DESCESTOQUE,
    CASE WHEN NFCAB.REPRESENT IS NULL THEN 'SR' ELSE PREPRESE.REPRESENT||'#'||PREPRESE.EMPRESA END AS "CODRTV",
    
    CASE WHEN NFCAB.SEQENDERECO > 0 THEN ENDCID.NOME||' - '||ENDCID.UF ELSE PESCID.NOME||' - '||PESCID.UF END AS "NOME_CIDADE",
    ITEMAGRO.GRUPO AS CODSUBGR,
    ITEMGRUPO.DESCRICAO AS "DESCSUBGR",  
    NFITEM.SEQNOTAITEM,
    NFITEM.ITEM AS CODITEM,
    
	NFITEM.CULTURAID AS OSCULTURA,
	NFITEM.DIAGNOSTICOID,
   LIMITE.LIMCRED_ID as OSCREDC,
   ITEMAGRO.DESCRICAO AS "DESCITEM",
   itemagro.unidade,
      
    NFITEM.CFOP,
    NFITEM.QUANTIDADE,
    0 QTDDEV,
     NFITEM.QUANTIDADE * ITEMAGRO.PESOLIQUIDO AS QTDKGLT,  
     0 QTDDEVKGLT,
  SUM(NFITEM.VALORTOTAL - (DIVIDE(NFITEM.VALORTOTAL, NFCAB.VALORPRODBRUTO) * DESCONTO.VALOR)) as VALOR,
  0 VLRDEV,
  SUM((COALESCE(nfitem.custocmv,0))*(nfitem.quantidade))CUSTOCMV,
  0 as CUSTOCMVNOTA,
  CASE WHEN u_tipoop.tipoop = ('TS')THEN 0 ELSE
  SUM((COALESCE(nfitem.custocmvp,0))*(nfitem.quantidade))END CUSTOCMVP,
  SUM((COALESCE(PEDITEMMARGEM.CUSTOGERENCIALORI,0))*(nfitem.quantidade)) AS CUSTOCMVPOR,
  0 CUSTOCMVDEV,
  0 CUSTOCMVPDEV
  ,COALESCE(NFCAB_U.VENDAORBIA,'N')VENDAORBIA
  ,COALESCE(NFCAB_U.IDORBIA,'0')IDORBIA
  ,NFCAB_U.USER_ORIGEM,
  SYSDATE AS Data_At
,NFCABCANHOTO.CANHOTORECEBIDO   
,PEDITEMNFITEM.TABPRCESTAB
,PEDITEMNFITEM.TABPRC

FROM NFCAB
                   
       LEFT JOIN (SELECT NFDESC.ESTAB,
                  NFDESC.SEQNOTA,
                  SUM(NFDESC.VALORDESCONTO) VALOR
            FROM NFDESC
            GROUP BY  NFDESC.ESTAB,
                      NFDESC.SEQNOTA
)DESCONTO

ON NFCAB.ESTAB = DESCONTO.ESTAB
  AND NFCAB.SEQNOTA = DESCONTO.SEQNOTA        
             

    INNER JOIN CONTAMOV ON
    CONTAMOV.NUMEROCM = NFCAB.NUMEROCM

    LEFT JOIN ENDERECO ON
    ENDERECO.NUMEROCM = NFCAB.NUMEROCM AND
    ENDERECO.SEQENDERECO = NFCAB.SEQENDERECO

    LEFT JOIN CIDADE ENDCID ON
    ENDCID.CIDADE = ENDERECO.CIDADE

    LEFT JOIN CIDADE PESCID ON
    PESCID.CIDADE = CONTAMOV.CIDADE
    
    INNER JOIN NFITEM ON
    NFCAB.ESTAB = NFITEM.ESTAB AND
    NFCAB.SEQNOTA = NFITEM.SEQNOTA 

    LEFT JOIN 
	(
	select distinct
	PEDITEMNFITEM.estab,
	PEDITEMNFITEM.serie,
	PEDITEMNFITEM.numero,
	PEDITEMNFITEM.seqpedite,
	PEDITEMNFITEM.estabnota,
	PEDITEMNFITEM.seqnota,
	PEDITEMNFITEM.seqnotaitem,
    PEDCAB.TABPRCESTAB,
    PEDCAB.TABPRC
	from PEDITEMNFITEM
    
    LEFT JOIN PEDITEM ON
        PEDITEM.ESTAB = PEDITEMNFITEM.ESTAB
        AND PEDITEM.SERIE = PEDITEMNFITEM.SERIE
        AND PEDITEM.NUMERO = PEDITEMNFITEM.NUMERO
        AND PEDITEM.SEQPEDITE = PEDITEMNFITEM.SEQPEDITE
    
    LEFT JOIN PEDCAB ON
        PEDCAB.ESTAB = PEDITEM.ESTAB
        AND PEDCAB.SERIE = PEDITEM.SERIE
        AND PEDCAB.NUMERO = PEDITEM.NUMERO
        
	)

	PEDITEMNFITEM ON PEDITEMNFITEM.ESTABNOTA=NFITEM.ESTAB
                          AND PEDITEMNFITEM.SEQNOTA=NFITEM.SEQNOTA
                          AND PEDITEMNFITEM.SEQNOTAITEM=NFITEM.SEQNOTAITEM
                          
    LEFT JOIN 
	(
	select distinct
	PEDITEMMARGEM.ESTAB,
    PEDITEMMARGEM.SERIE,
    PEDITEMMARGEM.NUMERO,
    PEDITEMMARGEM.SEQPEDITE,
	PEDITEMMARGEM.CUSTOGERENCIALORI
	from PEDITEMMARGEM

		)
			PEDITEMMARGEM ON  PEDITEMMARGEM.ESTAB= PEDITEMNFITEM.ESTAB
                           AND  PEDITEMMARGEM.SERIE=PEDITEMNFITEM.SERIE
                           AND PEDITEMMARGEM.NUMERO=PEDITEMNFITEM.NUMERO
                           AND PEDITEMMARGEM.SEQPEDITE=PEDITEMNFITEM.SEQPEDITE

   LEFT JOIN 
        (
        SELECT distinct
        PEDITEM.ESTAB,
        PEDITEM.SERIE,
        PEDITEM.NUMERO,
        PEDITEM.SEQPEDITE,
        COALESCE(PEDITEM.DTENTREGA,PEDCAB.DTPREVISAO)DTENTREGA
        FROM PEDCAB
        
        INNER JOIN PEDITEM ON 
            PEDITEM.ESTAB = PEDCAB.ESTAB
            AND PEDITEM.NUMERO = PEDCAB.NUMERO
            AND PEDITEM.SERIE = PEDCAB.SERIE
        
        )PED ON
        PED.ESTAB = PEDITEMNFITEM.ESTAB
        AND PED.SERIE = PEDITEMNFITEM.SERIE
        AND PED.NUMERO = PEDITEMNFITEM.NUMERO
        AND PED.SEQPEDITE = PEDITEMNFITEM.SEQPEDITE


    INNER JOIN ITEMAGRO ON
    ITEMAGRO.ITEM   =    NFITEM.ITEM
    AND ITEMAGRO.ITEM > 50

    INNER JOIN ITEMGRUPO ON
    ITEMGRUPO.GRUPO = ITEMAGRO.GRUPO
    
   inner join itemgrupo_u
                on itemgrupo.grupo = itemgrupo_u.grupo

                inner join u_gestoque
                on itemgrupo_u.u_gestoque_id = u_gestoque.u_gestoque_id

               
    LEFT JOIN ITEMMARCA ON ITEMMARCA.MARCA = ITEMAGRO.MARCA
                 
     LEFT JOIN PREPRESE ON
    PREPRESE.REPRESENT = NFCAB.REPRESENT 
       
    INNER JOIN NFCFG ON NFCFG.NOTACONF = NFCAB.NOTACONF
    
    inner join nfcfg_u on nfcfg_u.notaconf=nfcfg.notaconf
    
    inner join u_tipoop on u_tipoop.u_tipoop_id=nfcfg_u.u_tipoop_id
    
    INNER JOIN NATOPERACAO ON  NATOPERACAO.NATUREZADAOPERACAO = NFCFG.NATUREZADAOPERACAO AND
                               NATOPERACAO.ENTRADASAIDA = NFCFG.ENTRADASAIDA 
    
    INNER JOIN FILIAL ON FILIAL.ESTAB = NFCAB.ESTAB
                 
                       
     INNER JOIN U_TEMPRESA ON u_tempresa.estab = FILIAL.ESTAB
                        AND ((u_tempresa.insumos='S') OR (u_tempresa.exvenda='S') or (u_tempresa.estab = 10))   
                        
    LEFT JOIN NFCAB_U ON NFCAB_U.ESTAB = NFCAB.ESTAB
                    AND NFCAB_U.SEQNOTA = NFCAB.SEQNOTA
                    
    LEFT JOIN
        (
        SELECT DISTINCT
        NFCAB.DTEMISSAO,
        NFITEMAPARTIRDE.ESTAB,
        NFITEMAPARTIRDE.SEQNOTA,
        NFITEMAPARTIRDE.SEQNOTAITEM
        FROM NFCAB
        
        INNER JOIN NFITEM ON NFITEM.ESTAB = NFCAB.ESTAB
                        AND NFITEM.SEQNOTA = NFCAB.SEQNOTA
                        
        INNER JOIN NFCFG ON NFCFG.NOTACONF = NFCFG.NOTACONF
        
        INNER JOIN NFCFG_U ON NFCFG_U.NOTACONF = NFCFG.NOTACONF
        
        INNER JOIN U_TIPOOP ON u_tipoop.u_tipoop_id = nfcfg_u.u_tipoop_id
        
        INNER JOIN NFITEMAPARTIRDE ON NFITEMAPARTIRDE.ESTABORIGEM = NFITEM.ESTAB
                                AND NFITEMAPARTIRDE.SEQNOTAORIGEM = NFITEM.SEQNOTA
                                AND NFITEMAPARTIRDE.SEQNOTAITEMORIGEM = NFITEM.SEQNOTAITEM
                                
        LEFT JOIN NFITEM NFI ON NFI.ESTAB = NFITEMAPARTIRDE.ESTAB
                            AND NFI.SEQNOTA = NFITEMAPARTIRDE.SEQNOTA
                            AND NFI.SEQNOTAITEM = NFITEMAPARTIRDE.SEQNOTAITEM
                            
        LEFT JOIN NFCAB NFC ON NFC.ESTAB = NFI.ESTAB
                            AND NFC.SEQNOTA = NFI.SEQNOTA
                            
        INNER JOIN NFCFG CFG ON CFG.NOTACONF = NFCFG.NOTACONF
        
        INNER JOIN NFCFG_U CFG_U ON CFG_U.NOTACONF = CFG.NOTACONF
        
        INNER JOIN U_TIPOOP TIPOOP ON TIPOOP.u_tipoop_id = CFG_U.u_tipoop_id
        
        WHERE 
        U_TIPOOP.TIPOOP IN ('V','VF')
        AND TIPOOP.TIPOOP IN ('RF')
        
        )ORIGEM ON
        ORIGEM.ESTAB = NFITEM.ESTAB AND
        ORIGEM.SEQNOTA = NFITEM.SEQNOTA AND
        ORIGEM.SEQNOTAITEM = NFITEM.SEQNOTAITEM
        
       
LEFT JOIN  (
          select distinct
    nfitem.estab,
    nfitem.seqnota,
    nfitem.seqnotaitem,
    pduprec.limcred_id
   from nfcab

    inner join nfitem on nfitem.estab = nfcab.estab
                    and nfitem.seqnota = nfcab.seqnota
                    
    inner join nfcfg on nfcfg.notaconf = nfcab.notaconf
        
    inner join nfcfg_u on nfcfg_u.notaconf = nfcfg.notaconf
        
    inner join u_tipoop on u_tipoop.u_tipoop_id = nfcfg_u.u_tipoop_id
                       and u_tipoop.tipoop in ('V','RF','VF')

    ------ buscando origem da VENDA SE FOR REMESSA
    left join nfitemapartirde on nfitemapartirde.estab = nfitem.estab
                                and nfitemapartirde.seqnota = nfitem.seqnota
                                and nfitemapartirde.seqnotaitem = nfitem.seqnotaitem
                               
    ----- buscando a nota de VENDA/VF/REMESSA (ORIGEM)
    left join nfitem nfi on nfi.estab = nfitemapartirde.estaborigem
                    and nfi.seqnota = nfitemapartirde.seqnotaorigem
                    and nfi.seqnotaitem = nfitemapartirde.seqnotaitemorigem
                         
    left join nfcab nf on nf.estab = nfi.estab
                    and nf.seqnota = nfi.seqnota

    inner join nfcabagrfin on nfcabagrfin.estab = coalesce(nf.estab,nfcab.estab)
                            and nfcabagrfin.seqnota = coalesce(nf.seqnota,nfcab.seqnota)
                            
    inner join agrfinduprec on agrfinduprec.estab = nfcabagrfin.estab
                        and agrfinduprec.seqpagamento = nfcabagrfin.seqpagamento
                        
    inner join pduprec on pduprec.empresa = agrfinduprec.estab
                    and pduprec.duprec = agrfinduprec.duprec
        )LIMITE ON
        LIMITE.ESTAB = NFITEM.ESTAB
        AND LIMITE.SEQNOTA = NFITEM.SEQNOTA
        AND LIMITE.SEQNOTAITEM = NFITEM.SEQNOTAITEM
        
    LEFT JOIN NFCABCANHOTO ON
        NFCABCANHOTO.ESTAB = NFCAB.ESTAB
        AND NFCABCANHOTO.SEQNOTA = NFCAB.SEQNOTA
             
     
  WHERE  NFCAB.STATUS <> 'C'
         AND  u_tipoop.tipoop IN ('V','VF','RF','TS')
         -- and NFCFG.NOTACONF in (1,4,9) 
and nfcab.estab not in (5)
and cast(nfcab.dtemissao as date) >= cast('01/07/2024' as date)
    
GROUP BY FILIAL.ESTAB,
          FILIAL.REDUZIDO,  
nfcab.dtentsai,  
          NFCAB.DTEMISSAO,
			--PEDITEM.DTENTREGA,
           NFCAB.PRAZOPAGTO,
          NFCAB.NOTACONF,
           NFCAB.NOTA,
             NFCAB.SEQNOTA,
			 NFITEM.CULTURAID,
			NFITEM.DIAGNOSTICOID,
			LIMITE.LIMCRED_ID,
          NFCAB.NUMEROCM,CONTAMOV.NOME,
          nfcab.seqendereco,
          NFCAB.SEQENDERECO,ENDCID.NOME,
          ENDCID.UF,PESCID.NOME,PESCID.UF,
          NFITEM.SEQNOTAITEM,
          itemmarca.marca,itemmarca.descricao, itemagro.unidade,      
          u_gestoque.u_gestoque_id,u_gestoque.descricao,
          NFITEM.ITEM,ITEMAGRO.DESCRICAO,ITEMAGRO.PESOLIQUIDO,
          ITEMAGRO.GRUPO,ITEMGRUPO.DESCRICAO,
          NFCAB.REPRESENT,
          PREPRESE.REPRESENT,PREPRESE.EMPRESA,
        
          NFITEM.QUANTIDADE,NFITEM.CFOP,
          u_tipoop.tipoop,NFCAB_U.VENDAORBIA,NFCAB_U.IDORBIA,NFCAB_U.USER_ORIGEM,ORIGEM.DTEMISSAO,nfcab.dtautorizanfe,PED.DTENTREGA,NFCABCANHOTO.CANHOTORECEBIDO    
        ,PEDITEMNFITEM.TABPRCESTAB
,PEDITEMNFITEM.TABPRC

UNION ALL



SELECT
    FILIAL.ESTAB,
    FILIAL.REDUZIDO,
   
     NFCAB.DTEMISSAO,
nfcab.dtentsai,
     NFCAB.DTEMISSAO AS EMISSAO_ORIGEM,
CAST(nfcab.dtautorizanfe AS TIMESTAMP) as dtautorizanfe,
	PED.DTENTREGA,
      NFCAB.PRAZOPAGTO,
     NFCAB.SEQNOTA,
     NFCAB.NOTACONF,
      NFCAB.NOTA,
    --TO_CHAR(NFCAB.DTEMISSAO, 'DD')DIA,
   --TO_CHAR(NFCAB.DTEMISSAO, 'MM')||'-'||TO_CHAR(NFCAB.DTEMISSAO, 'MON')MES,
   --TO_CHAR(NFCAB.DTEMISSAO, 'YYYY')ANO,
    NFCAB.NUMEROCM,
    CONTAMOV.NOME AS "NOME_CLIENTE",
    nfcab.seqendereco,
       itemmarca.marca AS CODMARCA,
     itemmarca.descricao AS DESCMARCA,
     u_gestoque.u_gestoque_id AS CODGESTOQUE,
     u_gestoque.descricao AS DESCESTOQUE,
    CASE WHEN NFCAB.REPRESENT IS NULL THEN 'SR' ELSE PREPRESE.REPRESENT||'#'||PREPRESE.EMPRESA END AS "CODRTV",
    CASE WHEN NFCAB.SEQENDERECO > 0 THEN ENDCID.NOME||' - '||ENDCID.UF ELSE PESCID.NOME||' - '||PESCID.UF END AS "NOME_CIDADE",
    ITEMAGRO.GRUPO AS CODSUBGR,
    ITEMGRUPO.DESCRICAO AS "DESCSUBGR",  
    NFITEM.SEQNOTAITEM,
     NFITEM.ITEM AS CODITEM,
	 
	NFITEM.CULTURAID AS OSCULTURA,
	NFITEM.DIAGNOSTICOID,
    limite.limcred_id AS OSCREDC,
	--NULL VENDAORBIA,
   ITEMAGRO.DESCRICAO AS "DESCITEM",
    itemagro.unidade,
     NFITEM.CFOP,
     0 QUANTIDADE,
     NFITEM.QUANTIDADE QTDDEV,
     0 QTDKGLT,
     NFITEM.QUANTIDADE * ITEMAGRO.PESOLIQUIDO AS QTDDEVKGLT,     
   0 VALOR,
 SUM(NFITEM.VALORTOTAL - (DIVIDE(NFITEM.VALORTOTAL, NFCAB.VALORPRODBRUTO) * DESCONTO.VALOR)) as VLRDEV,  
  0 CUSTOCMV,
  SUM((COALESCE(nfitem.custocmv,0))*(nfitem.quantidade))CUSTOCMVNOTA,
  0 CUSTOCMVP,
  0 CUSTOCMVPOR,
  CUSTO.CUSTOCMV AS CUSTOCMVDEV,
  -- COALESCE(CMVP.CUSTOCMVPDEV,CMV.CUSTOCMVDEV)CUSTOCMVPDEV,
  CASE 
  WHEN CUSTO.CUSTOCMVP = 0 THEN CUSTO.CUSTOCMV
  ELSE CUSTO.CUSTOCMVP END CUSTOCMVPDEV,
  /*SUM((SELECT (COALESCE((nfi.custocmv),0)*((nfitem.quantidade))) FROM NFITEMAPARTIRDE
                                       
                                       INNER JOIN NFITEM NFI ON
                                       NFI.ESTAB = NFITEMAPARTIRDE.ESTABORIGEM AND
                                       NFI.SEQNOTA = NFITEMAPARTIRDE.SEQNOTAORIGEM AND
                                       NFI.SEQNOTAITEM = NFITEMAPARTIRDE.SEQNOTAITEMORIGEM

                                       INNER JOIN NFCAB NFDV ON
                                       NFDV.ESTAB = NFI.ESTAB AND
                                       NFDV.SEQNOTA = NFI.SEQNOTA

                                       INNER JOIN NFCFG NFCFGDV ON
                                       NFCFGDV.NOTACONF = NFDV.NOTACONF
                                       
                                      inner join nfcfg_u on nfcfg_u.notaconf=NFCFGDV.notaconf
    
                                      inner join u_tipoop on u_tipoop.u_tipoop_id=nfcfg_u.u_tipoop_id
                                       AND  u_tipoop.tipoop IN ('V','VF','RF')

                                       INNER JOIN NATOPERACAO NATDV ON
                                       NATDV.NATUREZADAOPERACAO = NFCFGDV.NATUREZADAOPERACAO AND
                                       NATDV.ENTRADASAIDA = NFCFGDV.ENTRADASAIDA 
                                       AND NATDV.TIPODCTO IN ('N')

                                       WHERE NFITEM.ESTAB = NFITEMAPARTIRDE.ESTABORIGEM
                                         AND NFITEM.SEQNOTA = NFITEMAPARTIRDE.SEQNOTA
                                         AND NFITEM.SEQNOTAITEM = NFITEMAPARTIRDE.SEQNOTAITEM
                                       )) AS CUSTOCMVDEV
                                       
                                      ,
    
    
    
COALESCE(
(SUM((SELECT (COALESCE(NF.custocmvp,0)*(nfitem.quantidade)) FROM NFITEMAPARTIRDE
                                       
                                       INNER JOIN NFITEM NFI ON
                                       NFI.ESTAB = NFITEMAPARTIRDE.ESTABORIGEM AND
                                       NFI.SEQNOTA = NFITEMAPARTIRDE.SEQNOTAORIGEM AND
                                       NFI.SEQNOTAITEM = NFITEMAPARTIRDE.SEQNOTAITEMORIGEM

                                       INNER JOIN NFCAB NFDV ON
                                       NFDV.ESTAB = NFI.ESTAB AND
                                       NFDV.SEQNOTA = NFI.SEQNOTA

                                       INNER JOIN NFCFG NFCFGDV ON
                                       NFCFGDV.NOTACONF = NFDV.NOTACONF
                                       
                                       inner join nfcfg_u on nfcfg_u.notaconf=NFCFGDV.notaconf
    
                                       inner join u_tipoop on u_tipoop.u_tipoop_id=nfcfg_u.u_tipoop_id
                                                                AND  u_tipoop.tipoop IN ('RF')

                                       INNER JOIN NATOPERACAO NATDV ON
                                       NATDV.NATUREZADAOPERACAO = NFCFGDV.NATUREZADAOPERACAO AND
                                       NATDV.ENTRADASAIDA = NFCFGDV.ENTRADASAIDA 
                                       AND NATDV.TIPODCTO IN ('N')
                                       
                                       INNER JOIN NFITEMAPARTIRDE NFAPARTIRDE ON 
                                            NFAPARTIRDE.ESTAB = NFI.ESTAB AND
                                            NFAPARTIRDE.SEQNOTA = NFI.SEQNOTA AND
                                            NFAPARTIRDE.SEQNOTAITEM = NFI.SEQNOTAITEM
                                            
                                        INNER JOIN NFITEM NF ON NF.ESTAB = NFAPARTIRDE.ESTABORIGEM
                                                            AND NF.SEQNOTA = NFAPARTIRDE.SEQNOTAORIGEM
                                                            AND NF.SEQNOTAITEM = NFAPARTIRDE.SEQNOTAITEMORIGEM
                                       

                                       WHERE NFITEM.ESTAB = NFITEMAPARTIRDE.ESTAB
                                         AND NFITEM.SEQNOTA = NFITEMAPARTIRDE.SEQNOTA
                                         AND NFITEM.SEQNOTAITEM = NFITEMAPARTIRDE.SEQNOTAITEM
                                       ))),
    
    
                                       
     SUM((SELECT (COALESCE(nfi.custocmvp,0)*(nfitem.quantidade)) FROM NFITEMAPARTIRDE
                                       
                                       INNER JOIN NFITEM NFI ON
                                       NFI.ESTAB = NFITEMAPARTIRDE.ESTABORIGEM AND
                                       NFI.SEQNOTA = NFITEMAPARTIRDE.SEQNOTAORIGEM AND
                                       NFI.SEQNOTAITEM = NFITEMAPARTIRDE.SEQNOTAITEMORIGEM

                                       INNER JOIN NFCAB NFDV ON
                                       NFDV.ESTAB = NFI.ESTAB AND
                                       NFDV.SEQNOTA = NFI.SEQNOTA

                                       INNER JOIN NFCFG NFCFGDV ON
                                       NFCFGDV.NOTACONF = NFDV.NOTACONF
                                       
                                       inner join nfcfg_u on nfcfg_u.notaconf=NFCFGDV.notaconf
    
                                       inner join u_tipoop on u_tipoop.u_tipoop_id=nfcfg_u.u_tipoop_id
                                                                AND  u_tipoop.tipoop IN ('V','VF','RF')

                                       INNER JOIN NATOPERACAO NATDV ON
                                       NATDV.NATUREZADAOPERACAO = NFCFGDV.NATUREZADAOPERACAO AND
                                       NATDV.ENTRADASAIDA = NFCFGDV.ENTRADASAIDA 
                                       AND NATDV.TIPODCTO IN ('N')

                                       WHERE NFITEM.ESTAB = NFITEMAPARTIRDE.ESTABORIGEM
                                         AND NFITEM.SEQNOTA = NFITEMAPARTIRDE.SEQNOTA
                                         AND NFITEM.SEQNOTAITEM = NFITEMAPARTIRDE.SEQNOTAITEM
                                       )) ) AS CUSTOCMVPDEV  
                                
                
                                        ,*/COALESCE(ORBIA.VENDAORBIA,'N')VENDAORBIA
                                        ,COALESCE(ORBIA.IDORBIA,'N')IDORBIA
                                        ,NFCAB_U.USER_ORIGEM
                                        ,SYSDATE AS Data_At
                                        ,NFCABCANHOTO.CANHOTORECEBIDO    
                                      ,LIMITE.TABPRCESTAB
                                    ,LIMITE.TABPRC
FROM NFCAB
                   
       LEFT JOIN (SELECT NFDESC.ESTAB,
                  NFDESC.SEQNOTA,
                  SUM(NFDESC.VALORDESCONTO) VALOR
            FROM NFDESC
            GROUP BY  NFDESC.ESTAB,
                      NFDESC.SEQNOTA
)DESCONTO

ON NFCAB.ESTAB = DESCONTO.ESTAB
  AND NFCAB.SEQNOTA = DESCONTO.SEQNOTA        

LEFT JOIN (SELECT NFITEMAPARTIRDE.ESTAB,NFITEMAPARTIRDE.SEQNOTA,NFCAB_U.VENDAORBIA,NFCAB_U.IDORBIA FROM NFITEMAPARTIRDE
               LEFT JOIN NFCAB DEV ON DEV.ESTAB = NFITEMAPARTIRDE.ESTABORIGEM
                                    AND DEV.SEQNOTA = NFITEMAPARTIRDE.SEQNOTAORIGEM
                LEFT JOIN NFCAB_U ON NFCAB_U.ESTAB = DEV.ESTAB
                                AND NFCAB_U.SEQNOTA = DEV.SEQNOTA
                                
                    GROUP BY NFITEMAPARTIRDE.ESTAB,NFITEMAPARTIRDE.SEQNOTA,NFCAB_U.VENDAORBIA,NFCAB_U.IDORBIA
                ) ORBIA
                ON NFCAB.ESTAB = ORBIA.ESTAB
                AND NFCAB.SEQNOTA = ORBIA.SEQNOTA             

    INNER JOIN CONTAMOV ON
    CONTAMOV.NUMEROCM = NFCAB.NUMEROCM

    LEFT JOIN ENDERECO ON
    ENDERECO.NUMEROCM = NFCAB.NUMEROCM AND
    ENDERECO.SEQENDERECO = NFCAB.SEQENDERECO

    LEFT JOIN CIDADE ENDCID ON
    ENDCID.CIDADE = ENDERECO.CIDADE

    LEFT JOIN CIDADE PESCID ON
    PESCID.CIDADE = CONTAMOV.CIDADE
    
    INNER JOIN NFITEM ON
    NFCAB.ESTAB = NFITEM.ESTAB AND
    NFCAB.SEQNOTA = NFITEM.SEQNOTA 

    INNER JOIN ITEMAGRO ON
    ITEMAGRO.ITEM   =    NFITEM.ITEM
    AND ITEMAGRO.ITEM > 50

    INNER JOIN ITEMGRUPO ON
    ITEMGRUPO.GRUPO = ITEMAGRO.GRUPO
    
   inner join itemgrupo_u
                on itemgrupo.grupo = itemgrupo_u.grupo

                inner join u_gestoque
                on itemgrupo_u.u_gestoque_id = u_gestoque.u_gestoque_id

               
    LEFT JOIN ITEMMARCA ON ITEMMARCA.MARCA = ITEMAGRO.MARCA
                 
     LEFT JOIN PREPRESE ON
    PREPRESE.REPRESENT = NFCAB.REPRESENT 
       
    INNER JOIN NFCFG ON NFCFG.NOTACONF = NFCAB.NOTACONF
    
      inner join nfcfg_u on nfcfg_u.notaconf=nfcfg.notaconf
    
    inner join u_tipoop on u_tipoop.u_tipoop_id=nfcfg_u.u_tipoop_id
    
    INNER JOIN NATOPERACAO ON  NATOPERACAO.NATUREZADAOPERACAO = NFCFG.NATUREZADAOPERACAO AND
                               NATOPERACAO.ENTRADASAIDA = NFCFG.ENTRADASAIDA 
    
    INNER JOIN FILIAL ON FILIAL.ESTAB = NFCAB.ESTAB
                 
                       
     INNER JOIN U_TEMPRESA ON u_tempresa.estab = FILIAL.ESTAB
                        AND ((u_tempresa.insumos='S') OR (u_tempresa.exvenda='S') or (u_tempresa.estab = 10))                
             
        LEFT JOIN NFCAB_U ON NFCAB_U.ESTAB = NFCAB.ESTAB
                        AND NFCAB_U.SEQNOTA = NFCAB.SEQNOTA
                        
                        
  left join
  
    (
    select distinct
        
    nfitem.estab,
    nfitem.seqnota,
    nfitem.seqnotaitem,
    pduprec.limcred_id,
     PEDCAB.TABPRCESTAB
    ,PEDCAB.TABPRC
   from nfcab

    inner join nfitem on nfitem.estab = nfcab.estab
                    and nfitem.seqnota = nfcab.seqnota
                    
    inner join nfcfg on nfcfg.notaconf = nfcab.notaconf
        
    inner join nfcfg_u on nfcfg_u.notaconf = nfcfg.notaconf
        
    inner join u_tipoop on u_tipoop.u_tipoop_id = nfcfg_u.u_tipoop_id
                       and u_tipoop.tipoop in ('DF-V','DV')

    ------ buscando origem da DEV ou DESF                  
    inner join nfitemapartirde on nfitemapartirde.estab = nfitem.estab
                                and nfitemapartirde.seqnota = nfitem.seqnota
                                and nfitemapartirde.seqnotaitem = nfitem.seqnotaitem
                               
    ----- buscando a nota de VENDA/VF/REMESSA (ORIGEM)
    inner join nfitem nfi on nfi.estab = nfitemapartirde.estaborigem
                    and nfi.seqnota = nfitemapartirde.seqnotaorigem
                    and nfi.seqnotaitem = nfitemapartirde.seqnotaitemorigem
                    
    ---- SE É REMSESA, TEM QUE BUSCAR A VF           
     left join nfitemapartirde apartir on
        apartir.estab = nfi.estab
        and apartir.seqnota = nfi.seqnota
        and apartir.seqnotaitem = nfi.seqnotaitem
        
    LEFT JOIN nfitem nfp on nfp.estab = apartir.estaborigem
                        and nfp.seqnota = apartir.seqnotaorigem
                        and nfp.seqnotaitem = apartir.seqnotaitemorigem
        
    inner join nfcab nf on
        nf.estab = coalesce(nfp.estab,nfi.estab)
        and nf.seqnota = coalesce(nfp.seqnota,nfi.seqnota)
        
    left join peditemnfitem on
        peditemnfitem.estabnota = coalesce(nfp.estab,nfi.estab)
        and peditemnfitem.seqnota = coalesce(nfp.seqnota,nfi.seqnota)
        and peditemnfitem.seqnotaitem = coalesce(nfp.seqnotaitem,nfi.seqnotaitem)
    
    left join pedcab on 
        pedcab.estab = peditemnfitem.estab
        and pedcab.serie = peditemnfitem.serie
        and pedcab.numero = peditemnfitem.numero
        
    left join nfcabagrfin on nfcabagrfin.estab = nf.estab
                    and nfcabagrfin.seqnota = nf.seqnota
    
    left join agrfinduprec on agrfinduprec.estab = nfcabagrfin.estab
                    and agrfinduprec.seqpagamento = nfcabagrfin.seqpagamento
                    
    left join pduprec on pduprec.empresa = agrfinduprec.estab
                and pduprec.duprec = agrfinduprec.duprec
    )LIMITE ON
    LIMITE.ESTAB = NFITEM.ESTAB
    AND LIMITE.SEQNOTA = NFITEM.SEQNOTA
    AND LIMITE.SEQNOTAITEM = NFITEM.SEQNOTAITEM


left join
    (
    select distinct
    nfitemapartirde.estab,
    nfitemapartirde.seqnota,
    nfitemapartirde.seqnotaitem,
    coalesce(peditem.dtentrega,pedcab.dtprevisao)dtentrega
    from nfitemapartirde 
    
    inner join nfitem on
        nfitem.estab = nfitemapartirde.estaborigem
        and nfitem.seqnota = nfitemapartirde.seqnotaorigem
        and nfitem.seqnotaitem = nfitemapartirde.seqnotaitemorigem
    
    inner join peditemnfitem on
        peditemnfitem.estabnota = nfitem.estab
        and peditemnfitem.seqnota = nfitem.seqnota
        and peditemnfitem.seqnotaitem = nfitem.seqnotaitem
        
    inner join peditem on
        peditem.estab = peditemnfitem.estab
        and peditem.serie = peditemnfitem.serie
        and peditem.numero = peditemnfitem.numero
        and peditem.seqpedite = peditemnfitem.seqpedite
    
    inner join pedcab on 
        pedcab.estab = peditem.estab
        and pedcab.serie = peditem.serie
        and pedcab.numero = peditem.numero
    )ped on
    ped.estab = nfitem.estab
    and ped.seqnota = nfitem.seqnota
    and ped.seqnotaitem = nfitem.seqnotaitem
                        
        LEFT JOIN (
            SELECT
    NFITEMAPARTIRDE.estab,
    NFITEMAPARTIRDE.seqnota,
    NFITEMAPARTIRDE.seqnotaitem,
    sum(NFITEMAPARTIRDE.QUANTIDADE *  
    case
    when nf.custocmvp = 0 then nf.custocmv
    when nf.custocmvp <> 0 then nf.custocmvp 
    else nfi.custocmvp end) CUSTOCMVP,
    sum(NFITEMAPARTIRDE.QUANTIDADE * nfi.custocmv) CUSTOCMV,
    sum(nfi.custocmv)cmv
    
    FROM NFITEMAPARTIRDE
                                       
                                       INNER JOIN NFITEM NFI ON
                                       NFI.ESTAB = NFITEMAPARTIRDE.ESTABORIGEM AND
                                       NFI.SEQNOTA = NFITEMAPARTIRDE.SEQNOTAORIGEM AND
                                       NFI.SEQNOTAITEM = NFITEMAPARTIRDE.SEQNOTAITEMORIGEM

                                       INNER JOIN NFCAB NFDV ON
                                       NFDV.ESTAB = NFI.ESTAB AND
                                       NFDV.SEQNOTA = NFI.SEQNOTA

                                       INNER JOIN NFCFG NFCFGDV ON
                                       NFCFGDV.NOTACONF = NFDV.NOTACONF
                                       
                                      inner join nfcfg_u on nfcfg_u.notaconf=NFCFGDV.notaconf
    
                                      inner join u_tipoop on u_tipoop.u_tipoop_id=nfcfg_u.u_tipoop_id
                                       AND  u_tipoop.tipoop IN ('V','VF','RF')

                                       INNER JOIN NATOPERACAO NATDV ON
                                       NATDV.NATUREZADAOPERACAO = NFCFGDV.NATUREZADAOPERACAO AND
                                       NATDV.ENTRADASAIDA = NFCFGDV.ENTRADASAIDA 
                                       AND NATDV.TIPODCTO IN ('N')
                                        
                                       LEFT JOIN NFITEMAPARTIRDE NFAPARTIRDE ON 
                                            NFAPARTIRDE.ESTAB = NFI.ESTAB AND
                                            NFAPARTIRDE.SEQNOTA = NFI.SEQNOTA AND
                                            NFAPARTIRDE.SEQNOTAITEM = NFI.SEQNOTAITEM
                                            
                                        LEFT JOIN NFITEM NF ON NF.ESTAB = NFAPARTIRDE.ESTABORIGEM
                                                            AND NF.SEQNOTA = NFAPARTIRDE.SEQNOTAORIGEM
                                                            AND NF.SEQNOTAITEM = NFAPARTIRDE.SEQNOTAITEMORIGEM
                                                            
                                        INNER JOIN NFCAB  ON
                                       NFCAB.ESTAB = NFITEMAPARTIRDE.ESTAB AND
                                       NFCAB.SEQNOTA = NFITEMAPARTIRDE.SEQNOTA

                                       INNER JOIN NFCFG  ON
                                       NFCFG.NOTACONF = NFCAB.NOTACONF
                                       
                                      inner join nfcfg_u nfcf on nfcf.notaconf=NFCFG.notaconf
    
                                      inner join u_tipoop nfcftp on nfcftp.u_tipoop_id= nfcf.u_tipoop_id
                                       AND  nfcftp.tipoop IN ('DF-V','DV')
                                       
                                       LEFT JOIN U_TEMPRESA ON
                                       U_TEMPRESA.ESTAB =  NFITEMAPARTIRDE.estab
                        
                                       
                                    
                                       
                                        group by
                                        NFITEMAPARTIRDE.estab,
                                        NFITEMAPARTIRDE.seqnota,
                                        NFITEMAPARTIRDE.seqnotaitem
                                        
                                                                  ) CUSTO ON 
                                                                CUSTO.ESTAB = NFITEM.ESTAB AND
                                                                CUSTO.SEQNOTA = NFITEM.SEQNOTA AND
                                                                CUSTO.SEQNOTAITEM = NFITEM.SEQNOTAITEM
                                                                               
         LEFT JOIN NFCABCANHOTO ON
        NFCABCANHOTO.ESTAB = NFCAB.ESTAB
        AND NFCABCANHOTO.SEQNOTA = NFCAB.SEQNOTA               
                        
                        
                        
     
  WHERE   NFCAB.STATUS <> 'C'
          AND  u_tipoop.tipoop IN ('DV','DF-V')

and cast(nfcab.dtemissao as date) >= cast('01/07/2024' as date)
and nfcab.estab not in (5)
--and nfcab.estab not in (5) and nfcab.seqnota = 6132 and nfcab.estab = 48
--and nfcab.estab = 19
         -- and NFCFG.NOTACONF in (2,3,6)
       --  and nfcab.dtemissao = '04/10/2023'
--and nfcab.seqnota in (35151)

--    and nfcab.seqnota not in (34469,34460,34492,34505,34456,34503,34482,34496,34493,34462,34486,34482,34500,34509,34523,34530,34548,34517,34505,34501,34445,34505,34547,34489,34495,34497,34505,34538,34537,34534,34505,34482,34489,34465,34472,34502,34507,34487,34482,34504,34505,34481,34449,34484,34442,34512,34493,34483,34499,34471,34482,34535,34445,34529,34546,34542,34449,34512,34544,34505,34492,34505,34461,34494,34505,34507,34490,34440,34482,34439,34498,34492,34474,34443,34519,34482,34505,34482,34509,34541,34505,34484,34457,34514,34505,34528,34549,34438,34534,34552,34473,34514,34505,34488,34482,34497,34505,34527,34518,34480)          

GROUP BY FILIAL.ESTAB,
          FILIAL.REDUZIDO,    
          NFCAB.DTEMISSAO,
nfcab.dtentsai,
           NFCAB.PRAZOPAGTO,
NFCAB.NOTACONF,
            NFCAB.SEQNOTA,
           NFCAB.NOTA,
           limite.limcred_id,
          NFCAB.NUMEROCM,CONTAMOV.NOME,
          nfcab.seqendereco,
          NFCAB.SEQENDERECO,ENDCID.NOME,
          ENDCID.UF,PESCID.NOME,PESCID.UF,
          itemmarca.marca,itemmarca.descricao,      
          u_gestoque.u_gestoque_id,u_gestoque.descricao, itemagro.unidade,
          NFITEM.SEQNOTAITEM,
		   NFITEM.CULTURAID,
			NFITEM.DIAGNOSTICOID,
          NFITEM.ITEM,ITEMAGRO.DESCRICAO,
          ITEMAGRO.GRUPO,ITEMGRUPO.DESCRICAO,ITEMAGRO.PESOLIQUIDO,
          NFCAB.REPRESENT,
           
          PREPRESE.REPRESENT,PREPRESE.EMPRESA,
          NFITEM.QUANTIDADE, NFITEM.CFOP,ORBIA.VENDAORBIA,ORBIA.IDORBIA,NFCAB_U.USER_ORIGEM,nfcab.dtautorizanfe,PED.DTENTREGA
          ,CUSTO.CUSTOCMV
          ,CUSTO.CUSTOCMVP,NFCABCANHOTO.CANHOTORECEBIDO    
           ,LIMITE.TABPRCESTAB
            ,LIMITE.TABPRC

UNION ALL

SELECT
    FILIAL.ESTAB,
    
    FILIAL.REDUZIDO,
    NFCAB.DTEMISSAO,
nfcab.dtentsai,
    NFCAB.DTEMISSAO AS EMISSAO_ORIGEM,
CAST(nfcab.dtautorizanfe AS TIMESTAMP) as dtautorizanfe,
	NULL DTENTREGA,
    NFCAB.DTEMISSAO AS PRAZOPAGTO,
      NFCAB.SEQNOTA,
       NFCAB.NOTACONF,
      NFCAB.NOTA,
   -- TO_CHAR(NFCAB.DTEMISSAO, 'DD')DIA,
  -- TO_CHAR(NFCAB.DTEMISSAO, 'MM')||'-'||TO_CHAR(NFCAB.DTEMISSAO, 'MON')MES,
    --  TO_CHAR(NFCAB.DTEMISSAO, 'YYYY')ANO,
     NFCAB.NUMEROCM,
    CONTAMOV.NOME AS "NOME_CLIENTE",  
    nfcab.seqendereco,
     itemmarca.marca AS CODMARCA,
     itemmarca.descricao AS DESCMARCA,
     u_gestoque.u_gestoque_id AS CODGESTOQUE,
     u_gestoque.descricao AS DESCESTOQUE,
    CASE WHEN NFCAB.REPRESENT IS NULL THEN 'SR' ELSE PREPRESE.REPRESENT||'#'||PREPRESE.EMPRESA END AS "CODRTV",    
    CASE WHEN NFCAB.SEQENDERECO > 0 THEN ENDCID.NOME||' - '||ENDCID.UF ELSE PESCID.NOME||' - '||PESCID.UF END AS "NOME_CIDADE",
    ITEMAGRO.GRUPO AS CODSUBGR,
    ITEMGRUPO.DESCRICAO AS "DESCSUBGR",  
    NFITEM.SEQNOTAITEM,
    NFITEM.ITEM AS CODITEM,	
	 NFITEM.CULTURAID AS OSCULTURA,
	NFITEM.DIAGNOSTICOID,
    NULL OSCREDC,
	--NULL VENDAORBIA,		
   ITEMAGRO.DESCRICAO AS "DESCITEM",
   itemagro.unidade,      
    NFITEM.CFOP,
    NFITEM.QUANTIDADE,
    0 QTDDEV,
     NFITEM.QUANTIDADE * ITEMAGRO.PESOLIQUIDO AS QTDKGLT,  
     0 QTDDEVKGLT,
  SUM(NFITEM.VALORTOTAL - (DIVIDE(NFITEM.VALORTOTAL, NFCAB.VALORPRODBRUTO) * DESCONTO.VALOR)) as VALOR,
  0 VLRDEV,
  SUM((COALESCE(nfitem.custocmv,0))*(nfitem.quantidade))CUSTOCMV,
  0 as CUSTOCMVNOTA,
  CASE WHEN u_tipoop.tipoop IN ('TS','BP')THEN 0 ELSE
  SUM((COALESCE(nfitem.custocmvp,0))*(nfitem.quantidade))END CUSTOCMVP,
  SUM((COALESCE(PEDITEMMARGEM.CUSTOGERENCIALORI,0))*(nfitem.quantidade)) AS CUSTOCMVPOR,
  0 CUSTOCMVDEV,
  0 CUSTOCMVPDEV,
  'N' AS VENDAORBIA,
  '0' AS IDORBIA
  ,NFCAB_U.USER_ORIGEM,
  SYSDATE AS Data_At
  ,NFCABCANHOTO.CANHOTORECEBIDO    
     ,PEDCAB.TABPRCESTAB
    ,PEDCAB.TABPRC                                                

FROM NFCAB
                   
       LEFT JOIN (SELECT NFDESC.ESTAB,
                  NFDESC.SEQNOTA,
                  SUM(NFDESC.VALORDESCONTO) VALOR
            FROM NFDESC
            GROUP BY  NFDESC.ESTAB,
                      NFDESC.SEQNOTA
)DESCONTO

ON NFCAB.ESTAB = DESCONTO.ESTAB
  AND NFCAB.SEQNOTA = DESCONTO.SEQNOTA        
             

    INNER JOIN CONTAMOV ON
    CONTAMOV.NUMEROCM = NFCAB.NUMEROCM

    LEFT JOIN ENDERECO ON
    ENDERECO.NUMEROCM = NFCAB.NUMEROCM AND
    ENDERECO.SEQENDERECO = NFCAB.SEQENDERECO

    LEFT JOIN CIDADE ENDCID ON
    ENDCID.CIDADE = ENDERECO.CIDADE

    LEFT JOIN CIDADE PESCID ON
    PESCID.CIDADE = CONTAMOV.CIDADE
    
    INNER JOIN NFITEM ON
    NFCAB.ESTAB = NFITEM.ESTAB AND
    NFCAB.SEQNOTA = NFITEM.SEQNOTA 

    LEFT JOIN PEDITEMNFITEM ON PEDITEMNFITEM.ESTABNOTA=NFITEM.ESTAB
                          AND PEDITEMNFITEM.SEQNOTA=NFITEM.SEQNOTA
                          AND PEDITEMNFITEM.SEQNOTAITEM=NFITEM.SEQNOTAITEM
                          
    LEFT JOIN PEDITEM ON
        PEDITEM.ESTAB= PEDITEMNFITEM.ESTAB
                           AND  PEDITEM.SERIE=PEDITEMNFITEM.SERIE
                           AND PEDITEM.NUMERO=PEDITEMNFITEM.NUMERO
                           AND PEDITEM.SEQPEDITE=PEDITEMNFITEM.SEQPEDITE
                           
    LEFT JOIN PEDCAB ON
        PEDCAB.ESTAB = PEDITEM.ESTAB
        AND PEDCAB.SERIE = PEDITEM.SERIE
        AND PEDCAB.NUMERO = PEDITEM.NUMERO
                          
    LEFT JOIN PEDITEMMARGEM ON  PEDITEMMARGEM.ESTAB= PEDITEMNFITEM.ESTAB
                           AND  PEDITEMMARGEM.SERIE=PEDITEMNFITEM.SERIE
                           AND PEDITEMMARGEM.NUMERO=PEDITEMNFITEM.NUMERO
                           AND PEDITEMMARGEM.SEQPEDITE=PEDITEMNFITEM.SEQPEDITE

    INNER JOIN ITEMAGRO ON
    ITEMAGRO.ITEM   =    NFITEM.ITEM
    AND ITEMAGRO.ITEM > 50

    INNER JOIN ITEMGRUPO ON
    ITEMGRUPO.GRUPO = ITEMAGRO.GRUPO
    
   inner join itemgrupo_u
                on itemgrupo.grupo = itemgrupo_u.grupo

                inner join u_gestoque
                on itemgrupo_u.u_gestoque_id = u_gestoque.u_gestoque_id

               
    LEFT JOIN ITEMMARCA ON ITEMMARCA.MARCA = ITEMAGRO.MARCA
                 
     LEFT JOIN PREPRESE ON
    PREPRESE.REPRESENT = NFCAB.REPRESENT 
       
    INNER JOIN NFCFG ON NFCFG.NOTACONF = NFCAB.NOTACONF
    
    inner join nfcfg_u on nfcfg_u.notaconf=nfcfg.notaconf
    
    inner join u_tipoop on u_tipoop.u_tipoop_id=nfcfg_u.u_tipoop_id
    
    INNER JOIN NATOPERACAO ON  NATOPERACAO.NATUREZADAOPERACAO = NFCFG.NATUREZADAOPERACAO AND
                               NATOPERACAO.ENTRADASAIDA = NFCFG.ENTRADASAIDA 
    
    INNER JOIN FILIAL ON FILIAL.ESTAB = NFCAB.ESTAB
                 
                       
     INNER JOIN U_TEMPRESA ON u_tempresa.estab = FILIAL.ESTAB
                        AND ((u_tempresa.insumos='S') OR (u_tempresa.exvenda='S') or (u_tempresa.estab = 10))     
                        
       LEFT JOIN NFCAB_U ON NFCAB_U.ESTAB = NFCAB.ESTAB
                        AND NFCAB_U.SEQNOTA = NFCAB.SEQNOTA
                        
        LEFT JOIN NFCABCANHOTO ON
        NFCABCANHOTO.ESTAB = NFCAB.ESTAB
        AND NFCABCANHOTO.SEQNOTA = NFCAB.SEQNOTA     
     
  WHERE  NFCAB.STATUS <> 'C'
         AND  u_tipoop.tipoop IN ('BP','BS')
and nfcab.estab not in (5)

 and cast(nfcab.dtemissao as date) >= cast('01/07/2024' as date)
         
         GROUP BY FILIAL.ESTAB,
          FILIAL.REDUZIDO,    
          NFCAB.DTEMISSAO,
            nfcab.dtentsai,
           NFCAB.PRAZOPAGTO,
          NFCAB.NOTACONF,
           NFCAB.NOTA,
             NFCAB.SEQNOTA,
          NFCAB.NUMEROCM,CONTAMOV.NOME,
          nfcab.seqendereco,
          NFCAB.SEQENDERECO,ENDCID.NOME,
          ENDCID.UF,PESCID.NOME,PESCID.UF,
          NFITEM.SEQNOTAITEM,
		   NFITEM.CULTURAID,
			NFITEM.DIAGNOSTICOID,
          itemmarca.marca,itemmarca.descricao, itemagro.unidade,      
          u_gestoque.u_gestoque_id,u_gestoque.descricao,
          NFITEM.ITEM,ITEMAGRO.DESCRICAO,ITEMAGRO.PESOLIQUIDO,
          ITEMAGRO.GRUPO,ITEMGRUPO.DESCRICAO,
          NFCAB.REPRESENT,
          PREPRESE.REPRESENT,PREPRESE.EMPRESA,
          
          NFITEM.QUANTIDADE,NFITEM.CFOP,
          u_tipoop.tipoop,NFCAB_U.USER_ORIGEM,nfcab.dtautorizanfe,NFCABCANHOTO.CANHOTORECEBIDO    
        ,PEDCAB.TABPRCESTAB
        ,PEDCAB.TABPRC 
    
)DADOS
