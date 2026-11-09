select
roma.estab as cod_unidade,
roma.romaneio as id_romaneio,
roma.dtemissao ||' '|| roma.hora as data_hora_expedimento,
roma.item as cod_produto,
romacfg.descricao as tipo_saida,
nfcab.ordemcarga as id_ordem_carga,
roma.ticket as id_ticket_pesagem,
nfcab.nota as id_doc_fiscal,
roma.numerocm as cod_destinatario,
contamov.nome as titularidade,
roma.pesototal - nvl(roma.tara,0) as peso_expedido_kg,
roma.pesototal as peso_total_romaneio_kg,
'S' as linha_principal_romaneio,
null as id_movimento_estoque,
case when roma.estornado = 'N' then 'OK' else 'ESTORNADO' end status_romaneio,
roma.userid as id_usuario,
1 as id_item_romaneio
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
where roma.ENTRADASAIDA = 'S'
and roma.dtemissao between :DTINI and :DTFIM
