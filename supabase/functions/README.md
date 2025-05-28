# 🚀 Edge Functions de Supabase

## 📋 Configuración del Entorno de Desarrollo

### Requisitos Previos
- [Deno](https://deno.land/) instalado
- [Supabase CLI](https://supabase.com/docs/guides/cli) instalado
- Extensión de Deno para VS Code (recomendado)

### Configuración de VS Code

1. **Instalar la extensión de Deno:**
   ```
   Nombre: Deno
   ID: denoland.vscode-deno
   ```

2. **Configuración automática:**
   - El archivo `.vscode/settings.json` ya está configurado
   - Deno se habilitará automáticamente para la carpeta `supabase/functions`

### Estructura de Archivos

```
supabase/functions/
├── deno.json                    # Configuración global de Deno
├── send-push-notification/
│   ├── index.ts                 # Función principal
│   ├── deno.json               # Configuración específica
│   └── types.d.ts              # Definiciones de tipos
└── README.md                   # Este archivo
```

## 🔧 Desarrollo Local

### Ejecutar Funciones Localmente

```bash
# Iniciar Supabase localmente
supabase start

# Servir funciones en modo desarrollo
supabase functions serve

# Servir función específica
supabase functions serve send-push-notification --env-file .env.local
```

### Variables de Entorno

Crear archivo `.env.local` en la raíz del proyecto:

```env
FIREBASE_PROJECT_ID=tu-proyecto-firebase
FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@tu-proyecto.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nTU_CLAVE_PRIVADA\n-----END PRIVATE KEY-----"
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=tu-anon-key-local
```

## 🚀 Despliegue

### Desplegar Función

```bash
# Desplegar función específica
supabase functions deploy send-push-notification

# Desplegar todas las funciones
supabase functions deploy
```

### Configurar Variables de Entorno en Producción

```bash
# Configurar variables en Supabase
supabase secrets set FIREBASE_PROJECT_ID=tu-proyecto-firebase
supabase secrets set FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@tu-proyecto.iam.gserviceaccount.com
supabase secrets set FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nTU_CLAVE_PRIVADA\n-----END PRIVATE KEY-----"
```

## 🧪 Pruebas

### Probar Función Localmente

```bash
# Con curl
curl -X POST 'http://localhost:54321/functions/v1/send-push-notification' \
  -H 'Authorization: Bearer TU-JWT-TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "user_id": "uuid-del-usuario",
    "title": "Prueba Local",
    "message": "Mensaje de prueba desde desarrollo local"
  }'
```

### Probar en Producción

```bash
curl -X POST 'https://tu-proyecto.supabase.co/functions/v1/send-push-notification' \
  -H 'Authorization: Bearer TU-JWT-TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "user_id": "uuid-del-usuario",
    "title": "Prueba Producción",
    "message": "Mensaje de prueba desde producción"
  }'
```

## 🔍 Debugging

### Ver Logs

```bash
# Logs en tiempo real
supabase functions logs send-push-notification

# Logs con filtro
supabase functions logs send-push-notification --filter="ERROR"
```

### Debugging en VS Code

1. **Configurar breakpoints** en el código TypeScript
2. **Usar console.log()** para debugging básico
3. **Revisar logs** en la consola de Supabase

## 📚 Recursos Adicionales

- [Documentación de Edge Functions](https://supabase.com/docs/guides/functions)
- [Documentación de Deno](https://deno.land/manual)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)

## ⚠️ Notas Importantes

1. **Tipos de TypeScript:** Los archivos `types.d.ts` proporcionan definiciones para Deno
2. **CORS:** Las funciones incluyen headers CORS para desarrollo web
3. **Autenticación:** Todas las funciones requieren JWT token válido
4. **Rate Limiting:** Considera implementar rate limiting en producción 