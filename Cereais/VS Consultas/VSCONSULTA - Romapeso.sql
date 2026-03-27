with peso as (
   select  romapeso.*,
          contamov.nome as nomeforn,
          itemagro.descricao as nomeitem,
          transp.nome as nomeprestador,
          terceiros.nome as nometerceiros,
          cast('' as varchar(20)) as autorizado,
          cast('' as varchar(20)) as autorizadoromaquali,
          ( romapeso.pesototal - romapeso.tara ) as pesoliquido,
          romacfg.obrigaph
     from romapeso
    inner join romacfg
   on romacfg.romaneioconfig = romapeso.romaneioconfig
     left join contamov
   on ( contamov.numerocm = romapeso.numerocm )
     left join contamov transp
   on ( transp.numerocm = romapeso.prestador )
     left join contamov terceiros
   on ( terceiros.numerocm = romapeso.terceiros )
     left join itemagro
   on ( itemagro.item = romapeso.item )
    -- USUARIO DA TELA
     left join pusers
   on ( pusers.userid = :USERID )
    where not exists (
      select 1
        from romapesofat
       where romapesofat.estab = romapeso.estab
         and romapesofat.placa = romapeso.placa
         and romapesofat.sequencia = romapeso.sequencia
         and romapesofat.numerocm = romapeso.numerocm
   )
      and romapeso.estab = :ESTAB
      /*Se estiver para visualizar todas as leituras de peso*/
      and ( ( pusers.visuleitpeso = 'S' )
       or
       /* ou o usuário só pode ver suas leituras de peso*/ ( ( romapeso.userid = :USERID )
      and ( pusers.visuleitpeso = 'N' ) ) )
),leitura as (
   select l.estab,
          l.placa,
          l.sequencia,
          sum(
             case
                when coalesce(
                   l.liberado,
                   'N'
                ) = 'S' then
                   1
                else
                   0
             end
          ) libe,
          sum(
             case
                when coalesce(
                   l.liberado,
                   'N'
                ) = 'N' then
                   1
                else
                   0
             end
          ) bloq,
          sum(
             case
                when coalesce(
                   l.liberado,
                   'N'
                ) = 'C' then
                   1
                else
                   0
             end
          ) canc,
          max(
             case
                when l.tipoliberacao = 'E' then
                   1
             end
          ) tem_liberacao
     from leituraaut l
    inner join peso
   on peso.estab = l.estab
      and peso.placa = l.placa
      and peso.sequencia = l.sequencia
      and ( ( l.id = peso.idpesototalmanual )
       or ( l.id = peso.idtaramanual )
       or ( l.id = peso.idautorizacaopeso )
       or ( l.id = peso.idautorizacaodescont )
       or ( l.id = peso.idautorizaembarque ) )
    group by l.estab,
             l.placa,
             l.sequencia
),info_descto as (
   select r.estab,
          r.placa,
          r.sequencia,
          max(
             case
                when r.obrigatorio = 'S' then
                   'S'
             end
          ) obrdesctos,
          max(
             case
                when r.obrigatorio = 'S'
                   and r.reftabela = 0 then
                   'N'
             end
          ) desctosok
     from romapesodesc r
    inner join peso
   on peso.estab = r.estab
      and peso.placa = r.placa
      and peso.sequencia = r.sequencia
    group by r.estab,
             r.placa,
             r.sequencia
),qualidade as (
   select distinct q.estab,
                   q.placa,
                   q.sequencia,
                   max(
                      case
                         when alterougrau = 'N' then
                            1
                         else
                            0
                      end
                   ) as qualidadeok,
                   max(
                      case
                         when a.autorizado <> 'S' then
                            1
                      end
                   ) qualidade_pendente,
                   max(a.autorizado) autorizado
     from romapesoqualidade q
    inner join peso
   on peso.estab = q.estab
      and peso.placa = q.placa
      and peso.sequencia = q.sequencia
     left join autoromaquali a
   on a.sequencia = q.seqautorizacao
    group by q.estab,
             q.placa,
             q.sequencia
),class_semente as (
   select distinct c.estab,
                   c.placa,
                   c.sequencia
     from romapesoclass c
    inner join romaclassnome n
   on n.classificacao = c.classificacao
    inner join peso
   on peso.estab = c.estab
      and peso.placa = c.placa
      and peso.sequencia = c.sequencia
    where c.percentual > 0
      and n.semente = 'S'
),peso_final as (
   select peso.*,
          info_descto.obrdesctos,
          NVL(info_descto.desctosok,'S') AS desctosok,
          case
             when qualidade.qualidadeok = 1 then
                'N'
             else
                'S'
          end as qualidadeok,
          nvl(leitura.libe,0)libe,
          nvl(leitura.bloq,0)bloq,
          nvl(leitura.canc,0)canc,
          qualidade.autorizado as qualidadeaprova,
          leitura.tem_liberacao,
          qualidade.qualidade_pendente,
          case
             when class_semente.estab is not null then
                1
          end as tem_semente
     from peso
     left join info_descto
   on info_descto.estab = peso.estab
      and info_descto.placa = peso.placa
      and info_descto.sequencia = peso.sequencia
     left join qualidade
   on qualidade.estab = peso.estab
      and qualidade.placa = peso.placa
      and qualidade.sequencia = peso.sequencia
     left join leitura
   on leitura.estab = peso.estab
      and leitura.placa = peso.placa
      and leitura.sequencia = peso.sequencia
     left join class_semente
   on class_semente.estab = peso.estab
      and class_semente.placa = peso.placa
      and class_semente.sequencia = peso.sequencia
),dados as (
   select
    ----- 1 VALIDAÇÃO DA VSCONSULTA
    peso_final.*
     from peso_final
    where ( peso_final.pesototal = 0
       or peso_final.tara = 0
       or peso_final.salvalepesosemroma = 'S'
       or peso_final.numerocm is null )
   union all
   select
    ----- 2 VALIDAÇÃO DA VSCONSULTA
    peso_final.*
     from peso_final
    where ( peso_final.idautorizacaopeso > 0
       or peso_final.idautorizacaodescont > 0 )
      and peso_final.tem_liberacao = 1
   union all
   select
    ----- 3 VALIDAÇÃO DA VSCONSULTA
    peso_final.*
     from peso_final
    where peso_final.qualidade_pendente = 1
      and peso_final.tem_semente = 1
   union all
   select
    ----- 4 VALIDAÇÃO DA VSCONSULTA
    peso_final.*
     from peso_final
    where peso_final.pesototal > 0
      and peso_final.tara > 0
      and peso_final.obrigaph = 'L'
      and peso_final.phoriginal < 0
)
select estab,
       placa,
       sequencia,
       numerocm,
       item,
       obs,
       dtpeso,
       pesototal,
       tara,
       ticketbalanca,
       prestador,
       qualcontrato,
       seqendereco,
       terceiros,
       horapesotot,
       horapesotara,
       tiporoma,
       seqimp,
       seqenderecoter,
       areacampo,
       dtpesotara,
       seqprog,
       manualpeso,
       manualtara,
       romaneioconfig,
       codbarrasprodutor,
       userid,
       nfprodutor,
       serienfprodutor,
       phoriginal,
       nrovagao,
       motorista,
       ufplaca,
       pesoorigem,
       mand_amostra1,
       mand_amostra2,
       mand_amostra3,
       mand_media,
       fototara,
       placa1,
       placa2,
       tpveic,
       safra,
       tirouamostra,
       amospend_id,
       local,
       percsemaprov,
       fn,
       gercevada,
       salvalepesosemroma,
       possiveltara,
       idpesototalmanual,
       idtaramanual,
       campo,
       variedade,
       cultura,
       mand_amostra4,
       mand_amostra5,
       mand_amostra6,
       idautorizacaopeso,
       pesograointarroz,
       pesograoquearroz,
       pesocascaarroz,
       pesofareloarroz,
       dtnfprodutor,
       chaveacessonfp,
       cod_motorista,
       idautorizacaodescont,
       ultalt,
       seqrelacionada,
       sincronizado,
       seqimpoffline,
       alertarecolhimento,
       idautorizaembarque,
       geroufinanceiro,
       roma_campo,
       seqnotatransp,
       estabnotatransp,
       cod_roma_cotton,
       safra_cotton,
       estab_cotton,
       finalidadetipo,
       rfid,
       statussync,
       guid,
       calcfreteloc,
       u_ph,
       u_fn,
       nomeforn,
       nomeitem,
       nomeprestador,
       nometerceiros,
       idpesototalmanual as idpesototalmanual_1,
       idtaramanual as idtaramanual_1,
       autorizado,
       autorizadoromaquali,
       pesoliquido,
       obrdesctos,
       desctosok,
       qualidadeok,
       libe,
       bloq,
       canc,
       qualidadeaprova
  from dados"