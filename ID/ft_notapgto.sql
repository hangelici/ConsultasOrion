with base_nf as (
   select n.estab,
          n.seqnota,
          n.dtemissao
     from nfcab n
     join u_tempresa u
   on u.estab = n.estab
    where n.status <> 'C'
      and u.insumos = 'S'
      and u.exvenda = 'S'
      and n.dtemissao >= (
      select dtini
        from u_periodosafra
   )
),fin as (
   select b.estab,
          b.seqnota,
          b.dtemissao,
          pd.nroparcela,
          pd.quitada,
          max(pr.dtrecbto) as dtpag
     from base_nf b
     left join nfcabagrfin naf
   on naf.estab = b.estab
      and naf.seqnota = b.seqnota
     left join agrfinduprec af
   on af.estab = naf.estab
      and af.seqpagamento = naf.seqpagamento
     left join pduprec pd
   on pd.empresa = af.estab
      and pd.duprec = af.duprec
     left join prduprec pr
   on pr.empresa = pd.empresa
      and pr.duprec = pd.duprec
    group by b.estab,
             b.seqnota,
             pd.nroparcela,
             pd.quitada,
             b.dtemissao
),agregado as (
   select estab,
          seqnota,
          dtemissao,
          max(dtpag) as ult_dt,
          coalesce(
             max(nroparcela),
             1
          ) as parcela
     from fin
    group by estab,
             seqnota,
             dtemissao
)
select a.estab as osestab,
       a.seqnota as nota,
       a.ult_dt,
       a.parcela as qtd_parcela,
       f.quitada,
       a.estab
       || '#'
       || a.seqnota as chave_bx,
       a.dtemissao
  from agregado a
  left join fin f
on f.estab = a.estab
   and f.seqnota = a.seqnota
   and coalesce(
   f.nroparcela,
   1
) = a.parcela