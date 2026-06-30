with dpl as (
   select empresa,
          duprec,
          seqrecbto,
          ( valor ) as valor
     from prdupred
   union all
   select empresa,
          duprec,
          seqrecbto,
          ( vlrcheqrec ) as valor
     from prdurech
   union all
   select empresa,
          duprec,
          seqrecbto,
          valor
     from prduredup
   union all
   select empresa,
          duprec,
          seqrecbto,
          valor
     from prdurecar
   union all
   select empresa,
          duprec,
          seqrecbto,
          valor
     from prdureout
   union all
   select empresa,
          duprec,
          seqrecbto,
          valor
     from prdurecm
    where troco = 'N'
),baixas_dpl as (
   select empresa,
          duprec,
          seqrecbto,
          sum(valor) as valor
     from dpl
    group by empresa,
             duprec,
             seqrecbto
),baixas as (
   select prduprec.empresa,
          prduprec.duprec,
          sum(
             case
                when prduprec.tiporec in('J') then
                   baixas_dpl.valor
                else
                   0
             end
          ) juros,
          sum(
             case
                when prduprec.tiporec in('R') then
                   baixas_dpl.valor
                else
                   0
             end
          ) rec,
          sum(
             case
                when prduprec.tiporec in('D') then
                   baixas_dpl.valor
                else
                   0
             end
          ) descto
     from prduprec
    inner join baixas_dpl
   on baixas_dpl.empresa = prduprec.empresa
      and baixas_dpl.duprec = prduprec.duprec
      and baixas_dpl.seqrecbto = prduprec.seqrecbto
    where tiporec in ( 'R',
                       'J',
                       'D' )
    group by prduprec.empresa,
             prduprec.duprec
)
select dados.*
  from (
   select distinct 'CHQ' as tipodoc,
                   pduprec.empresa as osestab,
                   nfcab.nota,
                   repre.numerocm as osrtv,
                   pduprec.cliente as numerocm,
                   prdurech.dtlanca as dtemissao,
        --PRDUPREC.DTRECBTO,
                   pduprec.dtvencto as dtvencto,
                   itemagro.item as osproduto,
                   nfitem.quantidade,
                   nfitem.valorunitario,
                   nfitem.valortotal,
                   sum(prdurech.vlrcheqrec) as valor,
                   sum(prdurech.vlrcheqrec) as saldo,
                   divide(
                      sum(prdurech.vlrcheqrec) *(divide(
                         nfitem.valortotal,
                         sum(prdurech.vlrcheqrec)
                      ) * 100),
                      100
                   ) as valorliq,
                   0 recebido,
                   arredondar(
                      divide(
                         (nfitem.valortotal) -(nfitem.quantidade * nfitem.custocmvp),
                         (nfitem.valortotal)
                      ) * 100,
                      2
                   ) as margem,
                   case
                      when arredondar(
                         divide(
                            (nfitem.valortotal) -(nfitem.quantidade * nfitem.custocmvp),
                            (nfitem.valortotal)
                         ) * 100,
                         2
                      ) between 0 and 19.99  then
                         arredondar(
                            (divide(
                               sum(prdurech.vlrcheqrec) *(divide(
                                  nfitem.valortotal,
                                  sum(prdurech.vlrcheqrec)
                               ) * 100),
                               100
                            ) * divide(
                               arredondar(
                                  divide(
                                     (nfitem.valortotal) -(nfitem.quantidade * nfitem.custocmvp),
                                     (nfitem.valortotal)
                                  ) * 100,
                                  2
                               ),
                               100
                            )) * 0.05,
                            2
                         )
                      when arredondar(
                         divide(
                            (nfitem.valortotal) -(nfitem.quantidade * nfitem.custocmvp),
                            (nfitem.valortotal)
                         ) * 100,
                         2
                      ) between 20 and 24.99 then
                         arredondar(
                            (divide(
                               sum(prdurech.vlrcheqrec) *(divide(
                                  nfitem.valortotal,
                                  sum(prdurech.vlrcheqrec)
                               ) * 100),
                               100
                            ) * divide(
                               arredondar(
                                  divide(
                                     (nfitem.valortotal) -(nfitem.quantidade * nfitem.custocmvp),
                                     (nfitem.valortotal)
                                  ) * 100,
                                  2
                               ),
                               100
                            )) * 0.08,
                            2
                         )
                      else
                         arredondar(
                            (divide(
                               sum(prdurech.vlrcheqrec) *(divide(
                                  nfitem.valortotal,
                                  sum(prdurech.vlrcheqrec)
                               ) * 100),
                               100
                            ) * divide(
                               arredondar(
                                  divide(
                                     (nfitem.valortotal) -(nfitem.quantidade * nfitem.custocmvp),
                                     (nfitem.valortotal)
                                  ) * 100,
                                  2
                               ),
                               100
                            )) * 0.1,
                            2
                         )
                   end provisaoliq,
                   nfitem.custocmvp
     from pcheqrec
    inner join prdurech
   on prdurech.empresa = pcheqrec.empresa
      and prdurech.cliente = pcheqrec.cliente
      and prdurech.nrocheque = pcheqrec.nrocheque
      and pcheqrec.dtlanca is null
    inner join prduprec
   on prduprec.empresa = prdurech.empresa
      and prduprec.duprec = prdurech.duprec
      and prduprec.seqrecbto = prdurech.seqrecbto
    inner join pduprec
   on prduprec.empresa = pduprec.empresa
      and prduprec.duprec = pduprec.duprec
    inner join contamov
   on ( pduprec.cliente = contamov.numerocm )
     left join contamov repre
   on ( pduprec.represent = repre.numerocm )
     left join agrfinduprec
   on ( pduprec.empresa = agrfinduprec.estab )
      and ( pduprec.duprec = agrfinduprec.duprec )
     left join nfcabagrfin
   on ( agrfinduprec.estab = nfcabagrfin.estab )
      and ( agrfinduprec.seqpagamento = nfcabagrfin.seqpagamento )
     left join nfitem
   on ( nfcabagrfin.estab = nfitem.estab )
      and ( nfcabagrfin.seqnota = nfitem.seqnota )
     left join itemagro
   on ( nfitem.item = itemagro.item )
     left join nfcab
   on ( nfcab.estab = nfcabagrfin.estab )
      and ( nfcab.seqnota = nfcabagrfin.seqnota )
     left join preprese
   on ( pduprec.represent = preprese.represent )
      and ( preprese.empresa = pduprec.empresa )
     left join itemgrupo
   on ( itemgrupo.grupo = itemagro.grupo )
    where pcheqrec.empresa <> 5
      and pcheqrec.dtlanca is null
      and pcheqrec.valor > 0
      and prduprec.dtrecbto <= current_date
      and repre.numerocm > 100
    group by pduprec.empresa,
             nfcab.nota,
             repre.numerocm,
             pduprec.cliente,
             prdurech.dtlanca,
             pduprec.dtvencto,
             itemagro.item,
             nfitem.quantidade,
             nfitem.valorunitario,
             nfitem.valortotal,
             pduprec.valor,
             nfitem.custocmvp
   having sum(prdurech.vlrcheqrec) > 0
   union all
   select distinct 'DUP' as tipodoc,
                   pduprec.empresa as osestab,
                   nfcab.nota,
                   repre.numerocm as osrtv,
                   pduprec.cliente as numerocm,
                   pduprec.dtemissao,
                   nfcab.prazopagto dtvencto,
                   itemagro.item as osproduto,
                   nfitem.quantidade,
                   nfitem.valorunitario,
                   nfitem.valortotal,
                   ( ( pduprec.valor ) ) valor,
                   pduprec.valor - coalesce(
                      baixas.rec,
                      0
                   ) as saldo,
                   arredondar(
                      (nfitem.valortotal + coalesce(
                         baixas.juros,
                         0
                      ) - coalesce(
                         baixas.descto,
                         0
                      ) -(divide(
                         nfitem.valortotal,
                         (pduprec.valor)
                      ) * coalesce(
                         baixas.rec,
                         0
                      ))),
                      2
                   ) as valorliq,
                   coalesce(
                      baixas.rec,
                      0
                   ) as recebido,
                   arredondar(
                      divide(
                         (nfitem.valortotal) -(nfitem.quantidade * nfitem.custocmvp),
                         (nfitem.valortotal)
                      ) * 100,
                      2
                   ) as margem,
                   case
                      when arredondar(
                         divide(
                            (nfitem.valortotal) -(nfitem.quantidade * nfitem.custocmvp),
                            (nfitem.valortotal)
                         ) * 100,
                         2
                      ) between 0 and 19.99  then
                         arredondar(
                            (arredondar(
                               (nfitem.valortotal + coalesce(
                                  baixas.juros,
                                  0
                               ) - coalesce(
                                  baixas.descto,
                                  0
                               ) -(divide(
                                  nfitem.valortotal,
                                  (pduprec.valor)
                               ) * coalesce(
                                  baixas.rec,
                                  0
                               ))),
                               2
                            ) * divide(
                               arredondar(
                                  divide(
                                     (nfitem.valortotal) -(nfitem.quantidade * nfitem.custocmvp),
                                     (nfitem.valortotal)
                                  ) * 100,
                                  2
                               ),
                               100
                            )) * 0.05,
                            2
                         )
                      when arredondar(
                         divide(
                            (nfitem.valortotal) -(nfitem.quantidade * nfitem.custocmvp),
                            (nfitem.valortotal)
                         ) * 100,
                         2
                      ) between 20 and 24.99 then
                         arredondar(
                            (arredondar(
                               (nfitem.valortotal + coalesce(
                                  baixas.juros,
                                  0
                               ) - coalesce(
                                  baixas.descto,
                                  0
                               ) -(divide(
                                  nfitem.valortotal,
                                  (pduprec.valor)
                               ) * coalesce(
                                  baixas.rec,
                                  0
                               ))),
                               2
                            ) * divide(
                               arredondar(
                                  divide(
                                     (nfitem.valortotal) -(nfitem.quantidade * nfitem.custocmvp),
                                     (nfitem.valortotal)
                                  ) * 100,
                                  2
                               ),
                               100
                            )) * 0.08,
                            2
                         )
                      else
                         arredondar(
                            (arredondar(
                               (nfitem.valortotal + coalesce(
                                  baixas.juros,
                                  0
                               ) - coalesce(
                                  baixas.descto,
                                  0
                               ) -(divide(
                                  nfitem.valortotal,
                                  (pduprec.valor)
                               ) * coalesce(
                                  baixas.rec,
                                  0
                               ))),
                               2
                            ) * divide(
                               arredondar(
                                  divide(
                                     (nfitem.valortotal) -(nfitem.quantidade * nfitem.custocmvp),
                                     (nfitem.valortotal)
                                  ) * 100,
                                  2
                               ),
                               100
                            )) * 0.1,
                            2
                         )
                   end provisaoliq,
                   nfitem.custocmvp
     from pduprec
     left join baixas
   on baixas.empresa = pduprec.empresa
      and baixas.duprec = pduprec.duprec
    inner join contamov
   on ( pduprec.cliente = contamov.numerocm )
     left join contamov repre
   on ( pduprec.represent = repre.numerocm )
     left join agrfinduprec
   on ( pduprec.empresa = agrfinduprec.estab )
      and ( pduprec.duprec = agrfinduprec.duprec )
     left join nfcabagrfin
   on ( agrfinduprec.estab = nfcabagrfin.estab )
      and ( agrfinduprec.seqpagamento = nfcabagrfin.seqpagamento )
     left join nfitem
   on ( nfcabagrfin.estab = nfitem.estab )
      and ( nfcabagrfin.seqnota = nfitem.seqnota )
     left join itemagro
   on ( nfitem.item = itemagro.item )
     left join nfcab
   on ( nfcab.estab = nfcabagrfin.estab )
      and ( nfcab.seqnota = nfcabagrfin.seqnota )
     left join preprese
   on ( pduprec.represent = preprese.represent )
      and ( preprese.empresa = pduprec.empresa )
     left join ppescli
   on ( ppescli.cliente = contamov.numerocm )
      and ( ppescli.empresa = pduprec.estabcliente )
     left join itemgrupo
   on ( itemgrupo.grupo = itemagro.grupo )
    where pduprec.empresa <> 5
      and pduprec.dtemissao <= current_date
      and repre.numerocm > 100
      and ( pduprec.valor - coalesce(
      baixas.rec,
      0
   ) ) > 0
   union all
   select distinct 'CHQ' as tipodoc,
                   pduprec.empresa as osestab,
                   nfcab.nota,
                   repre.numerocm as osrtv,
                   pduprec.cliente as numerocm,
                   prdurech.dtlanca as dtemissao,
                   pduprec.dtvencto as dtvencto,
                   itemagro.item as osproduto,
                   nfitem.quantidade,
                   nfitem.valorunitario,
                   nfitem.valortotal,
                   sum(prdurech.vlrcheqrec) as valor,
                   sum(prdurech.vlrcheqrec) as saldo,
                   divide(
                      sum(prdurech.vlrcheqrec) *(divide(
                         nfitem.valortotal,
                         sum(prdurech.vlrcheqrec)
                      ) * 100),
                      100
                   ) as valorliq,
                   0 recebido,
                   arredondar(
                      divide(
                         (nfitem.valortotal) -(nfitem.quantidade * nfitem.custocmvp),
                         (nfitem.valortotal)
                      ) * 100,
                      2
                   ) as margem,
                   case
                      when preprese.comisconf = 9  then
                         arredondar(
                            divide(
                               sum(prdurech.vlrcheqrec) *(divide(
                                  nfitem.valortotal,
                                  sum(prdurech.vlrcheqrec)
                               ) * 100),
                               100
                            ) * 0.05,
                            2
                         )
                      when preprese.comisconf = 10 then
                         arredondar(
                            divide(
                               sum(prdurech.vlrcheqrec) *(divide(
                                  nfitem.valortotal,
                                  sum(prdurech.vlrcheqrec)
                               ) * 100),
                               100
                            ) * 0.03,
                            2
                         )
                      when preprese.comisconf = 11 then
                         arredondar(
                            divide(
                               sum(prdurech.vlrcheqrec) *(divide(
                                  nfitem.valortotal,
                                  sum(prdurech.vlrcheqrec)
                               ) * 100),
                               100
                            ) * 0.05,
                            2
                         )
                      else
                         arredondar(
                            divide(
                               sum(prdurech.vlrcheqrec) *(divide(
                                  nfitem.valortotal,
                                  sum(prdurech.vlrcheqrec)
                               ) * 100),
                               100
                            ) * 0.05,
                            2
                         )
                   end provisaoliq,
                   nfitem.custocmvp
     from pcheqrec
    inner join prdurech
   on prdurech.empresa = pcheqrec.empresa
      and prdurech.cliente = pcheqrec.cliente
      and prdurech.nrocheque = pcheqrec.nrocheque
      and pcheqrec.dtlanca is null
    inner join prduprec
   on prduprec.empresa = prdurech.empresa
      and prduprec.duprec = prdurech.duprec
      and prduprec.seqrecbto = prdurech.seqrecbto
    inner join pduprec
   on prduprec.empresa = pduprec.empresa
    --AND PRDUPREC.CLIENTE = PDUPREC.CLIENTE
      and prduprec.duprec = pduprec.duprec
    inner join contamov
   on ( pduprec.cliente = contamov.numerocm )
     left join contamov repre
   on ( pduprec.represent = repre.numerocm )
     left join agrfinduprec
   on ( pduprec.empresa = agrfinduprec.estab )
      and ( pduprec.duprec = agrfinduprec.duprec )
     left join nfcabagrfin
   on ( agrfinduprec.estab = nfcabagrfin.estab )
      and ( agrfinduprec.seqpagamento = nfcabagrfin.seqpagamento )
     left join nfitem
   on ( nfcabagrfin.estab = nfitem.estab )
      and ( nfcabagrfin.seqnota = nfitem.seqnota )
     left join itemagro
   on ( nfitem.item = itemagro.item )
     left join nfcab
   on ( nfcab.estab = nfcabagrfin.estab )
      and ( nfcab.seqnota = nfcabagrfin.seqnota )
     left join preprese
   on ( pduprec.represent = preprese.represent )
      and ( preprese.empresa = pduprec.empresa )
     left join itemgrupo
   on ( itemgrupo.grupo = itemagro.grupo )
    where pcheqrec.empresa = 5
      and pcheqrec.dtlanca is null
      and pcheqrec.valor > 0
      and prduprec.dtrecbto <= current_date
      and repre.numerocm > 100
    group by pduprec.empresa,
             nfcab.nota,
             repre.numerocm,
             preprese.comisconf,
             pduprec.cliente,
             prdurech.dtlanca,
             pduprec.dtvencto,
             itemagro.item,
             nfitem.quantidade,
             nfitem.valorunitario,
             nfitem.valortotal,
             pduprec.valor,
             nfitem.custocmvp
   having sum(prdurech.vlrcheqrec) > 0
   union all
   select distinct 'DUP' as tipodoc,
                   pduprec.empresa as osestab,
                   nfcab.nota,
                   repre.numerocm as osrtv,
                   pduprec.cliente as numerocm,
                   pduprec.dtemissao,
                   nfcab.prazopagto dtvencto,
                   itemagro.item as osproduto,
                   nfitem.quantidade,
                   nfitem.valorunitario,
                   nfitem.valortotal,
                   ( ( pduprec.valor ) ) valor,
                   pduprec.valor - coalesce(
                      baixas.rec,
                      0
                   ) as saldo,
                   arredondar(
                      (nfitem.valortotal + coalesce(
                         baixas.juros,
                         0
                      ) - coalesce(
                         baixas.descto,
                         0
                      ) -(divide(
                         nfitem.valortotal,
                         (pduprec.valor)
                      ) * coalesce(
                         baixas.rec,
                         0
                      ))),
                      2
                   ) as valorliq,
                   coalesce(
                      baixas.rec,
                      0
                   ) as recebido,
                   arredondar(
                      divide(
                         (nfitem.valortotal) -(nfitem.quantidade * nfitem.custocmvp),
                         (nfitem.valortotal)
                      ) * 100,
                      2
                   ) as margem,
                   case
                      when preprese.comisconf = 9  then
                         arredondar(
                            (nfitem.valortotal + coalesce(
                               baixas.juros,
                               0
                            ) - coalesce(
                               baixas.descto,
                               0
                            ) -(divide(
                               nfitem.valortotal,
                               (pduprec.valor)
                            ) * coalesce(
                               baixas.rec,
                               0
                            ))) * 0.005,
                            2
                         )
                      when preprese.comisconf = 10 then
                         arredondar(
                            (nfitem.valortotal + coalesce(
                               baixas.juros,
                               0
                            ) - coalesce(
                               baixas.descto,
                               0
                            ) -(divide(
                               nfitem.valortotal,
                               (pduprec.valor)
                            ) * coalesce(
                               baixas.rec,
                               0
                            ))) * 0.003,
                            2
                         )
                      when preprese.comisconf = 11 then
                         arredondar(
                            (nfitem.valortotal + coalesce(
                               baixas.juros,
                               0
                            ) - coalesce(
                               baixas.descto,
                               0
                            ) -(divide(
                               nfitem.valortotal,
                               (pduprec.valor)
                            ) * coalesce(
                               baixas.rec,
                               0
                            ))) * 0.01,
                            2
                         )
                      else
                         arredondar(
                            (nfitem.valortotal + coalesce(
                               baixas.juros,
                               0
                            ) - coalesce(
                               baixas.descto,
                               0
                            ) -(divide(
                               nfitem.valortotal,
                               (pduprec.valor)
                            ) * coalesce(
                               baixas.rec,
                               0
                            ))) * 0.005,
                            2
                         )
                   end provisaoliq,
                   nfitem.custocmvp
     from pduprec
     left join baixas
   on baixas.empresa = pduprec.empresa
      and baixas.duprec = pduprec.duprec
    inner join contamov
   on ( pduprec.cliente = contamov.numerocm )
     left join contamov repre
   on ( pduprec.represent = repre.numerocm )
     left join agrfinduprec
   on ( pduprec.empresa = agrfinduprec.estab )
      and ( pduprec.duprec = agrfinduprec.duprec )
     left join nfcabagrfin
   on ( agrfinduprec.estab = nfcabagrfin.estab )
      and ( agrfinduprec.seqpagamento = nfcabagrfin.seqpagamento )
     left join nfitem
   on ( nfcabagrfin.estab = nfitem.estab )
      and ( nfcabagrfin.seqnota = nfitem.seqnota )
     left join itemagro
   on ( nfitem.item = itemagro.item )
     left join nfcab
   on ( nfcab.estab = nfcabagrfin.estab )
      and ( nfcab.seqnota = nfcabagrfin.seqnota )
     left join preprese
   on ( pduprec.represent = preprese.represent )
           -- AND (PREPRESE.EMPRESA = PDUPREC.EMPRESA)
     left join ppescli
   on ( ppescli.cliente = contamov.numerocm )
      and ( ppescli.empresa = pduprec.estabcliente )
     left join itemgrupo
   on ( itemgrupo.grupo = itemagro.grupo )
    where pduprec.empresa = 5
      and pduprec.dtemissao <= current_date
      and ( pduprec.valor - coalesce(
      baixas.rec,
      0
   ) ) > 0
      and repre.numerocm > 100
) dados
 where dados.provisaoliq > 0