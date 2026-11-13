-- comis paga
select
comisacdoc.estab,
comisacdoc.numerocm as represent,
contamov.nome as rtv,
u_gestoque.descricao as grupo,
trunc(datacred,'MM') as data,
sum(comisvalor) as comiss_paga
from comisacdoc
inner join nfitem on
    nfitem.estab = comisacdoc.estab
    and nfitem.seqnota = comisacdoc.seqnota
    and nfitem.seqnotaitem = comisacdoc.seqnotaitem
 inner join itemagro on itemagro.item = nfitem.item
 inner join itemgrupo on itemgrupo.grupo = itemagro.grupo
 inner join itemgrupo_u on itemgrupo_u.grupo = itemgrupo.grupo
 inner join u_gestoque on u_gestoque.u_gestoque_id = itemgrupo_u.u_gestoque_id
 inner join contamov on contamov.numerocm = comisacdoc.numerocm
where comisacdoc.datacred between :DTINI and :DTFIM
group by 
comisacdoc.estab,
comisacdoc.numerocm,
trunc(datacred,'MM'),
u_gestoque.descricao,
contamov.nome