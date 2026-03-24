WITH DPL AS
    (SELECT
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
    
BAIXAS_DPL AS
    (SELECT
        EMPRESA,
        DUPREC,
        SEQRECBTO,
        SUM(VALOR) AS VALOR
    FROM DPL
    GROUP BY
        EMPRESA,
        DUPREC,
        SEQRECBTO
    ),
    
BAIXAS AS
    (SELECT
        PRDUPREC.EMPRESA,
        PRDUPREC.DUPREC,
        SUM(BAIXAS_DPL.VALOR) AS VLR,
        SUM(PRDUPREC.VALOR * CASE WHEN PRDUPREC.TIPOREC IN ('R','J') THEN 1 ELSE -1 END) AS PAGO,
        SUM(CASE WHEN PRDUPREC.TIPOREC IN ('J') THEN BAIXAS_DPL.VALOR ELSE 0 END) JUROS,
        SUM(CASE WHEN PRDUPREC.TIPOREC IN ('R') THEN BAIXAS_DPL.VALOR ELSE 0 END) REC
    FROM PRDUPREC
    INNER JOIN BAIXAS_DPL
        ON  BAIXAS_DPL.EMPRESA  = PRDUPREC.EMPRESA
        AND BAIXAS_DPL.DUPREC   = PRDUPREC.DUPREC
        AND BAIXAS_DPL.SEQRECBTO= PRDUPREC.SEQRECBTO
    WHERE
            TIPOREC IN ('R','J')
        AND DTRECBTO <= :DTBASE
    GROUP BY
        PRDUPREC.EMPRESA,
        PRDUPREC.DUPREC
    ),
    
REAJ_ANT AS
    (SELECT
        ESTAB,
        DUPREC,
        DTREAJUSTE,
        VALORATU,
        VALORREAJ,
        ROW_NUMBER() OVER (PARTITION BY ESTAB, DUPREC ORDER BY DTREAJUSTE DESC) AS RN
    FROM PDUPRECREAJ
    WHERE DTREAJUSTE <= (:DTBASE)
    ),
    
REAJ_MAX AS
    (SELECT
        ESTAB,
        DUPREC,
        DTREAJUSTE,
        VALORATU,
        VALORREAJ,
        ROW_NUMBER() OVER (PARTITION BY ESTAB, DUPREC ORDER BY DTREAJUSTE DESC) AS RN
    FROM PDUPRECREAJ
    WHERE
        DTREAJUSTE >= (:DTBASE)
    ),
    
DUP_REAJ AS
    (SELECT 
        RM.ESTAB,
        RM.DUPREC,
        (CASE 
         -- Se a data de posição for menor que a data do reajuste, e não houver registro em REAJ_ANT,
         -- usa o VALORATU (valor antes do reajuste) de RM; caso haja RA, você pode optar por usar
         -- o VALORREAJ de RA se isso for o desejado. Aqui, por exemplo, usamos NVL para usar RA.VALORREAJ se existir;
         -- se não, usamos RM.VALORATU.
            WHEN (:DTBASE) < RM.DTREAJUSTE
                THEN NVL(RA.VALORREAJ, RM.VALORATU)
            ELSE RM.VALORREAJ
        END
        ) AS VALORREAJ
        FROM    (SELECT *
                FROM REAJ_MAX
                WHERE RN = 1
                ) RM
            LEFT JOIN   (SELECT *
                        FROM REAJ_ANT
                        WHERE RN = 1
                        ) RA
                ON  RM.ESTAB = RA.ESTAB
                AND RM.DUPREC = RA.DUPREC
    ),

BAIXAS_CM AS
    (SELECT
        ESTABACERTADO,
        SEQACERTADA,
        NUMEROCM,
        SUM(VALOR) AS VLR
    FROM CONTAMOVLANAC
    WHERE
            TIPO = 'B'
        AND CONTAMOVLANAC.DTACERTO <= (:DTBASE)
    GROUP BY
        ESTABACERTADO,
        SEQACERTADA,
        NUMEROCM
    )

SELECT
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
    (case
        when TIPO_DOC IN ('ACB','AC','DDVE','AC','ACB','ACC','ACV','DUPP','IMEC','TFDP')
            THEN (DADOS1.VALOR * -1)
        ELSE DADOS1.VALOR
    END
    ) AS VALOR,
    /*
    case when TIPO_DOC in ('ACB','AC','DDVE') THEN DADOS1.juros *-1 ELSE DADOS1.juros END juros,
    */
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
  dados.status,
--(CASE WHEN DADOS.CULTURA = 'FARMTECH' THEN 'BOLETO FARMTECH' ELSE dados.status END) AS STATUS,
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
select distinct
sum(coalesce(NVLRSALDO,0)) as saldo_valor
from contrato
INNER JOIN U_TEMPRESA
    ON  CONTRATO.ESTAB = U_TEMPRESA.ESTAB

inner join contratoite on
    contratoite.estab = contrato.estab
    and contratoite.contrato = contrato.contrato
    
    
INNER JOIN TABLE (PCONTRATOSALDO( CONTRATO.ESTAB,
                 CURRENT_DATE, CONTRATO.CONTRATO, CONTRATO.CONTRATO,
                 CONTRATOITE.SEQITEM, CONTRATOITE.SEQITEM, NULL, NULL, NULL,
                 NULL, NULL)) PSALDO
    ON (0=0)
    where
    contrato.numerocm = dados.NUMEROCM /*AND CONTRATO.ESTAB = DADOS.ESTAB*/ AND CONTRATO.ATIVO = 'A' AND U_TEMPRESA.GRAOS = 'S'
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
    
    
COALESCE(VALORREAJ,PDUPREC.VALOR) - COALESCE(BAIXAS.REC,0) AS SALDO,
  --coalesce(PSALDODUPREC.PNSALDODUPREC,0) as saldo,--- coalesce(pduprec.desconto,0) as saldo,
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
  
--left JOIN TABLE( PSALDODUPREC_TESTE(PDUPREC.EMPRESA, PDUPREC.DUPREC, NULL, :DTBASE))PSALDODUPREC
 --        ON 0=0  
        
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
 ARREDONDAR(COALESCE(VALORREAJ,PDUPREC.VALOR) - COALESCE(BAIXAS.REC,0) -  COALESCE(DESCPEND,0) ,0) > 0
  AND  ((COALESCE(VALORREAJ,PDUPREC.VALOR)  - COALESCE(BAIXAS.REC,0)) - COALESCE(PDUPREC.DESCONTO,0)) <> 0
   AND PDUPREC.DUPREC <> ('84388-1') 
  and coalesce(pduprec.situacao,0) <> 39
  -- (coalesce(PSALDODUPREC.PNSALDODUPREC,0)  > 0) --- COALESCE(PDUPREC.DESCONTO,0) ) > 0 
  --AND PDUPREC.QUITADA <> 'S'
  --and filial.estab <> 11
--<#if ESTAB?has_content>
	AND (0 in (:ESTAB) OR FILIAL.ESTAB IN (:ESTAB))
--</#if>
  
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

union all
  SELECT
'A RECEBER' AS TIPO,
FILIAL.ESTAB,
FILIAL.REDUZIDO AS FILIAL,
CONTAMOV.NUMEROCM,
CASE WHEN CONTAMOV.CNPJF >11 THEN 'PJ' ELSE 'PF' END PF_PJ,
CASE WHEN CONTAMOV.REVENDA = 'S' THEN 'Revenda'
    WHEN CONTAMOV.PRODUTOR = 'S' THEN 'Produtor'
    WHEN CONCEITO.CONCEITO = 96 THEN 'Fornecedor'
    WHEN CONTAMOV.NOME LIKE '%USINA%' THEN 'USINA'
    WHEN CONTAMOV.CNPJF > 11 THEN 'PJ' ELSE 'PF'
    END TIPO_CLIENTE,
CONTAMOV.CNPJF,
CONTAMOV.NOME as CLIENTE,
'CHEQ' AS TIPO_DOC,
'CHEQUE' as DESC_TIPO,
CAST(NROCHEQUE AS VARCHAR(100) )AS DOCUMENTO,
PSITUACA.DESCRICAO as STATUS,
1 PARCELA,
TO_CHAR(PCHEQREC.DTEMISSAO,'DD/MM/YYYY') AS DTEMISSAO,
EXTRACT(YEAR FROM PCHEQREC.DTEMISSAO) AS ANO,
EXTRACT(MONTH FROM PCHEQREC.DTEMISSAO) AS MES,
TO_CHAR(PCHEQREC.DTBOMPARA,'DD/MM/YYYY') AS DTVENCTO,
arredondar(CAST(:DTBASE AS DATE) - PCHEQREC.DTBOMPARA ,0) AS ATRASO,
limcred.descricao as cultura,
PCHEQREC.valor,
0 as juros,
CASE
          WHEN PCHEQREC.DTLANCA IS NULL
          THEN PCHEQREC.VALOR
          ELSE
            CASE 
              WHEN PCHEQREC.DTLANCA <= :DTBASE
              THEN 0
              ELSE PCHEQREC.VALOR
          END
      END AS SALDO,
CONCEITO.DESCRICAO AS CONCEITO_CREDITO,
FILIALRTV.REDUZIDO AS FILIAL_RTV,
RTV.NOME AS CONSULTOR,
NULL AS IDOCORRENCIA,
NULL AS FAT_AGRUPA,
NULL DTREAJUSTE
FROM PCHEQREC

LEFT JOIN PREPRESE
    ON PREPRESE.EMPRESA = PCHEQREC.ESTABREPRESENTANTE
    AND PREPRESE.REPRESENT = PCHEQREC.REPRESENTANTE

INNER JOIN CONTAMOV ON CONTAMOV.NUMEROCM = PCHEQREC.CLIENTE
LEFT JOIN CONCEITOPESSOA ON CONCEITOPESSOA.NUMEROCM=CONTAMOV.NUMEROCM
LEFT JOIN CONCEITO ON CONCEITO.CONCEITO=CONCEITOPESSOA.CONCEITO

INNER JOIN FILIAL ON FILIAL.ESTAB = PCHEQREC.EMPRESA
INNER JOIN U_TEMPRESA ON U_TEMPRESA.ESTAB = FILIAL.ESTAB

LEFT JOIN PSITUACA ON PSITUACA.SITUACAO = PCHEQREC.SITUACAO     
LEFT JOIN LIMCRED ON LIMCRED.ID =  PCHEQREC.LIMCRED_ID
    
LEFT JOIN CONTAMOV RTV ON RTV.NUMEROCM = PCHEQREC.REPRESENTANTE
LEFT JOIN CONTAMOVFUNCIONARIO ON CONTAMOVFUNCIONARIO.NUMEROCM = RTV.NUMEROCM
LEFT JOIN FILIAL FILIALRTV ON FILIALRTV.ESTAB = CONTAMOVFUNCIONARIO.LOCALTRABALHO

WHERE
PCHEQREC.SEQLANCATRAN IS NULL
AND PCHEQREC.DTEMISSAO BETWEEN :DTINI AND :DTFIM
AND PCHEQREC.DTBOMPARA BETWEEN :DTINIVENC AND :DTFIMVENC
AND PCHEQREC.DTLANCA IS NULL 
AND PCHEQREC.EMPRESA <> 800
AND PCHEQREC.SITUACAO  in (12,10)

 <#if REPRESENT?has_content>  
AND PCHEQREC.REPRESENTANTE IN (:REPRESENT)
 </#if>
  
 <#if NUMEROCM?has_content>  
	AND CONTAMOV.NUMEROCM IN (:NUMEROCM)
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
  
  
    -- gerencial farmtech não tem baixa: é o desconto
UNION ALL  
  
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
    
    
 (PDUPREC.VALOR - COALESCE(PDUPREC.DESCONTO,0)) as saldo,
--COALESCE(VALORREAJ,PDUPREC.VALOR) - COALESCE(BAIXAS.REC,0) AS SALDO,
  --coalesce(PSALDODUPREC.PNSALDODUPREC,0) as saldo,--- coalesce(pduprec.desconto,0) as saldo,
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
/*
  LEFT JOIN BAIXAS ON
    BAIXAS.EMPRESA = PDUPREC.EMPRESA
    AND BAIXAS.DUPREC = PDUPREC.DUPREC
*/
LEFT JOIN DUP_REAJ ON
    DUP_REAJ.ESTAB = PDUPREC.EMPRESA
    AND DUP_REAJ.DUPREC = PDUPREC.DUPREC
  
--left JOIN TABLE( PSALDODUPREC_TESTE(PDUPREC.EMPRESA, PDUPREC.DUPREC, NULL, :DTBASE))PSALDODUPREC
 --        ON 0=0  
        
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
 (PDUPREC.VALOR - COALESCE(PDUPREC.DESCONTO,0)) > 0
 --ARREDONDAR(COALESCE(VALORREAJ,PDUPREC.VALOR) - COALESCE(BAIXAS.REC,0),0) > 0
 and pduprec.situacao = 39
   AND PDUPREC.DUPREC <> ('84388-1') 
  -- (coalesce(PSALDODUPREC.PNSALDODUPREC,0)  > 0) --- COALESCE(PDUPREC.DESCONTO,0) ) > 0 
  --AND PDUPREC.QUITADA <> 'S'
  --and filial.estab <> 11
--<#if ESTAB?has_content>
	AND (0 in (:ESTAB) OR FILIAL.ESTAB IN (:ESTAB))
--</#if>
  
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


UNION ALL

SELECT
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
  dados.status,
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
--DADOS.vencimento_limite,
DADOS.filial_rtv,
DADOS.consultor,
DADOS.CULTURA,
(
select distinct
sum(coalesce(NVLRSALDO,0)) as saldo_valor
from contrato
INNER JOIN U_TEMPRESA
    ON  CONTRATO.ESTAB = U_TEMPRESA.ESTAB

inner join contratoite on
    contratoite.estab = contrato.estab
    and contratoite.contrato = contrato.contrato
    
    
INNER JOIN TABLE (PCONTRATOSALDO( CONTRATO.ESTAB,
                 CURRENT_DATE, CONTRATO.CONTRATO, CONTRATO.CONTRATO,
                 CONTRATOITE.SEQITEM, CONTRATOITE.SEQITEM, NULL, NULL, NULL,
                 NULL, NULL)) PSALDO
    ON (0=0)
    where
    contrato.numerocm = dados.NUMEROCM /*AND CONTRATO.ESTAB = DADOS.ESTAB*/ AND CONTRATO.ATIVO = 'A' AND U_TEMPRESA.GRAOS = 'S'
)saldo_ctr
, null fat_agrupa
,null dtreajuste

FROM(

select
filial.estab,
filial.reduzido as filial,
CONTAMOVLAN.numerocm,
case when contamov.cnpjf >11 then 'PJ' ELSE 'PF' end PF_PJ,
case when contamov.revenda = 'S' THEN 'Revenda'
    when contamov.produtor = 'S' THEN 'Produtor'
    when conceito.conceito = 96 then 'Fornecedor'
    WHEN contamov.nome like '%USINA%' THEN 'USINA'
    when contamov.cnpjf > 11 then 'PJ' ELSE 'PF'
    end tipo_cliente,
contamov.cnpjf,
contamov.nome as cliente,
contamovtp.tipo as tipo_doc,
contamovtp.descricao as desc_tipo,
contamovlan.nrodocto as documento,
  
    CASE WHEN contamovlan.SITUACAO = 'B' THEN 'Baixado'
  	when contamovlan.situacao = 'P' then 'Pendente'
  when contamovlan.situacao = 'A' then 'Acertado Parcialmente'
  END status,
1 as parcela,
TO_CHAR(CONTAMOVLAN.DTMOVTO,'DD/MM/YYYY')DTEMISSAO,
extract(year from CONTAMOVLAN.DTMOVTO) as ano,
extract(month from CONTAMOVLAN.DTMOVTO) as mes,
TO_CHAR(CONTAMOVLAN.VENCIMENTO,'DD/MM/YYYY') DTVENCTO,
arredondar(CAST(:DTBASE AS DATE) - CONTAMOVLAN.VENCIMENTO,0) AS ATRASO,
contamovlan.valor,
contamovlan.juros,
/*arredondar(
divide(
divide(
   arredondar(CAST(:DTBASE AS DATE) - CONTAMOVLAN.VENCIMENTO,0)*pconfpad.juromensal,
    30)*contamovlan.valor,100),2) as juros,*/
CONTAMOVLAN.VALOR - COALESCE(BAIXAS_CM.VLR,0) AS SALDO,
  --PSALDOCONTAMOVLAN(CONTAMOVLAN.NUMEROCM, CONTAMOVLAN.ESTAB, CONTAMOVLAN.SEQCM, :DTBASE) as saldo,
conceito.descricao as conceito_credito,
--'GERAL' LIMITE_CREDITO,
--pessoalimcred.vlrlimite,
--TO_CHAR(pessoalimcred.vencimento_limite,'DD/MM/YYYY')vencimento_limite,
COALESCE(filialrtv.reduzido,'S/RTV') as filial_rtv,
COALESCE(rtv.nome,'S/RTV') as consultor,
ocorrenciacontamov.IDOCORRENCIA,
  '' as cultura
from CONTAMOVLAN

inner join filial on filial.estab = contamovlan.estab

INNER JOIN CONTAMOV ON
        CONTAMOV.NUMEROCM   = CONTAMOVLAN.NUMEROCM 
        
        left join u_tempresa on u_tempresa.estab = filial.estab
        
left join conceitopessoa on conceitopessoa.numerocm=contamov.numerocm

left join conceito on conceito.conceito=conceitopessoa.conceito

left join contamovtp on
    contamovtp.tipo = CONTAMOVLAN.tipo
    and contamovtp.DEBCRED = CONTAMOVLAN.DEBCRED
/*
left join 
    (
    SELECT
    NUMEROCM,
    DTVIGENCIAFIM AS vencimento_limite,
    SUM(VLRLIMITE)VLRLIMITE
    FROM pessoalimcred
    GROUP BY
    NUMEROCM,
    DTVIGENCIAFIM
    
    )
    pessoalimcred on 
    pessoalimcred.numerocm = CONTAMOVLAN.numerocm*/
    
LEFT JOIN AGRFINCTAMOV ON AGRFINCTAMOV.ESTAB = CONTAMOVLAN.ESTAB
                            AND AGRFINCTAMOV.NUMEROCM = CONTAMOVLAN.NUMEROCM
                            AND AGRFINCTAMOV.SEQCM = CONTAMOVLAN.SEQCM
                            
LEFT JOIN NFCABAGRFIN ON NFCABAGRFIN.ESTAB = AGRFINCTAMOV.ESTAB
                        AND NFCABAGRFIN.SEQPAGAMENTO = AGRFINCTAMOV.SEQPAGAMENTO
                        
LEFT JOIN NFCAB ON NFCAB.SEQNOTA = NFCABAGRFIN.SEQNOTA
                        AND NFCAB.ESTAB = NFCABAGRFIN.ESTAB
 
LEFT JOIN BAIXAS_CM ON
    BAIXAS_CM.ESTABACERTADO = CONTAMOVLAN.ESTAB
    AND BAIXAS_CM.SEQACERTADA = CONTAMOVLAN.SEQCM
    AND BAIXAS_CM.NUMEROCM = CONTAMOVLAN.NUMEROCM
  
  
 LEFT join contamov rtv on rtv.numerocm = NFCAB.represent
left join contamovfuncionario on contamovfuncionario.numerocm = rtv.numerocm

left join filial filialrtv on filialrtv.estab = contamovfuncionario.localtrabalho  
    
 LEFT JOIN ( SELECT  ocorrenciacontamov.ESTAB,
                           ocorrenciacontamov.SEQCM,
                           ocorrenciacontamov.NUMEROCM,
                           MAX(ocorrenciacontamov.IDOCORRENCIA)IDOCORRENCIA
                           
     

         FROM ocorrenciacontamov

        INNER JOIN OCORRENCIAFINAN ON ocorrenciafinan.idocorrencia = ocorrenciacontamov.idocorrencia

        GROUP BY ocorrenciacontamov.ESTAB,ocorrenciacontamov.SEQCM,ocorrenciacontamov.NUMEROCM

        ) ocorrenciacontamov

         ON ocorrenciacontamov.ESTAB = CONTAMOVLAN.ESTAB
         AND ocorrenciacontamov.SEQCM = CONTAMOVLAN.SEQCM
         AND ocorrenciacontamov.NUMEROCM = CONTAMOVLAN.NUMEROCM
    
     inner JOIN PCONFPAD ON
        PCONFPAD.EMPRESA = filial.estab
    
    
    
    
WHERE 
 ARREDONDAR(CONTAMOVLAN.VALOR - COALESCE(BAIXAS_CM.VLR,0),0) > 0
  --PSALDOCONTAMOVLAN(CONTAMOVLAN.NUMEROCM, CONTAMOVLAN.ESTAB, CONTAMOVLAN.SEQCM, :DTBASE) > 0 --AND CONTAMOVLAN.SITUACAO <> 'B'
  --and filial.estab <> 11
  AND (CONTAMOVLAN.DEBCRED = 'D' OR (CONTAMOVLAN.DEBCRED = 'C' AND CONTAMOVLAN.TIPO IN ('ACB','AC','DDVE','AC','ACB','ACC','ACV','DUPP','IMEC','TFDP')))
and CONTAMOVLAN.TIPO not in ('ACT','AV','DDCO','JCSB')
  AND CONTAMOVLAN.TIPO NOT IN ('ACT','TACT','ACCR')
 -- AND CONTAMOVLAN.ESTAB < 800
-- <#if ESTAB?has_content>
	AND (0 IN (:ESTAB) OR FILIAL.ESTAB IN (:ESTAB))
--</#if>
  
AND CONTAMOVLAN.DTMOVTO BETWEEN :DTINI AND :DTFIM
AND CONTAMOVLAN.VENCIMENTO BETWEEN :DTINIVENC AND :DTFIMVENC
 -- AND (conceito.conceito <> 96)
  <#if REPRESENT?has_content>  
    AND NFCAB.REPRESENT IN (:REPRESENT)
  </#if>
  
<#if NUMEROCM?has_content>  
	AND CONTAMOV.NUMEROCM IN (:NUMEROCM)
</#if>

--and (U_TEMPRESA.graos = 'S' or U_TEMPRESA.insumos = 'S')
  
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
(:EMPRESA = 1 and EMPRESA >= 1)
OR
(:EMPRESA = 2 and EMPRESA <100)
)
)
  
)DADOS

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
    MAX(ITEMCOTITE.DTCOTACAOFIN) AS ULTDATA,
    MAX(ITEMCOTITE.FIXACAO) KEEP (DENSE_RANK LAST ORDER BY ITEMCOTITE.DTCOTACAOFIN) AS FIXACAO
FROM ITEMCOTITE
INNER JOIN U_TEMPRESA 
    ON U_TEMPRESA.ESTAB = ITEMCOTITE.ESTAB
WHERE
    U_TEMPRESA.GRAOS = 'S'
    AND ITEMCOTITE.COTACAO IN (1, 2, 3, 6)
GROUP BY
    ITEMCOTITE.ESTAB,
    ITEMCOTITE.COTACAO
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