SELECT
DADOS.*,
CASE WHEN DADOS.CONTCONF = 7 THEN 'CLÁUSULA 7 - FORO DE COMPETÊNCIA' ELSE 'CLÁUSULA 6 - FORO DE COMPETÊNCIA' END FORO_COMPETENCIA,
    CASE WHEN 
    DADOS.CONTCONF = 3 THEN 
             TO_CLOB(
                'a) Mercadoria: ' || DADOS.PRODUTO || ' ' || DADOS.QTRIGO || ', ' || DADOS.DESCPRODUTO || CHR(10) ||
                'b) Quilos brutos finais (pós-classificação): ' || REPLACE(REPLACE(REPLACE(REPLACE(TO_CHAR(DADOS.QTDADE, '999G999G999'), ' ', ''), '.', 'TEMP'), ',', '.'), 'TEMP', ',') || ' Kg' || CHR(10) ||
                'c) Quantidade de '||(case when item in (16988) then 'toneladas: ' else 'sacas: ' end)|| REPLACE(REPLACE(REPLACE(REPLACE(TO_CHAR(DADOS.QTDADESC, '999G999G999'), ' ', ''), '.', 'TEMP'), ',', '.'), 'TEMP', ',') || ' (' || DADOS.QTDADESCDESC ||(case when item in (16988) then ') Toneladas' else  ') Sacas' end)|| CHR(10) ||
                'd) Preço por '||(case when item in (16988) then 'tonelada:' else 'saca:' end )||' A Fixar' || CHR(10) ||
                CASE WHEN DADOS.TIPOENTREGA = 'DISPONIVEL' THEN 'e)Entrega: Produto Disponível' ELSE 'e) Entrega de ' || TO_CHAR(DADOS.dtinicioent, 'DD/MM/YYYY') || ' até ' || TO_CHAR(DADOS.dtlimentimp, 'DD/MM/YYYY') END || CHR(10) ||
                'f) Safra: ' || DADOS.SAFRA || CHR(10) ||
                'g) Local de entrega/carregamento: ' || DADOS.endcm || CHR(10) ||
                'h) Prazo p/ Pagamento: A Combinar no momento da fixação' || CHR(10) ||
                'i) Pagamento Antecipado: R$ ' || (CASE WHEN DADOS.VALORADIANTADO = 0 THEN '0'||REPLACE(REPLACE(REPLACE(REPLACE(TO_CHAR(DADOS.VALORADIANTADO, '999G999G999D00'), ' ', ''), '.', 'TEMP'), ',', '.'), 'TEMP', ',') 
                                                   ELSE REPLACE(REPLACE(REPLACE(REPLACE(TO_CHAR(DADOS.VALORADIANTADO, '999G999G999D00'), ' ', ''), '.', 'TEMP'), ',', '.'), 'TEMP', ',') END)||
                                                   ' (' || DADOS.DESC_VALORADIANTADO || ')' || CHR(10) ||
                'j) Encargos Financeiros: ' || REPLACE(REPLACE(REPLACE(REPLACE(TO_CHAR(DADOS.PORCENTAGEMJUROS, '999G999G990D0', 'NLS_NUMERIC_CHARACTERS = '',.'''), ' ', ''), ',', 'TEMP'), ',', '.'), 'TEMP', ',') || '% (' || DADOS.DESC_PORCENTAGEMJUROS || ') ao mês'
                /*'j) Encargos Financeiros: ' || REPLACE(REPLACE(REPLACE(REPLACE(TO_CHAR(DADOS.PORCENTAGEMJUROS, '999G999G999'), ' ', ''), '.', 'TEMP'), ',', '.'), 'TEMP', ',') || '% (' || DADOS.DESC_PORCENTAGEMJUROS || ' Por cento) ao mês'|| CHR(10) ||
                'k)  Banco '|| PCOBBANCO.DESCRICAO||', Agência '||CONTAMOVBCODEP.AGENCIA||', Conta para pagamento n° '||CONTAMOVBCODEP.CONTA||', Variação XX de titularidade da VENDEDOR(A).'*/
            )
     WHEN 
     DADOS.CONTCONF = 7 AND DADOS.TIPOFRETES = 'CIF' THEN 
             TO_CLOB(
                'a) Mercadoria: ' || DADOS.PRODUTO || ' TIPO EXPORTAÇÃO' || DADOS.QTRIGO || ', ' || DADOS.DESCPRODUTO || CHR(10) ||
                'b) Quilos brutos finais (pós-classificação): ' || REPLACE(REPLACE(REPLACE(REPLACE(TO_CHAR(DADOS.QTDADE, '999G999G999'), ' ', ''), '.', 'TEMP'), ',', '.'), 'TEMP', ',') || ' Kg' || CHR(10) ||
                'c) Quantidade de '||(case when item in (16988) then 'toneladas: ' else 'sacas: ' end) || REPLACE(REPLACE(REPLACE(REPLACE(TO_CHAR(DADOS.QTDADESC, '999G999G999'), ' ', ''), '.', 'TEMP'), ',', '.'), 'TEMP', ',') || ' (' || DADOS.QTDADESCDESC || (case when item in (16988) then ') Toneladas' else  ') Sacas' end) || CHR(10) ||
                'd) Preço por '||(case when item in (16988) then 'tonelada: ' else 'saca: 'end)||TIPOMOEDA|| REPLACE(REPLACE(REPLACE(REPLACE(TO_CHAR(DADOS.VUNIT, '999G999G999D00'), ' ', ''), '.', 'TEMP'), ',', '.'), 'TEMP', ',') || ' (' || DADOS.VUNITDESC || '). '||clausula_dolar || CHR(10) ||
                'e) Preço total: '||TIPOMOEDA || REPLACE(REPLACE(REPLACE(REPLACE(TO_CHAR(DADOS.VTOTAL, '999G999G999D00'), ' ', ''), '.', 'TEMP'), ',', '.'), 'TEMP', ',') || ' (' || DADOS.VTOTALDESC || ')' || CHR(10) ||
                'f) Entrega de ' || TO_CHAR(DADOS.dtinicioent, 'DD/MM/YYYY') || ' até ' || TO_CHAR(DADOS.dtlimentimp, 'DD/MM/YYYY') || CHR(10) ||
                'g) Safra: ' || DADOS.SAFRA || CHR(10) ||
                'h) Local de entrega/carregamento: Um dos terminais portuários de ' || DADOS.local_alinea || CHR(10) ||
                'i) Prazo p/ Pagamento: ' || DADOS.DTPGTO || CHR(10) ||
                (CASE WHEN LENGTH(PEDCAB_U.CONTABANCPROD) >= 6 AND DADOS.CONTCONF IN (7) THEN PEDCAB_U.CONTABANCPROD ELSE NULL END)
            ) 
     WHEN 
     DADOS.CONTCONF = 7 AND DADOS.TIPOFRETES = 'FOB' THEN 
             TO_CLOB(
                'a) Mercadoria: ' || DADOS.PRODUTO || ' TIPO EXPORTAÇÃO' || DADOS.QTRIGO || ', ' || DADOS.DESCPRODUTO || CHR(10) ||
                'b) Quilos brutos finais (pós-classificação): ' || REPLACE(REPLACE(REPLACE(REPLACE(TO_CHAR(DADOS.QTDADE, '999G999G999'), ' ', ''), '.', 'TEMP'), ',', '.'), 'TEMP', ',') || ' Kg' || CHR(10) ||
                'c) Quantidade de '||(case when item in (16988) then 'toneladas: ' else 'sacas: ' end)|| REPLACE(REPLACE(REPLACE(REPLACE(TO_CHAR(DADOS.QTDADESC, '999G999G999'), ' ', ''), '.', 'TEMP'), ',', '.'), 'TEMP', ',') || ' (' || DADOS.QTDADESCDESC || (case when item in (16988) then ') Toneladas' else  ') Sacas' end) || CHR(10) ||
                'd) Preço por '||(case when item in (16988) then 'tonelada: ' else 'saca: 'end)||TIPOMOEDA || REPLACE(REPLACE(REPLACE(REPLACE(TO_CHAR(DADOS.VUNIT, '999G999G999D00'), ' ', ''), '.', 'TEMP'), ',', '.'), 'TEMP', ',') || ' (' || DADOS.VUNITDESC || '). '||clausula_dolar || CHR(10) ||
                'e) Preço total: '||TIPOMOEDA || REPLACE(REPLACE(REPLACE(REPLACE(TO_CHAR(DADOS.VTOTAL, '999G999G999D00'), ' ', ''), '.', 'TEMP'), ',', '.'), 'TEMP', ',') || ' (' || DADOS.VTOTALDESC || ')' || CHR(10) ||
                'f) Entrega de ' || TO_CHAR(DADOS.dtinicioent, 'DD/MM/YYYY') || ' até ' || TO_CHAR(DADOS.dtlimentimp, 'DD/MM/YYYY') || CHR(10) ||
                'g) Safra: ' || DADOS.SAFRA || CHR(10) ||
                'h) Local de entrega/carregamento: ' || DADOS.endcm || CHR(10) ||
                'i) Prazo p/ Pagamento: ' || DADOS.DTPGTO || CHR(10) ||
                 (CASE WHEN LENGTH(PEDCAB_U.CONTABANCPROD) >= 6 AND DADOS.CONTCONF IN (7) THEN PEDCAB_U.CONTABANCPROD ELSE NULL END)
            )                
        ELSE
            TO_CLOB(
                'a) Mercadoria: ' || DADOS.PRODUTO || ' ' || DADOS.QTRIGO || ', ' || DADOS.DESCPRODUTO || CHR(10) ||
                'b) Quilos brutos finais (pós-classificação): ' || REPLACE(REPLACE(REPLACE(REPLACE(TO_CHAR(DADOS.QTDADE, '999G999G999'), ' ', ''), '.', 'TEMP'), ',', '.'), 'TEMP', ',') || ' Kg' || CHR(10) ||
                'c) Quantidade de '||(case when item in (16988) then 'toneladas: ' else 'sacas: ' end) || REPLACE(REPLACE(REPLACE(REPLACE(TO_CHAR(DADOS.QTDADESC, '999G999G999'), ' ', ''), '.', 'TEMP'), ',', '.'), 'TEMP', ',') || ' (' || DADOS.QTDADESCDESC || (case when item in (16988) then ') Toneladas' else  ') Sacas' end) || CHR(10) ||
                'd) Preço por '||(case when item in (16988) then 'tonelada: ' else 'saca: 'end)||TIPOMOEDA|| REPLACE(REPLACE(REPLACE(REPLACE(TO_CHAR(DADOS.VUNIT, '999G999G999D00'), ' ', ''), '.', 'TEMP'), ',', '.'), 'TEMP', ',') || ' (' || DADOS.VUNITDESC || '). '||clausula_dolar || CHR(10) ||
                'e) Preço total: '||TIPOMOEDA || REPLACE(REPLACE(REPLACE(REPLACE(TO_CHAR(DADOS.VTOTAL, '999G999G999D00'), ' ', ''), '.', 'TEMP'), ',', '.'), 'TEMP', ',') || ' (' || DADOS.VTOTALDESC || ')' || CHR(10) ||
                'f) Entrega de ' || TO_CHAR(DADOS.dtinicioent, 'DD/MM/YYYY') || ' até ' || TO_CHAR(DADOS.dtlimentimp, 'DD/MM/YYYY') || CHR(10) ||
                'g) Safra: ' || DADOS.SAFRA || CHR(10) ||
                'h) Local de entrega/carregamento: ' || DADOS.endcm || CHR(10) ||
                'i) Prazo p/ Pagamento: ' || DADOS.DTPGTO || CHR(10) ||
                 (CASE WHEN LENGTH(PEDCAB_U.CONTABANCPROD) >= 6 AND DADOS.CONTCONF IN (1,2) THEN PEDCAB_U.CONTABANCPROD ELSE NULL END)
            )
            
    END AS CLAUSULA_UM_FORMATADA
 FROM
 (
SELECT
    FILIAL.ESTAB,
    CONTRATO.CONTRATO,
    CONTRATO.CONTCONF,
    CONTRATO_U.TIPOENTREGA,
     CASE WHEN CONTRATOCFG.ENTRADASAIDA='E' THEN 'COMPRADOR(A)'ELSE 'VENDEDOR(A)' END TIPOOS,
     CASE WHEN CONTRATOCFG.ENTRADASAIDA='E' THEN 'VENDEDOR(A)'ELSE 'COMPRADOR(A)' END TIPOPESSOA,
     '6' AS CFC,
      CASE WHEN CONTRATOCFG.ENTRADASAIDA='E' and contratoite.item not in (16988) THEN
     'plantada no domicílio ou em qualquer outra área de propriedade do VENDEDOR(A) ou, ainda, que esteja em posse para fins de produção agrícola.'
     ELSE '' END DESCPRODUTO,
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

     CASE WHEN CONTAMOV.sexo='J' THEN ''
      WHEN PPESCLI.PAIS='Brasil' then
          (' Brasileiro(a), produtor(a) rural')
    ELSE COALESCE(' '||PPESCLI.PAIS,' Brasileiro(a)')||', produtor(a) rural'
    END AS DADOSPESSOAP,
    CONTAMOV.nome,
     CASE WHEN CONTRATO.ENDALTERNATIVO > 0 AND CONTAMOV.sexo='J' THEN ENDERECO.cnpjf
    ELSE CONTAMOV.CNPJF END CNPJF,
    CONTRATO.ENDALTERNATIVO,
    case when CONTRATO.ENDALTERNATIVO > 0 then
    tipologradouro.descricao||' '||endereco.ENDERECO||', '||endereco.numeroend||' - '||endereco.COMPLEMENTO||', '||endereco.BAIRRO||', Cep:'||endereco.cep||' na cidade de '||CIdade.NOME||'-'||CIDade.UF
    else
    tipologradouro.descricao||' '||CONTAMOV.ENDERECO||', '||CONTAMOV.numeroend||' - '||CONTAMOV.COMPLEMENTO||', '||CONTAMOV.BAIRRO||', Cep:'||contamov.cep||' na cidade de '||CIdade.NOME||'-'||CIDade.UF end AS ENDCOMPRADOR,

    
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

          WHEN CONTRATOCFG.ENTRADASAIDA='E' AND localest_u.seqendereco = 0 THEN
           COALESCE(PESSRET.APELIDO,'')||','||PESSRET.ENDERECO||', Nº'||PESSRET.numeroend||', CNPJ/CPF:'||PESSRET.CNPJF||', '||pessretcidade.NOME||'-'||pessretcidade.UF

            WHEN CONTRATOCFG.ENTRADASAIDA='E' and localest_u.seqendereco > 0 THEN
           COALESCE(PESSRET.APELIDO,'')||','||PESSEND.ENDERECO||', Nº'||PESSEND.numeroend||', CNPJ/CPF:'||PESSEND.CNPJF||', '||endretcidade.NOME||' -'||endretcidade.UF

          ELSE 'Sem Local de Retirada/Entrega' END AS endcm,
          CIDADE_LOCAL.NOME||' - '||CIDADE_LOCAL.UF AS local_alinea,
            

    
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
    WHEN CONTRATO_U.TIPOPGTO ='APRAZOCTR' THEN   numdiaspagto||' Dias da Emissão do Contrato'
    WHEN CONTRATO_U.TIPOPGTO ='APRAZOAMOSTRA' THEN numdiaspagto||' Dias da Entrega da Carga de Amostra'
    WHEN CONTRATO_U.TIPOPGTO ='APRAZOEMBARQUE' THEN numdiaspagto||' Dias do Carregamento da Mercadoria'
    WHEN CONTRATO_U.TIPOPGTO ='APRAZODESCARGA' THEN numdiaspagto||' Dias da Entrega da Mercadoria'
    WHEN contratodtvencto.dtvencto is NULL then  numdiaspagto||' Dias'
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
    THEN 'O(A) COMPRADOR(A) declara que faz jus a suspensão de PIS e COFINS conforme previsto no item (b), Inciso I, artigo 569 IN RFB nº 2121/22, ou seja, declara que destinará o consumo dessa aquisição, em sua totalidade, na preparação dos tipos utilizados na alimentação de animais vivos classificados nas posições 01.03 e 01.05, classificados no código 23.09.90 da TIPI.'
    END TRIBUTO,

    COALESCE(CLAUSULA.CLAUSULAUM,CLAUSULA_MG.CLAUSULAUM,CLAUSULA_UF.CLAUSULAUM,CLAUSULA_TD.CLAUSULAUM) AS CLAUSULAUM,

    CASE WHEN CONTRATO_U.INSECAOTAXA = 'S' AND CONTRATO_U.TIPOPESSOA = 'EMPRESA' THEN COALESCE(DOISCTRE_FILT.CLAUSULA,DOISCTRE_UNI.CLAUSULA,DOISCTRE.CLAUSULA,DOISCTRERRO.CLAUSULA)
         WHEN CONTRATO_U.INSECAOTAXA = 'N' AND CONTRATO_U.TIPOPESSOA = 'EMPRESA' THEN COALESCE(DOISCTRE_FILT.CLAUSULA,DOISCTRE_UNI.CLAUSULA,DOISCTRE.CLAUSULA,DOISCTRERRO.CLAUSULA)
         WHEN CONTRATO_U.TIPOPESSOA <> 'EMPRESA' THEN COALESCE(DOISCTRE.CLAUSULA,DOISCTRERRO.CLAUSULA)
         END "FORMA ENTREGA",
    

     COALESCE(PGTOCTRE.DESCRICAO,PGTOCTRERRO.DESCRICAO) AS "FORMA DE PGTO",

    COALESCE(GERALCTRE.DESCRICAO,GERALCTRERRO.DESCRICAO) AS "CLAUSULA GERAL",
    CASE WHEN ((contrato_u.statusaprov <> '2 - Aprovado') or (CONTRATO_U.CONTRATO_EDIT = 'S')) THEN 'Contrato Não Aprovado'
    ELSE '' end statusaprov,
    
    COALESCE(CONTRATO_U.VALORADIANTADO,0) AS VALORADIANTADO,
    EXTENSO(COALESCE(CONTRATO_U.VALORADIANTADO,0)) AS DESC_VALORADIANTADO,
    COALESCE(CONTRATO_U.PORCENTAGEMJUROS,0) AS PORCENTAGEMJUROS,
    OS_EXTENSO_PORCENTO(COALESCE(CONTRATO_U.PORCENTAGEMJUROS,0)) AS DESC_PORCENTAGEMJUROS,
    case when contrato.MOEDA = 2 then 'US$ ' else 'R$ ' end TIPOMOEDA,
    case when contrato.moeda = 2 then 'Não obstante o preço do produto tenha sido fixado em dólar norte americano, o pagamento será realizado em moeda corrente nacional, e para tanto, as partes ajustam que a conversão será feita pela taxa média de compra e venda, na modalidade Sistema PTAX, pela cotação do fechamento do dia útil imediatamente anterior ao do pagamento, conforme divulgado pelo SISBACEN.'
    else null end clausula_dolar
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

 LEFT JOIN U_CLAUSULACTR CLAUSULA ON  CLAUSULA.ITEM = CONTRATOITE.ITEM
                                    --AND CLAUSULA.CONTCONF = contratocfg.contconf
                                    AND ',' || CLAUSULA.CONTCONF || ',' LIKE '%,' || TO_CHAR(CONTRATO.CONTCONF) || ',%'
                                    AND CLAUSULA.QUALIDADETR = CONTRATO_U.QTRIGO
                                    AND CLAUSULA.ESTAB = CONTRATO.ESTAB
                                    AND CLAUSULA.UF = CIDFIL.UF
                                    
                                    
  LEFT JOIN U_CLAUSULACTR CLAUSULA_MG ON  CLAUSULA_MG.ITEM = CONTRATOITE.ITEM
                                    --AND CLAUSULA_MG.CONTCONF = contratocfg.contconf
                                    AND ',' || CLAUSULA_MG.CONTCONF || ',' LIKE '%,' || TO_CHAR(CONTRATO.CONTCONF) || ',%'
                                    AND CLAUSULA_MG.QUALIDADETR = CONTRATO_U.QTRIGO
                                    AND CLAUSULA_MG.ESTAB = 1
                                    AND CLAUSULA_MG.UF  = 'MG'                                        


  LEFT JOIN U_CLAUSULACTR CLAUSULA_UF ON  CLAUSULA_UF.ITEM = CONTRATOITE.ITEM
                                    --AND CLAUSULA_UF.CONTCONF = contratocfg.contconf
                                    AND ',' || CLAUSULA_UF.CONTCONF || ',' LIKE '%,' || TO_CHAR(CONTRATO.CONTCONF) || ',%'
                                    AND CLAUSULA_UF.QUALIDADETR = CONTRATO_U.QTRIGO
                                    AND CLAUSULA_UF.ESTAB = CONTRATO.ESTAB
                                    AND CLAUSULA_UF.UF IS NULL     
                                    
   LEFT JOIN U_CLAUSULACTR CLAUSULA_TD ON  CLAUSULA_TD.ITEM = CONTRATOITE.ITEM
                                    --AND CLAUSULA_TD.CONTCONF = contratocfg.contconf
                                    AND ',' || CLAUSULA_TD.CONTCONF || ',' LIKE '%,' || TO_CHAR(CONTRATO.CONTCONF) || ',%'
                                    AND CLAUSULA_TD.QUALIDADETR = CONTRATO_U.QTRIGO

     left JOIN U_CLAUSULADOISCTR DOISCTRE_FILT ON
    DOISCTRE_FILT.TIPO      = CONTRATO_U.TIPOENTREGA AND
    DOISCTRE_FILT.TIPOFRETE = CONTRATO_U.TIPOFRETES AND
    DOISCTRE_FILT.ARMAZEM   = CONTRATO_U.TIPOPESSOA AND
    DOISCTRE_FILT.ITEM      = CONTRATOITE.ITEM   AND
    DOISCTRE_FILT.ESTAB     = CONTRATO.ESTAB AND
    DOISCTRE_FILT.TABELADIF = COALESCE(CONTRATO_U.INSECAOTAXA,'N') AND
    ',' || DOISCTRE_FILT.CONFCONT || ',' LIKE '%,' || TO_CHAR(CONTRATO.CONTCONF) || ',%'
   
   left JOIN U_CLAUSULADOISCTR DOISCTRE_UNI ON
    DOISCTRE_UNI.TIPO      = CONTRATO_U.TIPOENTREGA AND
    DOISCTRE_UNI.TIPOFRETE = CONTRATO_U.TIPOFRETES AND
    DOISCTRE_UNI.ARMAZEM   = CONTRATO_U.TIPOPESSOA AND
    DOISCTRE_UNI.ITEM      = CONTRATOITE.ITEM   AND
    DOISCTRE_UNI.ESTAB     = 1 AND
    DOISCTRE_UNI.TABELADIF = COALESCE(CONTRATO_U.INSECAOTAXA,'N') AND 
    ',' || DOISCTRE_UNI.CONFCONT || ',' LIKE '%,' || TO_CHAR(CONTRATO.CONTCONF) || ',%'
    
     left JOIN U_CLAUSULADOISCTR DOISCTRE ON
    DOISCTRE.TIPO      = CONTRATO_U.TIPOENTREGA AND
    DOISCTRE.TIPOFRETE = CONTRATO_U.TIPOFRETES AND
    DOISCTRE.ARMAZEM   = CONTRATO_U.TIPOPESSOA AND
    DOISCTRE.ITEM IS NULL AND
    DOISCTRE.ESTAB IS NULL AND
    DOISCTRE.TABELADIF = 'N' AND 
    ',' || DOISCTRE.CONFCONT || ',' LIKE '%,' || TO_CHAR(CONTRATO.CONTCONF) || ',%'
   
    
    left JOIN U_CLAUSULADOISCTR DOISCTRERRO ON
    DOISCTRERRO.u_clausuladoisctr_id = 999
    

    left JOIN U_CLAUSULAPGTOCTR PGTOCTRE ON  PGTOCTRE.TIPOPGTO  = CONTRATO_U.TIPOPGTO
                              AND 
                              ',' || PGTOCTRE.CONFCONT || ',' LIKE '%,' || TO_CHAR(CONTRATO.CONTCONF) || ',%'

   left JOIN U_CLAUSULAPGTOCTR PGTOCTRERRO ON PGTOCTRERRO.U_CLAUSULAPGTOCTR_ID IN (999)

     LEFT JOIN U_CLAUSULAGERALCTR GERALCTRE ON ',' || GERALCTRE.CONFCONT || ',' LIKE '%,' || TO_CHAR(CONTRATO.CONTCONF) || ',%'

      LEFT JOIN U_CLAUSULAGERALCTR GERALCTRERRO ON GERALCTRERRO.U_CLAUSULAGERALCTR_ID = 999

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
                                AND ((CONTRATO_U.TIPOPGTO ='ANTECIPADO') OR (CONTRATO_U.TIPOPGTO IN ('APRAZO','APRAZOCTR','APRAZOAMOSTRA','APRAZOEMBARQUE','APRAZODESCARGA')))
                                
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