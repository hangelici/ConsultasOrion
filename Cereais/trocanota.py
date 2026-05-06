import cx_Oracle
import pandas as pd
import psycopg2
from collections import defaultdict
from datetime import datetime,date
import logging
import os
from decimal import Decimal, InvalidOperation

def normaliza_placa(placa):
    if placa is None:
        return None

    placa = placa.strip().upper()
    return placa if placa else None

def parse_data_pg(data_str):
    return datetime.strptime(data_str, "%Y.%m.%d").date()

def parse_data_oracle(data_str):
    return datetime.strptime(data_str, "%Y.%m.%d")

def to_number_br(valor):
    if valor is None:
        return None
    if isinstance(valor, (int, float)):
        return valor
    if isinstance(valor, str):
        valor = valor.replace('.', '').replace(',', '.')
        return float(valor)
    return valor

#### Configuração de LOGS
log_dir = "C:\Integra Troca Nota\logs"
os.makedirs(log_dir, exist_ok=True)
log_path = os.path.join(log_dir, f"execucao_{date.today():%Y%m%d}.log")

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] - %(message)s",
    handlers=[
        logging.FileHandler(log_path, encoding="utf-8"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

#### Configurações
user_fiscal = os.getenv("FISCAL_USER")
password_fiscal = os.getenv("FISCAL_SENHA")
bd_fiscal = os.getenv("FISCAL_BD")
host_fiscal = os.getenv("FISCAL_HOST")
port_fiscal = os.getenv("FISCAL_PORT")

user_bd = os.getenv("USER_API_ORACLE")
password_bd = os.getenv("SENHA_API_ORACLE")
dsn_bd = os.getenv("BD_DSN")

user_app = os.getenv("APP_USER")
password_app = os.getenv("APP_SENHA")
bd_app = os.getenv("APP_DB")
host_app = os.getenv("APP_HOST")
port_app = os.getenv("APP_PORT")

# =========================
# Criar conexão Oracle
# =========================
try:
    cx_Oracle.init_oracle_client(lib_dir=r"C:\instantclient_21_10")
    db_connection = cx_Oracle.connect(
        user=user_bd,
        password=password_bd,
        dsn=dsn_bd
    )
    db_connection.autocommit = False
    cursor_oracle = db_connection.cursor()
    logger.info("Conexão com Oracle estabelecida.")
except Exception as e:
    logger.exception(f"Erro ao conectar ao Oracle: {e}")
    raise SystemExit(1)

# =========================
# Criar conexão Fiscal IO
# =========================
try:
    fiscalio_con = psycopg2.connect(
        host=host_fiscal,
        user=user_fiscal,
        port = port_fiscal,
        password=password_fiscal,
        database=bd_fiscal)
    fiscal_cursor = fiscalio_con.cursor()
    logger.info("Conexão com Fiscal IO estabelecida.")
except Exception as e:
    logger.exception(f"Erro ao conectar ao Fiscal IO: {e}")
    raise SystemExit(1)

# =========================
# Criar conexão APP
# =========================
try:
    os_app = psycopg2.connect(
        host=host_app,
        user=user_app,
        port = port_app,
        password=password_app,
        database=bd_app)
    app_cursor = os_app.cursor()
    logger.info("Conexão com APP estabelecida.")
except Exception as e:
    logger.exception(f"Erro ao conectar ao APP: {e}")
    raise SystemExit(1)

# ------------------- CONSULTAS ORACLE ------------------- #
# Usar essas notas para buscar se existe no Fiscal IO ou não
cursor_oracle.execute("""
    select distinct
    nfcab.chaveacessonfe
    from nfcab
    inner join nfitem on
        nfitem.estab = nfcab.estab
        and nfitem.seqnota = nfcab.seqnota
    inner join u_tempresa u on u.estab = nfcab.estab
    where
    nfitem.cfop in (5906,5907,5117,5116,5101,5102,6101,6102)
    and nfcab.dtemissao between (current_date - 4) and current_date
    and u.GRAOS = 'S'
    and u.OUTROS = 'N'
""")
chaves = [row[0] for row in cursor_oracle.fetchall()]
chaves_oracle = set(chaves)

# Depois de achar as notas que ainda não estão no Sistema, buscamos novamente mas com CFOP diferente
cursor_oracle.execute("""
    select distinct
    nfcab.chaveacessonfe
    from nfcab
    inner join nfitem on
        nfitem.estab = nfcab.estab
        and nfitem.seqnota = nfcab.seqnota
    inner join u_tempresa u on u.estab = nfcab.estab
    where
    nfitem.cfop not in (5906,5907,5117,5116,5101,5102,6101,6102)
    and nfcab.dtemissao between (current_date - 4) and current_date
    and u.GRAOS = 'S'
    and u.OUTROS = 'N'
""")
chaves_filtro = [row[0] for row in cursor_oracle.fetchall()]
chaves_filtro_oracle = set(chaves_filtro)

# Validar NCM no FIscal IO
cursor_oracle.execute("""
    select
    NCM
    FROM NCM                  
""")
chave_ncm = [row[0] for row in cursor_oracle.fetchall()]
lista_ncm = set(chave_ncm)

# Validar se existe a pessoa do Fiscal IO no Agro
cursor_oracle.execute("""
    select
    cnpjf,INSCESTAD,PRODUTOR,0 as SEQENDERECO,numerocm
    from contamov
    where INSCESTAD is not NULL
    union all
    SELECT
    cnpjf,CREDENCIALAGRO AS INSCESTAD,PRODUTOREND AS PRODUTOR,SEQENDERECO,numerocm
    from endereco                
""")
rows_pess = cursor_oracle.fetchall()
pessoa_dict = {
    (str(row[0]).strip(), str(row[1]).strip()): (row[2], row[3])
    for row in rows_pess
}
cnpj_numerocm_dict = {
    str(row[0]).strip(): row[4]
    for row in rows_pess
}

# Buscar ordem de carga
cursor_oracle.execute("""
    SELECT
    f.idcarga,
    f.estab,
    f.localestoque,
    t.placa,
    itemagro.ncm,
    f.PESOLIQUIDO,
    f.DTVALIDADE,
    localest_u.CLASSIFICACAO1
    from ordemcargafrete F
    inner join ordemcargatransp t on t.idcarga = f.idcarga
    inner join itemagro on itemagro.item = f.item
    left join localest_u on localest_u.estab = f.estab and localest_u.local = f.localestoque
    WHERE trunc(f.DTVALIDADE) = trunc(current_date)
    and t.placa is not null              
""")
carga_dict = {}
for row in cursor_oracle.fetchall():
    chave = (
        row[3].strip().upper(),   # placa
        row[4],                  # ncm
        row[6].date()            # DTVALIDADE
    )

    carga_dict[chave] = {
        "idcarga": row[0],
        "localestoque": row[2],
        "peso": int(round(float(row[5]), 2)),
        "classificacao": row[7]
    }

# Buscar apenas Filiais de cereais
cursor_oracle.execute("""
    select 
    filial.cnpj,
    filial.estab                 
    from u_tempresa u
    inner join filial on filial.estab = u.estab
    where
    u.GRAOS = 'S'
    and u.OUTROS = 'N'
""")
cnpjs = {
    str(row[0]).strip(): row[1]
    for row in cursor_oracle.fetchall()
}
chaves_cnpj = set(cnpjs)

# Buscando contratos com saldo
cursor_oracle.execute("""
    WITH CTRNOTA AS (
    SELECT
    CONTRATONFITE.ESTAB,
    CONTRATONFITE.CONTRATO,
    CONTRATONFITE.SEQITEM,
    CASE 
        WHEN (NAT.TIPODCTO IN ('N','X','A','T') and NFCFG.NOTACONF not IN (1041)) AND NATAPARTIRDE.TIPOBAIXA IN ('A','Q') AND NFCAB.NOTACONF NOT IN (291) AND NATAPARTIRDE.OPERACAO NOT IN ('N','R') THEN CONTRATONFITE.QUANTIDADE
        WHEN NAT.TIPODCTO IN ('D') AND NATAPARTIRDE.TIPOBAIXA IN ('A','Q') AND NAT.ENTRADASAIDA = 'E' AND CONTRATOCFG.ENTRADASAIDA = 'E' AND NATAPARTIRDE.OPERACAO NOT IN ('N','R') THEN CONTRATONFITE.QUANTIDADE
        WHEN NAT.TIPODCTO IN ('D') AND NATAPARTIRDE.TIPOBAIXA IN ('A','Q') AND NAT.ENTRADASAIDA = 'S' AND CONTRATOCFG.ENTRADASAIDA = 'S' AND NATAPARTIRDE.OPERACAO NOT IN ('N','R') THEN CONTRATONFITE.QUANTIDADE
        ELSE 0
    END BAIXADO,
    CASE 
        WHEN NAT.TIPODCTO IN ('D') AND NATAPARTIRDE.TIPOBAIXA IN ('A','Q') AND NAT.ENTRADASAIDA = 'E' AND CONTRATOCFG.ENTRADASAIDA = 'E' AND NATAPARTIRDE.OPERACAO NOT IN ('N','R') THEN 0
        WHEN NAT.TIPODCTO IN ('D') AND NATAPARTIRDE.TIPOBAIXA IN ('A','Q') AND NAT.ENTRADASAIDA = 'S' AND CONTRATOCFG.ENTRADASAIDA = 'S' AND NATAPARTIRDE.OPERACAO NOT IN ('N','R') THEN 0
        WHEN (NAT.TIPODCTO = 'D' OR NFCFG.NOTACONF IN (1041)) AND NATAPARTIRDE.TIPOBAIXA IN ('A','Q') AND NATAPARTIRDE.OPERACAO NOT IN ('N','R') THEN CONTRATONFITE.QUANTIDADE
        ELSE 0
    END DEVOLIDO,
    CASE 
        WHEN NAT.TIPODCTO IN ('N','X','A') AND NATAPARTIRDE.TIPOBAIXA IN ('A','Q') AND NFCFG.NOTACONF IN (291) AND NATAPARTIRDE.OPERACAO NOT IN ('N','R') THEN CONTRATONFITE.QUANTIDADE
        ELSE 0
    END CANCELADO,
    CASE 
        WHEN NAT.TIPODCTO IN ('N','X','A') AND NATAPARTIRDE.TIPOBAIXA IN ('A','Q') AND NFCFG.NOTACONF IN (291) AND NATAPARTIRDE.OPERACAO NOT IN ('N','R') THEN CONTRATONFITE.QUANTIDADE
        ELSE 0
    END CANCELADO_CALC
    FROM CONTRATONFITE
    INNER JOIN CONTRATO ON CONTRATO.ESTAB = CONTRATONFITE.ESTAB AND CONTRATO.CONTRATO = CONTRATONFITE.CONTRATO
    INNER JOIN CONTRATOITE ON 
        CONTRATOITE.ESTAB = CONTRATONFITE.ESTAB
        AND CONTRATOITE.CONTRATO = CONTRATONFITE.CONTRATO
        AND CONTRATONFITE.SEQITEM = CONTRATONFITE.SEQITEM
    INNER JOIN NFCAB ON NFCAB.ESTAB = CONTRATONFITE.ESTABNOTA AND NFCAB.SEQNOTA = CONTRATONFITE.SEQNOTA
    INNER JOIN NFCFG ON NFCFG.NOTACONF = NFCAB.NOTACONF
    INNER JOIN NATOPERACAO NAT ON NAT.NATUREZADAOPERACAO = NFCFG.NATUREZADAOPERACAO AND NAT.ENTRADASAIDA = NFCFG.ENTRADASAIDA 
    INNER JOIN CONTRATOCFG ON CONTRATOCFG.CONTCONF = CONTRATO.CONTCONF    
    INNER JOIN CONTRATOCFG_U ON CONTRATOCFG_U.CONTCONF = CONTRATO.CONTCONF
    LEFT JOIN U_TIPOCTR ON U_TIPOCTR.U_TIPOCTR_ID = CONTRATOCFG_U.U_TIPOCTR_ID  
    LEFT JOIN NFCFG_U U ON U.NOTACONF = NFCFG.NOTACONF
    LEFT JOIN U_TIPOOP P ON U.U_TIPOOP_ID = P.U_TIPOOP_ID
    INNER JOIN NATAPARTIRDE ON
        NATAPARTIRDE.NATUREZADAOPERACAO = NAT.NATUREZADAOPERACAO
        AND NATAPARTIRDE.ENTRADASAIDA = NAT.ENTRADASAIDA
        AND NATAPARTIRDE.NATOPERORIGEM = CONTRATOCFG.NATUREZA
        AND NATAPARTIRDE.ENTRADASAIDAORIGEM = CONTRATOCFG.ENTRADASAIDA
    WHERE CONTRATOCFG.ENTRADASAIDA = 'E'
),
BAIXAS AS (
    SELECT
    ESTAB,
    CONTRATO,
    SEQITEM,
    SUM(BAIXADO) AS BAIXADO,
    SUM(DEVOLIDO) AS DEVOLIDO,
    SUM(CANCELADO) AS CANCELADO
    FROM CTRNOTA
    GROUP BY ESTAB, CONTRATO, SEQITEM
),
CANC AS (
    SELECT
    CONTRATOCANC.ESTAB,
    CONTRATOCANC.CONTRATO,
    CONTRATOCANC.SEQITEM,
    SUM(CONTRATOCANC.QUANTIDADE) AS CANC
    FROM CONTRATOCANC
    INNER JOIN CONTRATO ON CONTRATO.ESTAB = CONTRATOCANC.ESTAB AND CONTRATO.CONTRATO = CONTRATOCANC.CONTRATO
    INNER JOIN CONTRATOCFG ON CONTRATOCFG.CONTCONF = CONTRATO.CONTCONF    
    INNER JOIN CONTRATOCFG_U ON CONTRATOCFG_U.CONTCONF = CONTRATO.CONTCONF
    LEFT JOIN U_TIPOCTR ON U_TIPOCTR.U_TIPOCTR_ID = CONTRATOCFG_U.U_TIPOCTR_ID 
    WHERE CONTRATOCFG.ENTRADASAIDA = 'E'--U_TIPOCTR.TIPOCTR IN ('CTR-C')
    GROUP BY CONTRATOCANC.ESTAB, CONTRATOCANC.CONTRATO, CONTRATOCANC.SEQITEM
),
VENCTO AS (
    SELECT
    ESTAB,
    CONTRATO,
    MAX(DTVENCTO) AS DTVENCTO
    FROM CONTRATODTVENCTO C
    GROUP BY ESTAB,CONTRATO
),
SALDO_MANUAL AS (
SELECT 
CONTRATO.ESTAB,
CONTRATO.CONTRATO,
CONTRATO.CONTCONF,
contratoite.QUANTIDADE,
NVL(ENDERECO.CNPJF,CONTAMOV.CNPJF) AS CNPJF,
COALESCE(ENDERECO.CREDENCIALAGRO,CONTAMOV.INSCESTAD,'0') AS INSCESTAD,
NVL(V.DTVENCTO,CONTRATO.DTVENCTO) AS DTVENCTO,
COALESCE(BAIXAS.BAIXADO,0)BAIXADO,
COALESCE(BAIXAS.CANCELADO,0)CANCELADO,
COALESCE(BAIXAS.DEVOLIDO,0)DEVOLIDO,
COALESCE(CANC.CANC,0)CANC,
ARREDONDAR(CONTRATOITE.QUANTIDADE - COALESCE(BAIXAS.BAIXADO,0) - COALESCE(BAIXAS.CANCELADO,0) + COALESCE(BAIXAS.DEVOLIDO,0) - COALESCE(CANC.CANC,0), 0) SALDO,
CONTRATO.NUMEROCM
FROM CONTRATO

INNER JOIN CONTRATOITE ON CONTRATOITE.ESTAB = CONTRATO.ESTAB AND CONTRATOITE.CONTRATO = CONTRATO.CONTRATO
INNER JOIN CONTRATOCFG ON CONTRATOCFG.CONTCONF = CONTRATO.CONTCONF
INNER JOIN CONTRATOCFG_U ON CONTRATOCFG_U.CONTCONF = CONTRATOCFG.CONTCONF
INNER JOIN U_TIPOCTR ON U_TIPOCTR.U_TIPOCTR_ID = CONTRATOCFG_U.U_TIPOCTR_ID
LEFT JOIN BAIXAS ON BAIXAS.ESTAB = CONTRATOITE.ESTAB AND BAIXAS.CONTRATO = CONTRATOITE.CONTRATO AND BAIXAS.SEQITEM = CONTRATOITE.SEQITEM
LEFT JOIN CANC ON CANC.ESTAB = CONTRATOITE.ESTAB AND CANC.CONTRATO = CONTRATOITE.CONTRATO AND CANC.SEQITEM = CONTRATOITE.SEQITEM
INNER JOIN U_TEMPRESA U ON U.ESTAB = CONTRATO.ESTAB
LEFT JOIN VENCTO V ON 
    V.ESTAB = CONTRATO.ESTAB
    AND V.CONTRATO = CONTRATO.CONTRATO
LEFT JOIN ENDERECO ON
    ENDERECO.NUMEROCM = CONTRATO.NUMEROCM
    AND ENDERECO.SEQENDERECO =  CONTRATO.ENDALTERNATIVO
LEFT JOIN CONTAMOV ON CONTAMOV.NUMEROCM = CONTRATO.NUMEROCM
WHERE 
CONTRATOCFG.ENTRADASAIDA = 'E'
AND CONTRATO.ATIVO = 'A'
AND U.GRAOS = 'S'
and U_TIPOCTR.TIPOCTR IN ('CTR-C')
)
SELECT
*
FROM(
SELECT
SALDO_MANUAL.ESTAB,
SALDO_MANUAL.CONTRATO,
SALDO_MANUAL.CNPJF,
SALDO_MANUAL.INSCESTAD,
SALDO_MANUAL.DTVENCTO,
ROW_NUMBER() OVER (
            PARTITION BY SALDO_MANUAL.ESTAB, SALDO_MANUAL.NUMEROCM
            ORDER BY ABS(SALDO_MANUAL.DTVENCTO - TRUNC(SYSDATE))
        ) AS RN,
SALDO_MANUAL.CONTCONF,
SALDO_MANUAL.NUMEROCM
FROM SALDO_MANUAL
WHERE SALDO > 0 
)DADOS
WHERE RN = 1
""")
contrato_dict = {}
for row in cursor_oracle.fetchall():
    estab = row[0]
    contrato = row[1]
    cnpjf = row[2]
    inscestad = row[3]
    contconf = row[6]
    numerocm = row[7]

    chave = (
    str(numerocm).strip() if numerocm is not None else None,
    str(estab).strip() if estab is not None else None
    )
    contrato_dict[chave] = (estab, contrato, contconf)

## Buscando tabela de tipos de operação
cursor_oracle.execute(""" 
    SELECT
        CFOP,CONTCONF,TIPOCLIENTE,NOTACONF,TIPOBAIXA
    FROM U_TIPO_OPERACAO
""")
tipo_op_dict = {}
for row in cursor_oracle.fetchall():
    cfop = str(row[0]).strip()
    contconf= row[1]
    tipocliente = str(row[2]).strip()
    notaconf = row[3]
    tipobaixa = row[4]

    chave = (cfop, contconf, tipocliente)

    tipo_op_dict[chave] = (notaconf, tipobaixa)

# ------------------- CONSULTAS FISCAL IO ------------------- #
fiscal_cursor.execute("""
        select
filial,chave,dtemi,emitid,emitie,
coalesce(trnplaca,placa1,placa2) as trnplaca,
num,ncm,qcom,vprod,cfop,utrib,serie,xprod,cstat
from(
select
d.filial,d.chave,d.dtemi,d.emitid,d.emitie,
case when d.trnplaca = '' then null else d.trnplaca end trnplaca,
d.num,d2.ncm,d2.qcom,d2.vprod,d2.cfop,d2.utrib,d.serie,d2.xprod,d.cstat,
(regexp_match(infadfisco, '[A-Z]{3}[-.\\s]?[0-9][A-Z0-9][0-9]{2}'))[1] AS placa1,
(regexp_match(infcpl,    '[A-Z]{3}[-.\\s]?[0-9][A-Z0-9][0-9]{2}'))[1] AS placa2
from "document" d 
inner join docitem d2 on d2.chave = d.chave
left join filial f on f.cnpj = d.emitid
left join docheadtext d3 on d3.chave = d.chave
where
d2.cfop in ('5906','5907','5117','5116','5101','5102','6101','6102')
and f.cnpj is null
and cast(d.dtemi as date) between (current_date-4) and current_date
)dados
    """)
pg_rows = fiscal_cursor.fetchall()

# Aplicando filtro de filiais de cereais
pg_rows = [
    (cnpjs[str(row[0]).strip()],) + row[1:]
    for row in pg_rows
    if str(row[0]).strip() in cnpjs
]

# Aplicando filtro de notas não inseridas no viasoft
resultado_final = [
    row for row in pg_rows
    if row[1] not in chaves_filtro_oracle
]
# Buscando referencias
fiscal_cursor.execute("""
SELECT
    d3.dockey,
    MAX(d3.refkey) AS refkey,
    max(d4.num) as nota
FROM "document" d 
INNER JOIN docitem d2 
    ON d2.chave = d.chave
LEFT JOIN filial f 
    ON f.cnpj = d.emitid
INNER JOIN doclink d3 
    ON d3.dockey = d.chave
inner join "document" d4 on d4.chave = d3.refkey
WHERE
    d2.cfop IN ('5906','5907','5117','5116','5101','5102','6101','6102')
    AND f.cnpj IS NULL
    AND CAST(d.dtemi AS DATE) BETWEEN (CURRENT_DATE - 4) AND CURRENT_DATE
GROUP BY
    d3.dockey
HAVING COUNT(d3.refkey) = 1
""")
ref_rows = fiscal_cursor.fetchall()
dict_ref = {row[0]: (row[1], row[2]) for row in ref_rows}

# Buscando eventos de hoje
fiscal_cursor.execute(r"""
    select
    e.chave as "CHAVE",
    e.tpevento,
    e.xevento,
    CASE
        WHEN e.hremi !~ '^\d{2}:\d{2}:\d{2}$'
        	THEN d.hremi
        ELSE coalesce(e.hremi,'00:00:00')
     end "HORAEMISSAO",
    e.dtemi as "DTEMISSAO",

    CASE
        WHEN e.hremi !~ '^\d{2}:\d{2}:\d{2}$'
        	THEN e.dtemi || ' ' || coalesce(d.hremi,'00:00:00')
        ELSE e.dtemi || ' ' || coalesce(e.hremi,'00:00:00')
     end "DATAHORA"   

    from "event" e
    inner join "document" d on d.chave = e.chave
    where
    e.dtemi is not null and e.dtemi <> ''
    and cast(e.dtemi as date) = current_date
""")
event_df = fiscal_cursor.fetchall()

dados_convertidos = []
for linha in event_df:
    chave, tpevento, xevento, horaemissao, dtemissao_str, dt_timestamp_str = linha

    # Converter DTEMISSAO (só data)
    if isinstance(dtemissao_str, str):
        dtemissao_str = dtemissao_str.strip()
        try:
            dtemissao = datetime.strptime(dtemissao_str, "%Y.%m.%d").date()
        except ValueError:
            print(f"Data inválida: {dtemissao_str}")
            print(chave)
            continue
    else:
        dtemissao = dtemissao_str

    # Converter DATAHORA (timestamp completo)
    if isinstance(dt_timestamp_str, str):
        dt_timestamp_str = dt_timestamp_str.strip()
        try:
            dt_timestamp = datetime.strptime(dt_timestamp_str, "%Y.%m.%d %H:%M:%S")
        except ValueError:
            print(f"Data inválida: {dt_timestamp_str}")
            print(chave)
            continue
    else:
        dt_timestamp = dt_timestamp_str

    # Montar na ordem correta da tabela Oracle
    nova_linha = (
        chave,  # CHAVE
        dtemissao,  # DTEMISSAO
        horaemissao,  # HORAEMISSAO
        dt_timestamp,  # DATAHORA
        tpevento,  # TPEVENTO
        xevento  # XEVENTO
    )

    dados_convertidos.append(nova_linha)

# ------------------- CONSULTAS APP  ------------------- #
app_cursor.execute("""
    select
    sum(transacao."Quantidade") as "Qtd",
    cast(agendamento."Embarque" as date)  as "Embarque",
    veiculo."Placa"
    from "log_CargaTransacao" transacao
    join "log_CargaDado" agendamento on transacao."CargaDadoId" = agendamento."Id"
    join "log_CargaTran" tran on tran."CargaDadoId" = agendamento."Id"
    join "log_Veiculo" veiculo on veiculo."Id" = tran."VeiculoId"
    where
    cast(agendamento."Embarque" as date) = cast(current_date as date) and transacao."TransacaoTipoId" = 1 and transacao."Cancelada" = false and transacao."Excluido" = false
    group by
    veiculo."Placa",
    cast(agendamento."Embarque" as date) 
""")
os_app_rows = app_cursor.fetchall()
app_dict = {}
for row in os_app_rows:
    qtd = int(round(float(row[0]), 0)) if row[0] is not None else 0
    data = row[1]               # já é date
    placa = normaliza_placa(row[2])

    if placa is not None:
        app_dict[(placa, data)] = qtd

# ------------------- VALIDAÇÕES  ------------------- #
pg_agrupado = defaultdict(int)
pg_agrupado_app = defaultdict(int)

# Agrupando dados do APP e Fiscal IO
for row in resultado_final:
    placa = normaliza_placa(row[5])
    if placa is None:
        continue

    try:
        data = parse_data_pg(row[2])
    except Exception:
        continue

    ncm = row[7]

    try:
        qcom = int(round(float(str(row[8]).replace(',', '.')), 0))
    except (ValueError, TypeError):
        qcom = 0
    
    pg_agrupado[(placa, ncm, data)] += qcom
    pg_agrupado_app[(placa,data)] += qcom
 

resultado_final_otimizado = []
for row in resultado_final:
    # ---------------- NORMALIZAÇÕES ----------------
    placa = normaliza_placa(row[5])
    ncm = row[7]

    try:
        data = parse_data_pg(row[2])
    except Exception:
        data = None

    emitid = str(row[3]).strip() if row[3] is not None else None
    emitie = str(row[4]).strip() if row[4] is not None else None

    cfop = str(row[10]).strip()

    # ---------------- NCM ----------------
    ncm_valid = 'S' if ncm in lista_ncm else 'N'

    # ---------------- PRODUTOR ----------------
    if (emitid, emitie) in pessoa_dict:
        produtor, seqendereco = pessoa_dict[(emitid, emitie)]
    else:
        produtor = 'NAO EXISTE'
        seqendereco = None
    
    # ---------------- CODIGO PESSOA ----------------
    codpess = cnpj_numerocm_dict.get(emitid)

    # ---------------- CONTRATO ----------------
    codpess = str(codpess).strip() if codpess is not None else None

    estab_row = str(row[0]).strip() if row[0] is not None else None
    chave_ctr = (codpess, estab_row)

    estab_contrato, contrato, contconf = contrato_dict.get(
        chave_ctr,
        (None, None, None)
    )
    classestoque = None
    # ---------------- CARGA ----------------
    if placa is None or data is None:
        idcarga = None
        localestoque = None
        dif_peso = None
        dif_pesoapp = None
        classestoque = None
    else:
        chave_carga = (placa, ncm, data)
        chave_app = (placa,data)

        soma_pg = pg_agrupado.get(chave_carga)
        soma_app = pg_agrupado_app.get(chave_app)

        if chave_carga in carga_dict:
            carga = carga_dict[chave_carga]
            idcarga = carga["idcarga"]
            localestoque = carga["localestoque"]
            classestoque = carga["classificacao"]

            dif_peso = (
                soma_pg - carga["peso"]
                if soma_pg is not None
                else None
            )
        else:
            idcarga = None
            localestoque = None
            dif_peso = None
        
        # APP
        if chave_app in app_dict:
            peso_app = app_dict[chave_app]

            dif_pesoapp = (
                soma_app - peso_app
                if soma_app is not None
                else None
            )
        else:
            dif_pesoapp = None

    # ---------------- Config Nota e Tipo de Baixa ---------------- #
    if produtor == 'S':
        tipocliente = 'PRODUTOR'
    elif produtor == 'NAO EXISTE':
        tipocliente = 'NAO EXISTE'
    else:
        tipocliente = 'EMPRESA'

    if contconf is not None:
        chave_tipo = (cfop, contconf, tipocliente)
        if chave_tipo in tipo_op_dict:
            notaconf, tipobaixa = tipo_op_dict[chave_tipo]
        else:
            notaconf, tipobaixa = None, None
    else:
            notaconf, tipobaixa = None, None

    if tipobaixa == 'CONTRATO' and classestoque != 6:
        classestoque = 3
    elif tipobaixa == 'CONTRATO' and classestoque ==6:
        classestoque = 6
    else:
        classestoque = 999
    
    ## Ajuste config p/ filiais (ticket 1153492 acao 19)
    estab = row[0]
    if estab in (30,34,89) and notaconf == 275:
        notaconf = 255
    elif estab in (30,34,89) and notaconf == 284:
        notaconf = 314
    
    # ---------------- Nota referencia ---------------- #
    chave_ref = row[1]
    num_ref = None
    if chave_ref in dict_ref:
        _, num_ref = dict_ref[chave_ref]

    # ---------------- NOVA LINHA ----------------
    resultado_final_otimizado.append(
    row + (
        ncm_valid,
        produtor,
        seqendereco,     
        idcarga,
        localestoque,
        dif_peso,
        dif_pesoapp,
        estab_contrato,
        contrato,
        contconf,
        notaconf,
        tipobaixa,
        num_ref,
        classestoque,
        codpess
    )
)

dados_para_insert = []
for row in resultado_final_otimizado:
    lista = list(row)
    # -------------------------------------------------
    # CONVERTE DATA (posição 2 = DTEMI)
    # -------------------------------------------------
    try:
        lista[2] = parse_data_oracle(lista[2])
    except:
        lista[2] = None
    
    lista[8] = to_number_br(lista[8])   # quantidade
    lista[9] = to_number_br(lista[9])   # valortotal
    lista[0] = to_number_br(lista[0])   # estab

    # -------------------------------------------------
    # CAPTURA CAMPOS FINAIS
    # -------------------------------------------------
    ncm_valid      = lista[-15]
    produtor       = lista[-14]
    seqendereco    = lista[-13]
    idcarga        = lista[-12]
    localestoque   = lista[-11]
    dif_peso       = lista[-10]
    dif_peso_app   = lista[-9]
    estab_contrato = lista[-8]
    contrato       = lista[-7]
    confcont       = lista[-6]
    notaref        = lista[-3]
    classestoque   = lista[-2]

    # -------------------------------------------------
    # STATUS COM PRIORIDADE
    # -------------------------------------------------
    if produtor == 'NAO EXISTE':
        status = 111

    elif idcarga is None:
        status = 112

    #elif dif_peso is None or dif_peso != 0:
    #    status = 113

    elif dif_peso_app is None or dif_peso_app != 0:
        status = 114

    elif estab_contrato is None:
        status = 115

    elif ncm_valid == 'NAO EXISTE':
        status = 116
    
    elif notaref is not None:
        status = 113

    else:
        status = 100  # OK

    # -------------------------------------------------
    # ADICIONA STATUS NO FINAL
    # -------------------------------------------------
    lista.append(status)
    dados_para_insert.append(tuple(lista))

merge_sql = """
MERGE INTO u_fiscal_io_cont t
USING (
    SELECT
        :1  AS estab,
        :2  AS chaveacesso,
        :3  AS dtemissao,
        :4  AS cnpjf,
        :5  AS ieemitente,
        :6  AS placa,
        :7  AS numeronota,
        :8  AS ncm,
        :9  AS quantidade,
        :10 AS valortotal,
        :11 AS cfop,
        :12 AS unidadetributavel,
        :13 AS serie,
        :14 AS item,
        :15 AS STATUS_NOTA,
        :16 AS VALIDANCM,
        :17 AS produtor,
        :18 AS seqendereco,
        :19 AS ordemcarga,
        :20 AS localestoque,
        :21 AS difviasoft,
        :22 AS difapp,
        :23 AS estabcontrato,
        :24 AS contrato,
        :25 AS contconf,
        :26 AS notaconf,
        :27 AS tipobaixa,
        :28 AS notaref,
        :29 AS CLASSIF_LOCAL,
        :30 as numerocm,
        :31 AS status
    FROM dual
) s
ON (
       t.estab         = s.estab
   AND t.chaveacesso   = s.chaveacesso
   AND t.dtemissao     = s.dtemissao
   AND t.cnpjf         = s.cnpjf
   AND t.ieemitente    = s.ieemitente
   AND t.ncm           = s.ncm
   AND t.cfop          = s.cfop
   
)
WHEN MATCHED THEN
    UPDATE SET
        t.valortotal       = s.valortotal,
        t.unidadetributavel= s.unidadetributavel,
        t.serie            = s.serie,
        t.item             = s.item,
        t.numeronota    = s.numeronota,
        t.validancm        = s.validancm,
        t.produtor         = s.produtor,
        t.seqendereco      = s.seqendereco,
        t.ordemcarga       = s.ordemcarga,
        t.localestoque     = s.localestoque,
        t.difviasoft       = s.difviasoft,
        t.difapp           = s.difapp,
        t.estabcontrato    = s.estabcontrato,
        t.contrato         = s.contrato,
        t.contconf         = s.contconf,
        t.notaconf         = s.notaconf,
        t.tipobaixa        = s.tipobaixa,
        t.status           = s.status,
        t.STATUS_NOTA      = s.STATUS_NOTA,
        t.notaref          = s.notaref,
        t.CLASSIF_LOCAL     = s.CLASSIF_LOCAL,
        t.numerocm          = s.numerocm

WHEN NOT MATCHED THEN
    INSERT (
        estab,
        chaveacesso,
        dtemissao,
        cnpjf,
        ieemitente,
        placa,
        numeronota,
        ncm,
        quantidade,
        valortotal,
        cfop,
        unidadetributavel,
        serie,
        item,
        STATUS_NOTA,
        validancm,
        produtor,
        seqendereco,
        ordemcarga,
        localestoque,
        difviasoft,
        difapp,
        estabcontrato,
        contrato,
        contconf,
        notaconf,
        tipobaixa,
        notaref,
        CLASSIF_LOCAL,
        numerocm,
        status
    )
    VALUES (
        s.estab,
        s.chaveacesso,
        s.dtemissao,
        s.cnpjf,
        s.ieemitente,
        s.placa,
        s.numeronota,
        s.ncm,
        s.quantidade,
        s.valortotal,
        s.cfop,
        s.unidadetributavel,
        s.serie,
        s.item,
        s.STATUS_NOTA,
        s.validancm,
        s.produtor,
        s.seqendereco,
        s.ordemcarga,
        s.localestoque,
        s.difviasoft,
        s.difapp,
        s.estabcontrato,
        s.contrato,
        s.contconf,
        s.notaconf,
        s.tipobaixa,
        s.notaref,
        s.CLASSIF_LOCAL,
        s.numerocm,
        s.status
    )
"""

try:
    logger.info('Inserindo dados na tabela U_FISCAL_IO_CONT...')
    cursor_oracle.executemany(merge_sql, dados_para_insert)
    db_connection.commit()
except  Exception as e:
    db_connection.rollback()
    logger.exception(f"Erro ao inserir dados na tabela U_FISCAL_IO_CONT: {e}")
    raise SystemExit(1)

BATCH_SIZE = 1000
delete_sql_eventos = """
DELETE FROM U_NOTASSIEG_EVENTOS
WHERE TRUNC(DTEMISSAO) = TRUNC(SYSDATE)
"""
insert_sql_eventos = """
INSERT INTO U_NOTASSIEG_EVENTOS (
    CHAVE,
    DTEMISSAO,
    HORAEMISSAO,
    DATAHORA,
    TPEVENTO,
    XEVENTO
) VALUES (
    :1, :2, :3, :4, :5, :6
)
"""
total_event = len(dados_convertidos)

try:
    logger.info('Deletando eventos de hoje...')
    cursor_oracle.execute(delete_sql_eventos)

    logger.info('Inserindo novos eventos...')

    for i in range(0, total_event, BATCH_SIZE):
        batch = dados_convertidos[i:i + BATCH_SIZE]

        cursor_oracle.executemany(insert_sql_eventos, batch)

        logger.info(f"Lote {i // BATCH_SIZE + 1} preparado ({len(batch)} registros)")

    db_connection.commit()
    logger.info('Processo concluído com sucesso.')

except Exception as e:
    db_connection.rollback()
    logger.exception(f"Erro no processamento de eventos: {e}")
    raise SystemExit(1)