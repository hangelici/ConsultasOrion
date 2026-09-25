with base as (
    select /*+ MATERIALIZE */ distinct
    c.estab,
    filial.reduzido,
    c.contrato,
    c.estabnota,
    c.seqnota,
    nfcab.nota,
    contrato.numerocm,
    nfcabagrfin.seqpagamento,
    sum(c.VALOR) as VALOR
    from contratonfite c
    inner join contrato on
        contrato.estab = c.estab
        and contrato.contrato = c.contrato
    inner join contratocfg on contratocfg.contconf = contrato.contconf
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
    and (contratocfg.entradasaida = 'S' OR (contrato.estab = 79 and contratocfg.entradasaida = 'E'))
    group by
    c.estab,
    c.contrato,
    c.estabnota,
    c.seqnota,
    nfcab.nota,
    nfcabagrfin.seqpagamento,
    filial.reduzido, contrato.numerocm
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
),
base_pag as (
    select /*+ MATERIALIZE */
    u.empresa,
    u.duppag,
    u.fornecedor,
    u.seqpagtodu,
    g.seqpagamento,
    u.estabfornecedor
    from PPDUPPAG u
    inner join AGRFINDUPPAG g on
        g.estab = u.empresa
        and g.duppag = u.duppag
        and g.fornecedor = u.fornecedor
        and g.estabfornecedor = u.estabfornecedor
    where exists  (
        select 1 from base
        where base.estab = g.estab
        and base.seqpagamento = g.seqpagamento
        and base.numerocm = g.fornecedor
    )
)
select
b.reduzido||'-'||bp.empresa as empresa,
b.contrato,
bp.duppag,
b.nota,
contamov.nome||'-'||contamov.numerocm as cliente,
b.valor as vlrctr,
pd.valor as vlrdup,
sum(CASE WHEN pportado.descricao like '%BANCO%' or pportado.descricao like '%CAIXA%' then ppduppad.VALOR else 0 END) as banco,
SUM(CASE 
    WHEN NVL(PLANCA.PORTADOR,0) <> 101 
        AND pportado.descricao not like '%BANCO%' 
        AND pportado.descricao not like '%CAIXA%'
    THEN ppduppad.VALOR ELSE 0 END
) AS OUTROS_PORTADORES,
SUM(CASE WHEN NVL(PLANCA.PORTADOR,0) = 101 THEN ppduppad.VALOR ELSE 0 END) AS ACERTO,
SUM( nvl(ppaduche.VLRCHEQUEP,0) + nvl(ppaduchr.VLRCHEQUE,0)  ) AS CHEQUE,
0 AS OUTROS,
0 AS CARTAO,
SUM(ppaducm.VALOR) AS CONTAMOV,
SUM(ppduppadup.VALOR) AS DINHEIRO
from base_pag bp

inner join contamov on contamov.numerocm = bp.fornecedor

inner join PDUPPAGA pd on
    pd.empresa = bp.empresa
    and pd.duppag = bp.duppag
    and pd.fornecedor = bp.fornecedor
    and pd.estabfornecedor = bp.estabfornecedor

inner join base b on
    b.estab = bp.empresa
    and b.seqpagamento = bp.seqpagamento
    and b.numerocm = bp.fornecedor

left join ppduppad
    on (ppduppad.empresa = bp.empresa)
    and (ppduppad.fornecedor = bp.fornecedor)
    and (ppduppad.estabfornecedor = bp.estabfornecedor)
    and (ppduppad.duppag = bp.duppag)
    and (ppduppad.seqpagtodu = bp.seqpagtodu)

left join planca on 
    (ppduppad.empresa = planca.empresa)
    and (ppduppad.dtlanca = planca.dtlanca)
    and (ppduppad.seqlanca = planca.seqlanca)

left join pportado on 
    planca.empresa = pportado.empresa
    and planca.portador = pportado.portador

left join ppaducm on 
    (ppaducm.empresa = bp.empresa)
    and (ppaducm.fornecedor = bp.fornecedor)
    and (ppaducm.estabfornecedor = bp.estabfornecedor)
    and (ppaducm.duppag = bp.duppag)
    and (ppaducm.seqpagtodu = bp.seqpagtodu)

left join ppduppadup on  
    (ppduppadup.empresa         = bp.empresa)
    and (ppduppadup.fornecedor         = bp.fornecedor)
    and (ppduppadup.estabfornecedor = bp.estabfornecedor)
    and (ppduppadup.duppag             = bp.duppag)
    and (ppduppadup.seqpagtodu         = bp.seqpagtodu)

left join ppaduche on 
    (ppaduche.empresa = bp.empresa)
    and (ppaduche.fornecedor = bp.fornecedor)
    and (ppaduche.estabfornecedor = bp.estabfornecedor)
    and (ppaduche.duppag = bp.duppag)
    and (ppaduche.seqpagtodu = bp.seqpagtodu)

left join ppaduchr on 
    (ppaduchr.empresa = bp.empresa)
    and (ppaduchr.fornecedor = bp.fornecedor)
    and (ppaduchr.estabfornecedor = bp.estabfornecedor)
    and (ppaduchr.duppag = bp.duppag)
    and (ppaduchr.seqpagtodu = bp.seqpagtodu)

group by
b.reduzido,
bp.empresa,
b.contrato,
bp.duppag,
b.nota,
contamov.nome,
contamov.numerocm,
b.valor,
pd.valor

union all


select
b.reduzido||'-'||br.empresa as empresa,
b.contrato,
br.duprec,
b.nota,
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
SUM(PRDURECM.VALOR) AS CONTAMOV,
SUM(prduredup.VALOR) AS DINHEIRO
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

left join prduredup on 
    (prduredup.empresa = br.empresa)
    and (prduredup.duprec = br.duprec)
    and (prduredup.seqrecbto = br.seqrecbto)

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
