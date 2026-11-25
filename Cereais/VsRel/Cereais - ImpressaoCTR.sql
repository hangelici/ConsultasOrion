SELECT
    DADOS.*,
   CASE
    WHEN DADOS.CONTCONF IN (20, 21, 26)
        THEN 'CLÁUSULA 10º - FORO DE COMPETÊNCIA'
    WHEN DADOS.CONTCONF IN (7, 8)
        THEN 'CLÁUSULA 8º - FORO DE COMPETÊNCIA'
    WHEN DADOS.CONTCONF IN (1,2,3) THEN 'CLÁUSULA 7º - FORO DE COMPETÊNCIA'
    ELSE 'CLÁUSULA 7º - FORO DE COMPETÊNCIA'
END AS FORO_COMPETENCIA,
    (CASE
        WHEN DADOS.CONTCONF = 3
            THEN TO_CLOB(
                        'a) Mercadoria: ' || DADOS.PRODUTO || ' ' || DADOS.QTRIGO || ', ' || DADOS.DESCPRODUTO ||
                            CHR(10) ||
                        'b) Quilos brutos finais (pós-classificação): ' ||
                        REPLACE(REPLACE(REPLACE(REPLACE(TO_CHAR(DADOS.QTDADE, '999G999G999'), ' ', ''), '.', 'TEMP'), ',', '.'), 'TEMP', ',') || ' Kg' ||
                            CHR(10) ||
                        'c) Quantidade de ' || (case when item in (16988) then 'toneladas: ' else 'sacas: ' end) ||
                        REPLACE(REPLACE(REPLACE(REPLACE(TO_CHAR(DADOS.QTDADESC, '999G999G999'), ' ', ''), '.', 'TEMP'), ',', '.'), 'TEMP', ',') || ' (' ||
                        DADOS.QTDADESCDESC ||(case when item in (16988) then ') Toneladas' else  ') Sacas' end)||
                            CHR(10) ||
                        'd) Preço por '||(case when item in (16988) then 'tonelada:' else 'saca:' end ) || ' A Fixar' ||
                            CHR(10) ||
                        (CASE
                            WHEN DADOS.TIPOENTREGA = 'DISPONIVEL' THEN 'e)Entrega: Produto Disponível'
                            ELSE 'e) Entrega de ' || TO_CHAR(DADOS.dtinicioent, 'DD/MM/YYYY') || ' até ' || TO_CHAR(DADOS.dtlimentimp, 'DD/MM/YYYY')
                        END
                        ) ||
                            CHR(10) ||
                        'f) Safra: ' || DADOS.SAFRA ||
                            CHR(10) ||
                        'g) Local de entrega/carregamento: ' || DADOS.endcm ||
                            CHR(10) ||
                        'h) Prazo p/ Pagamento: A Combinar no momento da fixação' ||
                            CHR(10) ||
                        'i) Pagamento Antecipado: R$ ' ||
                        (CASE
                            WHEN DADOS.VALORADIANTADO = 0 THEN '0' || REPLACE(REPLACE(REPLACE(REPLACE(TO_CHAR(DADOS.VALORADIANTADO, '999G999G999D00'), ' ', ''), '.', 'TEMP'), ',', '.'), 'TEMP', ',')
                            ELSE REPLACE(REPLACE(REPLACE(REPLACE(TO_CHAR(DADOS.VALORADIANTADO, '999G999G999D00'), ' ', ''), '.', 'TEMP'), ',', '.'), 'TEMP', ',')
                        END
                        ) || ' (' || DADOS.DESC_VALORADIANTADO || ')' ||
                            CHR(10) ||
                        'j) Encargos Financeiros: ' ||
                        REPLACE(REPLACE(REPLACE(REPLACE(TO_CHAR(DADOS.PORCENTAGEMJUROS, '999G999G990D0', 'NLS_NUMERIC_CHARACTERS = '',.'''), ' ', ''), ',', 'TEMP'), ',', '.'), 'TEMP', ',') || '% ('
                        || DADOS.DESC_PORCENTAGEMJUROS || ') ao mês.'||  CHR(10) ||
                        'A cessão do crédito a terceiro não afasta as obrigações fiscais do(a) VENDEDOR(A) decorrentes desta operação. O pagamento realizado pelo(a) COMPRADOR(A) ao cessionário indicado pelo(a) VENDEDOR(A) será considerado, para todos os fins, como pagamento feito ao(a) próprio(a) VENDEDOR(A), devendo ser formalizada a respectiva quitação. Se o(a) VENDEDOR(A) for contribuinte do IBS e da CBS, a(o) COMPRADOR(A) poderá, quando permitido pela legislação, recolher diretamente os tributos incidentes sobre a operação e descontar esses valores do montante a ser pago ao cessionário, considerando-se essa parcela igualmente quitada perante o(a) VENDEDOR(A).' 
                        /*
                        'j) Encargos Financeiros: ' ||
                        REPLACE(REPLACE(REPLACE(REPLACE(TO_CHAR(DADOS.PORCENTAGEMJUROS, '999G999G999'), ' ', ''), '.', 'TEMP'), ',', '.'), 'TEMP', ',') || '% (' || DADOS.DESC_PORCENTAGEMJUROS ||
                        ' Por cento) ao mês'||
                            CHR(10) ||
                        'k) Banco ' || PCOBBANCO.DESCRICAO || ', Agência ' || CONTAMOVBCODEP.AGENCIA || ', Conta para pagamento n° ' || CONTAMOVBCODEP.CONTA || ', Variação XX de titularidade da VENDEDOR(A).'
                        */
                        )
        WHEN DADOS.CONTCONF = 8
            THEN TO_CLOB(
                        'a) Mercadoria: ' || DADOS.PRODUTO || ' TIPO EXPORTAÇÃO' || DADOS.QTRIGO || ', ' || DADOS.DESCPRODUTO ||
                            CHR(10) ||
                        'b) Quilos brutos finais (pós-classificação): ' || REPLACE(REPLACE(REPLACE(REPLACE(TO_CHAR(DADOS.QTDADE, '999G999G999'), ' ', ''), '.', 'TEMP'), ',', '.'), 'TEMP', ',') || ' Kg' ||
                            CHR(10) ||
                        'c) Quantidade de ' || (case when item in (16988) then 'toneladas: ' else 'sacas: ' end) ||
                        REPLACE(REPLACE(REPLACE(REPLACE(TO_CHAR(DADOS.QTDADESC, '999G999G999'), ' ', ''), '.', 'TEMP'), ',', '.'), 'TEMP', ',') || ' (' || DADOS.QTDADESCDESC ||
                        (case when item in (16988) then ') Toneladas' else  ') Sacas' end) ||
                            CHR(10) ||
                        'd) Preço por '||(case when item in (16988) then 'tonelada: ' else 'saca: 'end) || TIPOMOEDA ||
                        REPLACE(REPLACE(REPLACE(REPLACE(TO_CHAR(DADOS.VUNIT, '999G999G999D00'), ' ', ''), '.', 'TEMP'), ',', '.'), 'TEMP', ',') || ' (' || DADOS.VUNITDESC || '). ' || clausula_dolar ||
                            CHR(10) ||
                        'e) Preço total: ' || TIPOMOEDA || REPLACE(REPLACE(REPLACE(REPLACE(TO_CHAR(DADOS.VTOTAL, '999G999G999D00'), ' ', ''), '.', 'TEMP'), ',', '.'), 'TEMP', ',') ||
                        ' (' || DADOS.VTOTALDESC || ')' ||
                            CHR(10) ||
                        'f) Entrega de ' || TO_CHAR(DADOS.dtinicioent, 'DD/MM/YYYY') || ' até ' || TO_CHAR(DADOS.dtlimentimp, 'DD/MM/YYYY') ||
                            CHR(10) ||
                        'g) Safra: ' || DADOS.SAFRA ||
                            CHR(10) ||
                        'h) Local de Origem do Produto: ' || DADOS.OS_MICRORREGIAO || ' (nomenclatura adotada pelo operador do terminal ferroviário)' ||
                            CHR(10) ||
                        ('i) Local de entrega/carregamento: CIF ' || DADOS.LOCAL_ALINEA) ||
                            CHR(10) ||
                        'j) Prazo p/ Pagamento: ' || DADOS.DTPGTO ||  CHR(10) ||
                        'A cessão do crédito a terceiro não afasta as obrigações fiscais do(a) VENDEDOR(A) decorrentes desta operação. O pagamento realizado pelo(a) COMPRADOR(A) ao cessionário indicado pelo(a) VENDEDOR(A) será considerado, para todos os fins, como pagamento feito ao(a) próprio(a) VENDEDOR(A), devendo ser formalizada a respectiva quitação. Se o(a) VENDEDOR(A) for contribuinte do IBS e da CBS, a(o) COMPRADOR(A) poderá, quando permitido pela legislação, recolher diretamente os tributos incidentes sobre a operação e descontar esses valores do montante a ser pago ao cessionário, considerando-se essa parcela igualmente quitada perante o(a) VENDEDOR(A).'
                            ||                        
                            CHR(10) ||
                        (CASE
                            WHEN LENGTH(PEDCAB_U.CONTABANCPROD) >= 6
                                THEN REGEXP_REPLACE(PEDCAB_U.CONTABANCPROD,'^j\)', 'k)') || (CASE
                                                                                                WHEN DADOS.OPTRIANGULAR = 'S' AND DADOS.NUMEROCM_CLIENTE NOT IN (24870) THEN '(1)'
                                                                                                ELSE NULL
                                                                                            END
                                                                                            )
                            WHEN DADOS.NOME = 'OURO SAFRA TRADING INTERNATIONAL S.A' THEN ('k) Boleta: ' || DADOS.NUMCOMPRADOR)
                            ELSE NULL
                        END
                        )
                        )
        WHEN DADOS.CONTCONF = 7 AND DADOS.TIPOFRETES = 'CIF'
            THEN TO_CLOB(
                        'a) Mercadoria: ' || DADOS.PRODUTO || ' TIPO EXPORTAÇÃO' || DADOS.QTRIGO || ', ' || DADOS.DESCPRODUTO ||
                            CHR(10) ||
                        'b) Quilos brutos finais (pós-classificação): ' || REPLACE(REPLACE(REPLACE(REPLACE(TO_CHAR(DADOS.QTDADE, '999G999G999'), ' ', ''), '.', 'TEMP'), ',', '.'), 'TEMP', ',') || ' Kg' ||
                            CHR(10) ||
                        'c) Quantidade de ' || (case when item in (16988) then 'toneladas: ' else 'sacas: ' end) ||
                        REPLACE(REPLACE(REPLACE(REPLACE(TO_CHAR(DADOS.QTDADESC, '999G999G999'), ' ', ''), '.', 'TEMP'), ',', '.'), 'TEMP', ',') || ' (' || DADOS.QTDADESCDESC ||
                        (case when item in (16988) then ') Toneladas' else  ') Sacas' end) ||
                            CHR(10) ||
                        'd) Preço por ' || (case when item in (16988) then 'tonelada: ' else 'saca: 'end) || TIPOMOEDA ||
                        REPLACE(REPLACE(REPLACE(REPLACE(TO_CHAR(DADOS.VUNIT, '999G999G999D00'), ' ', ''), '.', 'TEMP'), ',', '.'), 'TEMP', ',') || ' (' || DADOS.VUNITDESC || '). '||clausula_dolar ||
                            CHR(10) ||
                        'e) Preço total: ' || TIPOMOEDA || REPLACE(REPLACE(REPLACE(REPLACE(TO_CHAR(DADOS.VTOTAL, '999G999G999D00'), ' ', ''), '.', 'TEMP'), ',', '.'), 'TEMP', ',') || ' (' || DADOS.VTOTALDESC || ')' ||
                            CHR(10) ||
                        'f) Entrega de ' || TO_CHAR(DADOS.dtinicioent, 'DD/MM/YYYY') || ' até ' || TO_CHAR(DADOS.dtlimentimp, 'DD/MM/YYYY') ||
                            CHR(10) ||
                        'g) Safra: ' || DADOS.SAFRA ||
                            CHR(10) ||
                        'h) Local de entrega/carregamento: CIF ' ||DADOS.local_alinea ||
                            CHR(10) ||
                        'i) Prazo p/ Pagamento: ' || DADOS.DTPGTO ||
                            CHR(10) ||
                        (CASE
                            WHEN LENGTH(PEDCAB_U.CONTABANCPROD) >= 6 AND DADOS.CONTCONF IN (7)
                                THEN PEDCAB_U.CONTABANCPROD ||  (CASE
                                                                    WHEN DADOS.OPTRIANGULAR = 'S' AND DADOS.NUMEROCM_CLIENTE NOT IN (24870) THEN '(1)'
                                                                    ELSE NULL
                                                                END
                                                                ) || CHR(10) || 
                                                                'A cessão do crédito a terceiro não afasta as obrigações fiscais do(a) VENDEDOR(A) decorrentes desta operação. O pagamento realizado pelo(a) COMPRADOR(A) ao cessionário indicado pelo(a) VENDEDOR(A) será considerado, para todos os fins, como pagamento feito ao(a) próprio(a) VENDEDOR(A), devendo ser formalizada a respectiva quitação. Se o(a) VENDEDOR(A) for contribuinte do IBS e da CBS, a(o) COMPRADOR(A) poderá, quando permitido pela legislação, recolher diretamente os tributos incidentes sobre a operação e descontar esses valores do montante a ser pago ao cessionário, considerando-se essa parcela igualmente quitada perante o(a) VENDEDOR(A).'

                            ELSE  CHR(10) || 
                            'j) A cessão do crédito a terceiro não afasta as obrigações fiscais do(a) VENDEDOR(A) decorrentes desta operação. O pagamento realizado pelo(a) COMPRADOR(A) ao cessionário indicado pelo(a) VENDEDOR(A) será considerado, para todos os fins, como pagamento feito ao(a) próprio(a) VENDEDOR(A), devendo ser formalizada a respectiva quitação. Se o(a) VENDEDOR(A) for contribuinte do IBS e da CBS, a(o) COMPRADOR(A) poderá, quando permitido pela legislação, recolher diretamente os tributos incidentes sobre a operação e descontar esses valores do montante a ser pago ao cessionário, considerando-se essa parcela igualmente quitada perante o(a) VENDEDOR(A).'

                        END)
                        )
        WHEN (DADOS.CONTCONF = 7 AND DADOS.TIPOFRETES = 'FOB') OR DADOS.CONTCONF = 26
            THEN TO_CLOB(
                        'a) Mercadoria: ' || DADOS.PRODUTO || ' TIPO EXPORTAÇÃO' || DADOS.QTRIGO || ', ' || DADOS.DESCPRODUTO ||
                            CHR(10) ||
                        'b) Quilos brutos finais (pós-classificação): ' || REPLACE(REPLACE(REPLACE(REPLACE(TO_CHAR(DADOS.QTDADE, '999G999G999'), ' ', ''), '.', 'TEMP'), ',', '.'), 'TEMP', ',') || ' Kg' ||
                            CHR(10) ||
                        'c) Quantidade de ' || (case when item in (16988) then 'toneladas: ' else 'sacas: ' end) ||
                        REPLACE(REPLACE(REPLACE(REPLACE(TO_CHAR(DADOS.QTDADESC, '999G999G999'), ' ', ''), '.', 'TEMP'), ',', '.'), 'TEMP', ',') || ' (' || DADOS.QTDADESCDESC ||
                        (case when item in (16988) then ') Toneladas' else  ') Sacas' end) ||
                            CHR(10) ||
                        'd) Preço por '||(case when item in (16988) then 'tonelada: ' else 'saca: 'end) || TIPOMOEDA ||
                        REPLACE(REPLACE(REPLACE(REPLACE(TO_CHAR(DADOS.VUNIT, '999G999G999D00'), ' ', ''), '.', 'TEMP'), ',', '.'), 'TEMP', ',') || ' (' || DADOS.VUNITDESC || '). ' || clausula_dolar ||
                            CHR(10) ||
                        'e) Preço total: ' || TIPOMOEDA || REPLACE(REPLACE(REPLACE(REPLACE(TO_CHAR(DADOS.VTOTAL, '999G999G999D00'), ' ', ''), '.', 'TEMP'), ',', '.'), 'TEMP', ',') ||
                        ' (' || DADOS.VTOTALDESC || ')' ||
                            CHR(10) ||
                        'f) Entrega de ' || TO_CHAR(DADOS.dtinicioent, 'DD/MM/YYYY') || ' até ' || TO_CHAR(DADOS.dtlimentimp, 'DD/MM/YYYY') ||
                            CHR(10) ||
                        'g) Safra: ' || DADOS.SAFRA ||
                            CHR(10) ||
                        (CASE
                            WHEN DADOS.CONTCONF = 26 AND DADOS.NOME = 'OURO SAFRA TRADING INTERNATIONAL S.A' AND DADOS.TIPOFRETES = 'CIF'
                                THEN ('h) Local de entrega/carregamento: CIF ' || DADOS.LOCAL_ALINEA)
                            ELSE ('h) Local de entrega/carregamento: ' || DADOS.endcm)
                        END
                        ) ||
                            CHR(10) ||
                        'i) Prazo p/ Pagamento: ' || DADOS.DTPGTO ||
                            CHR(10) ||
                        (CASE
                            WHEN DADOS.CONTCONF = 7 AND LENGTH(PEDCAB_U.CONTABANCPROD) >= 6
                                THEN PEDCAB_U.CONTABANCPROD ||  (CASE
                                                                    WHEN DADOS.OPTRIANGULAR = 'S' AND DADOS.NUMEROCM_CLIENTE NOT IN (24870) THEN '(1)'
                                                                    ELSE NULL
                                                                END
                                                                ) || case when dados.contconf in (1,2,3,7,8) then
                                                                CHR(10) || 'A cessão do crédito a terceiro não afasta as obrigações fiscais do(a) VENDEDOR(A) decorrentes desta operação. O pagamento realizado pelo(a) COMPRADOR(A) ao cessionário indicado pelo(a) VENDEDOR(A) será considerado, para todos os fins, como pagamento feito ao(a) próprio(a) VENDEDOR(A), devendo ser formalizada a respectiva quitação. Se o(a) VENDEDOR(A) for contribuinte do IBS e da CBS, a(o) COMPRADOR(A) poderá, quando permitido pela legislação, recolher diretamente os tributos incidentes sobre a operação e descontar esses valores do montante a ser pago ao cessionário, considerando-se essa parcela igualmente quitada perante o(a) VENDEDOR(A).'
                                                                else null end
                            WHEN DADOS.CONTCONF = 26 AND DADOS.NOME = 'OURO SAFRA TRADING INTERNATIONAL S.A' THEN ('j) Boleta: ' || DADOS.NUMCOMPRADOR)
                            ELSE NULL
                        END
                        ) || '' ||  CHR(10) || (CASE
                                        WHEN DADOS.CONTCONF IN (1,2,7)
                                            THEN 'Eventuais alterações nos dados bancários deverão ser comunicadas previamente pelo(a) Vendedor(a)(1) e formalizadas por meio de termo aditivo, com solicitação realizada pelo e-mail contratos.aditivo@ourosafra.com.br em até 05 (cinco) dias úteis antes do prazo previsto para pagamento.'
                                        ELSE NULL
                                    END
                                    )
                        ) || '' || 
                        CASE WHEN DADOS.CONTCONF = 7 AND LENGTH(PEDCAB_U.CONTABANCPROD) < 6 THEN
                        CHR(10) ||
                        'j) A cessão do crédito a terceiro não afasta as obrigações fiscais do(a) VENDEDOR(A) decorrentes desta operação. O pagamento realizado pelo(a) COMPRADOR(A) ao cessionário indicado pelo(a) VENDEDOR(A) será considerado, para todos os fins, como pagamento feito ao(a) próprio(a) VENDEDOR(A), devendo ser formalizada a respectiva quitação. Se o(a) VENDEDOR(A) for contribuinte do IBS e da CBS, a(o) COMPRADOR(A) poderá, quando permitido pela legislação, recolher diretamente os tributos incidentes sobre a operação e descontar esses valores do montante a ser pago ao cessionário, considerando-se essa parcela igualmente quitada perante o(a) VENDEDOR(A).'
                        ELSE NULL END
        ELSE TO_CLOB(
                    'a) Mercadoria: ' || DADOS.PRODUTO || ' ' || DADOS.QTRIGO || ', ' || DADOS.DESCPRODUTO ||
                        CHR(10) ||
                    'b) Quilos brutos finais (pós-classificação): ' || REPLACE(REPLACE(REPLACE(REPLACE(TO_CHAR(DADOS.QTDADE, '999G999G999'), ' ', ''), '.', 'TEMP'), ',', '.'), 'TEMP', ',') || ' Kg' ||
                        CHR(10) ||
                    'c) Quantidade de '||(case when item in (16988) then 'toneladas: ' else 'sacas: ' end) ||
                    REPLACE(REPLACE(REPLACE(REPLACE(TO_CHAR(DADOS.QTDADESC, '999G999G999'), ' ', ''), '.', 'TEMP'), ',', '.'), 'TEMP', ',') || ' (' || DADOS.QTDADESCDESC ||
                    (case when item in (16988) then ') Toneladas' else  ') Sacas' end) ||
                        CHR(10) ||
                    'd) Preço por '||(case when item in (16988) then 'tonelada: ' else 'saca: 'end) || TIPOMOEDA ||
                    REPLACE(REPLACE(REPLACE(REPLACE(TO_CHAR(DADOS.VUNIT, '999G999G999D00'), ' ', ''), '.', 'TEMP'), ',', '.'), 'TEMP', ',') || ' (' || DADOS.VUNITDESC || '). '||clausula_dolar ||
                        CHR(10) ||
                    'e) Preço total: '||TIPOMOEDA || REPLACE(REPLACE(REPLACE(REPLACE(TO_CHAR(DADOS.VTOTAL, '999G999G999D00'), ' ', ''), '.', 'TEMP'), ',', '.'), 'TEMP', ',') || ' (' || DADOS.VTOTALDESC || ')' ||
                        CHR(10) ||
                    'f) Entrega de ' || TO_CHAR(DADOS.dtinicioent, 'DD/MM/YYYY') || ' até ' || TO_CHAR(DADOS.dtlimentimp, 'DD/MM/YYYY') ||
                        CHR(10) ||
                    'g) Safra: ' || DADOS.SAFRA || CHR(10) ||
                    (CASE
                        WHEN DADOS.CONTCONF = 26 AND DADOS.NOME = 'OURO SAFRA TRADING INTERNATIONAL S.A' AND DADOS.TIPOFRETES = 'CIF'
                            THEN ('h) Local de entrega/carregamento: CIF ' || DADOS.LOCAL_ALINEA)
                        ELSE ('h) Local de entrega/carregamento: ' || DADOS.endcm)
                    END
                    ) ||
                        CHR(10) ||
                    'i) Prazo p/ Pagamento: ' || DADOS.DTPGTO ||
                        CHR(10) ||
                    (CASE
                        WHEN LENGTH(PEDCAB_U.CONTABANCPROD) >= 6 AND DADOS.CONTCONF IN (1,2)
                            THEN PEDCAB_U.CONTABANCPROD ||  (CASE
                                                                WHEN DADOS.OPTRIANGULAR = 'S' AND DADOS.NUMEROCM_CLIENTE NOT IN (24870) THEN '(1)'
                                                                ELSE NULL
                                                            END
                                                            )
                        WHEN DADOS.CONTCONF = 26 AND DADOS.NOME = 'OURO SAFRA TRADING INTERNATIONAL S.A' THEN ('j) Boleta: ' || DADOS.NUMCOMPRADOR)
                        ELSE NULL
                    END
                    ) || '' ||  (CASE
                                    WHEN DADOS.CONTCONF IN (1,2,7)
                                        THEN ' Eventuais alterações nos dados bancários deverão ser comunicadas previamente pelo(a) Vendedor(a)(1) e formalizadas por meio de termo aditivo, com solicitação realizada pelo e-mail contratos.aditivo@ourosafra.com.br em até 05 (cinco) dias úteis antes do prazo previsto para pagamento.'
                                    ELSE NULL
                                END
                                )
                    ) || CHR(10) || (
                        case when dados.contconf in (1,2,3,7,8) then
                        'A cessão do crédito a terceiro não afasta as obrigações fiscais do(a) VENDEDOR(A) decorrentes desta operação. O pagamento realizado pelo(a) COMPRADOR(A) ao cessionário indicado pelo(a) VENDEDOR(A) será considerado, para todos os fins, como pagamento feito ao(a) próprio(a) VENDEDOR(A), devendo ser formalizada a respectiva quitação. Se o(a) VENDEDOR(A) for contribuinte do IBS e da CBS, a(o) COMPRADOR(A) poderá, quando permitido pela legislação, recolher diretamente os tributos incidentes sobre a operação e descontar esses valores do montante a ser pago ao cessionário, considerando-se essa parcela igualmente quitada perante o(a) VENDEDOR(A).'
                        end 
                    )
    END
    ) AS CLAUSULA_UM_FORMATADA,
    (CASE
        WHEN DADOS.NOME = 'OURO SAFRA TRADING INTERNATIONAL S.A' THEN 'RUT'
        ELSE 'CPF/CNPJ'
    END
    ) AS TIPODOC,
    (CASE
        WHEN DADOS.NOMETRI = 'OURO SAFRA TRADING INTERNATIONAL S.A' THEN 'RUT'
        ELSE 'CPF/CNPJ'
    END
    ) AS TIPODOCTRI,
    (CASE
        WHEN DADOS.NOME = 'OURO SAFRA TRADING INTERNATIONAL S.A' THEN '219551870013'
        ELSE DADOS.CNPJF
    END
    ) AS CNPJF2,
    (CASE
        WHEN DADOS.NOMETRI = 'OURO SAFRA TRADING INTERNATIONAL S.A' THEN '219551870013'
        ELSE DADOS.CNPJFTRI
    END
    ) AS CNPJF3,
    (CASE
        WHEN DADOS.NOME = 'OURO SAFRA TRADING INTERNATIONAL S.A' THEN ''
        ELSE 'residente e domiciliado'
    END
    ) AS RESIDENTEDOMICILIADO,
    (CASE
        WHEN DADOS.NOMETRI = 'OURO SAFRA TRADING INTERNATIONAL S.A' THEN ''
        ELSE 'residente e domiciliado'
    END
    ) AS RESIDENTEDOMICILIADOTRI,
    (CASE
        WHEN DADOS.NOME = 'OURO SAFRA TRADING INTERNATIONAL S.A' THEN 'Pessoa Jurídica de direito privado'
        ELSE DADOS.DADOSPESSOA
    END
    ) AS DADOSPESSOA2,
    (CASE
        WHEN DADOS.NOMETRI = 'OURO SAFRA TRADING INTERNATIONAL S.A' THEN 'Pessoa Jurídica de direito privado'
        ELSE DADOS.DADOSPESSOATRI
    END
    ) AS DADOSPESSOA3,
    (CASE
        WHEN DADOS.NOME = 'OURO SAFRA TRADING INTERNATIONAL S.A' THEN DADOS.ENDCOMPRADORTRADING
        ELSE DADOS.ENDCOMPRADOR
    END
    ) AS ENDCOMPRADOR2,
    (CASE
        WHEN DADOS.NOMETRI = 'OURO SAFRA TRADING INTERNATIONAL S.A' THEN DADOS.ENDCOMPRADORTRADING
        ELSE DADOS.ENDCOMPRADORTRI
    END
    ) AS ENDCOMPRADOR3,
    --
    (CASE
        WHEN DADOS.OPTRIANGULAR = 'S' AND DADOS.NUMEROCM_CLIENTE NOT IN (24870) THEN DADOS.NOMETRI
        ELSE NULL
    END
    ) AS MOSTRANOMETRI,
    (CASE
        WHEN DADOS.OPTRIANGULAR = 'S' AND DADOS.NUMEROCM_CLIENTE NOT IN (24870)
            THEN    ', ' || (CASE
                                WHEN DADOS.NOMETRI = 'OURO SAFRA TRADING INTERNATIONAL S.A' THEN 'Pessoa Jurídica de direito privado'
                                ELSE DADOS.DADOSPESSOATRI
                            END
                            ) ||
                    ', ' || DADOS.DADOSPESSOAPTRI || ' inscrito(a) no ' ||
                    (CASE
                        WHEN DADOS.NOMETRI = 'OURO SAFRA TRADING INTERNATIONAL S.A' THEN 'RUT'
                        ELSE 'CPF/CNPJ'
                    END
                    ) || ' sob o N° '
        ELSE NULL
    END
    ) AS MOSTRATRECHOTRI1,
    (CASE
        WHEN DADOS.OPTRIANGULAR = 'S' AND DADOS.NUMEROCM_CLIENTE NOT IN (24870)
            THEN    (CASE
                        WHEN DADOS.NOMETRI = 'OURO SAFRA TRADING INTERNATIONAL S.A' THEN '219551870013'
                        ELSE DADOS.CNPJFTRI
                    END
                    )
        ELSE NULL
    END
    ) AS MOSTRACNPJFTRI,
    (CASE
        WHEN DADOS.OPTRIANGULAR = 'S' AND DADOS.NUMEROCM_CLIENTE NOT IN (24870)
            THEN    (CASE
                        WHEN DADOS.NOMETRI = 'OURO SAFRA TRADING INTERNATIONAL S.A' THEN ''
                        ELSE ' residente e domiciliado'
                    END
                    )
        ELSE NULL
    END
    ) AS MOSTRARESIDENTEDOMICILIADOTRI,
    (CASE
        WHEN DADOS.OPTRIANGULAR = 'S' AND DADOS.NUMEROCM_CLIENTE NOT IN (24870)
            THEN    (CASE
                        WHEN DADOS.NOMETRI = 'OURO SAFRA TRADING INTERNATIONAL S.A' THEN DADOS.ENDCOMPRADORTRADING
                        ELSE DADOS.ENDCOMPRADORTRI
                    END
                    )
        ELSE NULL
    END
    ) AS MOSTRAENDCOMPRADORTRI,
    (CASE
        WHEN DADOS.OPTRIANGULAR = 'S' AND DADOS.NUMEROCM_CLIENTE NOT IN (24870) THEN ', doravante designado '
        ELSE NULL
    END
    ) AS MOSTRATRECHOTRI2,
    (CASE
        WHEN DADOS.OPTRIANGULAR = 'S' AND DADOS.NUMEROCM_CLIENTE NOT IN (24870) THEN DADOS.TIPOPESSOA || '(2), '
        ELSE NULL
    END
    ) AS MOSTRATIPOPESSOATRI,
    (CASE
        WHEN DADOS.OPTRIANGULAR = 'S' AND DADOS.NUMEROCM_CLIENTE NOT IN (24870)
            THEN ' fica justa e contratada esta compra e venda, de acordo com as cláusulas e condições que seguem'
        ELSE NULL
    END
    ) AS MOSTRATRECHOTRI3,
    --
    (CASE
        WHEN COALESCE(DADOS.OPTRIANGULAR,'N') = 'N' AND DADOS.NUMEROCM_CLIENTE NOT IN (24870) THEN ' fica justa e contratada esta compra e venda, de acordo com as cláusulas e condições que seguem'
        ELSE NULL
    END
    ) AS MOSTRATRECHOSEMTRI,
    (CASE
        WHEN DADOS.OPTRIANGULAR = 'S' AND DADOS.NUMEROCM_CLIENTE NOT IN (24870) THEN 'do(s) VENDEDOR(ES)'
        ELSE 'do(a) VENDEDOR(A)'
    END
    ) AS MOSTRAVENDEDORES
                                        
--
--

FROM
    (
    SELECT
    FILIAL.ESTAB,
    CONTRATO.CONTRATO,
    CONTRATO.CONTCONF,
    CONTRATO.NUMCOMPRADOR,
    CONTRATO_U.TIPOENTREGA,
    CASE WHEN CONTRATOCFG.ENTRADASAIDA='E' THEN 'COMPRADOR(A)'ELSE 'VENDEDOR(A)' END TIPOOS,
    CASE WHEN CONTRATOCFG.ENTRADASAIDA='E' THEN 'VENDEDOR(A)'ELSE 'COMPRADOR(A)' END TIPOPESSOA,
    '6' AS CFC,
    (CASE 
    WHEN (
    CONTRATOCFG.ENTRADASAIDA = 'E'
    OR CONTRATO.CONTCONF = 26
    )
    AND contratoite.item NOT IN (16988)
    AND COALESCE(CONTRATO_U.OS_TRIANGULAR, 'N') = 'N' OR CONTRATO.NUMEROCM IN (24870)
    THEN 'plantada no domicílio ou em qualquer outra área de propriedade do VENDEDOR(A) ou, ainda, que esteja em posse para fins de produção agrícola.'
    WHEN (
    CONTRATOCFG.ENTRADASAIDA = 'E'
    OR CONTRATO.CONTCONF = 26
    )
    AND contratoite.item NOT IN (16988)
    AND COALESCE(CONTRATO_U.OS_TRIANGULAR, 'N') = 'S' AND CONTRATO.NUMEROCM NOT IN (24870)
    THEN 'plantada no domicílio ou em qualquer outra área de propriedade do VENDEDOR(A)(2) ou, ainda, que esteja em posse para fins de produção agrícola.'
    ELSE '' 
    END
    ) DESCPRODUTO,
    contrato_u.tipofretes,
    FILIAL.RAZAOSOC AS COMPRADORA,
    FILIAL.ENDERECO||', Nº'||FILIAL.NUMEEND||' - '||FILIAL.COMPEND||', '||FILIAL.BAIRRO||', Cep:'||filial.cep||' na cidade de '||CIDFIL.NOME||'-'||CIDFIL.UF AS ENDFIL,
    FILIAL.CNPJ AS CNPJFIL,
    FILIAL.INSCEST AS IEFIL,
    CIDFIL.NOME as COMARCA,
    CIDFIL.UF AS UFCOMARCA,
    
    
    CASE WHEN ppescli.estcivil='J'  THEN 'Pessoa Jurídica'
    WHEN ppescli.estcivil='S' THEN 'Solteiro(a)'
    WHEN ppescli.estcivil='C' THEN 'Casado(a)'
    WHEN ppescli.estcivil='V' THEN 'Viúvo(a)'
    WHEN ppescli.estcivil='D' THEN 'Divorciado(a)'
    WHEN ppescli.estcivil='Q' THEN 'desQuitado(a)'
    WHEN ppescli.estcivil='A' THEN 'Amasiado(a)'
    WHEN ppescli.estcivil='U' THEN 'União Estável'
    END AS DADOSPESSOA,
    
    CASE WHEN ppescli_tri.estcivil='J'  THEN 'Pessoa Jurídica'
    WHEN ppescli_tri.estcivil='S' THEN 'Solteiro(a)'
    WHEN ppescli_tri.estcivil='C' THEN 'Casado(a)'
    WHEN ppescli_tri.estcivil='V' THEN 'Viúvo(a)'
    WHEN ppescli_tri.estcivil='D' THEN 'Divorciado(a)'
    WHEN ppescli_tri.estcivil='Q' THEN 'desQuitado(a)'
    WHEN ppescli_tri.estcivil='A' THEN 'Amasiado(a)'
    WHEN ppescli_tri.estcivil='U' THEN 'União Estável'
    END AS DADOSPESSOATRI,
    
    CASE WHEN CONTAMOV.sexo='J' THEN ''
    WHEN PPESCLI.PAIS='Brasil' then
    (' Brasileiro(a), produtor(a) rural')
    ELSE COALESCE(' '||PPESCLI.PAIS,' Brasileiro(a)')||', produtor(a) rural'
    END AS DADOSPESSOAP,
    CASE WHEN CONTAMOV_TRI.sexo='J' THEN ''
    WHEN PPESCLI_TRI.PAIS='Brasil' then
    (' Brasileiro(a), produtor(a) rural')
    ELSE COALESCE(' '||PPESCLI_TRI.PAIS,' Brasileiro(a)')||', produtor(a) rural'
    END AS DADOSPESSOAPTRI,
    CONTAMOV.nome,
    CASE WHEN CONTRATO.ENDALTERNATIVO > 0 AND CONTAMOV.sexo='J' THEN ENDERECO.cnpjf
    ELSE CONTAMOV.CNPJF END CNPJF,
    CONTRATO.ENDALTERNATIVO,
    (case
        when CONTRATO.ENDALTERNATIVO > 0
            then    tipologradouro.descricao || ' ' || endereco.ENDERECO || ', ' || endereco.numeroend || ' - ' || endereco.COMPLEMENTO || ', ' ||
                    endereco.BAIRRO || ', Cep:' || endereco.cep || ' na cidade de ' || CIdade.NOME || '-' || CIDade.UF
        else    tipologradouro.descricao || ' ' || CONTAMOV.ENDERECO || ', ' || CONTAMOV.numeroend || ' - '||CONTAMOV.COMPLEMENTO || ', ' ||
                CONTAMOV.BAIRRO || ', Cep:' || contamov.cep || ' na cidade de ' || CIdade.NOME||'-'||CIDade.UF
    end
    ) AS ENDCOMPRADOR,
    (tipologradouro_TRI.descricao || ' ' || CONTAMOV_TRI.ENDERECO || ', ' || CONTAMOV_TRI.numeroend || ' - '||CONTAMOV_TRI.COMPLEMENTO || ', ' ||
    CONTAMOV_TRI.BAIRRO || ', Cep:' || CONTAMOV_TRI.cep || ' na cidade de ' || CIdade_TRI.NOME||'-'||CIdade_TRI.UF
    ) AS ENDCOMPRADORTRI,
    (CASE
        WHEN UPPER(CONTAMOV.NOME) = 'OURO SAFRA TRADING INTERNATIONAL S.A'
            then    tipologradouro.descricao || ' ' || CONTAMOV.ENDERECO || ', ' || CONTAMOV.numeroend || ' - ' || CONTAMOV.COMPLEMENTO ||/* ', ' ||
                    CONTAMOV.BAIRRO ||*/ ', zip code:' || contamov.cep || ' na cidade de ' || CIdade.NOME /*|| '-' || CIDade.UF*/
        ELSE NULL
    END
    ) AS ENDCOMPRADORTRADING,
    CMPESSENT.NUMEROCM,
    contrato.seqendentrega,
    CASE
    WHEN CONTRATOCFG.ENTRADASAIDA='S' AND contrato_u.tipofretes='FOB'AND (contrato.seqendretirada = 0 OR contrato.seqendretirada IS NULL) THEN
    CMPESRET.ENDERECO||', Nº'||CMPESRET.numeroend||', CNPJ/CPF:'||CMPESRET.CNPJF||', '||CIDADECMPESRETENDCM.NOME||'-'||CIDADECMPESRETENDCM.UF
    
    WHEN CONTRATOCFG.ENTRADASAIDA='S' AND contrato_u.tipofretes='FOB'AND (contrato.seqendretirada > 0) THEN
    CMPESRETEND.ENDERECO||', Nº'||CMPESRETEND.numeroend||', CNPJ/CPF:'||CMPESRETEND.CNPJF||', '||CIDADEPESRETEND.NOME||'-'||CIDADEPESRETEND.UF
    
    WHEN CONTRATOCFG.ENTRADASAIDA='S' AND contrato_u.tipofretes='CIF' AND (contrato.seqendentrega = 0 OR contrato.seqendentrega IS NULL) THEN
    CMPESSENT.ENDERECO||', Nº'||CMPESSENT.numeroend||', CNPJ/CPF:'||CMPESSENT.CNPJF||', '||CIDADEPESSENDCM.NOME||'-'||CIDADEPESSENDCM.UF
    
    WHEN CONTRATOCFG.ENTRADASAIDA='S' AND contrato_u.tipofretes='CIF' AND contrato.seqendentrega > 0  THEN
    CMPESSEND.ENDERECO||', Nº'||CMPESSEND.numeroend||', CNPJ/CPF:'||CMPESSEND.CNPJF||', '||CIDADEPESSEND.NOME||'-'||CIDADEPESSEND.UF
    
    WHEN CONTRATOCFG.ENTRADASAIDA = 'E' AND contrato.contconf in (1,2) AND contrato_u.tipofretes='CIF' AND CONTRATO_U.TIPOPESSOA IN('TERCEIRO','PROPRIO') THEN
    'CIF ' ||CIDADE_LOCAL.NOME||' - '||CIDADE_LOCAL.UF    
    
    WHEN CONTRATOCFG.ENTRADASAIDA = 'E' 
    AND contrato.contconf in (1,2,7) 
    AND contrato_u.tipofretes='FOB' 
    THEN
    COALESCE(PESSRET.APELIDO,'')||','||
    
    COALESCE(PESSEND.ENDERECO, PESSRET.ENDERECO)||', Nº'||
    COALESCE(PESSEND.numeroend, PESSRET.numeroend)||
    
    ', CNPJ/CPF:'||COALESCE(PESSEND.CNPJF, PESSRET.CNPJF)||
    
    ', '||COALESCE(endretcidade.NOME, pessretcidade.NOME)||
    ' -'||COALESCE(endretcidade.UF, pessretcidade.UF)
    
    WHEN CONTRATOCFG.ENTRADASAIDA = 'E' AND contrato.contconf in (7) AND contrato_u.tipofretes='CIF' AND CONTRATO_U.TIPOPESSOA = 'EMPRESA' AND CONTRATO_U.ESTAB = 79 THEN
    'CIF '||endretcidade.NOME||' - '||endretcidade.UF   
    
    
    WHEN CONTRATOCFG.ENTRADASAIDA='E'  AND CONTRATO_U.TIPOPESSOA = 'EMPRESA' AND localest_u.seqendereco = 0 THEN
    COALESCE(PESSRET.APELIDO,'')||','||PESSRET.ENDERECO||', Nº'||PESSRET.numeroend||', CNPJ/CPF:'||PESSRET.CNPJF||', '||pessretcidade.NOME||'-'||pessretcidade.UF
    
    
    WHEN CONTRATOCFG.ENTRADASAIDA='E' and localest_u.seqendereco > 0 THEN
    COALESCE(PESSRET.APELIDO,'')||','||PESSEND.ENDERECO||', Nº'||PESSEND.numeroend||', CNPJ/CPF:'||PESSEND.CNPJF||', '||endretcidade.NOME||' -'||endretcidade.UF
    
    
    ELSE 'Sem Local de Retirada/Entrega' END AS endcm,
    CIDADE_LOCAL.NOME||' - '||CIDADE_LOCAL.UF AS local_alinea,
    
    PESSEND.ENDERECO as teste123,
    localest.local as local,
    PESSRET.NUMEROCM as pessolocal,
    pessretcidade.cidade as pescidade,
    CMPESSEND.numeroend,
    PESSEND.numeroend pessende,
    
    
    CASE
    WHEN CONTRATO_U.TIPOPGTO ='AVISTA' AND CONTRATO.CONTCONF NOT IN (1,2) THEN 'A Vista'
    WHEN CONTRATO_U.TIPOPGTO ='AVISTA' AND CONTRATO.CONTCONF IN (1,2) THEN 'A Vista, após emissão dos documentos comprobatórios de inexistência de ônus relativo ao produto negociado'
    --WHEN CONTRATO_U.TIPOPGTO ='5DIAUTIL' THEN 'No dia 15 do Mês Subsequente ao previsto para a entrega ou, em caso de atraso, no dia 15 do mês subsequente ao adimplemento total do contrato'
    WHEN CONTRATO_U.TIPOPGTO ='5DIAUTIL' THEN 'No dia '||to_char(contrato.dtvencto,'DD')||' do Mês Subsequente ao previsto para a entrega ou, em caso de atraso, no dia '||to_char(contrato.dtvencto,'DD')||' do mês subsequente ao adimplemento total do contrato'
    WHEN CONTRATO_U.TIPOPGTO ='DIASUBSEQUENTE' THEN 'No dia '||to_char(contrato.dtvencto,'DD')||' do Mês Subsequente ao previsto para a entrega ou, em caso de atraso, no dia '||to_char(contrato.dtvencto,'DD')||' do mês subsequente ao adimplemento total do contrato'
    --WHEN CONTRATO_U.TIPOPGTO ='5DIAUTIL' THEN '5º Dia útil do Mês Subsequente ao previsto para a entrega ou, em caso de atraso,no 5º dia útil dos mês subsequente ao adimplemento total do contrato'
    WHEN CONTRATO_U.TIPOPGTO ='SOBRERODAS' AND CONTRATO.CONTCONF NOT IN (1,2) THEN 'Após o Carregamento (Sobre Rodas)'
    WHEN CONTRATO_U.TIPOPGTO ='SOBRERODAS' AND CONTRATO.CONTCONF IN (1,2) THEN 'Após o Carregamento (Sobre Rodas) e emissão dos documentos comprobatórios de inexistência de ônus relativo ao produto negociado.'
    WHEN CONTRATO_U.TIPOPGTO ='ANTECIPADO' AND CONTRATO.CONTCONF NOT IN (1,2) THEN 'Antecipado - '||to_char(contratodtvencto.dtvencto,'DD/MM/YYYY')
    WHEN CONTRATO_U.TIPOPGTO ='ANTECIPADO' AND CONTRATO.CONTCONF IN (1,2) THEN 'Antecipado - '||to_char(contratodtvencto.dtvencto,'DD/MM/YYYY')||' ,após emissão dos documentos comprobatórios de inexistência de ônus relativo ao produto negociado.'
    WHEN CONTRATO_U.TIPOPGTO ='APRAZOCTR' THEN contratodtvencto.numdiaspagto||' Dias da Emissão do Contrato'
    WHEN CONTRATO_U.TIPOPGTO ='APRAZOAMOSTRA' THEN contratodtvencto.numdiaspagto||' Dias da Entrega da Carga de Amostra'
    WHEN CONTRATO_U.TIPOPGTO ='APRAZOEMBARQUE' THEN contratodtvencto.numdiaspagto||' Dias do Carregamento da Mercadoria'
    WHEN CONTRATO_U.TIPOPGTO ='APRAZODESCARGA' THEN contratodtvencto.numdiaspagto||' Dias da Entrega da Mercadoria'
    WHEN CONTRATO_U.TIPOPGTO ='ANTECIPADOPARC' THEN' Antecipado por lote após emissão dos documentos comprobatórios de inexistência de ônus relativo ao produto negociado.'
    WHEN CONTRATO_U.TIPOPGTO = 'SOBREDESCARGA' THEN '(' || (contratodtvencto.numdiaspagto * 24) || ') horas após cada descarga, mediante a emissão e a apresentação dos documentos comprobatórios da inexistência de ônus ou gravames relativos ao produto negociado.'    WHEN contratodtvencto.dtvencto is NULL then  contratodtvencto.numdiaspagto||' Dias'
    WHEN CONTRATO_U.TIPOPGTO ='APRAZO' AND CONTRATO.CONTCONF IN (1,2,7) THEN to_char(contratodtvencto.dtvencto,'DD/MM/YYYY') || ', após emissão dos documentos comprobatórios de inexistência de ônus relativo ao produto negociado.'
    Else to_char(contratodtvencto.dtvencto,'DD/MM/YYYY')
    end DTPGTO,
    
    
    
    
    CASE WHEN CONTRATOITE.ITEM=2 THEN CONTRATO_U.QTRIGO
    ELSE '' END QTRIGO,
    CASE WHEN contratocfg.contconf = 2 THEN ' '
    ELSE ' ' END AS LF,
    ITEMAGRO.ITEM,
    ITEMAGRO.DESCRICAO AS PRODUTO,
    CONTRATOITE.QUANTIDADE AS QTDADE,
    EXTENSO(arredondar(CONTRATOITE.QUANTIDADE,2)) AS QTDADEDESC,
    /*case 
    when contratoite.item in (16988) then TRUNC(CONTRATOITE.QUANTIDADE,2) 
    else TRUNC(CONTRATOITE.QUANTIDADE/60,2) 
    end AS QTDADESC, */
    trunc(divide(contratoite.quantidade,coalesce(multiplic,60)),2) QTDADESC,
    /*
    case 
    when contratoite.item in (16988) then extensosc_quantidade(TRUNC(CONTRATOITE.QUANTIDADE,2)) 
    else os_extensosc(TRUNC(CONTRATOITE.QUANTIDADE/60,2)) 
    end AS QTDADESCDESC,   */
    CASE
    WHEN ITEMPREMB.MULTIPLIC >= 1000 THEN  extensosc_quantidade(TRUNC(DIVIDE(CONTRATOITE.QUANTIDADE,MULTIPLIC),2))
    ELSE os_extensosc(TRUNC(DIVIDE(CONTRATOITE.QUANTIDADE,COALESCE(MULTIPLIC,60)),2)) 
    END QTDADESCDESC,
    
    
    ARREDONDAR(CONTRATOITE.VALORUNIT,2) AS VUNIT,
    case when contrato.moeda = 2 then EXTENSO_dolar(ARREDONDAR(CONTRATOITE.VALORUNIT,2)) else  EXTENSO (ARREDONDAR(CONTRATOITE.VALORUNIT,2)) end VUNITDESC,
    CONTRATOITE.VALORTOTAL AS VTOTAL,
    case when contrato.moeda = 2 then EXTENSO_dolar(arredondar(CONTRATOITE.VALORTOTAL,2))else EXTENSO (arredondar(CONTRATOITE.VALORTOTAL,2)) end  VTOTALDESC,
    CONTRATO.DTMOVSALDO AS DTINI,
    contrato_u.dtinicioent,
    CONTRATO.DATALIMITEENT AS DTFIN,
    contrato.dtlimentimp AS dtlimentimp,
    SAFRAS.DESCRICAO AS SAFRA,
    
    CASE WHEN EXTRACT(MONTH FROM CONTRATO.DTEMISSAO)='01' THEN EXTRACT(DAY FROM CONTRATO.DTEMISSAO)||''||' de Janeiro de '||''||EXTRACT(YEAR FROM CONTRATO.DTEMISSAO)
    WHEN EXTRACT(MONTH FROM CONTRATO.DTEMISSAO)='02' THEN EXTRACT(DAY FROM CONTRATO.DTEMISSAO)||''||' de Fevereiro de '||''||EXTRACT(YEAR FROM CONTRATO.DTEMISSAO)
    WHEN EXTRACT(MONTH FROM CONTRATO.DTEMISSAO)='03' THEN EXTRACT(DAY FROM CONTRATO.DTEMISSAO)||''||' de Março de '||''||EXTRACT(YEAR FROM CONTRATO.DTEMISSAO)
    wHEN EXTRACT(MONTH FROM CONTRATO.DTEMISSAO)='04' THEN EXTRACT(DAY FROM CONTRATO.DTEMISSAO)||''||' de Abril de '||''||EXTRACT(YEAR FROM CONTRATO.DTEMISSAO)
    wHEN EXTRACT(MONTH FROM CONTRATO.DTEMISSAO)='05' THEN EXTRACT(DAY FROM CONTRATO.DTEMISSAO)||''||' de Maio de '||''||EXTRACT(YEAR FROM CONTRATO.DTEMISSAO)
    wHEN EXTRACT(MONTH FROM CONTRATO.DTEMISSAO)='06' THEN EXTRACT(DAY FROM CONTRATO.DTEMISSAO)||''||' de Junho de '||''||EXTRACT(YEAR FROM CONTRATO.DTEMISSAO)
    wHEN EXTRACT(MONTH FROM CONTRATO.DTEMISSAO)='07' THEN EXTRACT(DAY FROM CONTRATO.DTEMISSAO)||''||' de Julho de '||''||EXTRACT(YEAR FROM CONTRATO.DTEMISSAO)
    wHEN EXTRACT(MONTH FROM CONTRATO.DTEMISSAO)='08' THEN EXTRACT(DAY FROM CONTRATO.DTEMISSAO)||''||' de Agosto de '||''||EXTRACT(YEAR FROM CONTRATO.DTEMISSAO)
    wHEN EXTRACT(MONTH FROM CONTRATO.DTEMISSAO)='09' THEN EXTRACT(DAY FROM CONTRATO.DTEMISSAO)||''||' de Setembro de '||''||EXTRACT(YEAR FROM CONTRATO.DTEMISSAO)
    wHEN EXTRACT(MONTH FROM CONTRATO.DTEMISSAO)='10' THEN EXTRACT(DAY FROM CONTRATO.DTEMISSAO)||''||' de Outubro de '||''||EXTRACT(YEAR FROM CONTRATO.DTEMISSAO)
    wHEN EXTRACT(MONTH FROM CONTRATO.DTEMISSAO)='11' THEN EXTRACT(DAY FROM CONTRATO.DTEMISSAO)||''||' de Novembro de '||''||EXTRACT(YEAR FROM CONTRATO.DTEMISSAO)
    wHEN EXTRACT(MONTH FROM CONTRATO.DTEMISSAO)='12' THEN EXTRACT(DAY FROM CONTRATO.DTEMISSAO)||''||' de Dezembro de '||''||EXTRACT(YEAR FROM CONTRATO.DTEMISSAO)
    end DTEMIMES,
    CONTRATO.DTEMISSAO,
    
    CASE WHEN CONTRATOCFG.ENTRADASAIDA='S' AND CONTRATOITE.ITEM IN (1,23,6) AND (contamov.cdclasspessoa IN (6, 21) OR endereco.cdclasspessoa IN (6,21))
    THEN 'O(A) COMPRADOR(A) declara que faz jus a suspensão de PIS e COFINS conforme Inciso I, artigo 569 IN RFB nº 2121/22, ou seja, declara que destinará o consumo dessa aquisição, em sua totalidade, na preparação dos tipos utilizados na alimentação de animais vivos classificados nas posições 01.03 e 01.05, classificados no código 23.09.90 da TIPI.'
    END TRIBUTO,
    
    COALESCE(/*CLAUSULATRIANGULAR.CLAUSULAUM,*/CLAUSULA.CLAUSULAUM,CLAUSULA_MG.CLAUSULAUM,CLAUSULA_UF.CLAUSULAUM,CLAUSULA_TD.CLAUSULAUM) AS CLAUSULAUM,
    
    CASE WHEN CONTRATO_U.INSECAOTAXA = 'S' AND CONTRATO_U.TIPOPESSOA = 'EMPRESA' THEN COALESCE(/*U_CLAUSULADOISCTRTRIANGULAR.CLAUSULA,*/DOISCTRE_FILT.CLAUSULA,DOISCTRE_UNI.CLAUSULA,DOISCTRE.CLAUSULA,DOISCTRERRO.CLAUSULA)
    WHEN CONTRATO_U.INSECAOTAXA = 'N' AND CONTRATO_U.TIPOPESSOA = 'EMPRESA' THEN COALESCE(/*U_CLAUSULADOISCTRTRIANGULAR.CLAUSULA,*/DOISCTRE_FILT.CLAUSULA,DOISCTRE_UNI.CLAUSULA,DOISCTRE.CLAUSULA,DOISCTRERRO.CLAUSULA)
    WHEN CONTRATO_U.TIPOPESSOA <> 'EMPRESA' THEN COALESCE(/*U_CLAUSULADOISCTRTRIANGULAR.CLAUSULA,*/DOISCTRE.CLAUSULA,DOISCTRERRO.CLAUSULA)
    END "FORMA ENTREGA",
    
    
    COALESCE(/*U_CLAUSULAPGTOCTRTRIANGULAR.DESCRICAO,*/PGTOCTRE.DESCRICAO,PGTOCTRERRO.DESCRICAO) AS "FORMA DE PGTO",
    
    COALESCE(/*U_CLAUSULAGERALCTRTRIANGULAR.DESCRICAO,*/GERALCTRE_LIM_FEV.DESCRICAO,GERALCTRE_ITEM_PGTO.DESCRICAO,GERALCTRE_ITEM.DESCRICAO,GERALCTRE_PGTO.DESCRICAO,GERALCTRE.DESCRICAO,GERALCTRERRO.DESCRICAO) AS "CLAUSULA GERAL",
    CASE WHEN ((contrato_u.statusaprov <> '2 - Aprovado') or (CONTRATO_U.CONTRATO_EDIT = 'S')) THEN 'Contrato Não Aprovado'
    ELSE '' end statusaprov,
    
    COALESCE(CONTRATO_U.VALORADIANTADO,0) AS VALORADIANTADO,
    EXTENSO(COALESCE(CONTRATO_U.VALORADIANTADO,0)) AS DESC_VALORADIANTADO,
    COALESCE(CONTRATO_U.PORCENTAGEMJUROS,0) AS PORCENTAGEMJUROS,
    OS_EXTENSO_PORCENTO(COALESCE(CONTRATO_U.PORCENTAGEMJUROS,0)) AS DESC_PORCENTAGEMJUROS,
    case when contrato.MOEDA = 2 then 'US$ ' else 'R$ ' end TIPOMOEDA,
    case when contrato.moeda = 2 then 'Não obstante o preço do produto tenha sido fixado em dólar norte americano, o pagamento será realizado em moeda corrente nacional, e para tanto, as partes ajustam que a conversão será feita pela taxa média de compra e venda, na modalidade Sistema PTAX, pela cotação do fechamento do dia útil imediatamente anterior ao do pagamento, conforme divulgado pelo SISBACEN.'
    else null end clausula_dolar,
    --
    contrato_u.os_microrregiao,
    CONTAMOV_TRI.NOME AS NOMETRI,
    CONTAMOV_TRI.CNPJF AS CNPJFTRI,
    --COALESCE(U_CLAUSULAGERALCTRTRIANGULAR.U_CLAUSULAGERALCTR_ID,GERALCTRE_LIM_FEV.U_CLAUSULAGERALCTR_ID,GERALCTRE_ITEM_PGTO.U_CLAUSULAGERALCTR_ID,GERALCTRE_ITEM.U_CLAUSULAGERALCTR_ID,GERALCTRE_PGTO.U_CLAUSULAGERALCTR_ID,GERALCTRE.U_CLAUSULAGERALCTR_ID,GERALCTRERRO.U_CLAUSULAGERALCTR_ID) AS U_CLAUSULAGERALCTR_ID,
    --COALESCE(GERALCTRE_LIM_FEV.OPTRIANGULAR,GERALCTRE_ITEM_PGTO.OPTRIANGULAR,GERALCTRE_ITEM.OPTRIANGULAR,GERALCTRE_PGTO.OPTRIANGULAR,GERALCTRE.OPTRIANGULAR,GERALCTRERRO.OPTRIANGULAR) AS OPTRIANGULAR
    CONTRATO_U.OS_TRIANGULAR AS OPTRIANGULAR,
    CONTRATO.NUMEROCM AS NUMEROCM_CLIENTE
    FROM CONTRATO
    INNER JOIN FILIAL ON
    FILIAL.ESTAB            = CONTRATO.ESTAB
    
    INNER JOIN CIDADE CIDFIL ON
    CIDFIL.CIDADE           = FILIAL.CIDADE
    
    INNER JOIN CONTRATOCFG ON CONTRATOCFG.CONTCONF    = CONTRATO.CONTCONF
    
    INNER JOIN CONTAMOV ON
    CONTAMOV.NUMEROCM       = CONTRATO.NUMEROCM
    
    LEFT JOIN ENDERECO ON
    ENDERECO.NUMEROCM       = CONTRATO.NUMEROCM AND
    ENDERECO.SEQENDERECO    = CONTRATO.ENDALTERNATIVO
    
    LEFT JOIN TIPOLOGRADOURO ON
    tipologradouro.codigo =  CASE WHEN CONTRATO.ENDALTERNATIVO > 0 THEN endereco.TPLOGRADOURO ELSE cONTAMOV.tplogradouro END
    
    LEFT JOIN PPESCLI ON
    PPESCLI.cliente      = CONTRATO.NUMEROCM
    
    
    left JOIN CIDADE ON
    cidade.cidade = CASE WHEN CONTRATO.ENDALTERNATIVO > 0 THEN ENDERECO.CIDADE ELSE CONTAMOV.CIDADE END
    
    
    INNER JOIN CONTRATOITE ON
    CONTRATOITE.ESTAB       = CONTRATO.ESTAB AND
    CONTRATOITE.CONTRATO    = CONTRATO.CONTRATO
    
    INNER JOIN ITEMAGRO ON  ITEMAGRO.ITEM           = CONTRATOITE.ITEM
    
    INNER JOIN SAFRAS ON SAFRAS.SAFRA            = CONTRATO.SAFRA
    
    
    INNER JOIN CONTRATO_U ON
    CONTRATO_U.ESTAB        = CONTRATO.ESTAB AND
    CONTRATO_U.CONTRATO     = CONTRATO.CONTRATO
    
    LEFT JOIN CONTAMOV CONTAMOV_TRI ON
    CONTRATO_U.COD_PRODUTOR = CONTAMOV_TRI.NUMEROCM
    
    LEFT JOIN ENDERECO ENDERECO_TRI ON
    ENDERECO_TRI.NUMEROCM       = CONTRATO_U.COD_PRODUTOR AND
    ENDERECO_TRI.CREDENCIALAGRO    = CONTRATO_U.INSCESTAD_PRODUTOR
    
    LEFT JOIN TIPOLOGRADOURO TIPOLOGRADOURO_TRI ON
    TIPOLOGRADOURO_TRI.codigo =  cONTAMOV_TRI.tplogradouro
    
    left JOIN CIDADE CIDADE_TRI ON
    CIDADE_TRI.cidade = CONTAMOV_TRI.CIDADE
    
    LEFT JOIN PPESCLI PPESCLI_TRI ON
    CONTRATO_U.COD_PRODUTOR = PPESCLI_TRI.CLIENTE
    
    -- clausulas ---------------------------------------------------------------
        --1--
    /*LEFT JOIN U_CLAUSULACTR CLAUSULATRIANGULAR
        ON  COALESCE(CONTRATO_U.OS_TRIANGULAR, 'N') = 'S' 
        AND COALESCE(CLAUSULATRIANGULAR.OPTRIANGULAR, 'N') = 'S'*/
    LEFT JOIN U_CLAUSULACTR CLAUSULA
        ON  CLAUSULA.ITEM = CONTRATOITE.ITEM
        --AND CLAUSULA.CONTCONF = contratocfg.contconf
        AND ',' || CLAUSULA.CONTCONF || ',' LIKE '%,' || TO_CHAR(CONTRATO.CONTCONF) || ',%'
        AND CLAUSULA.QUALIDADETR = CONTRATO_U.QTRIGO
        AND CLAUSULA.ESTAB = CONTRATO.ESTAB
        AND CLAUSULA.UF = CIDFIL.UF
        --
        AND COALESCE(CONTRATO_U.OS_TRIANGULAR, 'N') = COALESCE(CLAUSULA.OPTRIANGULAR, 'N')
    
    LEFT JOIN U_CLAUSULACTR CLAUSULA_MG
        ON  CLAUSULA_MG.ITEM = CONTRATOITE.ITEM
        --AND CLAUSULA_MG.CONTCONF = contratocfg.contconf
        AND ',' || CLAUSULA_MG.CONTCONF || ',' LIKE '%,' || TO_CHAR(CONTRATO.CONTCONF) || ',%'
        AND CLAUSULA_MG.QUALIDADETR = CONTRATO_U.QTRIGO
        AND CLAUSULA_MG.ESTAB = 1
        AND CLAUSULA_MG.UF  = 'MG'
        --
        AND COALESCE(CONTRATO_U.OS_TRIANGULAR, 'N') = COALESCE(CLAUSULA_MG.OPTRIANGULAR, 'N')
    
    LEFT JOIN U_CLAUSULACTR CLAUSULA_UF
        ON  CLAUSULA_UF.ITEM = CONTRATOITE.ITEM
        --AND CLAUSULA_UF.CONTCONF = contratocfg.contconf
        AND ',' || CLAUSULA_UF.CONTCONF || ',' LIKE '%,' || TO_CHAR(CONTRATO.CONTCONF) || ',%'
        AND CLAUSULA_UF.QUALIDADETR = CONTRATO_U.QTRIGO
        AND CLAUSULA_UF.ESTAB = CONTRATO.ESTAB
        AND CLAUSULA_UF.UF IS NULL
        --
        AND COALESCE(CONTRATO_U.OS_TRIANGULAR, 'N') = COALESCE(CLAUSULA_UF.OPTRIANGULAR, 'N')
    
    LEFT JOIN U_CLAUSULACTR CLAUSULA_TD
        ON  CLAUSULA_TD.ITEM = CONTRATOITE.ITEM
        --AND CLAUSULA_TD.CONTCONF = contratocfg.contconf
        AND ',' || CLAUSULA_TD.CONTCONF || ',' LIKE '%,' || TO_CHAR(CONTRATO.CONTCONF) || ',%'
        AND CLAUSULA_TD.QUALIDADETR = CONTRATO_U.QTRIGO
        --
        AND COALESCE(CONTRATO_U.OS_TRIANGULAR, 'N') = COALESCE(CLAUSULA_TD.OPTRIANGULAR, 'N')
        --1--
        --2--
    /*LEFT JOIN U_CLAUSULADOISCTR U_CLAUSULADOISCTRTRIANGULAR
        ON  COALESCE(CONTRATO_U.OS_TRIANGULAR, 'N') = COALESCE(U_CLAUSULADOISCTRTRIANGULAR.OPTRIANGULAR, 'N')
        AND CONTRATO_U.TIPOENTREGA = U_CLAUSULADOISCTRTRIANGULAR.TIPO
        AND CONTRATO_U.TIPOFRETES = U_CLAUSULADOISCTRTRIANGULAR.TIPOFRETE
        AND CONTRATO_U.TIPOPESSOA = U_CLAUSULADOISCTRTRIANGULAR.ARMAZEM*/
        
    left JOIN U_CLAUSULADOISCTR DOISCTRE_FILT
        ON  DOISCTRE_FILT.TIPO      = CONTRATO_U.TIPOENTREGA
        AND DOISCTRE_FILT.TIPOFRETE = CONTRATO_U.TIPOFRETES
        AND DOISCTRE_FILT.ARMAZEM   = CONTRATO_U.TIPOPESSOA
        AND DOISCTRE_FILT.ITEM      = CONTRATOITE.ITEM
        AND DOISCTRE_FILT.ESTAB     = CONTRATO.ESTAB
        AND DOISCTRE_FILT.TABELADIF = COALESCE(CONTRATO_U.INSECAOTAXA,'N')
        AND ',' || DOISCTRE_FILT.CONFCONT || ',' LIKE '%,' || TO_CHAR(CONTRATO.CONTCONF) || ',%'
        --
        AND COALESCE(CONTRATO_U.OS_TRIANGULAR, 'N') = COALESCE(DOISCTRE_FILT.OPTRIANGULAR, 'N')
    
    left JOIN U_CLAUSULADOISCTR DOISCTRE_UNI ON
        DOISCTRE_UNI.TIPO      = CONTRATO_U.TIPOENTREGA AND
        DOISCTRE_UNI.TIPOFRETE = CONTRATO_U.TIPOFRETES AND
        DOISCTRE_UNI.ARMAZEM   = CONTRATO_U.TIPOPESSOA AND
        DOISCTRE_UNI.ITEM      = CONTRATOITE.ITEM   AND
        DOISCTRE_UNI.ESTAB     = 1 AND
        DOISCTRE_UNI.TABELADIF = COALESCE(CONTRATO_U.INSECAOTAXA,'N') AND 
        ',' || DOISCTRE_UNI.CONFCONT || ',' LIKE '%,' || TO_CHAR(CONTRATO.CONTCONF) || ',%'
        --
        AND COALESCE(CONTRATO_U.OS_TRIANGULAR, 'N') = COALESCE(DOISCTRE_UNI.OPTRIANGULAR, 'N')
    
    left JOIN U_CLAUSULADOISCTR DOISCTRE ON
        DOISCTRE.TIPO      = CONTRATO_U.TIPOENTREGA AND
        DOISCTRE.TIPOFRETE = CONTRATO_U.TIPOFRETES AND
        DOISCTRE.ARMAZEM   = CONTRATO_U.TIPOPESSOA AND
        DOISCTRE.ITEM IS NULL AND
        DOISCTRE.ESTAB IS NULL AND
        DOISCTRE.TABELADIF = 'N' AND 
        ',' || DOISCTRE.CONFCONT || ',' LIKE '%,' || TO_CHAR(CONTRATO.CONTCONF) || ',%'
        --
        AND COALESCE(CONTRATO_U.OS_TRIANGULAR, 'N') = COALESCE(DOISCTRE.OPTRIANGULAR, 'N')
    
    left JOIN U_CLAUSULADOISCTR DOISCTRERRO ON
        DOISCTRERRO.u_clausuladoisctr_id = 999
        --2--
        --3--
    /*LEFT JOIN U_CLAUSULAPGTOCTR U_CLAUSULAPGTOCTRTRIANGULAR
        ON  COALESCE(CONTRATO_U.OS_TRIANGULAR, 'N') = COALESCE(U_CLAUSULAPGTOCTRTRIANGULAR.OPERACAOTRIANG, 'N')
        AND CONTRATO_U.TIPOPGTO = U_CLAUSULAPGTOCTRTRIANGULAR.TIPOPGTO*/
    
    left JOIN U_CLAUSULAPGTOCTR PGTOCTRE
        ON  PGTOCTRE.TIPOPGTO  = CONTRATO_U.TIPOPGTO
        AND ',' || PGTOCTRE.CONFCONT || ',' LIKE '%,' || TO_CHAR(CONTRATO.CONTCONF) || ',%'
        --
        AND COALESCE(CONTRATO_U.OS_TRIANGULAR, 'N') = COALESCE(PGTOCTRE.OPERACAOTRIANG, 'N')
    
    left JOIN U_CLAUSULAPGTOCTR PGTOCTRERRO
        ON PGTOCTRERRO.U_CLAUSULAPGTOCTR_ID IN (999)
        --3--
        --4--
    /*LEFT JOIN U_CLAUSULAGERALCTR U_CLAUSULAGERALCTRTRIANGULAR
        ON  COALESCE(CONTRATO_U.OS_TRIANGULAR, 'N') = 'S'
        AND COALESCE(U_CLAUSULAGERALCTRTRIANGULAR.OPTRIANGULAR, 'N') = 'S'*/
    /* -------------- clausula geral -------------- */
    LEFT JOIN U_CLAUSULAGERALCTR GERALCTRE
        ON ',' || GERALCTRE.CONFCONT || ',' LIKE '%,' || TO_CHAR(CONTRATO.CONTCONF) || ',%'
        --
        AND COALESCE(CONTRATO_U.OS_TRIANGULAR, 'N') = COALESCE(GERALCTRE.OPTRIANGULAR, 'N')
    LEFT JOIN U_CLAUSULAGERALCTR GERALCTRE_PGTO
        ON  ',' || GERALCTRE_PGTO.CONFCONT || ',' LIKE '%,' || TO_CHAR(CONTRATO.CONTCONF) || ',%'
        AND GERALCTRE_PGTO.TIPOPGTO = CONTRATO_U.TIPOPGTO
        AND GERALCTRE_PGTO.TIPOENTREGA = CONTRATO_U.TIPOENTREGA
        --
        AND COALESCE(CONTRATO_U.OS_TRIANGULAR, 'N') = COALESCE(GERALCTRE_PGTO.OPTRIANGULAR, 'N')
     /* -------------- clausula geral  item -------------- */
    LEFT JOIN (
    SELECT
    t.U_CLAUSULAGERALCTR_ID,
    t.DTINI,
    t.DTFIN,
    t.DESCRICAO,
    t.TIPO,
    REGEXP_SUBSTR(t.CONFCONT, '[^,]+', 1, LEVEL)  AS CONFCONT_ITEM,
    REGEXP_SUBSTR(t.CONFITEM, '[^,]+', 1, LEVEL)  AS CONFITEM_ITEM,
    T.OPTRIANGULAR
    FROM U_CLAUSULAGERALCTR t
    WHERE t.CONFITEM IS NOT NULL
    CONNECT BY
    PRIOR t.U_CLAUSULAGERALCTR_ID = t.U_CLAUSULAGERALCTR_ID
    AND PRIOR SYS_GUID() IS NOT NULL
    AND REGEXP_SUBSTR(t.CONFITEM, '[^,]+', 1, LEVEL) IS NOT NULL
    )GERALCTRE_ITEM
        ON  GERALCTRE_ITEM.CONFCONT_ITEM = CONTRATO.CONTCONF
        AND GERALCTRE_ITEM.CONFITEM_ITEM = CONTRATOITE.ITEM
        --
        AND COALESCE(CONTRATO_U.OS_TRIANGULAR, 'N') = COALESCE(GERALCTRE_ITEM.OPTRIANGULAR, 'N')

    LEFT JOIN (
    SELECT
    t.U_CLAUSULAGERALCTR_ID,
    t.DTINI,
    t.DTFIN,
    t.DESCRICAO,
    t.TIPO,
    REGEXP_SUBSTR(t.CONFCONT, '[^,]+', 1, LEVEL)  AS CONFCONT_ITEM,
    REGEXP_SUBSTR(t.CONFITEM, '[^,]+', 1, LEVEL)  AS CONFITEM_ITEM,
    t.TIPOENTREGA,
    t.TIPOPGTO,
    T.OPTRIANGULAR
    FROM U_CLAUSULAGERALCTR t
    WHERE t.CONFITEM IS NOT NULL AND t.TIPOENTREGA is not null and t.TIPOPGTO is not null
    CONNECT BY
    PRIOR t.U_CLAUSULAGERALCTR_ID = t.U_CLAUSULAGERALCTR_ID
    AND PRIOR SYS_GUID() IS NOT NULL
    AND REGEXP_SUBSTR(t.CONFITEM, '[^,]+', 1, LEVEL) IS NOT NULL
    )GERALCTRE_ITEM_PGTO
        ON  GERALCTRE_ITEM_PGTO.CONFCONT_ITEM = CONTRATO.CONTCONF
        AND GERALCTRE_ITEM_PGTO.CONFITEM_ITEM = CONTRATOITE.ITEM
        AND GERALCTRE_ITEM_PGTO.TIPOPGTO = CONTRATO_U.TIPOPGTO
        AND GERALCTRE_ITEM_PGTO.TIPOENTREGA = CONTRATO_U.TIPOENTREGA
        --
        AND COALESCE(CONTRATO_U.OS_TRIANGULAR, 'N') = COALESCE(GERALCTRE_ITEM_PGTO.OPTRIANGULAR, 'N')
    
    --
    LEFT JOIN (
    SELECT
    t.U_CLAUSULAGERALCTR_ID,
    t.DTINI,
    t.DTFIN,
    t.DESCRICAO,
    t.TIPO,
    --REGEXP_SUBSTR(t.CONFCONT, '[^,]+', 1, LEVEL)  AS CONFCONT_ITEM,
    t.CONFCONT as CONFCONT_ITEM,
    REGEXP_SUBSTR(t.CONFITEM, '[^,]+', 1, LEVEL)  AS CONFITEM_ITEM,
    t.TIPOENTREGA,
    t.TIPOPGTO,
    T.OPTRIANGULAR
    FROM U_CLAUSULAGERALCTR t
    WHERE
            /*t.CONFITEM IS NOT NULL
        AND t.TIPOENTREGA is not null
        and t.TIPOPGTO is not null
        and*/ t.limite_entrega = 2
    CONNECT BY
        PRIOR t.U_CLAUSULAGERALCTR_ID = t.U_CLAUSULAGERALCTR_ID
    AND PRIOR SYS_GUID() IS NOT NULL
    AND REGEXP_SUBSTR(t.CONFITEM, '[^,]+', 1, LEVEL) IS NOT NULL
    )GERALCTRE_LIM_FEV
        ON INSTR(   ',' || GERALCTRE_LIM_FEV.CONFCONT_ITEM || ',',
                    ',' || CONTRATO.CONTCONF || ','
                ) > 0
        --GERALCTRE_LIM_FEV.CONFCONT_ITEM = TO_CHAR(CONTRATO.CONTCONF)
        --AND GERALCTRE_LIM_FEV.CONFITEM_ITEM = CONTRATOITE.ITEM
        AND GERALCTRE_LIM_FEV.TIPOPGTO = CONTRATO_U.TIPOPGTO
        AND GERALCTRE_LIM_FEV.TIPOENTREGA = CONTRATO_U.TIPOENTREGA
        and to_char(contrato.dtlimentimp, 'mm') = '02'
    --
    LEFT JOIN U_CLAUSULAGERALCTR GERALCTRERRO ON GERALCTRERRO.U_CLAUSULAGERALCTR_ID = 999
        --4--
    -- clausulas ---------------------------------------------------------------
    LEFT JOIN CONTAMOV CMPESSENT ON CMPESSENT.NUMEROCM = CONTRATO.PESSENTREGA
    
    LEFT JOIN CIDADE CIDADEPESSENDCM ON  CIDADEPESSENDCM.cidade =  CMPESSENT.cidade
    
    LEFT JOIN ENDERECO CMPESSEND ON CMPESSEND.NUMEROCM       = CONTRATO.PESSENTREGA
    AND CMPESSEND.SEQENDERECO    = CONTRATO.SEQENDENTREGA
    
    LEFT JOIN CIDADE CIDADEPESSEND ON   CIDADEPESSEND.cidade =  cmpessend.cidade
    
    --
    LEFT JOIN CONTAMOV CMPESRET ON CMPESRET.NUMEROCM = CONTRATO.PESSRETIRADA
    
    LEFT JOIN CIDADE CIDADECMPESRETENDCM ON  CIDADECMPESRETENDCM.cidade =  CMPESRET.cidade
    
    LEFT JOIN ENDERECO CMPESRETEND ON CMPESRETEND.NUMEROCM       = CONTRATO.PESSRETIRADA
    AND CMPESRETEND.SEQENDERECO    = CONTRATO.SEQENDRETIRADA
    
    LEFT JOIN CIDADE CIDADEPESRETEND ON   CIDADEPESRETEND.cidade =  CMPESRETEND.cidade
    
    --
    
    
    LEFT JOIN LOCALEST ON LOCALEST.ESTAB = CONTRATOITE.ESTAB
    AND localest.local = CONTRATOITE.LOCAL
    
    LEFT JOIN CIDADE CIDADE_LOCAL ON CIDADE_LOCAL.CIDADE = LOCALEST.CIDADE                  
    
    LEFT JOIN localest_u ON localest_u.estab = LOCALEST.ESTAB
    AND localest_u.local = LOCALEST.LOCAL
    
    LEFT JOIN CONTAMOV PESSRET ON PESSRET.NUMEROCM = localest_u.numerocm
    AND localest_u.seqendereco=0
    
    left join cidade pessretcidade on pessretcidade.cidade=pessret.cidade
    
    LEFT JOIN ENDERECO PESSEND ON PESSEND.NUMEROCM = localest_u.numerocm
    AND PESSEND.SEQENDERECO = localest_u.seqendereco
    
    left join cidade endretcidade on endretcidade.cidade=pessend.cidade
    
    
    
    LEFT JOIN contratodtvencto ON contratodtvencto.estab = CONTRATO.ESTAB
    AND contratodtvencto.contrato = CONTRATO.CONTRATO
    AND ((CONTRATO_U.TIPOPGTO ='ANTECIPADO') OR (CONTRATO_U.TIPOPGTO IN ('APRAZO','APRAZOCTR','APRAZOAMOSTRA','APRAZOEMBARQUE','APRAZODESCARGA','SOBREDESCARGA')))
    
    LEFT JOIN ITEMPREMB ON
    ITEMPREMB.ESTAB = CONTRATOITE.ESTAB
    AND ITEMPREMB.ITEM = CONTRATOITE.ITEM
    
    WHERE CONTRATO.ESTAB =:ESTAB
    AND CONTRATO.CONTRATO =:CONTRATO
    AND ROWNUM = 1
    )DADOS

LEFT JOIN CONTRATOBX ON  CONTRATOBX.ESTABBX = DADOS.ESTAB AND CONTRATOBX.CONTRATOBX = DADOS.CONTRATO
LEFT JOIN U_LOGPEDCTR ON U_LOGPEDCTR.CONTRATO = COALESCE(CONTRATOBX.CONTRATO,DADOS.CONTRATO) AND U_LOGPEDCTR.ESTAB = COALESCE(CONTRATOBX.ESTAB,DADOS.ESTAB)
LEFT JOIN PEDCAB_U ON PEDCAB_U.ESTAB = U_LOGPEDCTR.ESTAB AND PEDCAB_U.NUMERO = U_LOGPEDCTR.PEDIDO AND PEDCAB_U.SERIE = U_LOGPEDCTR.SERIE_PED