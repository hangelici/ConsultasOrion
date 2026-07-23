WITH DPL AS (
    SELECT
    EMPRESA,
    DUPREC,
    SEQRECBTO,
    (VALOR) AS VALOR
    FROM PRDUPRED

    UNION ALL
    
    SELECT
    EMPRESA,
    DUPREC,
    SEQRECBTO,
    (VLRCHEQREC) AS VALOR
    FROM PRDURECH
    
    
    UNION ALL
    
    SELECT
    EMPRESA,
    DUPREC,
    SEQRECBTO,
    VALOR
    FROM PRDUREDUP
    
    UNION ALL
    
    SELECT
    EMPRESA,
    DUPREC,
    SEQRECBTO,
    VALOR
    FROM PRDURECAR
    
    UNION ALL
    
    SELECT
    EMPRESA,
    DUPREC,
    SEQRECBTO,
    VALOR
    FROM PRDUREOUT
    
    UNION ALL
    
    SELECT
    EMPRESA,
    DUPREC,
    SEQRECBTO,
    VALOR
    FROM PRDURECM
    WHERE TROCO = 'N'
    
),

BAIXAS_DPL AS (

    SELECT
    EMPRESA,
    DUPREC,
    SEQRECBTO,
    SUM(VALOR) AS VALOR
    FROM DPL

    GROUP BY EMPRESA,DUPREC,SEQRECBTO

), 

BAIXAS AS (
    SELECT
    PRDUPREC.EMPRESA,
    PRDUPREC.DUPREC,
    SUM(BAIXAS_DPL.VALOR) AS VLR,
    SUM(PRDUPREC.VALOR * CASE WHEN PRDUPREC.TIPOREC IN ('R','J') THEN 1 ELSE -1 END) AS PAGO,
    SUM(CASE WHEN PRDUPREC.TIPOREC IN ('J') THEN BAIXAS_DPL.VALOR ELSE 0 END) JUROS,
    SUM(CASE WHEN PRDUPREC.TIPOREC IN ('R') THEN BAIXAS_DPL.VALOR ELSE 0 END) REC
    FROM PRDUPREC
    
    INNER JOIN BAIXAS_DPL ON 
        BAIXAS_DPL.EMPRESA = PRDUPREC.EMPRESA
        AND BAIXAS_DPL.DUPREC = PRDUPREC.DUPREC
        and BAIXAS_DPL.SEQRECBTO= PRDUPREC.SEQRECBTO

    WHERE TIPOREC IN ('R','J')
    AND DTRECBTO <= :DTBASE
   
    GROUP BY PRDUPREC.EMPRESA,PRDUPREC.DUPREC
),

CTRNOTA AS
    (
    SELECT DISTINCT
    AGRFINDUPREC.ESTAB,
    AGRFINDUPREC.DUPREC,
    NFITEM.ESTABCONTRATO,
    NFITEM.CONTRATO
    FROM AGRFINDUPREC
    
     LEFT JOIN NFCABAGRFIN
        ON (AGRFINDUPREC.ESTAB = NFCABAGRFIN.ESTAB)
       AND (AGRFINDUPREC.SEQPAGAMENTO = NFCABAGRFIN.SEQPAGAMENTO)
       
    LEFT JOIN NFITEM
        ON (NFCABAGRFIN.ESTAB = NFITEM.ESTAB)
        AND (NFCABAGRFIN.SEQNOTA = NFITEM.SEQNOTA)
),
REAJ_ANT AS (
    SELECT
        ESTAB,
        DUPREC,
        DTREAJUSTE,
        VALORATU,
        VALORREAJ,
        ROW_NUMBER() OVER (PARTITION BY ESTAB, DUPREC ORDER BY DTREAJUSTE DESC) AS RN
    FROM
        PDUPRECREAJ
    WHERE
        CAST(DTREAJUSTE AS DATE) <= CAST(:DTBASE AS DATE) 
),

REAJ_MAX AS (
    SELECT
        ESTAB,
        DUPREC,
        DTREAJUSTE,
        VALORATU,
        VALORREAJ,
        ROW_NUMBER() OVER (PARTITION BY ESTAB, DUPREC ORDER BY DTREAJUSTE DESC) AS RN
    FROM
        PDUPRECREAJ
    WHERE
        CAST(DTREAJUSTE AS DATE) >= CAST(:DTBASE AS DATE) 
),

DUP_REAJ AS (
   SELECT 
      RM.ESTAB,
      RM.DUPREC,
      CASE 
         -- Se a data de posição for menor que a data do reajuste, e não houver registro em REAJ_ANT,
         -- usa o VALORATU (valor antes do reajuste) de RM; caso haja RA, você pode optar por usar
         -- o VALORREAJ de RA se isso for o desejado. Aqui, por exemplo, usamos NVL para usar RA.VALORREAJ se existir;
         -- se não, usamos RM.VALORATU.
         WHEN CAST(:DTBASE AS DATE) < RM.DTREAJUSTE THEN NVL(RA.VALORREAJ, RM.VALORATU)
         ELSE RM.VALORREAJ
      END AS VALORREAJ
   FROM 
      (SELECT * FROM REAJ_MAX WHERE RN = 1) RM
   LEFT JOIN
      (SELECT * FROM REAJ_ANT WHERE RN = 1) RA
      ON RM.ESTAB = RA.ESTAB AND RM.DUPREC = RA.DUPREC
)













select
DADOS1.ESTAB,
DADOS1.TIPO_FILIAL,
DADOS1.FILIAL,
DADOS1.NUMEROCM,
--DADOS1.PF_PJ,
DADOS1.TIPO_CLIENTE,
DADOS1.CNPJF,
DADOS1.CLIENTE,
DADOS1.TIPO_DOC,
DADOS1.desc_tipo,
DADOS1.DOCUMENTO,
dados1.status,
DADOS1.PARCELA,
DADOS1.DTEMISSAO,
DADOS1.ANO,
DADOS1.MES,
DADOS1.dtvencto,
DADOS1.ATRASO,
DADOS1.aging,
case when TIPO_DOC in ('ACB','AC','DDVE','AC','ACB','ACC','ACV','DUPP','IMEC','TFDP') THEN DADOS1.VALOR *-1 ELSE DADOS1.VALOR END VALOR,
/*case when TIPO_DOC in ('ACB','AC','DDVE') THEN DADOS1.juros *-1 ELSE DADOS1.juros END juros,*/
(case when TIPO_DOC in ('ACB','AC','DDVE','AC','ACB','ACC','ACV','DUPP','IMEC','TFDP') THEN DADOS1.SALDO *-1 ELSE DADOS1.SALDO END) SALDO,/*+
(case when TIPO_DOC in ('ACB','AC','DDVE') THEN DADOS1.juros *-1 ELSE DADOS1.juros END) SALDO,*/
/*(select
((sum(valor) - sum(vlr_dv)) - sum(vlr_bx)) as valor
from(

select
nfcab.estab,
nfcab.seqnota,
nfitem.seqnotaitem,
sum(nfitem.quantidade*nfitem.valorunitario) as valor,
coalesce(qtd_bx,0)*nfitem.valorunitario as vlr_bx,
coalesce(qtd_dv,0)*nfitem.valorunitario as vlr_dv

from nfcab

inner join nfitem on 
    nfitem.estab = nfcab.estab
    and nfitem.seqnota = nfcab.seqnota
    
inner join nfcfg on nfcfg.notaconf = nfcab.notaconf
inner join nfcfg_u on nfcfg_u.notaconf = nfcfg.notaconf
inner join u_tipoop on u_tipoop.u_tipoop_id = nfcfg_u.u_tipoop_id

inner join nfcabagrfin on
    nfcabagrfin.estab = nfcab.estab
    and nfcabagrfin.seqnota = nfcab.seqnota
    
inner join agrfinduprec on 
    agrfinduprec.estab = nfcabagrfin.estab
    and agrfinduprec.seqpagamento = nfcabagrfin.seqpagamento
    
inner join pduprec on
    pduprec.empresa = agrfinduprec.estab
    and pduprec.duprec = agrfinduprec.duprec
    
left join
    (
    select
    nfitemapartirde.estaborigem,
    nfitemapartirde.seqnotaorigem,
    nfitemapartirde.seqnotaitemorigem,
    sum(nfitemapartirde.quantidade)qtd_bx
    from nfcab 
    
    inner join nfitem on 
    nfitem.estab = nfcab.estab
    and nfitem.seqnota = nfcab.seqnota
    
    inner join nfcfg on nfcfg.notaconf = nfcab.notaconf
    inner join nfcfg_u on nfcfg_u.notaconf = nfcfg.notaconf
    inner join u_tipoop on u_tipoop.u_tipoop_id = nfcfg_u.u_tipoop_id
    
    inner join nfitemapartirde on
        nfitemapartirde.estab = nfitem.estab
        and nfitemapartirde.seqnota = nfitem.seqnota
        and nfitemapartirde.seqnotaitem = nfitem.seqnotaitem
        
    
    where
    u_tipoop.tipoop in ('RF')
    
    group by
    nfitemapartirde.estaborigem,
    nfitemapartirde.seqnotaorigem,
    nfitemapartirde.seqnotaitemorigem
    )remessa on
    remessa.estaborigem = nfitem.estab
    and remessa.seqnotaorigem = nfitem.seqnota
    and remessa.seqnotaitemorigem = nfitem.seqnotaitem
    
left join
    (
    select
    nfitemapartirde.estaborigem,
    nfitemapartirde.seqnotaorigem,
    nfitemapartirde.seqnotaitemorigem,
    sum(nfitemapartirde.quantidade)qtd_dv
    from nfcab 
    
    inner join nfitem on 
    nfitem.estab = nfcab.estab
    and nfitem.seqnota = nfcab.seqnota
    
    inner join nfcfg on nfcfg.notaconf = nfcab.notaconf
    inner join nfcfg_u on nfcfg_u.notaconf = nfcfg.notaconf
    inner join u_tipoop on u_tipoop.u_tipoop_id = nfcfg_u.u_tipoop_id
    
    inner join nfitemapartirde on
        nfitemapartirde.estab = nfitem.estab
        and nfitemapartirde.seqnota = nfitem.seqnota
        and nfitemapartirde.seqnotaitem = nfitem.seqnotaitem
        
    
    where
    u_tipoop.tipoop in ('DF-V')
    
    group by
    nfitemapartirde.estaborigem,
    nfitemapartirde.seqnotaorigem,
    nfitemapartirde.seqnotaitemorigem
    )devol on
    devol.estaborigem = nfitem.estab
    and devol.seqnotaorigem = nfitem.seqnota
    and devol.seqnotaitemorigem = nfitem.seqnotaitem

where
nfcab.status <> 'C'
and u_tipoop.tipoop in ('VF')
--and pduprec.duprec = '155803-1/1'
--and nfcab.estab = 46 
--and nfcab.dtemissao between '01/11/2023' and '30/11/2023'

and (   (nfitem.quantidade -  coalesce(qtd_dv,0)) - coalesce(qtd_bx,0)) > 0
and 
(pduprec.empresa = dados1.estab
and pduprec.duprec = dados1.documento 
)


group by
nfcab.estab,
nfcab.seqnota,
nfitem.seqnotaitem,
qtd_bx,
qtd_dv,
nfitem.valorunitario

)dados

) as saldo_remessa,*/

--case when TIPO_DOC in ('ACB','AC','DDVE') THEN DADOS1.saldo_atual *-1 ELSE DADOS1.saldo_atual END saldo_atual,
(DADOS1.saldo_ctr*-1)saldo_ctr,
DADOS1.obs,
DADOS1.situacao,
TO_CHAR(DADOS1.DTPROVAVELPAGAMENTO,'DD/MM/YYYY') AS DTPROVAVELPAGAMENTO,
DADOS1.conceito_credito,
DADOS1.CULTURA,
DADOS1.filial_rtv,
DADOS1.consultor,
PRODUTOR.saldoprod_sc,
PRODUTOR.saldoprod_vlr
,dados1.fat_agrupa
,coalesce(to_char(to_date(DADOS1.dtreajuste, 'DD/MM/YY')), to_char(to_date(dados1.dtvencto, 'DD/MM/YY'))) DTREAJUSTE
,JUROS
from(
select
--DADOS.TIPO,
DADOS.ESTAB,
CASE WHEN U_TEMPRESA.GRAOS = 'S' THEN 'Cereais'
	when U_TEMPRESA.INSUMOS = 'S' THEN 'Insumos'
    else 'Outros' END TIPO_FILIAL,
DADOS.FILIAL,
DADOS.NUMEROCM,
DADOS.PF_PJ,
DADOS.TIPO_CLIENTE,
DADOS.CNPJF,
DADOS.CLIENTE,
DADOS.TIPO_DOC,
dados.desc_tipo,
DADOS.DOCUMENTO,
(CASE WHEN DADOS.CULTURA = 'FARMTECH' THEN 'BOLETO FARMTECH' ELSE dados.status END) AS STATUS,
DADOS.PARCELA,
DADOS.DTEMISSAO,
DADOS.ANO,
DADOS.MES,
dados.dtvencto,
DADOS.ATRASO,
CASE WHEN atraso <= -31 then '0 - Vencer'
    when atraso >= -30 and atraso <= 0 then '1 - A Vencer até 30'
    when atraso > 0 and atraso < 31 then '2 - 1 a 30 '
    when atraso > 30 and atraso < 61 then '3 - 31 a 60 '
    when atraso > 60 and atraso < 91 then '4 - 61 a 90 '
    when atraso > 90 and atraso < 121 then '5 - 91 a 120 '
    when atraso > 120 and atraso < 181 then '6 - 121 a 180 '
    when atraso > 180 and atraso < 241 then '7 - 181 a 240 '
    when atraso > 240 and atraso < 366 then '8 - 241 a 365 '
    when atraso > 365 then '9 - Acima 365 '
     end aging,
DADOS.VALOR,
case when atraso <=0 then 0 else dados.juros end juros,
DADOS.SALDO,
saldo + (case when atraso <=0 then 0 else dados.juros end) as saldo_atual,
OCORRENCIAFINAN.obs as obs,
ocorrenciatipo.descricao as situacao,
OCORRENCIAFINAN.DTPROVAVELPAGAMENTO,
DADOS.conceito_credito,
--DADOS.limite_credito,
--DADOS.vlrlimite,
--DADOS.dtvigenciafim as vencimento_limite,
DADOS.filial_rtv,
DADOS.consultor,
DADOS.CULTURA,
(
select 
sum(coalesce(NVLRSALDO,0)) as saldo_valor
from contrato

inner join contratoite on
    contratoite.estab = contrato.estab
    and contratoite.contrato = contrato.contrato
    
    
INNER JOIN TABLE (PCONTRATOSALDO( CONTRATO.ESTAB,
                 CURRENT_DATE, CONTRATO.CONTRATO, CONTRATO.CONTRATO,
                 CONTRATOITE.SEQITEM, CONTRATOITE.SEQITEM, NULL, NULL, NULL,
                 NULL, NULL)) PSALDO
    ON (0=0)
    where
    contrato.numerocm = dados.NUMEROCM /*and contrato.estab = dados.estab*/
)saldo_ctr
,dados.fat_agrupa
,dados.dtreajuste

from(

select
'A RECEBER' AS TIPO,
filial.estab,
filial.reduzido as filial,
contamov.numerocm,
case when coalesce(endereco.cnpjf,contamov.cnpjf) >11 then 'PJ' ELSE 'PF' end PF_PJ,
case when contamov.revenda = 'S' THEN 'Revenda'
    when contamov.produtor = 'S' THEN 'Produtor'
    when conceito.conceito = 96 then 'Fornecedor'
    WHEN coalesce(endereco.nome,contamov.nome) like '%USINA%' THEN 'USINA'
    when coalesce(endereco.cnpjf,contamov.cnpjf) > 11 then 'PJ' ELSE 'PF'
    end tipo_cliente,
coalesce(endereco.cnpjf,contamov.cnpjf)cnpjf,
contamov.nome as cliente,
'DPL' AS TIPO_DOC,
'DUPLICATA' as desc_tipo,
pduprec.duprec as documento,
 psituaca.descricao as status,
pduprec.nroparcela as parcela,
to_char(pduprec.dtemissao,'DD/MM/YYYY') AS dtemissao,
extract(year from pduprec.dtemissao) as ano,
extract(month from pduprec.dtemissao) as mes,
to_char(pduprec.dtvencto,'DD/MM/YYYY')dtvencto,
arredondar(CAST(:DTBASE AS DATE) - pduprec.dtvencto ,0) AS ATRASO,
limcred.descricao as cultura,
pduprec.valorfatura as valor,
pduprec.juros,
/*arredondar(
divide(
divide(
   arredondar(CAST(:DTBASE AS DATE) -  pduprec.dtvencto,0)*pconfpad.juromensal,
    30)*pduprec.valor,100),2) as juros,*/
    
    
COALESCE(VALORREAJ,PDUPREC.VALOR) - COALESCE(BAIXAS.REC,0) AS SALDO,--- coalesce(pduprec.desconto,0) as saldo,
conceito.descricao as conceito_credito,
--limcred.descricao as limite_credito,
--pessoalimcred.vlrlimite,
--to_char(pessoalimcred.dtvigenciafim,'DD/MM/YYYY')dtvigenciafim,
filialrtv.reduzido as filial_rtv,
rtv.nome as consultor,
ocorrenciaduprec.idocorrencia,
PBLOQDIV.fatura as fat_agrupa,
dtreajuste AS  dtreajuste--dtreaj_ori AS  dtreajuste
from pduprec

inner join filial on filial.estab = pduprec.empresa
inner join contamov on contamov.numerocm = pduprec.cliente
left join endereco on 
    endereco.numerocm = pduprec.cliente
    and endereco.seqendereco = pduprec.seqendereco
left join conceitopessoa on conceitopessoa.numerocm=contamov.numerocm

left join conceito on conceito.conceito=conceitopessoa.conceito

left join limcred on limcred.id =  pduprec.limcred_id
/*
left join pessoalimcred on 
    pessoalimcred.numerocm = contamov.numerocm
    and pessoalimcred.limcred_id = pduprec.limcred_id*/
    
LEFT join contamov rtv on rtv.numerocm = pduprec.represent
left join contamovfuncionario on contamovfuncionario.numerocm = rtv.numerocm

left join filial filialrtv on filialrtv.estab = contamovfuncionario.localtrabalho

LEFT JOIN BAIXAS ON
    BAIXAS.EMPRESA = PDUPREC.EMPRESA
    AND BAIXAS.DUPREC = PDUPREC.DUPREC
       
LEFT JOIN DUP_REAJ ON
    DUP_REAJ.ESTAB = PDUPREC.EMPRESA
    AND DUP_REAJ.DUPREC = PDUPREC.DUPREC

LEFT JOIN ( SELECT  OCORRENCIADUPREC.ESTAB,
                           OCORRENCIADUPREC.DUPREC,
                           MAX(OCORRENCIADUPREC.IDOCORRENCIA)IDOCORRENCIA
                           
     

         FROM OCORRENCIADUPREC

        INNER JOIN OCORRENCIAFINAN ON ocorrenciafinan.idocorrencia = ocorrenciaduprec.idocorrencia

        GROUP BY OCORRENCIADUPREC.ESTAB,OCORRENCIADUPREC.DUPREC

        ) OCORRENCIADUPREC

         ON OCORRENCIADUPREC.ESTAB = PDUPREC.EMPRESA
         AND OCORRENCIADUPREC.duprec = PDUPREC.DUPREC

left join psituaca on psituaca.situacao = pduprec.situacao                             
     inner JOIN PCONFPAD ON
        PCONFPAD.EMPRESA = filial.estab            
        
        left join u_tempresa on u_tempresa.estab = filial.estab
        
left join PBLOQDIV on
  	PBLOQDIV.empresa = pduprec.empresa
  and PBLOQDIV.duprec = pduprec.duprec
  
left join
    (select
    estab,
    duprec,
    max(DTBASEJUROS)dtreajuste,
    min(DTVENCREAJ)dtreaj_ori
    from pduprecreaj
    
    group by
    estab,
    duprec
    )reaj on
    reaj.estab = pduprec.empresa
    and reaj.duprec = pduprec.duprec
        
where
--pduprec.quitada = 'N'
  COALESCE(VALORREAJ,PDUPREC.VALOR) - COALESCE(BAIXAS.REC,0) > 0 --- COALESCE(PDUPREC.DESCONTO,0) ) > 0 
AND (
    FILIAL.REDUZIDO NOT LIKE '%CD%' AND
    FILIAL.REDUZIDO NOT LIKE '%FAZ.%' AND
    FILIAL.REDUZIDO NOT LIKE '%VALERIA%' AND
    FILIAL.REDUZIDO NOT LIKE '%VALDINEI%' AND
    FILIAL.REDUZIDO NOT LIKE '%CEREAIS%' AND
    FILIAL.REDUZIDO NOT LIKE '%OS JURIDICO%' AND
    FILIAL.ESTAB NOT IN (800, 801, 802, 806, 807, 809, 1001, 1200, 79)
)
  AND CONTAMOV.NOME NOT  LIKE '%OURO SAFRA%'
  --AND PDUPREC.QUITADA <> 'S'
  --and filial.estab <> 11
--<#if ESTAB?has_content>
	AND (0 in (:ESTAB) OR FILIAL.ESTAB IN (:ESTAB))
--</#if>
 AND pduprec.duprec NOT LIKE 'FT%'  
AND PDUPREC.DTEMISSAO BETWEEN :DTINI AND :DTFIM
AND PDUPREC.DTVENCTO BETWEEN :DTINIVENC AND :DTFIMVENC
--  and (U_TEMPRESA.graos = 'S' or U_TEMPRESA.insumos = 'S')
 -- AND (conceito.conceito <> 96)
 <#if REPRESENT?has_content>  
AND PDUPREC.REPRESENT IN (:REPRESENT)
 </#if>
  
 <#if NUMEROCM?has_content>  
	AND PDUPREC.CLIENTE IN (:NUMEROCM)
</#if>
  
    and 
filial.empresa in 
(
select distinct
empresa
from filial

where
(0 in (:ESTAB) OR filial.estab in (:ESTAB))
and
filial.empresa in
(
select DISTINCT
empresa
from filial

where
(:EMPRESA = 1 and EMPRESA >=1)
OR
(:EMPRESA = 2 and EMPRESA <100)
)
)
  
)dados

LEFT JOIN OCORRENCIAFINAN ON ocorrenciafinan.idocorrencia = DADOS.idocorrencia
left join ocorrenciatipo on ocorrenciatipo.id = OCORRENCIAFINAN.idtipo
LEFT JOIN U_TEMPRESA ON U_TEMPRESA.ESTAB = DADOS.ESTAB



)dados1

left join
    (
WITH ITEM_COTACAO AS 
(
SELECT
ITEMCOTITE.ESTAB,
ITEMCOTITE.COTACAO,
FIXACAO
FROM ITEMCOTITE

INNER JOIN U_TEMPRESA 
    ON U_TEMPRESA.ESTAB = ITEMCOTITE.ESTAB

INNER JOIN (
    SELECT
    ESTAB,COTACAO,MAX(DTCOTACAOFIN) AS DTFIM
    FROM ITEMCOTITE
    GROUP BY ESTAB,COTACAO
)MAXIMO ON
    MAXIMO.ESTAB = ITEMCOTITE.ESTAB
    AND MAXIMO.COTACAO = ITEMCOTITE.COTACAO
    AND MAXIMO.DTFIM = ITEMCOTITE.DTCOTACAOFIN

WHERE
U_TEMPRESA.GRAOS = 'S'
AND ITEMCOTITE.COTACAO IN (1, 2, 3, 6)
    )      
SELECT DISTINCT
    DADOS.NUMEROCM, 
    SUM(DADOS.SALDO)/60 AS SALDOPROD_SC,
    SUM(DADOS.SALDO * ITEM_COTACAO.FIXACAO)/60 AS SALDOPROD_VLR
FROM (
  SELECT 
    ESTAB,
    NUMEROCM,
    SEQNOTA,
    SALDOLIQ AS SALDO,
    ITEM
  FROM OS_ROMPEND
  WHERE OS_ROMPEND.DTEMISSAO BETWEEN :DTINI AND :DTFIM
    AND (0 in (:ESTAB) OR OS_ROMPEND.ESTAB IN (:ESTAB)) 
 <#if NUMEROCM?has_content>     
    AND OS_ROMPEND.NUMEROCM IN (:NUMEROCM)
</#if>
  
    
  UNION ALL
  
  SELECT 
    ESTAB,
    NUMEROCM,
    SEQNOTA,
    SALDOLIQ AS SALDO,
    ITEM
  FROM OS_NOTASF
  WHERE OS_NOTASF.DTEMISSAO BETWEEN :DTINI AND :DTFIM
    AND (0 in (:ESTAB) OR OS_NOTASF.ESTAB IN (:ESTAB)) 
 <#if NUMEROCM?has_content>       
    AND OS_NOTASF.NUMEROCM IN (:NUMEROCM)
</#if>

  UNION ALL
  
  SELECT 
    ESTAB,
    NUMEROCM,
    SEQNOTA,
    SALDOLIQ AS SALDO,
    ITEM
  FROM OS_NOTASCD
  WHERE OS_NOTASCD.DTEMISSAO BETWEEN :DTINI AND :DTFIM
    AND (0 in (:ESTAB) OR OS_NOTASCD.ESTAB IN (:ESTAB))
 <#if NUMEROCM?has_content>      
    AND OS_NOTASCD.NUMEROCM IN (:NUMEROCM)
</#if>
) DADOS 
LEFT JOIN ITEM_COTACAO ON ITEM_COTACAO.COTACAO = DADOS.ITEM AND
      				                            ITEM_COTACAO.ESTAB = DADOS.ESTAB 
GROUP BY 
DADOS.NUMEROCM
  
    )PRODUTOR ON
   -- PRODUTOR.ESTAB = DADOS1.ESTAB
    --AND 
    PRODUTOR.NUMEROCM = DADOS1.NUMEROCM