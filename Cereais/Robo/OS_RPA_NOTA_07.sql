with notas as (
    select /*+ MATERIALIZE */
    nfcab.chaveacessonfe
    from nfcab
    inner join nfitem on
        nfitem.estab = nfcab.estab
        and nfitem.seqnota = nfcab.seqnota
   where
   nfitem.cfop not in (5906,5907,5117,5116,5101,5102,6101,6102)
    
    union 
    
    select /*+ MATERIALIZE */
    CHAVEACESSONFP as chaveacessonfe
    from nfcabprodutor
),
prod as (
    select distinct
    ncm.ncm
    from ncm
    inner join itemagro on itemagro.ncm = ncm.ncm
    inner join itemgrupo on itemgrupo.grupo = itemagro.grupo
    where
    itemgrupo.descricao like '%CEREAIS%'
OR itemgrupo.descricao like '%FARELO%'
),
EVENTOS AS (
    select /*+ MATERIALIZE */
    CHAVE
    from u_notassieg_eventos 
    WHERE 
    UPPER(XEVENTO) LIKE '%DESCONHE%'
    OR
    UPPER(XEVENTO) LIKE '%CANCEL%'
),
MOTIVO AS (
    SELECT /*+ MATERIALIZE */ CHAVEACESSO FROM U_MOTIVO_TRADING
    WHERE MOTIVO IN ('CNF - Nota Fiscal Cancelada','CNF - NF Divergente/Recusada')
),
ROBO AS (
    SELECT
    CHAVEACESSONFE,
    CASE WHEN CONTRATO = 0 THEN NULL ELSE CONTRATO END CONTRATO,
    CASE WHEN IDCARGA = 0 THEN NULL ELSE IDCARGA END IDCARGA,
    CASE WHEN NOTACONF = 0 THEN NULL ELSE NOTACONF END NOTACONF,
    CASE WHEN NOTAFILHA = 0 THEN NULL ELSE NOTAFILHA END NOTAFILHA,
    TIPOPESSOA
    FROM U_CONFENOTAROBO
)
select /*+ GATHER_PLAN_STATISTICS */
U_FISCAL_IO_CONT_ID,
f.CHAVEACESSO,
f.DTEMISSAO AS DTEMISS,
f.NUMERONOTA,
f.SERIE,
f.CNPJF,
f.IEEMITENTE,
f.ESTAB,
f.CFOP,
f.PLACA,
f.NCM,
f.ITEM,
f.QUANTIDADE,
f.UNIDADETRIBUTAVEL,
f.VALORTOTAL,
NVL(R.IDCARGA,F.ORDEMCARGA) AS ORDEMCARGA,
f.LOCALESTOQUE,
NVL(R.CONTRATO,F.CONTRATO) AS CONTRATO,
CASE WHEN R.TIPOPESSOA = 'P' THEN 'S'
    WHEN R.TIPOPESSOA <> 'P' THEN 'N'
    WHEN R.TIPOPESSOA IS NULL THEN
    TO_CHAR(F.PRODUTOR) END PRODUTOR,
CASE WHEN r.CHAVEACESSONFE is not null then '100' else to_char(f.STATUS) end STATUS,
f.MENSAGEMERRO,
f.DTPROCESSAMENTO,f.REPROCESSADO,f.SEQENDERECO,f.DIFVIASOFT,f.DIFAPP,f.ESTABCONTRATO,f.VALIDANCM,
NVL(R.NOTACONF,F.NOTACONF) AS NOTACONF ,
f.TIPOBAIXA,
f.CONTCONF,
f.STATUS_NOTA as STATUS_NOTA,
NVL(R.NOTAFILHA,F.NOTAREF) AS NOTAFILHA,
f.CLASSIF_LOCAL,
f.numerocm,
LPAD(EXTRACT(DAY FROM f.DTEMISSAO), 2, 0)||''||LPAD(EXTRACT(MONTH FROM f.DTEMISSAO), 2, 0)||''||EXTRACT(YEAR FROM f.DTEMISSAO)  AS DTEMISSAO
from u_fiscal_io_cont f
INNER JOIN PROD ON PROD.NCM = F.NCM
inner join u_tempresa u on u.estab = f.estab
LEFT JOIN ROBO R ON R.CHAVEACESSONFE = F.CHAVEACESSO
left join conceitopessoa p on p.numerocm = f.numerocm
where
nvl(f.status_nota,'100') not in ('101')
and (u.graos = 'S' and u.exvenda = 'S')
and nvl(p.conceito,0) <> 98 
and 
not exists  (
    select
    1
    from notas where chaveacessonfe = f.chaveacesso
)
AND NOT EXISTS (
        SELECT 1 FROM EVENTOS
        WHERE EVENTOS.CHAVE = F.CHAVEACESSO
    )
AND NOT EXISTS (
        SELECT 1 FROM MOTIVO
        WHERE MOTIVO.CHAVEACESSO = F.CHAVEACESSO
    )
    
