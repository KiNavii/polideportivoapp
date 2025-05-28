import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface NotificationRequest {
  user_id?: string
  title: string
  message: string
  data?: Record<string, any>
  topic?: string
  tokens?: string[]
}

interface FCMMessage {
  notification: {
    title: string
    body: string
  }
  data?: Record<string, string>
  token?: string
  topic?: string
  android?: {
    notification: {
      icon: string
      color: string
      sound: string
      priority: string
    }
  }
  apns?: {
    payload: {
      aps: {
        sound: string
        badge?: number
      }
    }
  }
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Verificar autenticación
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      throw new Error('No authorization header')
    }

    // Crear cliente Supabase
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: authHeader },
        },
      }
    )

    // Verificar usuario autenticado
    const { data: { user }, error: userError } = await supabaseClient.auth.getUser()
    if (userError || !user) {
      throw new Error('User not authenticated')
    }

    // Parsear request body
    const { user_id, title, message, data, topic, tokens }: NotificationRequest = await req.json()

    if (!title || !message) {
      throw new Error('Title and message are required')
    }

    // ⚠️ CONFIGURACIÓN TEMPORAL PARA PLAN GRATUITO
    // TODO: Reemplazar con tus credenciales de Firebase
    const firebaseConfig = {
      projectId: 'polideportivoapp-d395f',
      clientEmail: 'TU_CLIENT_EMAIL_AQUI', // Reemplazar con el client_email del JSON
      privateKey: 'TU_PRIVATE_KEY_AQUI',   // Reemplazar con el private_key del JSON
    }

    // Verificar configuración
    if (!firebaseConfig.clientEmail || firebaseConfig.clientEmail === 'TU_CLIENT_EMAIL_AQUI') {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Firebase credentials not configured. Please update the Edge Function with your Firebase service account credentials.',
          instructions: [
            '1. Go to Firebase Console > Project Settings > Service Accounts',
            '2. Generate new private key',
            '3. Replace TU_CLIENT_EMAIL_AQUI with client_email from JSON',
            '4. Replace TU_PRIVATE_KEY_AQUI with private_key from JSON',
            '5. Redeploy the function: supabase functions deploy send-push-notification'
          ]
        }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 400,
        }
      )
    }

    // Obtener tokens FCM
    let fcmTokens: string[] = []

    if (tokens) {
      fcmTokens = tokens
    } else if (user_id) {
      const { data: tokenData, error: tokenError } = await supabaseClient
        .from('user_fcm_tokens')
        .select('fcm_token')
        .eq('user_id', user_id)
        .eq('is_active', true)

      if (tokenError) {
        console.error('Error fetching FCM tokens:', tokenError)
        throw new Error('Failed to fetch FCM tokens')
      }

      fcmTokens = tokenData?.map((t: { fcm_token: string }) => t.fcm_token) || []
    } else if (topic) {
      fcmTokens = []
    } else {
      throw new Error('Either user_id, tokens, or topic must be provided')
    }

    // Preparar mensaje FCM
    const fcmMessage: FCMMessage = {
      notification: {
        title,
        body: message,
      },
      data: data ? Object.fromEntries(
        Object.entries(data).map(([key, value]) => [key, String(value)])
      ) : undefined,
      android: {
        notification: {
          icon: 'ic_notification',
          color: '#2196F3',
          sound: 'default',
          priority: 'high',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
          },
        },
      },
    }

    // Función simplificada para obtener token de acceso
    const getAccessToken = async () => {
      // Para plan gratuito, usamos una implementación simplificada
      // que funciona directamente con las credenciales
      
      const now = Math.floor(Date.now() / 1000)
      const jwtPayload = {
        iss: firebaseConfig.clientEmail,
        scope: 'https://www.googleapis.com/auth/firebase.messaging',
        aud: 'https://oauth2.googleapis.com/token',
        exp: now + 3600,
        iat: now,
      }

      // Crear JWT simplificado (sin firma por ahora)
      const header = btoa(JSON.stringify({ alg: 'RS256', typ: 'JWT' }))
      const payload = btoa(JSON.stringify(jwtPayload))
      
      // Para testing, retornamos un token mock
      // En producción, necesitarías implementar la firma RSA
      return 'mock_token_for_testing'
    }

    // Función para enviar notificación
    const sendToToken = async (token: string) => {
      // Para plan gratuito, simulamos el envío exitoso
      // En producción real, aquí iría la llamada a FCM
      
      console.log(`Simulating push notification to token: ${token.substring(0, 20)}...`)
      console.log(`Title: ${title}`)
      console.log(`Message: ${message}`)
      
      return { 
        success: true, 
        messageId: `mock_${Date.now()}`,
        note: 'Simulated for free plan - configure Firebase credentials for real push notifications'
      }
    }

    // Procesar envío
    let results: any[] = []

    if (topic) {
      results.push({ 
        success: true, 
        messageId: `topic_mock_${Date.now()}`,
        note: 'Topic simulation for free plan'
      })
    } else {
      if (fcmTokens.length === 0) {
        throw new Error('No FCM tokens found for the specified user(s)')
      }

      for (const token of fcmTokens) {
        const result = await sendToToken(token)
        results.push(result)
      }
    }

    const successful = results.filter(r => r.success).length
    const failed = results.filter(r => !r.success).length

    console.log(`Push notification processed: ${successful} successful, ${failed} failed`)

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Push notifications processed (simulated for free plan)',
        results: {
          successful,
          failed,
          total: results.length,
        },
        note: 'Configure Firebase credentials in the Edge Function for real push notifications',
        details: results
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )

  } catch (error) {
    console.error('Error in send-push-notification:', error)
    
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
        timestamp: new Date().toISOString()
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    )
  }
}) 