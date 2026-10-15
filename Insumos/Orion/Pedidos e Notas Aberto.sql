WITH EVENTO AS (
    SELECT
        N.CHAVE,
        N.TPEVENTO,
        N.XEVENTO
    FROM U_NOTASSIEG_EVENTOS N
    WHERE COALESCE(N.TPEVENTO, '0') IN (/*NF-E*/'110111','210220','210240' /*NFS-E*/,'101101','105102','105104','105105','305101','203206' /*CT-E*/,'610110','110111')
),
base as (
    select /*+ MATERIALIZE */
    peditem.estab,
    pedcab.dtemissao,
    pedcab.pessoa,
    peditem.serie,
    peditem.numero,
    nvl(endereco.cnpjf,contamov.cnpjf) as cnpjf,
    peditem.seqpedite,
    peditem.item,
    peditem.valorunitario,
    peditem.quantidade,
    peditem.quantidade - nvl(peditem.cancelado,0) as qtdped
    from pedcab
    inner join u_tempresa on u_tempresa.estab = pedcab.estab
    inner join peditem on
        peditem.estab = pedcab.estab
        and peditem.serie = pedcab.serie
        and peditem.numero = pedcab.numero
    inner join contamov on contamov.numerocm = pedcab.pessoa
    left join endereco on
        endereco.numerocm = pedcab.pessoa
        and endereco.seqendereco = pedcab.seqendereco
    where pedcab.status not in ('C','B')
    and pedcab.serie in ('PC')
    and u_tempresa.insumos = 'S'
),
baixas as (
    select
    p.estab,
    p.serie,
    p.numero,
    p.seqpedite,
    p.quantidade as qtdbx
    from PEDITEMNFITEM p
    inner join base on 
        base.estab = p.estab
        and base.serie = p.serie
        and base.numero = p.numero
        and base.seqpedite = p.seqpedite
),
pedidos as (
    select
    base.*,
    itemagro.ncm,
    nvl(baixas.qtdbx,0) as baixa,
   qtdped - nvl(baixas.qtdbx,0) as saldo
    from base
    inner join itemagro on itemagro.item = base.item
    left join baixas on 
            base.estab = baixas.estab
            and base.serie = baixas.serie
            and base.numero = baixas.numero
            and base.seqpedite = baixas.seqpedite

    where
    base.quantidade - nvl(baixas.qtdbx,0) > 0
),
PESSOAS AS (
    SELECT DISTINCT * FROM(
    select
    CNPJF,
    NUMEROCM
    FROM CONTAMOV
    UNION ALL
    select
    CNPJF,
    NUMEROCM
    FROM ENDERECO
    )DADOS
)
select
CASE WHEN PEDIDOS.NUMERO IS NULL THEN 'S/VINCULO' ELSE 'C/VINCULO' end TIPO,
NOTAS.ESTAB,
NOTAS.CHAVEACESSONFE,
TO_DATE(NOTAS.DTEMISSAO,'DD/MM/YYYY') AS DTEMISSAO,
NOTAS.CNPJ_EMITENTE,
NOTAS.NATOP,
NOTAS.NOTA,
NOTAS.NOMEMI,
PESSOAS.NUMEROCM,
ITE.NCM,
ITE.CFOP,
ITE.SEQNOTAITEM AS SEQITEM,
ITE.QUANTIDADE,
PEDIDOS.NUMERO as NUMPED,
PEDIDOS.QUANTIDADE AS QTDPED,
TO_DATE(PEDIDOS.DTEMISSAO,'DD/MM/YYYY') AS DTPEDIDO
FROM U_NOTASSIEG NOTAS
INNER JOIN U_TEMPRESA ON U_TEMPRESA.ESTAB = NOTAS.ESTAB
LEFT JOIN EVENTO
    ON EVENTO.CHAVE = NOTAS.CHAVEACESSONFE
INNER JOIN U_NOTASSIEG_ITENS ITE ON ITE.CHAVE = NOTAS.CHAVEACESSONFE
INNER JOIN PESSOAS ON PESSOAS.CNPJF = NOTAS.CNPJ_EMITENTE

LEFT JOIN PEDIDOS ON
    PEDIDOS.ESTAB = NOTAS.ESTAB
    AND PEDIDOS.NCM = ITE.NCM
    AND PEDIDOS.PESSOA = PESSOAS.NUMEROCM
    --and pedidos.quantidade = ite.quantidade
    and pedidos.saldo = ite.quantidade
    and pedidos.valorunitario = ite.VLRUNITARIO


WHERE NOTAS.MOD IN (55,65)
AND NOTAS.STATUS <> 101
AND U_TEMPRESA.INSUMOS = 'S'
AND NOT EXISTS (
    SELECT 1 FROM EVENTO 
    WHERE EVENTO.CHAVE = NOTAS.CHAVEACESSONFE
)
AND NOT EXISTS  (SELECT 1 FROM NFCAB WHERE NFCAB.CHAVEACESSONFE = NOTAS.CHAVEACESSONFE)
AND NOTAS.DTEMISSAO >= '01/01/2026'
AND NOTAS.DTEMISSAO BETWEEN :DTINI AND :DTFIM