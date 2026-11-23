select
ni.estab,
filial.reduzido as filial,
ni.chave,
un.nota,
ni.dtemissao,
ni.cfop,
ni.icmscdcst as cst,
nvl(ni.icmsvalor,0) as icms_retorno_fiscalio,
nfret.valorimposto as icms_retorno_vs,
nr.referencia as chave_origem,
nvl(ni2.icmsvalor,0) as icms_origem_fiscalio,
nfret2.valorimposto as icms_origem_vs,
case 
    when nvl(ni.icmsvalor,0) <> nfret.valorimposto then 'ERRO' 
    when nvl(ni2.icmsvalor,0) < nfret2.valorimposto then 'ERRO'
    when nvl(ni.icmsvalor,0) <> nvl(ni2.icmsvalor,0)  then 'ERRO'
    when nfret.valorimposto <> nfret2.valorimposto then 'ERRO'
    else 'OK'
end status
from u_notassieg_itens ni
inner join filial on filial.estab =ni.estab
inner join u_notassieg_ref nr on nr.chave = ni.chave
inner join u_notassieg un on
    un.estab = ni.estab
    and un.chaveacessonfe = ni.chave
inner join nfcab on
    nfcab.estab = un.estab
    and nfcab.chaveacessonfe = un.chaveacessonfe
left join nfitemimposto nfret on
    nfret.estab = nfcab.estab
    and nfret.seqnota = nfcab.seqnota
    and nfret.seqnotaitem = ni.seqnotaitem
    and nfret.imposto = 1
--- ######### NOTAS DE ORIGEM
inner join u_notassieg_itens ni2 on 
    ni2.chave = nr.referencia
    and substr(ni2.cfop,1,1) in ('5','6')
inner join nfcab nf on
    nf.estab = ni2.estab
    and nf.chaveacessonfe = ni2.chave
left join nfitemimposto nfret2 on
    nfret2.estab = nf.estab
    and nfret2.seqnota = nf.seqnota
    and nfret2.seqnotaitem = ni2.seqnotaitem
    and nfret2.imposto = 1
where nfcab.dtemissao between :DTINI and :DTFIM
and substr(ni.cfop,1,1) in ('1','2')