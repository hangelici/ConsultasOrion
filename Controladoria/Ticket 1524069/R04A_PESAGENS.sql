--R04A_PESAGENS · Tickets de pesagem
select
tb.estab as cod_unidade,
tb.ticket as id_ticket_pesagem,
tb.ticket as num_ticket,
tb.DATAENTRADA as data_hora_entrada,
tb.DATASAIDA as dara_hora_saida,
roma.placa as placa_veiculo,
romacfg.descricao as tipo_operacao,
roma.item as cod_produto,
roma.romaneio as id_romaneio,
roma.pesototal as peso_bruto_kg,
roma.tara,
roma.pesoliquido as peso_liquido_kg,
case when roma.estornado = 'S' then 'Estornado' else 'Ok' end status_ticket
from u_tempobalanca tb
inner join roma on
    roma.estab = tb.estab
    and roma.ticket = cast(tb.ticket as varchar2(40))
    and roma.romaneioconfig =tb.romaneioconfig
left join romacfg on romacfg.romaneioconfig = roma.romaneioconfig
where CAST(tb.datacriacaomov AS DATE) between :DTINI and :DTFIM
and (0 in (:ESTAB) or tb.estab in (:ESTAB))
