select
gf.numerocm as represent,
contamov.nome as rtv,
f.localtrabalho as estab,
trunc(gf.dt_ignicao_lig,'MM') as data,
sum(gf.distancia_perc) as distancia_perc,
(sum(gf.distancia_perc) * 0.6) + (20*45) as custo_distancia
from u_golfleet gf
inner join contamov on contamov.numerocm = gf.numerocm
inner join contamovfuncionario f on f.numerocm = gf.numerocm
where cast(gf.dt_ignicao_lig as date) between :DTINI and :DTFIM
group by
gf.numerocm,
contamov.nome,
f.localtrabalho,
trunc(gf.dt_ignicao_lig,'MM')