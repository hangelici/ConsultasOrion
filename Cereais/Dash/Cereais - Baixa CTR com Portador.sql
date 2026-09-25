with base as (
    select /*+ MATERIALIZE */ distinct
    c.estab,
    filial.reduzido,
    c.contrato,
    c.estabnota,
    c.seqnota,
    nfcab.nota,
    nfcabagrfin.seqpagamento,
    sum(c.VALOR) as VALOR
    from contratonfite c
    inner join contrato on
        contrato.estab = c.estab
        and contrato.contrato = c.contrato
    inner join filial on filial.estab = c.estab
    inner join cidade on cidade.cidade = filial.cidade
    inner join nfcab on
        nfcab.estab = c.estabnota
        and nfcab.seqnota = c.seqnota
    inner join nfcabagrfin on
        nfcabagrfin.estab = nfcab.estab
        and nfcabagrfin.seqnota = nfcab.seqnota
    where
    (0 in (:ESTAB) or filial.estab in (:ESTAB))
    and contrato.dtemissao between :DTINI and :DTFIM
    and (0 IN (:NUMEROCM) OR contrato.numerocm in (:NUMEROCM))
    and ('X' in (:UF) OR CIDADE.UF IN (:UF))
    group by
    c.estab,
    c.contrato,
    c.estabnota,
    c.seqnota,
    nfcab.nota,
    nfcabagrfin.seqpagamento,
    filial.reduzido
),
base_rec as (
    select /*+ MATERIALIZE */
    pr.empresa,
    pr.duprec,
    pr.seqrecbto,
    agrfinduprec.seqpagamento
    from PRDUPREC pr
    inner join agrfinduprec on
        agrfinduprec.estab = pr.empresa
        and agrfinduprec.duprec = pr.duprec
    where exists  (
        select 1 from base
        where base.estab = agrfinduprec.estab
        and base.seqpagamento = agrfinduprec.seqpagamento
    )
)
select
b.reduzido||'-'||br.empresa as empresa,
b.contrato,
br.duprec,
b.nota,
--br.seqpagamento,
contamov.nome||'-'||contamov.numerocm as cliente,
b.valor as vlrctr,
pduprec.valor as vlrdup,
sum(CASE WHEN pportado.descricao like '%BANCO%' or pportado.descricao like '%CAIXA%' then PRDUPRED.VALOR else 0 END) as banco,
SUM(CASE 
    WHEN NVL(PLANCA.PORTADOR,0) <> 101 
        AND pportado.descricao not like '%BANCO%' 
        AND pportado.descricao not like '%CAIXA%'
    THEN PRDUPRED.VALOR ELSE 0 END
) AS OUTROS_PORTADORES,
SUM(CASE WHEN NVL(PLANCA.PORTADOR,0) = 101 THEN PRDUPRED.VALOR ELSE 0 END) AS ACERTO,
SUM(PRDURECH.VLRCHEQREC) AS CHEQUE,
SUM(PRDUREOUT.VALOR) AS OUTROS,
SUM(PRDURECAR.VALOR) AS CARTAO,
SUM(PRDURECM.VALOR) AS CONTAMOV
from base_rec br

inner join pduprec on
    pduprec.empresa = br.empresa
    and pduprec.duprec = br.duprec

inner join contamov on contamov.numerocm = pduprec.cliente

inner join base b on
    b.estabnota = br.empresa
    and b.seqpagamento = br.seqpagamento

left join prdupred on (prdupred.empresa = br.empresa)
  and (prdupred.duprec = br.duprec)
  and (prdupred.seqrecbto = br.seqrecbto)

left join planca on 
    coalesce(prdupred.estabbaixa, prdupred.empresa) = planca.empresa
    and coalesce(prdupred.dtlancabaixa, prdupred.dtlanca) = planca.dtlanca
    and coalesce(prdupred.seqlancabaixa, prdupred.seqlanca) = planca.seqlanca  

left join pportado on 
    planca.empresa = pportado.empresa
    and planca.portador = pportado.portador

/* recebimentos em cheque */
left join prdurech on (prdurech.empresa = br.empresa)
  and (prdurech.duprec = br.duprec)
  and (prdurech.seqrecbto = br.seqrecbto)

/* recebimentos em outros */
left join prdureout on (prdureout.empresa = br.empresa)
  and (prdureout.duprec = br.duprec)
  and (prdureout.seqrecbto = br.seqrecbto)

/* recebimentos em conta movimento */
left join prdurecm on (prdurecm.empresa = br.empresa)
  and (prdurecm.duprec = br.duprec)
  and (prdurecm.seqrecbto = br.seqrecbto)
  and (prdurecm.troco = 'N')

 /* Recebimentos em Cart:1o */
left join prdurecar on (prdurecar.empresa = br.empresa)
  and (prdurecar.duprec = br.duprec)
  and (prdurecar.seqrecbto = br.seqrecbto)

group by
br.empresa,
br.duprec,
br.seqpagamento,
pduprec.valor,
b.contrato,
b.nota,
b.valor,
contamov.nome,
contamov.numerocm,
b.reduzido
