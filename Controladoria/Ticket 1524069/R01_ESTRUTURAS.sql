select
localest.estab as cod_unidade,
localest.local as cod_estrutura,
localest.descricao as nome_estrutura,
'OUTRO' as tipo_estrutura,
localest_u.capacidade as capacidade_valor,
localest.local as cod_local_estoque,
'VIASOFT' as fonte_cadastro,
localest.ultalt as data_atualizazcao
from localest
inner join u_tempresa u on u.estab = localest.estab
and u.graos = 'S'
left join localest_u on 
    localest_u.estab = localest.estab
    and localest_u.local = localest.local