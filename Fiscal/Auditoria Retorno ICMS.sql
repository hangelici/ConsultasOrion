select /*+ GATHER_PLAN_STATISTICS
           LEADING(nfitem nfcab r nfcab2 nfi nsi nsi2 nfiimposto nfiimposto2)
           USE_NL(nfcab r nfcab2 nfi nsi nsi2 nfiimposto nfiimposto2)
           INDEX(nfitem IDX_FK_CFOP_NFITEM)
           INDEX(r IX_U_NOTASSIEG_REF_CHAVE)
           INDEX(nfcab2 IDX_CHAVEACESSO)
           INDEX(nfi IDX_NFITEM_SEQNOTA_ESTAB)
           INDEX(nsi IX_U_NOTASSIEG_CHAVE)
           INDEX(nsi2 IX_U_NOTASSIEG_CHAVE)
        */
nfcab.dtemissao,
r.chave,
nfitem.cfop,
nsi.vicms,
nfiimposto.valorimposto as icms_vs,
r.REFERENCIA,
nfi.cfop as cfop_ref,
nsi2.vicms as vicms_ref,
nfiimposto2.valorimposto as icms_ref_vs,
case
  when nsi.vicms = nfiimposto.valorimposto and
  nsi2.vicms = nfiimposto2.valorimposto then 'OK'
  else 'Erro'
end status
from u_notassieg_ref r
inner join nfcab on nfcab.chaveacessonfe = r.chave
inner join nfitem on
  nfitem.estab = nfcab.estab 
  and nfitem.seqnota = nfcab.seqnota
inner join u_notassieg nsi on nsi.chaveacessonfe = r.chave
inner join nfitemimposto nfiimposto on
  nfiimposto.estab = nfitem.estab 
  and nfiimposto.seqnota = nfitem.seqnota 
  and nfiimposto.seqnotaitem = nfitem.seqnotaitem
  and nfiimposto.imposto = 1
----- ### referencia ### -----
inner join nfcab nfcab2 on nfcab2.chaveacessonfe = r.referencia
inner join nfitem nfi on
  nfi.estab = nfcab2.estab 
  and nfi.seqnota = nfcab2.seqnota
inner join u_notassieg nsi2 on nsi2.chaveacessonfe = r.referencia
inner join nfitemimposto nfiimposto2 on
  nfiimposto2.estab = nfi.estab 
  and nfiimposto2.seqnota = nfi.seqnota 
  and nfiimposto2.seqnotaitem = nfi.seqnotaitem
  and nfiimposto2.imposto = 1

where nfitem.cfop in ('2202','1202') and nfi.cfop in ('5202','6202','6102')
;
alter session set statistics_level = all;
SELECT *
FROM TABLE(
    DBMS_XPLAN.DISPLAY_CURSOR(
        null,
        NULL,
        'ALLSTATS LAST +PREDICATE +PEEKED_BINDS'
    )
);