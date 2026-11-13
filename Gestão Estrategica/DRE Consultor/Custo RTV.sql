select
contamov.numerocm as represent,
contamov.nome as rtv,
cs.dtreferencia as data,
sum(cs.valor) as vlr_brtmensal
from u_custo_senior cs
inner join contamov on contamov.cnpjf = cs.cpf
where cs.dtreferencia between :DTINI and :DTFIM
and upper(cs.DESCEVENTO) not like '%COMISS%'
group by
contamov.numerocm,
contamov.nome,
cs.dtreferencia