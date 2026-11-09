--- R06 Romaneios de entrada
select
roma.estab as cod_unidade,
roma.romaneio as id_romaneio,
roma.dtemissao ||' '|| roma.hora as data_hora_recebimento,
roma.item as cod_produto,
romacfg.romaneioconfig as cod_tipo_operacao,
roma.ticket as id_ticket_pesagem,
romaclass.classificacao as id_classificacao,
nfcab.nota as id_doc_fiscal,
roma.numerocm as cod_contraparte,
contamov.nome as titularidade,
roma.pesototal - nvl(roma.tara,0) as peso_recebido_kg,
roma.pesototal as peso_total_romaneio_kg,
'S' linha_principal_romaneio,
sum(romadesc.pesocalculado) as peso_descontos_kg,
roma.pesoliquido as peso_liq_comercial_kg,
null as id_movimento_estoque,
roma.local as cod_estrutura_destino,
case when roma.estornado = 'N' then 'OK' else 'ESTORNADO' end status_romaneio,
roma.userid as id_usuario
from roma
inner join romaclass on
    romaclass.estab         = roma.estab and
    romaclass.romaneio      = roma.romaneio and
    romaclass.entradasaida  = roma.entradasaida and
    romaclass.numerocm      = roma.numerocm and
    romaclass.percentual    > 0
left join nfcabroma on 
    nfcabroma.estab         = romaclass.estab and
    nfcabroma.romaneio      = romaclass.romaneio and
    nfcabroma.entradasaida  = romaclass.entradasaida and
    nfcabroma.numerocm      = romaclass.numerocm
left join nfcab on
    nfcab.estab = nfcabroma.estab
    and nfcab.seqnota = nfcabroma.seqnota
    and nfcab.numerocm = nfcabroma.numerocm
inner join romacfg on romacfg.romaneioconfig = roma.romaneioconfig
inner join contamov on contamov.numerocm = roma.numerocm
left join romadesc on
    romadesc.estab = roma.estab
    and romadesc.romaneio = roma.romaneio
    and romadesc.numerocm = roma.romaneio
    and romadesc.entradasaida = roma.entradasaida
where roma.ENTRADASAIDA = 'E'
and roma.dtemissao between :DTINI and :DTFIM

group by
roma.estab,
roma.romaneio,
roma.dtemissao,
roma.hora,
roma.item,
romacfg.romaneioconfig,
roma.ticket,
romaclass.classificacao,
nfcab.nota,
roma.numerocm,
contamov.nome,
roma.tara,
roma.pesototal,
roma.pesoliquido,
roma.local,
roma.estornado,
roma.userid