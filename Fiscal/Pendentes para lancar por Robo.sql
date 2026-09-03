 WITH params AS (
    SELECT
        TRUNC(ADD_MONTHS(SYSDATE, -1), 'MM') AS dt_inicial,
        TRUNC(SYSDATE, 'MM') AS dt_final
    FROM dual
),
baseimp AS (
    SELECT
        EXTRACT(YEAR FROM nfcab.dtentsai) AS ano,
        EXTRACT(MONTH FROM nfcab.dtentsai) AS mes,
        nfcab.estab,
        nfcab.numerocm,
        SUM(valorimposto) AS valorimposto
    FROM
        nfcab
        CROSS JOIN params
        INNER JOIN nfcabimposto i ON i.estab = nfcab.estab
                                  AND i.seqnota = nfcab.seqnota
    WHERE
        nfcab.dtentsai >= params.dt_inicial
        AND nfcab.dtentsai < params.dt_final
        AND nfcab.notaconf = 616
    GROUP BY
        EXTRACT(YEAR FROM nfcab.dtentsai),
        EXTRACT(MONTH FROM nfcab.dtentsai),
        nfcab.numerocm,
        nfcab.estab
),
os11_nfcab_a AS (
    SELECT
        nfcab_a.estab,
        nfcab_a.seqnota,
        nfitem.seqnotaitem,
        nfitem.quantidade,
        nfcab_a.numerocm,
        nfcfg_nota.naturezadaoperacao,
        nfcfg_nota.entradasaida
    FROM
        nfcab nfcab_a
        LEFT JOIN nfcfg nfcfg_nota ON nfcfg_nota.notaconf = nfcab_a.notaconf
        INNER JOIN filial ON filial.estab = nfcab_a.estab
        INNER JOIN cidade ON cidade.cidade = filial.cidade
        INNER JOIN u_tempresa t ON t.estab = filial.estab
        INNER JOIN nfitem ON nfitem.estab = nfcab_a.estab
                          AND nfitem.seqnota = nfcab_a.seqnota
    WHERE
        COALESCE(nfcab_a.status, 'N') <> 'C'
        AND nfcfg_nota.entradasaida = 'E'
        AND cidade.uf = 'SP'
        AND t.graos = 'S'
        AND t.emitenfse = 'N'
),
os11_apartirde_base AS (
    SELECT
        n.estaborigem,
        n.seqnotaorigem,
        n.seqnotaitemorigem,
        nfcab.numerocm,
        NVL(n.seqtransf, 0) AS seqtransf,
        natoperacao.tipodcto,
        CASE
            WHEN natoperacao.tipodcto IN ('X', 'N') THEN n.quantidade
            ELSE 0
        END AS quantidade,
        CASE
            WHEN natoperacao.tipodcto IN ('D') THEN n.quantidade
            ELSE 0
        END AS qtd_d,
        CASE
            WHEN natoperacao.tipodcto IN ('D') THEN n.qtdearmazenagem
            ELSE 0
        END AS qtdearmazenagem,
        CASE
            WHEN natoperacao.tipodcto IN ('D') THEN n.desctoseguro
            ELSE 0
        END AS desctoseguro,
        CASE
            WHEN natoperacao.tipodcto IN ('D') THEN n.desctoquebra
            ELSE 0
        END AS desctoquebra,
        CASE
            WHEN natoperacao.tipodcto IN ('D') THEN n.desctoexped
            ELSE 0
        END AS desctoexped,
        CASE
            WHEN natoperacao.tipodcto IN ('D') THEN n.desctofinalidade
            ELSE 0
        END AS desctofinalidade
    FROM
        nfitemapartirde n
        INNER JOIN filial ON filial.estab = n.estab
        INNER JOIN u_tempresa t ON t.estab = filial.estab
        INNER JOIN cidade ON cidade.cidade = filial.cidade
        INNER JOIN nfcab ON nfcab.estab = n.estab
                        AND nfcab.seqnota = n.seqnota
        INNER JOIN nfcfg ON nfcfg.notaconf = nfcab.notaconf
        LEFT JOIN natoperacao ON natoperacao.naturezadaoperacao = nfcfg.naturezadaoperacao
                              AND natoperacao.entradasaida = nfcfg.entradasaida
    WHERE
        natoperacao.tipodcto IN ('X', 'N', 'D')
        AND t.graos = 'S'
        AND cidade.uf = 'SP'
        AND t.emitenfse = 'N'
),
os11_apartirde AS (
    SELECT
        b.estaborigem,
        b.seqnotaorigem,
        b.seqnotaitemorigem,
        b.numerocm,
        SUM(b.quantidade) AS quantidade,
        SUM(b.qtd_d) AS qtd_d,
        SUM(b.qtdearmazenagem) AS qtdearmazenagem,
        SUM(b.desctoseguro) AS desctoseguro,
        SUM(b.desctoquebra) AS desctoquebra,
        SUM(b.desctoexped) AS desctoexped,
        SUM(b.desctofinalidade) AS desctofinalidade
    FROM
        os11_apartirde_base b
    WHERE
        b.seqtransf = 0
    GROUP BY
        b.estaborigem,
        b.seqnotaorigem,
        b.seqnotaitemorigem,
        b.numerocm
),
os11_transf_base AS (
    SELECT
        tr.estab,
        tr.seqnota,
        tr.seqnotaitem,
        NVL(tr.seqtransf, 0) AS seqtransf,
        tr.qtdetransf,
        tr.cedente,
        tr.destinatario
    FROM
        nfitemtransf tr
        INNER JOIN filial ON filial.estab = tr.estab
        INNER JOIN u_tempresa te ON te.estab = filial.estab
    WHERE
        te.graos = 'S'
        AND te.emitenfse = 'N'
),
os11_transf_destinatario AS (
    SELECT
        os11_transf_base.estab,
        os11_transf_base.seqnota,
        os11_transf_base.seqnotaitem,
        os11_transf_base.destinatario,
        SUM(os11_transf_base.qtdetransf) AS qtdetransf_destinatario
    FROM
        os11_transf_base
    WHERE
        os11_transf_base.seqtransf <> 0
        AND NOT EXISTS (
            SELECT
                1
            FROM
                nfitemapartirde f
            WHERE
                f.estaborigem = os11_transf_base.estab
                AND f.seqnotaorigem = os11_transf_base.seqnota
                AND f.seqnotaitemorigem = os11_transf_base.seqnotaitem
                AND f.seqtransf = os11_transf_base.seqtransf
        )
    GROUP BY
        os11_transf_base.estab,
        os11_transf_base.seqnota,
        os11_transf_base.seqnotaitem,
        os11_transf_base.destinatario
),
os11_transf_cedente AS (
    SELECT
        os11_transf_base.estab,
        os11_transf_base.seqnota,
        os11_transf_base.seqnotaitem,
        os11_transf_base.cedente,
        SUM(os11_transf_base.qtdetransf) AS qtdetransf_cedente
    FROM
        os11_transf_base
    WHERE
        os11_transf_base.seqtransf <> 0
        AND NOT EXISTS (
            SELECT
                1
            FROM
                os11_apartirde_base ab
            WHERE
                ab.estaborigem = os11_transf_base.estab
                AND ab.seqnotaorigem = os11_transf_base.seqnota
                AND ab.seqnotaitemorigem = os11_transf_base.seqnotaitem
                AND ab.seqtransf = os11_transf_base.seqtransf
                AND ab.tipodcto IN ('D')
        )
    GROUP BY
        os11_transf_base.estab,
        os11_transf_base.seqnota,
        os11_transf_base.seqnotaitem,
        os11_transf_base.cedente
),
os11_base_tab AS (
    SELECT
        nfitemtxservico.estab,
        nfitemtxservico.seqnota,
        nfitemtxservico.seqnotaitem,
        nfitemtxservico.sequencia,
        nfitemtxservico.tabperserv,
        nfitemtxservico.tabprcserv,
        nfitemtxservico.cobunica,
        nfitemtxservico.servico
    FROM
        nfitemtxservico
        INNER JOIN filial ON filial.estab = nfitemtxservico.estab
        INNER JOIN u_tempresa t ON t.estab = filial.estab
        INNER JOIN cidade ON cidade.cidade = filial.cidade
    WHERE
        nfitemtxservico.situacao = 'P'
        AND nfitemtxservico.servico = 30
        AND t.graos = 'S'
        AND cidade.uf = 'SP'
        AND t.emitenfse = 'N'
        AND (
            (
                nfitemtxservico.cobunica IN ('S', 'C')
                AND NOT EXISTS (
                    SELECT
                        1
                    FROM
                        nfitempgservico
                    WHERE
                        estab = nfitemtxservico.estab
                        AND seqnotadep = nfitemtxservico.seqnota
                        AND seqnotaitemdep = nfitemtxservico.seqnotaitem
                        AND sequencia = nfitemtxservico.sequencia
                )
                AND NOT EXISTS (
                    SELECT
                        1
                    FROM
                        nfitemtxservicopg
                    WHERE
                        estab = nfitemtxservico.estab
                        AND seqnota = nfitemtxservico.seqnota
                        AND seqnotaitem = nfitemtxservico.seqnotaitem
                        AND sequencia = nfitemtxservico.sequencia
                )
            )
            OR nfitemtxservico.cobunica = 'N'
        )
        AND NOT EXISTS (
            SELECT
                1
            FROM
                cobserconc
            WHERE
                cobserconc.estab = nfitemtxservico.estab
                AND cobserconc.seqnotadep = nfitemtxservico.seqnota
                AND cobserconc.seqnotaitemdep = nfitemtxservico.seqnotaitem
                AND cobserconc.servico = nfitemtxservico.servico
        )
),
os11_parcial AS (
    SELECT
        p.estabori,
        p.seqnotaori,
        p.seqnotaitemori,
        p.sequenciaori,
        SUM(p.qtdbasecalc) AS qtdbasecalc
    FROM
        nfitemtxservparcial p
        INNER JOIN u_tempresa t ON t.estab = p.estab
    WHERE
        t.emitenfse = 'N'
    GROUP BY
        p.estabori,
        p.seqnotaori,
        p.seqnotaitemori,
        p.sequenciaori
),
os11_retencao AS (
    SELECT
        retenporto.estab,
        retenporto.seqnota,
        retenporto.seqnotaitem,
        retenporto.item,
        NVL(retenporto.pesoretencao, 0) AS pesoretencao
    FROM
        retenporto
        INNER JOIN u_tempresa ON u_tempresa.estab = retenporto.estab
    WHERE
        retenporto.transacao = 'E'
        AND u_tempresa.emitenfse = 'S'
),
os11_saldo_temp AS (
    SELECT
        nf.estab,
        nf.seqnota,
        nf.seqnotaitem,
        nf.numerocm,
        nf.naturezadaoperacao,
        nf.entradasaida,
        (
            nf.quantidade
            + NVL(td.qtdetransf_destinatario, 0)
            - (
                NVL(os11_apartirde.quantidade, 0)
                + NVL(os11_apartirde.qtd_d, 0)
                + NVL(os11_apartirde.qtdearmazenagem, 0)
                + NVL(os11_apartirde.desctoseguro, 0)
                + NVL(os11_apartirde.desctoquebra, 0)
                + NVL(os11_apartirde.desctoexped, 0)
                + NVL(os11_apartirde.desctofinalidade, 0)
                + NVL(tc.qtdetransf_cedente, 0)
            )
        ) AS saldo
    FROM
        os11_nfcab_a nf
        LEFT JOIN os11_apartirde ON os11_apartirde.estaborigem = nf.estab
                                AND os11_apartirde.seqnotaorigem = nf.seqnota
                                AND os11_apartirde.seqnotaitemorigem = nf.seqnotaitem
                                AND os11_apartirde.numerocm = nf.numerocm
        LEFT JOIN os11_transf_destinatario td ON td.estab = nf.estab
                                             AND td.seqnota = nf.seqnota
                                             AND td.seqnotaitem = nf.seqnotaitem
                                             AND td.destinatario = nf.numerocm
        LEFT JOIN os11_transf_cedente tc ON tc.estab = nf.estab
                                        AND tc.seqnota = nf.seqnota
                                        AND tc.seqnotaitem = nf.seqnotaitem
                                        AND tc.cedente = nf.numerocm
),
os11_dv AS (
    SELECT
        'DV' AS tipo,
        nfitempgservico.estab,
        contamov.numerocm,
        nfcab_dep.seqendereco,
        nfitemtxservico.servico,
        itemagronf.item AS item,
        roma.romaneio
    FROM
        nfitempgservico
        JOIN filial ON filial.estab = nfitempgservico.estab
        JOIN u_tempresa t ON t.estab = filial.estab
        JOIN cidade ON cidade.cidade = filial.cidade
        JOIN nfitemtxservico ON nfitemtxservico.estab = nfitempgservico.estab
                            AND nfitemtxservico.seqnota = nfitempgservico.seqnotadep
                            AND nfitemtxservico.seqnotaitem = nfitempgservico.seqnotaitemdep
                            AND nfitemtxservico.sequencia = nfitempgservico.sequencia
        JOIN nfitem nfitem_dev ON nfitem_dev.estab = nfitempgservico.estabdev
                              AND nfitem_dev.seqnota = nfitempgservico.seqnotadev
                              AND nfitem_dev.seqnotaitem = nfitempgservico.seqnotaitemdev
        JOIN nfitem nfitem_dep ON nfitem_dep.estab = nfitemtxservico.estab
                              AND nfitem_dep.seqnota = nfitemtxservico.seqnota
                              AND nfitem_dep.seqnotaitem = nfitemtxservico.seqnotaitem
        JOIN nfcab nfcab_dep ON nfcab_dep.estab = nfitem_dep.estab
                            AND nfcab_dep.seqnota = nfitem_dep.seqnota
        LEFT JOIN endereco ON endereco.numerocm = nfcab_dep.numerocm
                          AND endereco.seqendereco = nfcab_dep.seqendereco
        JOIN contamov ON contamov.numerocm = nfcab_dep.numerocm
        JOIN itemagro itemagroservico ON itemagroservico.item = nfitemtxservico.servico
        JOIN itemagro itemagronf ON itemagronf.item = nfitem_dep.item
        LEFT JOIN nfcabroma ON nfcabroma.estab = nfitem_dep.estab
                           AND nfcabroma.seqnota = nfitem_dep.seqnota
                           AND nfcabroma.romaneio = nfitem_dep.romaneio
        LEFT JOIN roma ON roma.estab = nfcabroma.estab
                      AND roma.romaneio = nfcabroma.romaneio
                      AND roma.numerocm = nfcabroma.numerocm
                      AND roma.entradasaida = nfcabroma.entradasaida
    WHERE
        nfitemtxservico.servico = 30
        AND nfitempgservico.situacao = 'P'
        AND t.graos = 'S'
        AND t.emitenfse = 'N'
        AND cidade.uf = 'SP'
        AND NOT EXISTS (
            SELECT
                1
            FROM
                cobserconc
            WHERE
                cobserconc.estab = nfitempgservico.estab
                AND cobserconc.seqnotadep = nfitempgservico.seqnotadep
                AND cobserconc.seqnotaitemdep = nfitempgservico.seqnotaitemdep
                AND cobserconc.servico = nfitemtxservico.servico
        )
),
os11_dp AS (
    SELECT
        'DP' AS tipo,
        os11_base_tab.estab,
        contamov.numerocm,
        nfcab.seqendereco,
        os11_base_tab.servico,
        itemagro.item AS item,
        roma.romaneio
    FROM
        os11_base_tab
        JOIN nfitem ON nfitem.estab = os11_base_tab.estab
                   AND nfitem.seqnota = os11_base_tab.seqnota
                   AND nfitem.seqnotaitem = os11_base_tab.seqnotaitem
        JOIN nfcab ON nfcab.estab = nfitem.estab
                  AND nfcab.seqnota = nfitem.seqnota
        JOIN contamov ON contamov.numerocm = nfcab.numerocm
        JOIN itemagro ON itemagro.item = nfitem.item
        JOIN os11_saldo_temp ON os11_saldo_temp.estab = nfitem.estab
                            AND os11_saldo_temp.seqnota = nfitem.seqnota
                            AND os11_saldo_temp.seqnotaitem = nfitem.seqnotaitem
                            AND os11_saldo_temp.numerocm = nfcab.numerocm
        LEFT JOIN os11_retencao ON os11_retencao.estab = nfitem.estab
                               AND os11_retencao.seqnota = nfitem.seqnota
                               AND os11_retencao.seqnotaitem = nfitem.seqnotaitem
                               AND os11_retencao.item = nfitem.item
        LEFT JOIN os11_parcial ON os11_parcial.estabori = os11_base_tab.estab
                              AND os11_parcial.seqnotaori = os11_base_tab.seqnota
                              AND os11_parcial.seqnotaitemori = os11_base_tab.seqnotaitem
                              AND os11_parcial.sequenciaori = os11_base_tab.sequencia
        LEFT JOIN nfcabroma ON nfcabroma.estab = nfitem.estab
                           AND nfcabroma.seqnota = nfitem.seqnota
                           AND nfcabroma.romaneio = nfitem.romaneio
        LEFT JOIN roma ON roma.estab = nfcabroma.estab
                      AND roma.romaneio = nfcabroma.romaneio
                      AND roma.numerocm = nfcabroma.numerocm
                      AND roma.entradasaida = nfcabroma.entradasaida
    WHERE
        (
            os11_saldo_temp.saldo
            - NVL(os11_parcial.qtdbasecalc, 0)
            - NVL(os11_retencao.pesoretencao, 0)
        ) > 0
),
os11_resultado AS (
    SELECT
        estab,
        numerocm,
        NVL(seqendereco, 0) AS seqendereco,
        servico,
        item
    FROM
        os11_dv

    UNION ALL

    SELECT
        estab,
        numerocm,
        NVL(seqendereco, 0) AS seqendereco,
        servico,
        item
    FROM
        os11_dp
)
SELECT
    robo,
    SUM(qtd_d) AS qtd_pendente
FROM (
    SELECT 'RPA.OS01' AS robo,
           COUNT(*) AS qtd_d
    FROM os_rpa_pedidos_os01

    UNION ALL

    SELECT 'RPA.OS02' AS robo,
           COUNT(*) AS qtd_d
    FROM u_ticketlog_notas_lote
    WHERE status = 'PENDENTE'

    UNION ALL

    SELECT 'RPA.OS11' AS robo,
           COUNT(*) AS qtd_d
    FROM (
        SELECT DISTINCT
            estab,
            numerocm,
            seqendereco,
            servico,
            item,
            'V' AS tipocob,
            'PENDENTE' AS status
        FROM
            os11_resultado
    )

    UNION ALL

    SELECT 'RPA.OS14' AS robo,
           COUNT(*) AS qtd_d
    FROM os_rpa_pedidos_os14

    UNION ALL

    SELECT 'RPA.OS10' AS robo,
           COUNT(*) AS qtd_d
    FROM os_rpa_pedidos_os10
    WHERE tipo_prod = 'S'

    UNION ALL

    SELECT 'RPA.OS07' AS robo,
           COUNT(*) AS qtd_d
    FROM os_rpa_nota_07 t
    WHERE status = 100

    UNION ALL

    SELECT 'RPA.OS15' AS robo,
           COUNT(*) AS qtd_d
    FROM nfcab
        INNER JOIN filial ON filial.estab = nfcab.estab
        INNER JOIN nfcfg ON nfcfg.notaconf = nfcab.notaconf
        LEFT JOIN u_cartacorr ON u_cartacorr.estab = nfcab.estab
                             AND u_cartacorr.seqnota = nfcab.seqnota
    WHERE nfcab.status <> 'C'
      AND u_cartacorr.status = 'PENDENTE'

    UNION ALL

    SELECT
        CASE
            WHEN status = 1 THEN 'RPA.OS05-P1'
            WHEN status = 3 THEN 'RPA.OS05-P2-OC'
            WHEN status = 4 THEN 'RPA.OS05-P2-EMITIR'
            WHEN status = 7 THEN 'RPA.OS05-P3-DEV'
            WHEN status = 8 THEN 'RPA.OS06-CCT'
            ELSE 'RPA.ERRADO'
        END AS robo,
        COUNT(*) AS qtd_d
    FROM u_descarga_trading
        INNER JOIN filial ON filial.estab = u_descarga_trading.estab
    WHERE status IN (1, 3, 4, 7, 8)
    GROUP BY
        CASE
            WHEN status = 1 THEN 'RPA.OS05-P1'
            WHEN status = 3 THEN 'RPA.OS05-P2-OC'
            WHEN status = 4 THEN 'RPA.OS05-P2-EMITIR'
            WHEN status = 7 THEN 'RPA.OS05-P3-DEV'
            WHEN status = 8 THEN 'RPA.OS06-CCT'
            ELSE 'RPA.ERRADO'
        END

    UNION ALL

    SELECT 'RPA.OS16' AS robo,
           COUNT(DISTINCT nfcab.estab || '-' || nfcab.seqnota) AS qtd_d
    FROM nfcab
        INNER JOIN nfitem ON nfitem.estab = nfcab.estab
                         AND nfitem.seqnota = nfcab.seqnota
        INNER JOIN u_tempresa ON u_tempresa.estab = nfcab.estab
                             AND u_tempresa.graos = 'S'
                             AND u_tempresa.exvenda = 'S'
                             AND u_tempresa.ativo = 'S'
        INNER JOIN contamov ON contamov.numerocm = nfcab.numerocm
        INNER JOIN filial ON filial.estab = nfcab.estab
        INNER JOIN nfcfg ON nfcfg.notaconf = nfcab.notaconf
        INNER JOIN contratonfite ON contratonfite.estab = nfcab.estab
                                AND contratonfite.seqnota = nfcab.seqnota
        LEFT JOIN nfcfgestab ON nfcfgestab.estab = nfcab.estab
                            AND nfcfgestab.notaconf = nfcab.notaconf
                            AND nfcfgestab.seq = nfcab.seq_nfcfgestab
        LEFT JOIN nfcabserie ON nfcfgestab.estab = nfcabserie.estab
                            AND nfcfgestab.serie = nfcabserie.serie
    WHERE nfcab.dtemissao >= TO_DATE('01/01/2026', 'DD/MM/YYYY')
      AND nfcab.nprotautoriza IS NULL
      AND nfcab.status <> 'C'
      AND nfcfg.emitenfe = 'S'
      AND nfcab.notaconf IN (209, 210, 211, 229, 230, 241, 303, 342, 343, 394)
      AND nfcab.estab NOT IN (26)

    UNION ALL

    SELECT 'RPA.OS17' AS robo,
           COUNT(*) AS qtd_d
   FROM U_CREDITO_PRESUMIDO WHERE status ='PENDENTE'

    UNION ALL
    

    SELECT 'RPA.OS18' AS robo,
           COUNT(*) AS qtd_d
    FROM pduppaga p
    WHERE p.quitada = 'N'
      AND TRUNC(p.dtvencTO) = TRUNC(SYSDATE) + 1
      AND LENGTH(TRIM(TO_CHAR(p.fatura))) = 11
      AND TRIM(TO_CHAR(p.fatura)) LIKE TO_CHAR(SYSDATE, 'YYYY') || '%'
      
       UNION ALL

    SELECT 'RPA.OS19' AS robo,
           COUNT(*) AS qtd_d
   FROM U_COLABORADORES_AD WHERE STATUS_AD ='PENDENTE_AD'
      
)
GROUP BY robo
HAVING SUM(qtd_d) > 0
ORDER BY SUM(qtd_d) DESC, robo