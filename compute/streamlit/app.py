# app.py
import os
import streamlit as st
import boto3
from boto3.dynamodb.conditions import Key, Attr
import pandas as pd
import plotly.express as px
from datetime import datetime, timedelta, date
from botocore.exceptions import ClientError

st.set_page_config(layout="wide", page_title="DynamoDB Launches Dashboard")

# ---------- Config ----------
DYNAMODB_TABLE = os.environ.get("DYNAMODB_TABLE_NAME") #
AWS_REGION = os.environ.get("AWS_REGION")

# Nombres de índices que vamos a intentar (prioridad)
POSSIBLE_GSIS = ["launch_date-index", "launch_date-gsi", "LaunchDateIndex"]

# Campos que queremos proyectar para reducir I/O en scans
PROJECTION = "id, launch_date, launch_status, launchpad_id, flight_number, launch_date_precision"

# ---------- Utils ----------
# @st.cache_data(ttl=300)
def get_dynamodb_table():
    """
    Crea cliente/resource de boto3. Asume que las credenciales AWS están configuradas
    con variables de entorno, profile, o IAM role si corre en AWS.
    """
    dynamodb = boto3.resource("dynamodb", region_name=AWS_REGION)
    return dynamodb.Table(DYNAMODB_TABLE)


def iso_from_date(d: date, end_of_day: bool = False) -> str:
    """
    Convierte date a ISO8601 UTC string compatible con los valores de launch_date.
    Si end_of_day True pone 23:59:59.999Z para incluir todo el día.
    """
    if end_of_day:
        dt = datetime(d.year, d.month, d.day, 23, 59, 59, 999000)
    else:
        dt = datetime(d.year, d.month, d.day, 0, 0, 0, 0)
    return dt.strftime("%Y-%m-%dT%H:%M:%S.%fZ")[:-4] + "Z"  # corta microsegundos a ms


def try_query_by_gsi(table, start_iso, end_iso):
    """
    Intenta hacer Query sobre un GSI que indexa launch_date (lexicographic ISO strings).
    Retorna lista de items o lanza ClientError si no existe el índice.
    """
    last_e = None
    for idx in POSSIBLE_GSIS:
        try:
            resp = table.query(
                IndexName=idx,
                KeyConditionExpression=Key("launch_date").between(start_iso, end_iso),
                ProjectionExpression=PROJECTION,
            )
            items = resp.get("Items", [])
            # paginación de query
            while "LastEvaluatedKey" in resp:
                resp = table.query(
                    IndexName=idx,
                    KeyConditionExpression=Key("launch_date").between(start_iso, end_iso),
                    ProjectionExpression=PROJECTION,
                    ExclusiveStartKey=resp["LastEvaluatedKey"],
                )
                items.extend(resp.get("Items", []))
            return items
        except ClientError as e:
            # si el error es ResourceNotFoundException para el índice, probamos otro nombre
            code = e.response.get("Error", {}).get("Code", "")
            last_e = e
            if "ValidationException" in code or "ResourceNotFoundException" in code:
                continue
            else:
                raise
    # si no se pudo con ningun índice, re-lanzamos la ultima excepción
    if last_e:
        raise last_e
    return []


def scan_with_filter(table, start_iso, end_iso):
    """
    Fallback: scan paginado con FilterExpression (ineficiente para tablas grandes).
    Usa ProjectionExpression para reducir tamaño.
    """
    fe = Attr("launch_date").between(start_iso, end_iso)
    items = []
    resp = table.scan(
        FilterExpression=fe,
        ProjectionExpression=PROJECTION,
    )
    items.extend(resp.get("Items", []))
    while "LastEvaluatedKey" in resp:
        resp = table.scan(
            FilterExpression=fe,
            ProjectionExpression=PROJECTION,
            ExclusiveStartKey=resp["LastEvaluatedKey"],
        )
        items.extend(resp.get("Items", []))
    return items


@st.cache_data(ttl=300)
def fetch_items_by_date_range(start_date: date, end_date: date):
    """
    Devuelve un DataFrame con los items entre las dos fechas (inclusive).
    Intenta usar GSI para Query por rango; si no está, usa Scan (menos óptimo).
    """
    table = get_dynamodb_table()
    start_iso = iso_from_date(start_date, end_of_day=False)
    # Para incluir todo el último día añadimos 23:59:59 al end ISO
    end_iso = iso_from_date(end_date, end_of_day=True)

    # Intento query por GSI
    try:
        items = try_query_by_gsi(table, start_iso, end_iso)
        method = "query_gsi"
    except ClientError:
        # fallback a scan paginado con filtro
        items = scan_with_filter(table, start_iso, end_iso)
        method = "scan_filter"

    # Normalizar a DataFrame
    if not items:
        return pd.DataFrame(), method

    df = pd.DataFrame(items)
    # Asegura columnas mínimas
    for c in ["launch_date", "launch_status", "launchpad_id", "id"]:
        if c not in df.columns:
            df[c] = None

    # Parseo launch_date (algunas filas pueden tener None)
    def parse_iso_safe(v):
        try:
            # Si ya es datetime, devolver
            if isinstance(v, datetime):
                return v
            return pd.to_datetime(v, utc=True)
        except Exception:
            return pd.NaT

    df["launch_date"] = df["launch_date"].apply(parse_iso_safe)
    # Normaliza estado
    df["launch_status"] = df["launch_status"].astype(str).str.lower().fillna("unknown")
    # arreglar posibles typos
    df["launch_status"] = df["launch_status"].replace({"upcomming": "upcoming"})
    return df, method

# ---------- UI ----------
st.title("🚀 Dashboard de lanzamientos (DynamoDB)")
st.markdown(
    """
    Filtra por rango de fecha (consulta a DynamoDB por rango) y visualiza:
    - barras por mes: exitosos vs fallidos
    - barras por launchpad
    - línea: lanzamientos por fecha
    - pie: % success / upcoming / failed
    """
)

col1, col2 = st.columns([1, 3])
with col1:
    today = date.today()
    default_start = today - timedelta(days=365)
    start = st.date_input("Fecha inicio", default_start)
    end = st.date_input("Fecha fin", today)
    if start > end:
        st.error("La fecha de inicio no puede ser posterior a la fecha fin.")
    btn = st.button("Cargar datos")

with col2:
    st.write("Información de la consulta:")
    st.write(f"Tabla DynamoDB: **{DYNAMODB_TABLE}**")
    st.write("Intento utilizar un GSI `launch_date` para consultas eficientes por rango.")
    st.info("Si tu tabla no tiene un GSI sobre `launch_date`, la app hará un Scan paginado (menos eficiente).")

if btn:
    with st.spinner("Consultando DynamoDB..."):
        df, method = fetch_items_by_date_range(start, end)
    st.success(f"Datos cargados (método: {method}). {len(df)} filas recuperadas.")
    if df.empty:
        st.warning("No hay lanzamientos en el rango seleccionado.")
    else:
        # Pre-procesamiento adicional
        # convertir a timezone naive en UTC para agrupar
        df["date_utc"] = pd.to_datetime(df["launch_date"]).dt.tz_convert("UTC").dt.date
        df["month"] = pd.to_datetime(df["launch_date"]).dt.to_period("M").astype(str)
        # estado: keep only success/upcoming/failed/other
        def map_state(s):
            s = str(s).lower()
            if "success" in s:
                return "success"
            if "fail" in s or "failure" in s or "failed" in s:
                return "failed"
            if "upcoming" in s or "upcomming" in s:
                return "upcoming"
            return s or "unknown"
        df["state_norm"] = df["launch_status"].apply(map_state)

        # ---------- Chart 1: barras por mes (success vs failed)
        st.subheader("1) Lanzamientos por mes — Success vs Failed")
        monthly = (
            df[df["state_norm"].isin(["success", "failed"])]
            .groupby(["month", "state_norm"])
            .size()
            .reset_index(name="count")
        )
        if monthly.empty:
            st.info("No hay datos suficientes de success/failed en el rango.")
        else:
            fig1 = px.bar(
                monthly,
                x="month",
                y="count",
                color="state_norm",
                barmode="group",
                labels={"month": "Mes", "count": "Lanzamientos", "state_norm": "Estado"},
                title="Lanzamientos mensuales: success vs failed",
            )
            st.plotly_chart(fig1, use_container_width=True)

        # ---------- Chart 2: barras por launchpad
        st.subheader("2) Lanzamientos por Launchpad")
        launchpad_counts = df.groupby("launchpad_id").size().reset_index(name="count").sort_values("count", ascending=False)
        if launchpad_counts.empty:
            st.info("No hay launchpad_id en los datos.")
        else:
            fig2 = px.bar(
                launchpad_counts,
                x="launchpad_id",
                y="count",
                labels={"launchpad_id": "Launchpad ID", "count": "Lanzamientos"},
                title="Lanzamientos por Launchpad",
            )
            st.plotly_chart(fig2, use_container_width=True)

        # ---------- Chart 3: línea lanzamientos por fecha
        st.subheader("3) Línea: Número de lanzamientos por fecha")
        daily = df.groupby("date_utc").size().reset_index(name="count").sort_values("date_utc")
        if daily.empty:
            st.info("No hay lanzamientos por fecha para graficar.")
        else:
            # convertir date a datetime para la línea
            daily["date_utc"] = pd.to_datetime(daily["date_utc"])
            fig3 = px.line(
                daily,
                x="date_utc",
                y="count",
                labels={"date_utc": "Fecha (UTC)", "count": "Lanzamientos"},
                title="Lanzamientos por fecha",
                markers=True,
            )
            st.plotly_chart(fig3, use_container_width=True)

        # ---------- Chart 4: pie success/upcoming/failed
        st.subheader("4) Distribución: Success / Upcoming / Failed")
        pie = df["state_norm"].value_counts().reset_index()
        pie.columns = ["state", "count"]
        # filtrar a las 3 categorías principales y agrupar el resto como other
        top_states = ["success", "upcoming", "failed"]
        pie_top = pie[pie["state"].isin(top_states)].copy()
        others = pie[~pie["state"].isin(top_states)]
        if not others.empty:
            pie_top = pie_top.append({"state": "other", "count": int(others["count"].sum())}, ignore_index=True)
        fig4 = px.pie(pie_top, names="state", values="count", title="Porcentaje por estado de lanzamiento")
        st.plotly_chart(fig4, use_container_width=True)

        # Mostrar tabla de muestras y permitir descarga
        st.subheader("Datos (muestra)")
        st.dataframe(df.sample(min(200, len(df))).reset_index(drop=True))
        csv = df.to_csv(index=False)
        st.download_button("Descargar CSV completo", data=csv, file_name="launches_filtered.csv", mime="text/csv")
