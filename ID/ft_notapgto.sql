select distinct
dados.estab as osestab,
dados.seqnota as nota,
dados.ult_dt,
dados.parcela as qtd_parcela,
baixa.quitada,
dados.estab||'#'||dados.seqnota as chave_bx

from(

select
nfcab.estab,
nfcab.seqnota,
max(pag.dtpag)ult_dt,
max(nroparcela.parcela)parcela
from nfcab

inner join u_tempresa on u_tempresa.estab = nfcab.estab

left join nfcabagrfin on
    nfcabagrfin.estab = nfcab.estab
    and nfcabagrfin.seqnota = nfcab.seqnota

left join agrfinduprec on
    agrfinduprec.estab = nfcabagrfin.estab
    and agrfinduprec.seqpagamento = nfcabagrfin.seqpagamento

left join pduprec on
    pduprec.empresa = agrfinduprec.estab
    and pduprec.duprec = agrfinduprec.duprec

left join
    (
    select
    empresa,
    duprec,
    max(prduprec.dtrecbto)dtpag
    from prduprec
    group by
    empresa,duprec
    )pag on
    pag.empresa = pduprec.empresa
    and pag.duprec = pduprec.duprec


left join
    (
    select
    nfcab.estab,
    nfcab.seqnota,
    coalesce(max(pduprec.nroparcela),1)parcela
    from nfcab

    inner join u_tempresa on u_tempresa.estab = nfcab.estab

    left join nfcabagrfin on
        nfcabagrfin.estab = nfcab.estab
        and nfcabagrfin.seqnota = nfcab.seqnota

    left join agrfinduprec on
        agrfinduprec.estab = nfcabagrfin.estab
        and agrfinduprec.seqpagamento = nfcabagrfin.seqpagamento

    left join pduprec on
        pduprec.empresa = agrfinduprec.estab
        and pduprec.duprec = agrfinduprec.duprec

    where
    nfcab.status <> 'C'
    and u_tempresa.insumos = 'S'
    and u_tempresa.exvenda = 'S'

    group by
    nfcab.estab,
    nfcab.seqnota 
    )nroparcela on
    nroparcela.estab = nfcab.estab
    and nroparcela.seqnota = nfcab.seqnota

where
nfcab.status <> 'C'
and u_tempresa.insumos = 'S'
and u_tempresa.exvenda = 'S'
and nfcab.dtemissao >='01/01/2021'

group by
nfcab.estab,
nfcab.seqnota

)dados

left join(
    select 
    nfcab.estab,
    nfcab.seqnota,
    coalesce(nroparcela,1)parcela,
    pduprec.quitada
    from nfcab

    inner join u_tempresa on u_tempresa.estab = nfcab.estab

    left join nfcabagrfin on
        nfcabagrfin.estab = nfcab.estab
        and nfcabagrfin.seqnota = nfcab.seqnota

    left join agrfinduprec on
        agrfinduprec.estab = nfcabagrfin.estab
        and agrfinduprec.seqpagamento = nfcabagrfin.seqpagamento

    left join pduprec on
        pduprec.empresa = agrfinduprec.estab
        and pduprec.duprec = agrfinduprec.duprec
     where
    nfcab.status <> 'C'
    and u_tempresa.insumos = 'S'
    and u_tempresa.exvenda = 'S'
    )baixa on
    baixa.estab = dados.estab
    and baixa.seqnota = dados.seqnota
    and baixa.parcela = dados.parcela
