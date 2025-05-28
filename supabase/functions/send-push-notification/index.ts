// send-push-notification – Edge Function (Deno)  
// Maneja el envío de notificaciones push vía Firebase FCM usando tokens guardados en Supabase.
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
// ───────────────────────────────────────────────────────────
// Utilidades
// ───────────────────────────────────────────────────────────
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type"
};
// ───────────────────────────────────────────────────────────
// Función principal
// ───────────────────────────────────────────────────────────
serve(async (req)=>{
  // CORS pre-flight
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: corsHeaders
    });
  }
  try {
    console.log("🚀 Edge Function iniciada");
    
    // 1️⃣ Autenticación
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) throw new Error("No authorization header");
    
    console.log("✅ Authorization header encontrado");

    // 2️⃣ Supabase client con JWT del usuario
    const supabase = createClient(Deno.env.get("SUPABASE_URL") ?? "", Deno.env.get("SUPABASE_ANON_KEY") ?? "", {
      global: {
        headers: {
          Authorization: authHeader
        }
      }
    });
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) throw new Error("User not authenticated");
    
    console.log(`✅ Usuario autenticado: ${user.email}`);

    // 3️⃣ Parse body
    const { user_id, title, message, data, topic, tokens } = await req.json();
    if (!title || !message) throw new Error("Title and message are required");
    
    console.log(`📝 Mensaje: "${title}" - "${message}"`);

    // 4️⃣ Config Firebase service account desde variables de entorno
    const firebaseProjectId = Deno.env.get("FIREBASE_PROJECT_ID");
    const firebaseClientEmail = Deno.env.get("FIREBASE_CLIENT_EMAIL");
    const firebasePrivateKey = Deno.env.get("FIREBASE_PRIVATE_KEY");
    
    console.log("🔍 Verificando credenciales Firebase:");
    console.log(`- Project ID: ${firebaseProjectId ? '✅ Configurado' : '❌ Faltante'}`);
    console.log(`- Client Email: ${firebaseClientEmail ? '✅ Configurado' : '❌ Faltante'}`);
    console.log(`- Private Key: ${firebasePrivateKey ? '✅ Configurado' : '❌ Faltante'}`);
    
    // Verificar que todas las credenciales estén disponibles
    if (!firebaseProjectId || !firebaseClientEmail || !firebasePrivateKey) {
      console.log("❌ MODO SIMULACIÓN: Credenciales Firebase no configuradas");
      
      // Simular delay de red
      await new Promise((resolve)=>setTimeout(resolve, 1000));
      
      return new Response(JSON.stringify({
        success: true,
        mode: "simulation",
        message: "Notificación simulada - Credenciales Firebase no encontradas",
        debug: {
          projectId: !!firebaseProjectId,
          clientEmail: !!firebaseClientEmail,
          privateKey: !!firebasePrivateKey
        },
        results: {
          successful: 1,
          failed: 0
        }
      }), {
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json"
        }
      });
    }

    console.log("🔥 Todas las credenciales Firebase están disponibles - MODO PRODUCCIÓN");

    // Limpiar y formatear la private key correctamente
    let cleanPrivateKey = firebasePrivateKey;
    
    // Si la key no tiene headers, agregarlos
    if (!cleanPrivateKey.includes('-----BEGIN PRIVATE KEY-----')) {
      cleanPrivateKey = `-----BEGIN PRIVATE KEY-----\n${cleanPrivateKey}\n-----END PRIVATE KEY-----`;
    }
    
    // Reemplazar \n literales con saltos de línea reales
    cleanPrivateKey = cleanPrivateKey.replace(/\\n/g, '\n');
    
    // Asegurar formato correcto
    cleanPrivateKey = cleanPrivateKey
      .replace(/-----BEGIN PRIVATE KEY-----\s*/, '-----BEGIN PRIVATE KEY-----\n')
      .replace(/\s*-----END PRIVATE KEY-----/, '\n-----END PRIVATE KEY-----')
      .replace(/\n\n+/g, '\n'); // Eliminar líneas vacías múltiples

    console.log("🔑 Private key formateada correctamente");

    const firebaseConfig = {
      projectId: firebaseProjectId,
      clientEmail: firebaseClientEmail,
      privateKey: cleanPrivateKey
    };
    // 5️⃣ Obtener tokens FCM
    let fcmTokens = [];
    if (tokens && tokens.length) {
      fcmTokens = tokens;
      console.log(`📱 Usando tokens proporcionados: ${tokens.length}`);
    } else if (user_id) {
      const { data: rows, error } = await supabase.from("user_fcm_tokens").select("fcm_token").eq("user_id", user_id).eq("is_active", true);
      if (error) throw new Error("Failed to fetch FCM tokens");
      fcmTokens = rows?.map((r)=>r.fcm_token) ?? [];
      console.log(`📱 Tokens FCM obtenidos de BD: ${fcmTokens.length}`);
    } else if (!topic) {
      throw new Error("Provide user_id, tokens, or topic");
    }
    // 6️⃣ Construir mensaje base
    const baseMessage = {
      notification: {
        title,
        body: message
      },
      data: data ? Object.fromEntries(Object.entries(data).map(([k, v])=>[
          k,
          String(v)
        ])) : undefined,
      android: {
        priority: "high",
        notification: {
          icon: "ic_notification",
          color: "#2196F3",
          sound: "default",
          channel_id: "default"
        }
      },
      apns: {
        headers: {
          "apns-priority": "10"
        },
        payload: {
          aps: {
            sound: "default",
            badge: 1
          }
        }
      }
    };
    // ───── Helper: JWT → AccessToken ─────
    const getAccessToken = async ()=>{
      console.log("🔑 Generando access token...");
      
      const now = Math.floor(Date.now() / 1000);
      const header = btoa(JSON.stringify({
        alg: "RS256",
        typ: "JWT"
      })).replace(/=+$/, "");
      const payload = btoa(JSON.stringify({
        iss: firebaseConfig.clientEmail,
        scope: "https://www.googleapis.com/auth/firebase.messaging",
        aud: "https://oauth2.googleapis.com/token",
        exp: now + 3600,
        iat: now
      })).replace(/=+$/, "");
      const encoder = new TextEncoder();
      
      try {
        // Convertir PEM a DER (formato binario)
        const pemKey = firebaseConfig.privateKey
          .replace(/-----BEGIN PRIVATE KEY-----/g, '')
          .replace(/-----END PRIVATE KEY-----/g, '')
          .replace(/\s/g, '');
        
        // Decodificar base64 a ArrayBuffer
        const binaryDer = Uint8Array.from(atob(pemKey), c => c.charCodeAt(0));
        
        const key = await crypto.subtle.importKey("pkcs8", binaryDer, {
          name: "RSASSA-PKCS1-v1_5",
          hash: "SHA-256"
        }, false, [
          "sign"
        ]);
        const sigBuffer = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, encoder.encode(`${header}.${payload}`));
        const signature = btoa(String.fromCharCode(...new Uint8Array(sigBuffer))).replace(/=+$/, "").replace(/\+/g, "-").replace(/\//g, "_");
        const jwt = `${header}.${payload}.${signature}`;
        const res = await fetch("https://oauth2.googleapis.com/token", {
          method: "POST",
          headers: {
            "Content-Type": "application/x-www-form-urlencoded"
          },
          body: new URLSearchParams({
            grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
            assertion: jwt
          })
        });
        if (!res.ok) {
          const errorText = await res.text();
          console.error("❌ Error obteniendo access token:", errorText);
          throw new Error(`Failed to get access token: ${errorText}`);
        }
        const json = await res.json();
        console.log("✅ Access token obtenido exitosamente");
        return json.access_token;
      } catch (error) {
        console.error("❌ Error en generación de access token:", error);
        throw error;
      }
    };
    // ───── Helper: envío a token ─────
    const sendToToken = async (token, accessToken)=>{
      console.log(`📤 Enviando a token: ${token.substring(0, 20)}...`);
      
      const resp = await fetch(`https://fcm.googleapis.com/v1/projects/${firebaseConfig.projectId}/messages:send`, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          message: {
            ...baseMessage,
            token
          }
        })
      });
      if (!resp.ok) {
        const errText = await resp.text();
        console.error(`❌ Error enviando a token ${token.substring(0, 20)}...: ${errText}`);
        console.error(`❌ Status HTTP: ${resp.status}`);
        
        // Marcar token inactivo si FCM dice que está desregistrado
        if (resp.status === 404 || 
            resp.status === 410 || 
            errText.includes("UNREGISTERED") || 
            errText.includes("INVALID_REGISTRATION") ||
            errText.includes("NOT_FOUND")) {
          
          console.log(`🗑️ Marcando token como inactivo: ${token.substring(0, 20)}...`);
          await supabase.from("user_fcm_tokens").update({
            is_active: false
          }).eq("fcm_token", token);
          console.log(`✅ Token marcado como inactivo en BD`);
        }
        
        return {
          success: false,
          error: errText,
          status: resp.status,
          token_preview: token.substring(0, 20)
        };
      }
      console.log(`✅ Notificación enviada exitosamente a token: ${token.substring(0, 20)}...`);
      return {
        success: true
      };
    };
    // ───── Helper: envío a topic ─────
    const sendToTopic = async (topicName, accessToken)=>{
      console.log(`📤 Enviando a topic: ${topicName}`);
      
      const resp = await fetch(`https://fcm.googleapis.com/v1/projects/${firebaseConfig.projectId}/messages:send`, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          message: {
            ...baseMessage,
            topic: topicName
          }
        })
      });
      if (!resp.ok) return {
        success: false,
        error: await resp.text()
      };
      console.log(`✅ Notificación enviada exitosamente a topic: ${topicName}`);
      return {
        success: true
      };
    };
    // 7️⃣ Obtener access token y enviar
    const accessToken = await getAccessToken();
    let results = [];
    if (topic) {
      results.push(await sendToTopic(topic, accessToken));
    } else {
      const batchSize = 10;
      for(let i = 0; i < fcmTokens.length; i += batchSize){
        const batch = fcmTokens.slice(i, i + batchSize);
        const batchRes = await Promise.all(batch.map((t)=>sendToToken(t, accessToken)));
        results = results.concat(batchRes);
      }
    }
    const successful = results.filter((r)=>r.success).length;
    const failed = results.length - successful;
    console.log(`🎉 Proceso completado - Exitosas: ${successful}, Fallidas: ${failed}`);
    return new Response(JSON.stringify({
      success: true,
      mode: "production",
      message: "Notificación enviada usando Firebase FCM",
      results: {
        successful,
        failed,
        details: results
      }
    }), {
      headers: {
        ...corsHeaders,
        "Content-Type": "application/json"
      }
    });
  } catch (e) {
    console.error("❌ Edge function error:", e);
    return new Response(JSON.stringify({
      success: false,
      error: e.message,
      stack: e.stack
    }), {
      headers: {
        ...corsHeaders,
        "Content-Type": "application/json"
      },
      status: 400
    });
  }
});
