WITH  NFCAB_FILTRADA AS (
    SELECT *
    FROM NFCAB
    WHERE DTENTSAI BETWEEN :DTINICIAL AND :DTFINAL
      AND STATUS <> 'C'
),

SIEG AS (
    SELECT
    CHAVEACESSONFE,
    ESTAB,
    NOTA,
    CNPJ_EMITENTE,
    IE,
    CMUN,
    SUM(VNF) AS VNF
    FROM U_NOTASSIEG
    
    GROUP BY
    CHAVEACESSONFE,
    ESTAB,NOTA,
    CNPJ_EMITENTE,
    IE,
    CMUN
),

CIDADES AS (
    SELECT
    CIDADE,
    (CASE 
    WHEN LENGTH(cidade.IBGE) = 3 THEN UF.CODIGO||'00'||cidade.IBGE 
    WHEN LENGTH(cidade.IBGE) = 4 THEN UF.CODIGO||'0'||cidade.IBGE
    WHEN LENGTH(cidade.IBGE) = 2 THEN UF.CODIGO||'000'||cidade.IBGE 
    WHEN LENGTH(cidade.IBGE) = 1 THEN UF.CODIGO||'0000'||cidade.IBGE            
    ELSE UF.CODIGO||''||cidade.IBGE 
    END) CODCID
    FROM CIDADE
    LEFT JOIN UF ON UF.UF = CIDADE.UF
),

SIEG_ITENS AS (
    SELECT
    ESTAB,
    CHAVE,
    SEQNOTAITEM,
    CFOP,
    UNIDADE,
    LPAD(NCM,4) AS NCM,
    (CASE WHEN LENGTH(icmscdcst) >=4 THEN '9999' ELSE icmscdcst END) CST_ICMS,
 --   icmscdcst AS CST_ICMS,
    icmsbase,
    icmstaxa AS ALIQUOTA_ICMS,
    piscdcst AS CST_PIS,
    pistaxa AS ALIQUOTA_PIS,
    cofinscdcst AS CST_COFINS,
    cofinstaxa AS ALIQUOTA_COFINS,
    PISVALOR,
    COFINSVALOR
    FROM U_NOTASSIEG_ITENS 
    
),

PRODUTOR AS (
    SELECT
        NUMEROCM,
        CIDADE,
        inscestad,
        CASE WHEN PRODUTOR = 'S' THEN 'PRODUTOR' ELSE 'EMPRESA' END AS TIPO
    FROM CONTAMOV
),

ENDERECOS AS (
    SELECT
        NUMEROCM,
        SEQENDERECO,
        CIDADE,
        credencialagro,
        CASE WHEN PRODUTORend = 'S' THEN 'PRODUTOR' ELSE 'EMPRESA' END AS TIPO
    FROM ENDERECO
),
/*
IMPOSTOS AS (
    SELECT
    ESTAB,
    SEQNOTA,
    SEQNOTAITEM,
    MAX(CASE WHEN IMPOSTO = 1 THEN CST END) CST_ICMS,
    MAX(CASE WHEN IMPOSTO = 4 THEN CST END) CST_PIS,
    MAX(CASE WHEN IMPOSTO = 5 THEN CST END) CST_COFINS,
    MAX(CASE WHEN IMPOSTO = 4 THEN ALIQUOTA END) ALIQUOTA_PIS,
    MAX(CASE WHEN IMPOSTO = 5 THEN ALIQUOTA  END) ALIQUOTA_COFINS,
    MAX(CASE WHEN IMPOSTO = 1 THEN ALIQUOTA END) ALIQUOTA_ICMS
    FROM NFITEMIMPOSTO

    WHERE
    imposto in (1,4,5)

    GROUP BY
    ESTAB,
    SEQNOTA,
    SEQNOTAITEM
),*/

ICMS AS (
    SELECT
    ESTAB,
    SEQNOTA,
    SEQNOTAITEM,
    IMPOSTO,
    CST,
    ALIQUOTA,
    BASETRIBUTADA,
    VALORIMPOSTO
    FROM NFITEMIMPOSTO
    WHERE IMPOSTO = 1
),

PIS AS (
    SELECT
    ESTAB,
    SEQNOTA,
    SEQNOTAITEM,
    IMPOSTO,
    CST,
    ALIQUOTA,
    BASETRIBUTADA,
    VALORIMPOSTO
    FROM NFITEMIMPOSTO
    WHERE IMPOSTO = 4
),

COFINS AS (
    SELECT
    ESTAB,
    SEQNOTA,
    SEQNOTAITEM,
    IMPOSTO,
    CST,
    ALIQUOTA,
    BASETRIBUTADA,
    VALORIMPOSTO
    FROM NFITEMIMPOSTO
    WHERE IMPOSTO = 5
),

ITENS_MARCADOS AS (
    SELECT distinct
        ITEM,
        1 AS FLAG_REGRADO
    FROM U_REGRAS_NOTA
),

NCM_MARCADOS AS (
    SELECT DISTINCT
    NCM,
    1 AS FLAG_REGRADO
    FROM U_REGRAS_NOTA
)
select
*
from(
SELECT DISTINCT
coalesce(ENDE.TIPO,MOV.TIPO) as tipo,
--R.UF AS UF_2,
CID.UF,
NFCAB.ESTAB,
NFCAB.NOTA,
--NF.SEQNOTA,
NFCAB.NUMEROCM,
COALESCE(NFCAB.SEQENDERECO,0)SEQENDERECO,
--nfcab.notaconf,
--ITEMAGRO.ITEM,
LPAD(ITEMAGRO.NCM,4) AS NCM_NOTA,
SIEG_ITENS.NCM AS NCM_FISCALIO,
----- valida cfop
SIEG_ITENS.CFOP AS CFOP_FISCALIO,
NFI.CFOP as CFOP_NOTA,
cfopos as CFOP_REGRA,
CASE
        when R.UF is null then 'S' 
        WHEN INSTR(',' || REPLACE(cfopos, ' ', '')|| ',', ',' || TO_CHAR(NFI.CFOP) || ',') > 0 THEN 'N'
        ELSE 'S'
    END AS DIF_CFOP,
---- valida cst icms
SIEG_ITENS.CST_ICMS AS CST_ICMS_FISCALIO,
ICMS.CST AS CST_ICMS_NOTA,
R.CSTOS AS CST_REGRA,
CASE WHEN R.CSTOS IS NULL THEN 'S'
    when cast(R.CSTOS as number) <> cast(ICMS.CST as number) THEN 'S' 
    ELSE 'N' END DIF_CST,
CASE
    when R.UF is null then 'S' 
    WHEN SUBSTR(SIEG_ITENS.CST_ICMS,-2) IN ('00','20') and icmsbase <> icms.basetributada then 'S'
    ELSE 'N'
end DIF_BASE_CST,
------ valida cst piscofins
SIEG_ITENS.CST_PIS AS CST_PIS_FISCALIO,
SIEG_ITENS.CST_COFINS AS CST_COFINS_FISCALIO,
pis.CST as CST_PIS_NOTA,
COFINS.CST as CST_COFINS_NOTA,
R.CSTPISCOFINSOS as REGRA_CST_PISCOFINS,
CASE when R.UF is null then 'S' 
    when  R.CSTPISCOFINSOS is null or R.CSTPISCOFINSOS is null then 'S'
    WHEN R.CSTPISCOFINSOS <> PIS.CST OR R.CSTPISCOFINSOS <> COFINS.CST THEN 'S' 
ELSE 'N' END DIF_CST_PISCONFIS,
----- VALIDA CALCULO PISCONFIS CST 50
PIS.ALIQUOTA AS ALIQUOTA_PIS_NOTA,
COFINS.ALIQUOTA AS ALIQUOTA_COFINS_NOTA,
CASE
    when R.UF is null then 'S' 
    WHEN (SIEG_ITENS.CST_PIS <> '50' OR SIEG_ITENS.CST_COFINS <> '50') THEN 'N'
    WHEN (SIEG_ITENS.CST_PIS = '50' OR SIEG_ITENS.CST_COFINS = '50') AND (PIS.BASETRIBUTADA * 0.0925) = PIS.VALORIMPOSTO THEN 'N'
    WHEN (SIEG_ITENS.CST_PIS = '50' OR SIEG_ITENS.CST_COFINS = '50') AND (PIS.BASETRIBUTADA * 0.0925) <> PIS.VALORIMPOSTO THEN 'S'
END DIF_CST_50_PISCOFINS,
---- VALIDA VALOR PIS COFINS
CASE 
    when R.UF is null then 'S' 
    WHEN SIEG_ITENS.COFINSVALOR > 0 AND COALESCE(COFINS.VALORIMPOSTO,0) = 0 THEN 'S'
    WHEN SIEG_ITENS.PISVALOR > 0 AND COALESCE(PIS.VALORIMPOSTO,0) = 0 THEN 'S'
    ELSE 'N'
END DIF_VLR_PISCOFINS,
----- valida valor
case when arredondar(nf.valor,0) <> arredondar(SIEG.VNF,0) then 'S' else 'N' end dif_valor,
------- valida cidade
CIDADES.CODCID AS cidade_nota,
SIEG.CMUN as cidade_fiscalio, 
CASE WHEN CIDADES.CODCID <> SIEG.CMUN THEN 'S' ELSE 'N' END DIF_CID,
----- valida inscrição estudal
coalesce(trim(ende.credencialagro),trim(MOV.inscestad)) as IE_NOTA,
(SIEG.ie) AS IE_FISCALIO,
--case when coalesce(trim(ende.credencialagro),trim(MOV.inscestad)) <> cast(SIEG.ie as number) then 'S' ELSE 'N' end dif_ie,
CASE
  WHEN REGEXP_LIKE(coalesce(trim(ende.credencialagro), trim(MOV.inscestad)), '^\d+$') 
       AND REGEXP_LIKE(SIEG.ie, '^\d+$')
       AND TO_NUMBER(coalesce(trim(ende.credencialagro), trim(MOV.inscestad))) <> TO_NUMBER(SIEG.ie)
  THEN 'S'
  ELSE 'N'
END AS DIF_IE/*,
nfcab.chaveacessonfe,
nf.chaveacessonfe as chave_2,
NFCABPRODUTOR.CHAVEACESSONFP*/
FROM NFCAB_FILTRADA NFCAB

INNER JOIN FILIAL ON FILIAL.ESTAB = NFCAB.ESTAB
INNER JOIN CIDADE CID ON CID.CIDADE = FILIAL.CIDADE
INNER JOIN U_TEMPRESA ON U_TEMPRESA.ESTAB = FILIAL.ESTAB

INNER JOIN NFITEM ON
    NFITEM.ESTAB = NFCAB.ESTAB
    AND NFITEM.SEQNOTA = NFCAB.SEQNOTA

INNER JOIN ITEMAGRO ON ITEMAGRO.ITEM = NFITEM.ITEM

INNER JOIN NFCFG ON NFCFG.NOTACONF = NFCAB.NOTACONF
            AND NFCFG.FISCAL = 'S'
            AND NFCFG.ENTRADASAIDA = 'E'

INNER JOIN NFCFG_U ON NFCFG_U.NOTACONF = NFCFG.NOTACONF

INNER JOIN U_TIPOOP ON U_TIPOOP.U_TIPOOP_ID = NFCFG_U.U_TIPOOP_ID

----- TUDO EM RELAÇÃO A NOTA DO PRODUTOR
LEFT JOIN NFCABPRODUTOR ON
    NFCABPRODUTOR.ESTAB = NFCAB.ESTAB
    AND NFCABPRODUTOR.SEQNOTA = NFCAB.SEQNOTA

INNER JOIN NFCAB NF ON NF.ESTAB = NFCABPRODUTOR.ESTAB
            AND CAST(NF.NOTA AS VARCHAR(15))= NFCABPRODUTOR.NFPRODUTOR
            AND NF.NUMEROCM = NFCAB.NUMEROCM

INNER JOIN NFITEM NFI ON 
    NFI.ESTAB = NF.ESTAB
    AND NFI.SEQNOTA = NF.SEQNOTA

LEFT JOIN NFCFG CFG ON CFG.NOTACONF = NF.NOTACONF

LEFT JOIN PRODUTOR MOV ON MOV.NUMEROCM = NF.NUMEROCM

LEFT JOIN ENDERECOS ENDE ON ENDE.NUMEROCM = NF.NUMEROCM
                    AND ENDE.SEQENDERECO = NF.SEQENDERECO

LEFT JOIN CIDADES ON CIDADES.CIDADE = COALESCE(ENDE.CIDADE,MOV.CIDADE)

INNER JOIN SIEG ON SIEG.ESTAB = NF.ESTAB
                    AND SIEG.NOTA = NF.NOTA
                    AND SIEG.CHAVEACESSONFE = NFCABPRODUTOR.CHAVEACESSONFP --,NF.CHAVEACESSONFE)

LEFT JOIN ICMS ON
    ICMS.ESTAB = NFI.ESTAB
    AND ICMS.SEQNOTA = NFI.SEQNOTA
    AND ICMS.SEQNOTAITEM = NFI.SEQNOTAITEM

LEFT JOIN PIS ON
    PIS.ESTAB = NFI.ESTAB
    AND PIS.SEQNOTA = NFI.SEQNOTA
    AND PIS.SEQNOTAITEM = NFI.SEQNOTAITEM

LEFT JOIN COFINS ON
    COFINS.ESTAB = NFI.ESTAB
    AND COFINS.SEQNOTA = NFI.SEQNOTA
    AND COFINS.SEQNOTAITEM = NFI.SEQNOTAITEM

INNER JOIN SIEG_ITENS ON
    NFI.ESTAB = SIEG_ITENS.ESTAB
 --   AND NFI.SEQNOTAITEM = SIEG_ITENS.SEQNOTAITEM
   -- AND /*coalesce(NFCABPRODUTOR.CHAVEACESSONFP,NF.CHAVEACESSONFE)= SIEG_ITENS.CHAVE
      AND NFCABPRODUTOR.CHAVEACESSONFP = SIEG_ITENS.CHAVE

LEFT JOIN ITENS_MARCADOS MARC ON MARC.ITEM = NFI.ITEM
LEFT JOIN NCM_MARCADOS NCM_MARC ON NCM_MARC.NCM = SIEG_ITENS.NCM

LEFT JOIN OS_REGRA_NOTA_2 R ON
    R.UF = CID.UF
    AND R.ITEM = COALESCE(MARC.ITEM,0)
    AND R.CFOPFORNECEDOR = SIEG_ITENS.CFOP
    AND R.NCM = COALESCE(NCM_MARC.NCM,'0')--SIEG_ITENS.NCM
    AND CAST(R.CSTFORNECEDOR AS NUMBER) = CAST(SIEG_ITENS.CST_ICMS AS NUMBER)
    AND TRIM(R.ORIGEM) = TRIM(coalesce(ENDE.TIPO,MOV.TIPO))
    AND CAST(R.CSTPISCOFIS AS NUMBER) =  CAST(CASE WHEN LENGTH(SIEG_ITENS.CST_ICMS)>=4 THEN '0' ELSE (SIEG_ITENS.CST_PIS) END AS NUMBER)

WHERE
U_TEMPRESA.GRAOS = 'S'
AND NOT (CID.UF = 'MG' and (nf.notaconf = 320 OR NFCAB.NOTACONF = 320))
AND (NFCAB.ESTAB IN (:ESTAB) OR 0 IN (:ESTAB))
AND (CID.UF IN (:UF) OR 'X' IN (:UF))
UNION ALL


SELECT DISTINCT
coalesce(ENDE.TIPO,MOV.TIPO) as tipo,
--R.UF AS UF_2,
CID.UF,
NFCAB.ESTAB,
NFCAB.NOTA,
--NF.SEQNOTA,
NFCAB.NUMEROCM,
COALESCE(NFCAB.SEQENDERECO,0)SEQENDERECO,
--nfcab.notaconf,
--ITEMAGRO.ITEM,
LPAD(ITEMAGRO.NCM,4) AS NCM_NOTA,
SIEG_ITENS.NCM AS NCM_FISCALIO,
----- valida cfop
 SIEG_ITENS.CFOP AS CFOP_FISCALIO,
NFI.CFOP as CFOP_NOTA,
'1949' as CFOP_REGRA,
CASE
        when NFI.CFOP <> '1949' THEN 'S'
        ELSE 'N'
    END AS DIF_CFOP,
---- valida cst icms
SIEG_ITENS.CST_ICMS AS CST_ICMS_FISCALIO,
ICMS.CST AS CST_ICMS_NOTA,
'41' AS CST_REGRA,
CASE 
    when 90 <> cast(ICMS.CST as number) THEN 'S' 
    ELSE 'N' END DIF_CST,
    
CASE
    WHEN SUBSTR(SIEG_ITENS.CST_ICMS,-2) IN ('00','20') and icmsbase <> icms.basetributada then 'S'
    ELSE 'N'
end DIF_BASE_CST,
------ valida cst piscofins
SIEG_ITENS.CST_PIS AS CST_PIS_FISCALIO,
SIEG_ITENS.CST_COFINS AS CST_COFINS_FISCALIO,
pis.CST as CST_PIS_NOTA,
COFINS.CST as CST_COFINS_NOTA,
'98' as REGRA_CST_PISCOFINS,
CASE 
    WHEN 98 <> TO_NUMBER(PIS.CST) OR TO_NUMBER(COFINS.CST) <> 98 THEN 'S' 
ELSE 'N' END DIF_CST_PISCONFIS,
----- VALIDA CALCULO PISCONFIS CST 50
PIS.ALIQUOTA AS ALIQUOTA_PIS_NOTA,
COFINS.ALIQUOTA AS ALIQUOTA_COFINS_NOTA,
CASE
    WHEN (SIEG_ITENS.CST_PIS <> '50' OR SIEG_ITENS.CST_COFINS <> '50') THEN 'N'
    WHEN (SIEG_ITENS.CST_PIS = '50' OR SIEG_ITENS.CST_COFINS = '50') AND (PIS.BASETRIBUTADA * 0.0925) = PIS.VALORIMPOSTO THEN 'N'
    WHEN (SIEG_ITENS.CST_PIS = '50' OR SIEG_ITENS.CST_COFINS = '50') AND (PIS.BASETRIBUTADA * 0.0925) <> PIS.VALORIMPOSTO THEN 'S'
END DIF_CST_50_PISCOFINS,
---- VALIDA VALOR PIS COFINS
CASE 
    WHEN SIEG_ITENS.COFINSVALOR > 0 AND COALESCE(COFINS.VALORIMPOSTO,0) = 0 THEN 'S'
    WHEN SIEG_ITENS.PISVALOR > 0 AND COALESCE(PIS.VALORIMPOSTO,0) = 0 THEN 'S'
    ELSE 'N'
END DIF_VLR_PISCOFINS,
----- valida valor
case when arredondar(nf.valor,0) <> arredondar(SIEG.VNF,0) then 'S' else 'N' end dif_valor,
------- valida cidade
CIDADES.CODCID AS cidade_nota,
SIEG.CMUN as cidade_fiscalio, 
CASE WHEN CIDADES.CODCID <> SIEG.CMUN THEN 'S' ELSE 'N' END DIF_CID,
----- valida inscrição estudal
coalesce(trim(ende.credencialagro),trim(MOV.inscestad)) as IE_NOTA,
(SIEG.ie)  AS IE_FISCALIO,
CASE
  WHEN REGEXP_LIKE(coalesce(trim(ende.credencialagro), trim(MOV.inscestad)), '^\d+$') 
       AND REGEXP_LIKE(SIEG.ie, '^\d+$')
       AND TO_NUMBER(coalesce(trim(ende.credencialagro), trim(MOV.inscestad))) <> TO_NUMBER(SIEG.ie)
  THEN 'S'
  ELSE 'N'
END AS DIF_IE
/*,
--case when cast(coalesce(trim(ende.credencialagro),trim(MOV.inscestad)) as number) <> cast(SIEG.ie as number) then 'S' ELSE 'N' end dif_ie,
nfcab.chaveacessonfe,
nf.chaveacessonfe as chave_2,
NFCABPRODUTOR.CHAVEACESSONFP*/
FROM NFCAB_FILTRADA NFCAB

INNER JOIN FILIAL ON FILIAL.ESTAB = NFCAB.ESTAB
INNER JOIN CIDADE CID ON CID.CIDADE = FILIAL.CIDADE
INNER JOIN U_TEMPRESA ON U_TEMPRESA.ESTAB = FILIAL.ESTAB

INNER JOIN NFITEM ON
    NFITEM.ESTAB = NFCAB.ESTAB
    AND NFITEM.SEQNOTA = NFCAB.SEQNOTA

INNER JOIN ITEMAGRO ON ITEMAGRO.ITEM = NFITEM.ITEM

INNER JOIN NFCFG ON NFCFG.NOTACONF = NFCAB.NOTACONF
            AND NFCFG.FISCAL = 'S'
            AND NFCFG.ENTRADASAIDA = 'E'

INNER JOIN NFCFG_U ON NFCFG_U.NOTACONF = NFCFG.NOTACONF

INNER JOIN U_TIPOOP ON U_TIPOOP.U_TIPOOP_ID = NFCFG_U.U_TIPOOP_ID

----- TUDO EM RELAÇÃO A NOTA DO PRODUTOR
LEFT JOIN NFCABPRODUTOR ON
    NFCABPRODUTOR.ESTAB = NFCAB.ESTAB
    AND NFCABPRODUTOR.SEQNOTA = NFCAB.SEQNOTA

INNER JOIN NFCAB NF ON NF.ESTAB = NFCABPRODUTOR.ESTAB
            AND CAST(NF.NOTA AS VARCHAR(15))= NFCABPRODUTOR.NFPRODUTOR
            AND NF.NUMEROCM = NFCAB.NUMEROCM

INNER JOIN NFITEM NFI ON 
    NFI.ESTAB = NF.ESTAB
    AND NFI.SEQNOTA = NF.SEQNOTA

LEFT JOIN NFCFG CFG ON CFG.NOTACONF = NF.NOTACONF

LEFT JOIN PRODUTOR MOV ON MOV.NUMEROCM = NF.NUMEROCM

LEFT JOIN ENDERECOS ENDE ON ENDE.NUMEROCM = NF.NUMEROCM
                    AND ENDE.SEQENDERECO = NF.SEQENDERECO

LEFT JOIN CIDADES ON CIDADES.CIDADE = COALESCE(ENDE.CIDADE,MOV.CIDADE)

INNER JOIN SIEG ON SIEG.ESTAB = NF.ESTAB
                    AND SIEG.NOTA = NF.NOTA
                    AND SIEG.CHAVEACESSONFE = NFCABPRODUTOR.CHAVEACESSONFP --,NF.CHAVEACESSONFE)

LEFT JOIN ICMS ON
    ICMS.ESTAB = NFI.ESTAB
    AND ICMS.SEQNOTA = NFI.SEQNOTA
    AND ICMS.SEQNOTAITEM = NFI.SEQNOTAITEM

LEFT JOIN PIS ON
    PIS.ESTAB = NFI.ESTAB
    AND PIS.SEQNOTA = NFI.SEQNOTA
    AND PIS.SEQNOTAITEM = NFI.SEQNOTAITEM

LEFT JOIN COFINS ON
    COFINS.ESTAB = NFI.ESTAB
    AND COFINS.SEQNOTA = NFI.SEQNOTA
    AND COFINS.SEQNOTAITEM = NFI.SEQNOTAITEM

INNER JOIN SIEG_ITENS ON
    NFI.ESTAB = SIEG_ITENS.ESTAB
 --   AND NFI.SEQNOTAITEM = SIEG_ITENS.SEQNOTAITEM
    AND /*coalesce(*/NFCABPRODUTOR.CHAVEACESSONFP/*,NF.CHAVEACESSONFE)*/ = SIEG_ITENS.CHAVE

LEFT JOIN ITENS_MARCADOS MARC ON MARC.ITEM = NFI.ITEM
LEFT JOIN NCM_MARCADOS NCM_MARC ON NCM_MARC.NCM = SIEG_ITENS.NCM

WHERE
U_TEMPRESA.GRAOS = 'S'
AND  (CID.UF = 'MG' and (nf.notaconf = 320 OR NFCAB.NOTACONF = 320))
AND (NFCAB.ESTAB IN (:ESTAB) OR 0 IN (:ESTAB))
AND (CID.UF IN (:UF) OR 'X' IN (:UF))
AND coalesce(ENDE.TIPO,MOV.TIPO) = 'PRODUTOR'
)

WHERE
DIF_CFOP = 'S'
OR 
DIF_CST = 'S'
OR
DIF_BASE_CST = 'S'
OR
DIF_CST_PISCONFIS = 'S'
OR
DIF_CST_50_PISCOFINS = 'S'
OR
DIF_VLR_PISCOFINS = 'S'
OR
dif_valor = 'S'
OR
DIF_CID = 'S'
OR
DIF_IE = 'S'
