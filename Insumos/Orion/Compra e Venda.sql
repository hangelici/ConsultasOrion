select
nfcab.estab,
nfcab.seqnota,
nfitem.seqnotaitem,
nfcab.dtemissao,
nfitem.hora,
nfcab.notaconf,
nfcab.nota,
nfcab.numerocm,
contamov.cnpjf,
tipo.tipoop,
nfcfg.entradasaida,
nfitem.item,
nfitem.quantidade
from nfcab
inner join filial on filial.estab = nfcab.estab
inner join u_tempresa on u_tempresa.estab = filial.estab
inner join nfcfg on nfcfg.notaconf = nfcab.notaconf
inner join nfcfg_u on nfcfg_u.notaconf = nfcfg.notaconf
inner join u_tipoop tipo on tipo.u_tipoop_id = nfcfg_u.u_tipoop_id
inner join nfitem on
    nfitem.estab = nfcab.estab
    and nfitem.seqnota = nfcab.seqnota

/* ### TRANSFERENCIA 
1. Pegar CNPJ da origem
2. Verificar se é uma filial
3. Busca a Filial Consolidada
*/
inner join contamov on contamov.numerocm = nfcab.numerocm ----- 1
left join filial fc on fc.cnpj = contamov.cnpjf ----- 2
left join u_tempresa uc on uc.estab = fc.estab ----- 3

where
nfcab.status <> 'C'
and u_tempresa.insumos = 'S'
and (tipo.tipoop in ('V','VF','C','CF','BE','BS') or ((tipo.tipoop in ('TE') and nvl(uc.estabc,0) <> nfcab.estab)) )