select
m.estab as cod_unidade,
m.chave as id_movimento,
m.seq as id_item_movimento,
datamovim ||''|| horamovim as data_hora_efeito,
datamovim ||''|| horamovim as data_hora_lancamento,
2 as cod_tipo_movimento,
'Fisico' as desc_tipo_movimento,
m.item as cod_produto,
itemagro.unidade as unidade_original,
case when m.somadiminui = 'S' then m.quantidade else -m.quantidade end as qtd_sinal_kg,
m.natureza as tipo_doc_origem,
m.doc as id_doc_origem
from movitemagro m
inner join filial on filial.estab = m.estab
inner join u_tempresa on u_tempresa.estab = filial.estab and u_tempresa.graos = 'S'
inner join itemagro on itemagro.item = m.item
where m.datamovim between :DTINI and :DTFIM
and m.codigosaldo = 2