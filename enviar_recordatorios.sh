#!/bin/bash
# enviar_recordatorios.sh - Script completo para enviar recordatorios de citas - VERSIÓN CORREGIDA

# ============================================================================
# CONFIGURACIÓN
# ============================================================================
SUPABASE_URL="${SUPABASE_URL:-https://nllllvztipbrhryzxamm.supabase.co}"
GMAIL_USER="${GMAIL_USER}"
GMAIL_APP_PASSWORD="${GMAIL_APP_PASSWORD}"
SUPABASE_KEY="${SUPABASE_KEY}"

# ============================================================================
# FUNCIONES AUXILIARES
# ============================================================================

# Función para depurar las respuestas de la API
debug_api_response() {
  local response="$1"
  local endpoint="$2"
  echo "🔍 DEBUG API ($endpoint):"
  echo "   Status: $(echo "$response" | tail -n1)"
  echo "   Body: $(echo "$response" | head -n-1)"
}

# Función para verificar y actualizar la BD con mejor manejo de errores
actualizar_cita_enviada() {
  local cita_id="$1"
  local hora_actual="$2"
  local metodo="$3"
  
  echo "🗃️  Intentando actualizar cita $cita_id..."
  
  # Preparar datos para el PATCH
  local json_data="{\"recordatorio_enviado\": true, \"hora_recordatorio_enviado\": \"${hora_actual}:00\", \"metodo_envio\": \"${metodo}\"}"
  echo "   JSON a enviar: $json_data"
  
  # Enviar solicitud PATCH con más detalles
  local response=$(curl -s -w "\n%{http_code}" \
    -X PATCH "$SUPABASE_URL/rest/v1/citas?id=eq.$cita_id" \
    -H "apikey: $SUPABASE_KEY" \
    -H "Authorization: Bearer $SUPABASE_KEY" \
    -H "Content-Type: application/json" \
    -H "Prefer: return=representation" \
    -d "$json_data")
  
  local http_code=$(echo "$response" | tail -n1)
  local body=$(echo "$response" | head -n-1)
  
  echo "   Código HTTP: $http_code"
  echo "   Respuesta: $body"
  
  if [[ "$http_code" = "200" || "$http_code" = "204" ]]; then
    echo "✅ Base de datos actualizada correctamente para cita $cita_id"
    return 0
  else
    echo "❌ Error al actualizar BD para cita $cita_id"
    echo "   Código: $http_code"
    echo "   Error: $body"
    return 1
  fi
}

# ============================================================================
# FUNCIONES DE TEMPLATE (mantener igual que tu versión)
# ============================================================================

crear_template_html() {
  # ... (mantener tu función igual)
}

crear_template_texto() {
  # ... (mantener tu función igual)
}

# ============================================================================
# FUNCIONES DE ENVÍO
# ============================================================================

enviar_email_gmail() {
  local email="$1"
  local asunto="$2"
  local html="$3"
  local texto="$4"
  local cita_id="$5"
  
  echo "📤 Enviando email a: $email (Cita ID: $cita_id)"
  
  # Guardar templates en archivos temporales
  echo "$html" > /tmp/email_${cita_id}.html
  echo "$texto" > /tmp/email_${cita_id}.txt
  
  # Enviar usando swaks con más logging
  swaks \
    --to "$email" \
    --from "$GMAIL_USER" \
    --h-From: "Waldos Barber-Shop <$GMAIL_USER>" \
    --h-Reply-To: "$GMAIL_USER" \
    --header "Subject: $asunto" \
    --header "X-Priority: 1" \
    --header "Importance: High" \
    --header "X-Cita-ID: $cita_id" \
    --body "$texto" \
    --add-header "MIME-Version: 1.0" \
    --add-header "Content-Type: text/html; charset=UTF-8" \
    --data /tmp/email_${cita_id}.html \
    --server smtp.gmail.com:587 \
    --auth LOGIN \
    --auth-user "$GMAIL_USER" \
    --auth-password "$GMAIL_APP_PASSWORD" \
    --tls \
    --timeout 30 > /tmp/swaks_output_${cita_id}.log 2>&1
  
  local resultado=$?
  
  if [ $resultado -eq 0 ]; then
    echo "✅ Email enviado exitosamente"
    return 0
  else
    echo "❌ Error enviando email"
    cat /tmp/swaks_output_${cita_id}.log
    return 1
  fi
}

obtener_datos_cita() {
  # ... (mantener tu función igual)
}

# ============================================================================
# FUNCIÓN PRINCIPAL - MODIFICADA PARA MEJOR MANEJO DE BD
# ============================================================================

main() {
  echo "🚀 Iniciando envío de recordatorios con Gmail - VERSIÓN CORREGIDA"
  echo "=========================================="
  echo "📅 Fecha: $(TZ='America/Merida' date +'%Y-%m-%d')"
  echo "🕐 Hora: $(TZ='America/Merida' date +'%H:%M')"
  echo ""
  
  # Validar variables de entorno
  if [ -z "$SUPABASE_KEY" ]; then
    echo "❌ ERROR: SUPABASE_KEY no está definida"
    exit 1
  fi
  
  if [ -z "$GMAIL_USER" ] || [ -z "$GMAIL_APP_PASSWORD" ]; then
    echo "❌ ERROR: Credenciales de Gmail no están definidas"
    echo "   GMAIL_USER: ${GMAIL_USER:-No definido}"
    echo "   GMAIL_APP_PASSWORD: ${GMAIL_APP_PASSWORD:+[DEFINIDO]}"
    exit 1
  fi
  
  # Obtener fecha y hora actual
  FECHA_HOY=$(TZ='America/Merida' date +'%Y-%m-%d')
  HORA_ACTUAL=$(TZ='America/Merida' date +'%H:%M')
  HORA_ACTUAL_FULL="${HORA_ACTUAL}:00"
  
  echo "🔍 Buscando citas para hoy: $FECHA_HOY"
  echo "🕐 Hora actual: $HORA_ACTUAL_FULL"
  
  # Obtener citas para hoy - VERIFICAR CONEXIÓN A SUPABASE
  echo "🧪 Probando conexión a Supabase..."
  TEST_RESPONSE=$(curl -s -w "\n%{http_code}" \
    -X GET "$SUPABASE_URL/rest/v1/citas?limit=1" \
    -H "apikey: $SUPABASE_KEY" \
    -H "Authorization: Bearer $SUPABASE_KEY" \
    -H "Content-Type: application/json")
  
  TEST_CODE=$(echo "$TEST_RESPONSE" | tail -n1)
  
  if [[ ! "$TEST_CODE" = "200" && ! "$TEST_CODE" = "201" && ! "$TEST_CODE" = "204" ]]; then
    echo "❌ ERROR: No se pudo conectar a Supabase. Código: $TEST_CODE"
    echo "   Verifica SUPABASE_KEY: ${SUPABASE_KEY:0:10}..."
    exit 1
  fi
  
  echo "✅ Conexión a Supabase exitosa"
  
  # Obtener citas para hoy
  RESPONSE=$(curl -s -w "\n%{http_code}" \
    -X GET "$SUPABASE_URL/rest/v1/citas?fecha=eq.$FECHA_HOY&estado=in.(aceptada,pendiente,confirmada)&or=(recordatorio_enviado.eq.false,recordatorio_enviado.is.null)&select=*" \
    -H "apikey: $SUPABASE_KEY" \
    -H "Authorization: Bearer $SUPABASE_KEY" \
    -H "Content-Type: application/json")
  
  HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
  RESPONSE_BODY=$(echo "$RESPONSE" | head -n-1)
  
  echo "📊 Código de respuesta Supabase: $HTTP_CODE"
  
  if [[ "$HTTP_CODE" != "200" ]]; then
    echo "❌ Error al obtener citas: $HTTP_CODE"
    echo "   Respuesta: $RESPONSE_BODY"
    exit 1
  fi
  
  if [ -z "$RESPONSE_BODY" ] || [ "$RESPONSE_BODY" = "null" ] || [ "$RESPONSE_BODY" = "[]" ]; then
    CANTIDAD_CITAS=0
  else
    CANTIDAD_CITAS=$(echo "$RESPONSE_BODY" | jq '. | length' 2>/dev/null || echo 0)
  fi
  
  echo "📊 Citas encontradas: $CANTIDAD_CITAS"
  
  if [ "$CANTIDAD_CITAS" -eq 0 ]; then
    echo "✅ No hay citas pendientes para hoy"
    exit 0
  fi
  
  # Variables para estadísticas
  TOTAL_ENVIADOS=0
  TOTAL_FALLADOS=0
  TOTAL_SALTADOS=0
  BD_ACTUALIZADAS=0
  BD_FALLIDAS=0
  
  # Procesar cada cita
  echo ""
  echo "📋 Procesando citas..."
  echo "═══════════════════════════════════════════════════════════"
  
  for i in $(seq 0 $(($CANTIDAD_CITAS - 1))); do
    CITA=$(echo "$RESPONSE_BODY" | jq -c ".[$i]")
    
    ID=$(echo "$CITA" | jq -r '.id')
    HORA_CITA=$(echo "$CITA" | jq -r '.hora')
    CLIENTE_ID=$(echo "$CITA" | jq -r '.cliente_id')
    SERVICIO_ID=$(echo "$CITA" | jq -r '.servicio_id')
    BARBERO_ID=$(echo "$CITA" | jq -r '.barbero_id')
    RECORDATORIO_ENVIADO=$(echo "$CITA" | jq -r '.recordatorio_enviado // "false"')
    
    echo ""
    echo "🎯 CITA #$((i + 1))"
    echo "   ID: $ID"
    echo "   Hora: $HORA_CITA"
    echo "   Recordatorio ya enviado? $RECORDATORIO_ENVIADO"
    
    # Verificar si ya se envió recordatorio
    if [ "$RECORDATORIO_ENVIADO" = "true" ]; then
      echo "   ⏭️  Ya enviado, saltando..."
      TOTAL_SALTADOS=$((TOTAL_SALTADOS + 1))
      continue
    fi
    
    # Calcular minutos restantes
    HORA_ACTUAL_MIN=$((10#${HORA_ACTUAL:0:2} * 60 + 10#${HORA_ACTUAL:3:2}))
    HORA_CITA_MIN=$((10#${HORA_CITA:0:2} * 60 + 10#${HORA_CITA:3:2}))
    MINUTOS=$((HORA_CITA_MIN - HORA_ACTUAL_MIN))
    
    echo "   ⏰ Minutos restantes: $MINUTOS"
    
    # Solo enviar si faltan 55-125 minutos
    if [ $MINUTOS -ge 55 ] && [ $MINUTOS -le 125 ]; then
      echo "   ✅ PROCESANDO (en ventana 55-125 minutos)"
      
      # Obtener datos del cliente
      echo "   👤 Obteniendo datos del cliente..."
      CLIENTE_RESPONSE=$(curl -s -w "\n%{http_code}" \
        "$SUPABASE_URL/rest/v1/clientes?id=eq.$CLIENTE_ID&select=nombre,email,telefono" \
        -H "apikey: $SUPABASE_KEY" \
        -H "Authorization: Bearer $SUPABASE_KEY" \
        -H "Content-Type: application/json")
      
      CLIENTE_CODE=$(echo "$CLIENTE_RESPONSE" | tail -n1)
      CLIENTE_DATA=$(echo "$CLIENTE_RESPONSE" | head -n-1 | jq -r '.[0] // empty')
      
      EMAIL_CLIENTE=$(echo "$CLIENTE_DATA" | jq -r '.email // empty')
      NOMBRE_CLIENTE=$(echo "$CLIENTE_DATA" | jq -r '.nombre // "Cliente"')
      
      if [ -z "$EMAIL_CLIENTE" ] || [ "$EMAIL_CLIENTE" = "null" ]; then
        echo "   ❌ No hay email válido, marcando como enviado..."
        
        # Marcar como enviado para no volver a intentar
        if actualizar_cita_enviada "$ID" "$HORA_ACTUAL" "NO_EMAIL"; then
          BD_ACTUALIZADAS=$((BD_ACTUALIZADAS + 1))
        else
          BD_FALLIDAS=$((BD_FALLIDAS + 1))
        fi
        
        TOTAL_FALLADOS=$((TOTAL_FALLADOS + 1))
        continue
      fi
      
      echo "   👤 Cliente: $NOMBRE_CLIENTE"
      echo "   📧 Email: $EMAIL_CLIENTE"
      
      # Formatear fecha bonita
      DIA=$(TZ='America/Merida' date -d "$FECHA_HOY" '+%d')
      MES_NUM=$(TZ='America/Merida' date -d "$FECHA_HOY" '+%m')
      ANIO=$(TZ='America/Merida' date -d "$FECHA_HOY" '+%Y')
      MESES=("Enero" "Febrero" "Marzo" "Abril" "Mayo" "Junio" "Julio" "Agosto" "Septiembre" "Octubre" "Noviembre" "Diciembre")
      MES_INDEX=$((10#$MES_NUM - 1))
      MES=${MESES[$MES_INDEX]}
      FECHA_BONITA="$DIA de $MES de $ANIO"
      
      # Obtener datos adicionales (servicio, barbero, duración)
      DATOS_ADICIONALES=$(obtener_datos_cita "$ID" "$SERVICIO_ID" "$BARBERO_ID")
      SERVICIO_NOMBRE=$(echo "$DATOS_ADICIONALES" | cut -d'|' -f1)
      BARBERO_NOMBRE=$(echo "$DATOS_ADICIONALES" | cut -d'|' -f2)
      DURACION_SERVICIO=$(echo "$DATOS_ADICIONALES" | cut -d'|' -f3)
      
      echo "   ✂️  Servicio: $SERVICIO_NOMBRE"
      echo "   👨‍🎨 Barbero: $BARBERO_NOMBRE"
      echo "   ⏱️  Duración: $DURACION_SERVICIO"
      
      # Crear templates
      ASUNTO="Recordatorio: Tu cita hoy a las $HORA_CITA - Waldos Barber-Shop"
      HTML_CONTENT=$(crear_template_html "$NOMBRE_CLIENTE" "$FECHA_BONITA" "$HORA_CITA" "$MINUTOS" "$ID" "$SERVICIO_NOMBRE" "$BARBERO_NOMBRE" "$DURACION_SERVICIO")
      TEXTO_CONTENT=$(crear_template_texto "$NOMBRE_CLIENTE" "$FECHA_BONITA" "$HORA_CITA" "$MINUTOS" "$ID" "$SERVICIO_NOMBRE" "$BARBERO_NOMBRE" "$DURACION_SERVICIO")
      
      # Enviar email
      if enviar_email_gmail "$EMAIL_CLIENTE" "$ASUNTO" "$HTML_CONTENT" "$TEXTO_CONTENT" "$ID"; then
        echo "   ✅ Email enviado exitosamente"
        TOTAL_ENVIADOS=$((TOTAL_ENVIADOS + 1))
        
        # Actualizar base de datos con función mejorada
        echo "   🗃️  Actualizando base de datos..."
        if actualizar_cita_enviada "$ID" "$HORA_ACTUAL" "GMAIL"; then
          BD_ACTUALIZADAS=$((BD_ACTUALIZADAS + 1))
          echo "   📊 Cita marcada como notificada"
        else
          BD_FALLIDAS=$((BD_FALLIDAS + 1))
          echo "   ⚠️  Email enviado pero BD no actualizada"
        fi
        
      else
        echo "   ❌ Error al enviar email"
        TOTAL_FALLADOS=$((TOTAL_FALLADOS + 1))
        
        # Intentar marcar como fallida en BD
        echo "   🗃️  Marcando como fallido en BD..."
        actualizar_cita_enviada "$ID" "$HORA_ACTUAL" "FALLIDO" || true
      fi
      
    elif [ $MINUTOS -gt 125 ]; then
      echo "   ⏳ Demasiado temprano (+125 minutos)"
      TOTAL_SALTADOS=$((TOTAL_SALTADOS + 1))
    elif [ $MINUTOS -lt 0 ]; then
      echo "   ⏳ Cita ya pasó, marcando como enviado..."
      # Marcar citas pasadas como enviadas para no procesarlas más
      if actualizar_cita_enviada "$ID" "$HORA_ACTUAL" "CITA_PASADA"; then
        BD_ACTUALIZADAS=$((BD_ACTUALIZADAS + 1))
      else
        BD_FALLIDAS=$((BD_FALLIDAS + 1))
      fi
      TOTAL_SALTADOS=$((TOTAL_SALTADOS + 1))
    else
      echo "   ⏳ Fuera de ventana (<55 minutos)"
      TOTAL_SALTADOS=$((TOTAL_SALTADOS + 1))
    fi
    
    echo "   ──────────────────────────────────────────"
    
    # Pequeña pausa para no sobrecargar
    sleep 1
    
  done
  
  # Mostrar resumen detallado
  echo ""
  echo "═══════════════════════════════════════════════════════════"
  echo "📊 RESUMEN FINAL DETALLADO"
  echo "═══════════════════════════════════════════════════════════"
  echo "📧 EMAILS:"
  echo "   ✅ Enviados: $TOTAL_ENVIADOS"
  echo "   ❌ Fallados: $TOTAL_FALLADOS"
  echo "   ⏭️  Saltados: $TOTAL_SALTADOS"
  echo ""
  echo "🗃️  BASE DE DATOS:"
  echo "   ✅ Actualizadas: $BD_ACTUALIZADAS"
  echo "   ❌ Fallidas: $BD_FALLIDAS"
  echo ""
  echo "📊 TOTALES:"
  echo "   📅 Citas procesadas: $CANTIDAD_CITAS"
  echo "   🕐 Hora ejecución: $HORA_ACTUAL_FULL"
  echo "   📅 Fecha: $FECHA_HOY"
  echo "   🔧 Método: Gmail SMTP"
  echo "═══════════════════════════════════════════════════════════"
  
  # Mostrar errores específicos si los hubo
  if [ $BD_FALLIDAS -gt 0 ]; then
    echo ""
    echo "⚠️  ADVERTENCIA: $BD_FALLIDAS actualizaciones de BD fallaron"
    echo "   Verifica los logs anteriores para ver los errores"
  fi
  
  # Limpiar archivos temporales
  rm -f /tmp/email_*.html /tmp/email_*.txt /tmp/swaks_output_*.log 2>/dev/null
  
  if [ $TOTAL_ENVIADOS -gt 0 ] && [ $BD_FALLIDAS -eq 0 ]; then
    echo "✨ Proceso completado exitosamente"
    exit 0
  elif [ $BD_FALLIDAS -gt 0 ]; then
    echo "⚠️  Proceso completado con advertencias"
    exit 0  # Salir con éxito pero con advertencias
  else
    echo "ℹ️  No se enviaron emails, pero el proceso se completó"
    exit 0
  fi
}

# ============================================================================
# EJECUCIÓN
# ============================================================================

# Verificar si swaks está instalado
if ! command -v swaks &> /dev/null; then
  echo "⚠️  Instalando swaks..."
  sudo apt-get update && sudo apt-get install -y swaks jq curl
fi

# Ejecutar función principal
main "$@"