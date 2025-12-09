#!/bin/bash
# enviar_recordatorios.sh - Script completo para enviar recordatorios de citas - VERSIÓN CORREGIDA SIN metodo_envio

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

# Función para verificar y actualizar la BD con mejor manejo de errores
actualizar_cita_enviada() {
  local cita_id="$1"
  local hora_actual="$2"
  
  echo "🗃️  Intentando actualizar cita $cita_id..."
  
  # Preparar datos para el PATCH - SIN metodo_envio (porque no existe en tu BD)
  local json_data="{\"recordatorio_enviado\": true, \"hora_recordatorio_enviado\": \"${hora_actual}:00\"}"
  echo "   JSON a enviar: $json_data"
  
  # Enviar solicitud PATCH con más detalles
  local response=$(curl -s -w "\n%{http_code}" \
    -X PATCH "$SUPABASE_URL/rest/v1/citas?id=eq.$cita_id" \
    -H "apikey: $SUPABASE_KEY" \
    -H "Authorization: Bearer $SUPABASE_KEY" \
    -H "Content-Type: application/json" \
    -H "Prefer: return=minimal" \
    -d "$json_data")
  
  local http_code=$(echo "$response" | tail -n1)
  local body=$(echo "$response" | head -n-1)
  
  echo "   Código HTTP: $http_code"
  
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
# FUNCIONES DE TEMPLATE COMPLETAS (mantener igual)
# ============================================================================

crear_template_html() {
  local nombre="$1"
  local fecha="$2"
  local hora="$3"
  local minutos="$4"
  local id="$5"
  local servicio="$6"
  local barbero="$7"
  local duracion="$8"
  
  # Si no hay servicio, barbero o duración, usar valores por defecto
  local servicio_nombre="${servicio:-Corte de cabello}"
  local barbero_nombre="${barbero:-Nuestro barbero}"
  local duracion_servicio="${duracion:-30 minutos}"
  
  cat <<EOF
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Recordatorio de Cita - Waldos Barber-Shop</title>
    <style>
        body {
            font-family: 'Arial', sans-serif;
            line-height: 1.6;
            color: #333;
            margin: 0;
            padding: 0;
            background-color: #f5f5f5;
        }
        
        .container {
            max-width: 600px;
            margin: 0 auto;
            background-color: white;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
        }
        
        .header {
            background: linear-gradient(135deg, #1a1a1a 0%, #3a3a3a 100%);
            color: white;
            padding: 30px 20px;
            text-align: center;
            position: relative;
            overflow: hidden;
        }
        
        .header h1 {
            margin: 0;
            font-size: 32px;
            letter-spacing: 2px;
        }
        
        .header h2 {
            margin: 10px 0 0;
            font-size: 20px;
            font-weight: normal;
        }
        
        .content {
            padding: 30px;
        }
        
        .saludo {
            font-size: 18px;
            margin-bottom: 20px;
        }
        
        .info-box {
            background: white;
            padding: 20px;
            margin: 20px 0;
            border-left: 4px solid #ff6b35;
            box-shadow: 0 2px 5px rgba(0,0,0,0.05);
        }
        
        .info-box h3 {
            margin-top: 0;
            color: #ff6b35;
        }
        
        .detalle-item {
            margin-bottom: 10px;
            display: flex;
        }
        
        .detalle-label {
            font-weight: bold;
            min-width: 120px;
        }
        
        .urgente {
            background: #fff3cd;
            padding: 15px;
            border-radius: 5px;
            margin: 25px 0;
            border-left: 4px solid #ffc107;
            border: 2px solid #ffc107;
        }
        
        .urgente strong {
            color: #856404;
        }
        
        .direccion {
            background: #e9f7fe;
            padding: 15px;
            border-radius: 5px;
            margin: 20px 0;
            border-left: 4px solid #17a2b8;
        }
        
        .map-link {
            display: inline-block;
            margin-top: 10px;
            padding: 10px 20px;
            background-color: #4285f4;
            color: white;
            text-decoration: none;
            border-radius: 4px;
            font-weight: bold;
        }
        
        .footer {
            background: #1a1a1a;
            color: white;
            padding: 20px;
            text-align: center;
            font-size: 14px;
        }
        
        @media (max-width: 600px) {
            .detalle-item {
                flex-direction: column;
            }
            
            .detalle-label {
                margin-bottom: 5px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Waldos Barber-Shop</h1>
            <h2>Recordatorio de Cita</h2>
        </div>
        
        <div class="content">
            <p class="saludo">Hola ${nombre},</p>
            <p>Este es un recordatorio amigable de tu cita programada para <strong>hoy</strong>.</p>
            
            <div class="info-box">
                <h3>📋 Detalles de tu Cita</h3>
                
                <div class="detalle-item">
                    <span class="detalle-label">Servicio:</span>
                    <span>${servicio_nombre}</span>
                </div>
                
                <div class="detalle-item">
                    <span class="detalle-label">Fecha:</span>
                    <span>${fecha}</span>
                </div>
                
                <div class="detalle-item">
                    <span class="detalle-label">Hora:</span>
                    <span>${hora}</span>
                </div>
                
                <div class="detalle-item">
                    <span class="detalle-label">Barbero:</span>
                    <span>${barbero_nombre}</span>
                </div>
                
                <div class="detalle-item">
                    <span class="detalle-label">Duración:</span>
                    <span>${duracion_servicio}</span>
                </div>
            </div>
            
            <div class="urgente">
                <strong>⏰ ¡TU CITA ES EN ${minutos} MINUTOS!</strong>
            </div>
            
            <div class="direccion">
                <span class="detalle-label">📍 Dirección:</span>
                <span>Calle 24-A, Tzucacab, Yucatán</span>
                <br>
                <a href="https://www.google.com/maps?q=20.063818,-89.0476701" class="map-link" target="_blank">
                  Abrir en Google Maps
                </a>
            </div>
            
            <p style="text-align: center; font-size: 18px; margin-top: 30px;">
                <strong>¡Te esperamos pronto!</strong> 
            </p>
        </div>
        
        <div class="footer">
            <p>© 2025-2026 Waldos Barber Shop. Todos los derechos reservados.</p>
            <p>Este es un correo automático, por favor no respondas a este mensaje.</p>
            <p style="font-size: 12px; opacity: 0.8;">ID de referencia: WB-${id}</p>
        </div>
    </div>
</body>
</html>
EOF
}

crear_template_texto() {
  local nombre="$1"
  local fecha="$2"
  local hora="$3"
  local minutos="$4"
  local id="$5"
  local servicio="$6"
  local barbero="$7"
  local duracion="$8"
  
  local servicio_nombre="${servicio:-Corte de cabello}"
  local barbero_nombre="${barbero:-Nuestro barbero}"
  local duracion_servicio="${duracion:-30 minutos}"
  
  cat <<EOF
RECORDATORIO DE CITA - WALDOS BARBER-SHOP
═══════════════════════════════════════════════════════════

Hola ${nombre},

Este es un recordatorio amigable de tu cita programada para HOY.

📋 DETALLES DE TU CITA:
═══════════════════════════════════════════════════════════
• Servicio: ${servicio_nombre}
• Fecha: ${fecha}
• Hora: ${hora}
• Barbero: ${barbero_nombre}
• Duración: ${duracion_servicio}

⏰ ¡TU CITA ES EN ${minutos} MINUTOS!
═══════════════════════════════════════════════════════════

📍 DIRECCIÓN:
Waldos Barber-Shop
Calle 24-A, Tzucacab, Yucatán

📞 CONTACTO:
Teléfono: 999-123-4567
WhatsApp: 999-987-6543

💡 IMPORTANTE:
• Por favor llega 5-10 minutos antes
• Si llegas tarde, tu cita podría ser acortada
• Para cancelar o reprogramar responde este email

¡Te esperamos pronto!

═══════════════════════════════════════════════════════════
© 2025-2026 Waldos Barber Shop. Todos los derechos reservados.
Este es un correo automático, por favor no respondas a este mensaje.
ID de referencia: WB-${id}
═══════════════════════════════════════════════════════════
EOF
}

# ============================================================================
# FUNCIONES DE ENVÍO COMPLETAS
# ============================================================================

enviar_email_gmail() {
  local email="$1"
  local asunto="$2"
  local html="$3"
  local texto="$4"
  local cita_id="$5"
  
  echo "📤 Enviando email a: $email (Cita ID: $cita_id)"
  
  # Guardar HTML en archivo temporal
  echo "$html" > /tmp/email_${cita_id}.html
  
  # Enviar SOLO HTML, sin multipart
  swaks \
    --to "$email" \
    --from "$GMAIL_USER" \
    --h-From: "Waldos Barber-Shop <$GMAIL_USER>" \
    --h-Reply-To: "$GMAIL_USER" \
    --header "Subject: $asunto" \
    --header "X-Priority: 1" \
    --header "Importance: High" \
    --header "X-Cita-ID: $cita_id" \
    --header "MIME-Version: 1.0" \
    --header "Content-Type: text/html; charset=UTF-8" \
    --body "$html" \
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

# Función para obtener datos adicionales de la cita
obtener_datos_cita() {
  local cita_id="$1"
  local servicio_id="$2"
  local barbero_id="$3"
  
  local servicio_nombre="Corte de cabello"
  local barbero_nombre="Nuestro barbero"
  local duracion="30 minutos"
  
  # Obtener datos del servicio si existe
  if [ -n "$servicio_id" ] && [ "$servicio_id" != "null" ]; then
    local servicio_data=$(curl -s -X GET \
      "$SUPABASE_URL/rest/v1/servicios?id=eq.$servicio_id&select=nombre,duracion" \
      -H "apikey: $SUPABASE_KEY" \
      -H "Authorization: Bearer $SUPABASE_KEY" \
      -H "Content-Type: application/json" | jq -r '.[0] // empty')
    
    if [ -n "$servicio_data" ]; then
      servicio_nombre=$(echo "$servicio_data" | jq -r '.nombre // "Corte de cabello"')
      local duracion_min=$(echo "$servicio_data" | jq -r '.duracion // 30')
      duracion="${duracion_min} minutos"
    fi
  fi
  
  # Obtener datos del barbero si existe
  if [ -n "$barbero_id" ] && [ "$barbero_id" != "null" ]; then
    local barbero_data=$(curl -s -X GET \
      "$SUPABASE_URL/rest/v1/barberos?id=eq.$barbero_id&select=nombre" \
      -H "apikey: $SUPABASE_KEY" \
      -H "Authorization: Bearer $SUPABASE_KEY" \
      -H "Content-Type: application/json" | jq -r '.[0] // empty')
    
    if [ -n "$barbero_data" ]; then
      barbero_nombre=$(echo "$barbero_data" | jq -r '.nombre // "Nuestro barbero"')
    fi
  fi
  
  echo "$servicio_nombre|$barbero_nombre|$duracion"
}

# ============================================================================
# FUNCIÓN PRINCIPAL - CORREGIDA
# ============================================================================

main() {
  echo "🚀 Iniciando envío de recordatorios con Gmail"
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
        if actualizar_cita_enviada "$ID" "$HORA_ACTUAL"; then
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
      
      # Crear templates (CORREGIR typo: FECHA_BONita -> FECHA_BONITA)
      ASUNTO="Recordatorio: Tu cita hoy a las $HORA_CITA - Waldos Barber-Shop"
      HTML_CONTENT=$(crear_template_html "$NOMBRE_CLIENTE" "$FECHA_BONITA" "$HORA_CITA" "$MINUTOS" "$ID" "$SERVICIO_NOMBRE" "$BARBERO_NOMBRE" "$DURACION_SERVICIO")
      TEXTO_CONTENT=$(crear_template_texto "$NOMBRE_CLIENTE" "$FECHA_BONITA" "$HORA_CITA" "$MINUTOS" "$ID" "$SERVICIO_NOMBRE" "$BARBERO_NOMBRE" "$DURACION_SERVICIO")
      
      # Enviar email
      if enviar_email_gmail "$EMAIL_CLIENTE" "$ASUNTO" "$HTML_CONTENT" "$TEXTO_CONTENT" "$ID"; then
        echo "   ✅ Email enviado exitosamente"
        TOTAL_ENVIADOS=$((TOTAL_ENVIADOS + 1))
        
        # Actualizar base de datos con función mejorada
        echo "   🗃️  Actualizando base de datos..."
        if actualizar_cita_enviada "$ID" "$HORA_ACTUAL"; then
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
        actualizar_cita_enviada "$ID" "$HORA_ACTUAL" || true
      fi
      
    elif [ $MINUTOS -gt 125 ]; then
      echo "   ⏳ Demasiado temprano (+125 minutos)"
      TOTAL_SALTADOS=$((TOTAL_SALTADOS + 1))
    elif [ $MINUTOS -lt 0 ]; then
      echo "   ⏳ Cita ya pasó, marcando como enviado..."
      # Marcar citas pasadas como enviadas para no procesarlas más
      if actualizar_cita_enviada "$ID" "$HORA_ACTUAL"; then
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