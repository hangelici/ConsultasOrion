select 
nvl(endereco.cnpjf,contamov.cnpjf) as cnpjf,
contamov.nome as pessoa,
nfcab.valor,
nfcab.nota,
nfcab.serie,
count(*) as qtd
from nfcab
inner join nfcfg on nfcfg.notaconf = nfcab.notaconf
inner join NFCABAGRFIN on
    NFCABAGRFIN.estab = nfcab.estab
    and NFCABAGRFIN.seqnota = nfcab.seqnota
left join endereco on
    endereco.numerocm = nfcab.numerocm
    and endereco.seqendereco = nfcab.seqendereco
inner join contamov on contamov.numerocm = nfcab.numerocm
where
nfcab.status <> 'C'
and nfcfg.entradasaida = 'E'
and exists (
    select 1 from AGRFINDUPPAG agr
    where agr.estab = nfcabagrfin.estab
    and agr.seqpagamento = nfcabagrfin.seqpagamento
    and agr.fornecedor = nfcab.numerocm
)

group by
contamov.nome,
nvl(endereco.cnpjf,contamov.cnpjf),
nfcab.valor,
nfcab.nota,
nfcab.serie

having count(*) > 1