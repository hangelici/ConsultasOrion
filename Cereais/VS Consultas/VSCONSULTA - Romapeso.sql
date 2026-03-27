SELECT /*+ 
    GATHER_PLAN_STATISTICS
    QB_NAME(MAIN_QB)
    LEADING(peso)
    USE_NL(info_descto qualidade leitura class_semente)
*/

peso.estab,
peso.placa,
peso.sequencia,
peso.numerocm,
peso.item,
peso.obs,
peso.dtpeso,
peso.pesototal,
peso.tara,
peso.ticketbalanca,
peso.prestador,
peso.qualcontrato,
peso.seqendereco,
peso.terceiros,
peso.horapesotot,
peso.horapesotara,
peso.tiporoma,
peso.seqimp,
peso.seqenderecoter,
peso.areacampo,
peso.dtpesotara,
peso.seqprog,
peso.manualpeso,
peso.manualtara,
peso.romaneioconfig,
peso.codbarrasprodutor,
peso.userid,
peso.nfprodutor,
peso.serienfprodutor,
peso.phoriginal,
peso.nrovagao,
peso.motorista,
peso.ufplaca,
peso.pesoorigem,
peso.mand_amostra1,
peso.mand_amostra2,
peso.mand_amostra3,
peso.mand_media,
peso.fototara,
peso.placa1,
peso.placa2,
peso.tpveic,
peso.safra,
peso.tirouamostra,
peso.amospend_id,
peso.local,
peso.percsemaprov,
peso.fn,
peso.gercevada,
peso.salvalepesosemroma,
peso.possiveltara,
peso.idpesototalmanual,
peso.idtaramanual,
peso.campo,
peso.variedade,
peso.cultura,
peso.mand_amostra4,
peso.mand_amostra5,
peso.mand_amostra6,
peso.idautorizacaopeso,
peso.pesograointarroz,
peso.pesograoquearroz,
peso.pesocascaarroz,
peso.pesofareloarroz,
peso.dtnfprodutor,
peso.chaveacessonfp,
peso.cod_motorista,
peso.idautorizacaodescont,
peso.ultalt,
peso.seqrelacionada,
peso.sincronizado,
peso.seqimpoffline,
peso.alertarecolhimento,
peso.idautorizaembarque,
peso.geroufinanceiro,
peso.roma_campo,
peso.seqnotatransp,
peso.estabnotatransp,
peso.cod_roma_cotton,
peso.safra_cotton,
peso.estab_cotton,
peso.finalidadetipo,
peso.rfid,
peso.statussync,
peso.guid,
peso.calcfreteloc,
peso.u_ph,
peso.u_fn,
peso.nomeforn,
peso.nomeitem,
peso.nomeprestador,
peso.nometerceiros,

-- duplicados
peso.idpesototalmanual AS idpesototalmanual_1,
peso.idtaramanual AS idtaramanual_1,

-- calculados
CAST('' AS VARCHAR2(20)) AS autorizado,
CAST('' AS VARCHAR2(20)) AS autorizadoromaquali,
peso.pesoliquido,
info_descto.obrdesctos,
NVL(info_descto.desctosok,'S') AS desctosok,

CASE 
    WHEN qualidade.qualidadeok = 1 THEN 'N'
    ELSE 'S'
END AS qualidadeok,

NVL(leitura.libe,0) AS libe,
NVL(leitura.bloq,0) AS bloq,
NVL(leitura.canc,0) AS canc,
qualidade.autorizado AS qualidadeaprova

FROM (

    SELECT /*+ 
        QB_NAME(PESO_QB)
        MATERIALIZE
        NO_MERGE
        INDEX_RS_ASC(rp IDX_ROMAPESO_ESTAB)
    */
        rp.*,
        cm.nome AS nomeforn,
        ia.descricao AS nomeitem,
        transp.nome AS nomeprestador,
        terceiros.nome AS nometerceiros,
        (rp.pesototal - rp.tara) AS pesoliquido,
        rc.obrigaph
    FROM romapeso rp
    INNER JOIN romacfg rc
        ON rc.romaneioconfig = rp.romaneioconfig
    LEFT JOIN contamov cm
        ON cm.numerocm = rp.numerocm
    LEFT JOIN contamov transp
        ON transp.numerocm = rp.prestador
    LEFT JOIN contamov terceiros
        ON terceiros.numerocm = rp.terceiros
    LEFT JOIN itemagro ia
        ON ia.item = rp.item
    LEFT JOIN pusers pu
        ON pu.userid = :USERID
    WHERE 
        rp.estab = :ESTAB
        AND NOT EXISTS (
            SELECT /*+ USE_NL */ 1
            FROM romapesofat rf
            WHERE rf.estab = rp.estab
              AND rf.placa = rp.placa
              AND rf.sequencia = rp.sequencia
              AND rf.numerocm = rp.numerocm
        )
        AND (
            pu.visuleitpeso = 'S'
            OR (rp.userid = :USERID AND pu.visuleitpeso = 'N')
        )

) peso

LEFT JOIN (
    SELECT /*+ MATERIALIZE */
        r.estab,r.placa,r.sequencia,
        MAX(CASE WHEN r.obrigatorio='S' THEN 'S' END) obrdesctos,
        MAX(CASE WHEN r.obrigatorio='S' AND r.reftabela=0 THEN 'N' END) desctosok
    FROM romapesodesc r
    GROUP BY r.estab,r.placa,r.sequencia
) info_descto
ON info_descto.estab = peso.estab
AND info_descto.placa = peso.placa
AND info_descto.sequencia = peso.sequencia

LEFT JOIN (
    SELECT /*+ MATERIALIZE */
        q.estab,q.placa,q.sequencia,
        MAX(CASE WHEN alterougrau='N' THEN 1 ELSE 0 END) qualidadeok,
        MAX(CASE WHEN a.autorizado <> 'S' THEN 1 END) qualidade_pendente,
        MAX(a.autorizado) autorizado
    FROM romapesoqualidade q
    LEFT JOIN autoromaquali a
        ON a.sequencia = q.seqautorizacao
    GROUP BY q.estab,q.placa,q.sequencia
) qualidade
ON qualidade.estab = peso.estab
AND qualidade.placa = peso.placa
AND qualidade.sequencia = peso.sequencia

LEFT JOIN (
    SELECT /*+ MATERIALIZE */
        l.estab,l.placa,l.sequencia,
        SUM(CASE WHEN NVL(l.liberado,'N')='S' THEN 1 ELSE 0 END) libe,
        SUM(CASE WHEN NVL(l.liberado,'N')='N' THEN 1 ELSE 0 END) bloq,
        SUM(CASE WHEN NVL(l.liberado,'N')='C' THEN 1 ELSE 0 END) canc,
        MAX(CASE WHEN l.tipoliberacao='E' THEN 1 END) tem_liberacao
    FROM leituraaut l
    GROUP BY l.estab,l.placa,l.sequencia
) leitura
ON leitura.estab = peso.estab
AND leitura.placa = peso.placa
AND leitura.sequencia = peso.sequencia

LEFT JOIN (
    SELECT /*+ MATERIALIZE */
        c.estab,c.placa,c.sequencia
    FROM romapesoclass c
    INNER JOIN romaclassnome n
        ON n.classificacao = c.classificacao
    WHERE c.percentual > 0
      AND n.semente = 'S'
    GROUP BY c.estab,c.placa,c.sequencia
) class_semente
ON class_semente.estab = peso.estab
AND class_semente.placa = peso.placa
AND class_semente.sequencia = peso.sequencia

WHERE
(
    peso.pesototal = 0
    OR peso.tara = 0
    OR peso.salvalepesosemroma = 'S'
    OR peso.numerocm IS NULL

    OR (
        (peso.idautorizacaopeso > 0 OR peso.idautorizacaodescont > 0)
        AND leitura.tem_liberacao = 1
    )

    OR (
        qualidade.qualidade_pendente = 1
        AND class_semente.estab IS NOT NULL
    )

    OR (
        peso.pesototal > 0
        AND peso.tara > 0
        AND peso.obrigaph = 'L'
        AND peso.phoriginal < 0
    )
);