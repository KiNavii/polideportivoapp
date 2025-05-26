# Configuración de Eventos en Supabase

Para que la sección de eventos funcione correctamente, necesitas crear las tablas necesarias en tu base de datos Supabase. Sigue estos pasos:

## Paso 1: Acceder a la consola SQL de Supabase

1. Ve a [https://app.supabase.io/](https://app.supabase.io/) y accede a tu proyecto
2. En el menú lateral, selecciona **SQL Editor**
3. Crea un nuevo query

## Paso 2: Ejecutar el script SQL

Copia y pega el siguiente script SQL en el editor y ejecútalo:

```sql
-- Crear la tabla de eventos si no existe
CREATE TABLE IF NOT EXISTS "eventos" (
  "id" uuid DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
  "titulo" text NOT NULL,
  "descripcion" text NOT NULL,
  "fecha_evento" timestamp with time zone NOT NULL,
  "fecha_fin_evento" timestamp with time zone,
  "lugar" text NOT NULL,
  "imagen_url" text,
  "autor_id" uuid NOT NULL REFERENCES auth.users(id),
  "destacado" boolean DEFAULT false,
  "fecha_creacion" timestamp with time zone DEFAULT now() NOT NULL,
  "capacidad_maxima" integer,
  "participantes_actuales" integer DEFAULT 0,
  "requiere_inscripcion" boolean DEFAULT false,
  "estado" text DEFAULT 'programado'
);

-- Crear la tabla de inscripciones a eventos
CREATE TABLE IF NOT EXISTS "inscripciones_eventos" (
  "id" uuid DEFAULT extensions.uuid_generate_v4() PRIMARY KEY,
  "evento_id" uuid NOT NULL REFERENCES eventos(id) ON DELETE CASCADE,
  "usuario_id" uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  "fecha_inscripcion" timestamp with time zone DEFAULT now() NOT NULL,
  UNIQUE ("evento_id", "usuario_id")
);

-- Configurar seguridad
ALTER TABLE "eventos" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "inscripciones_eventos" ENABLE ROW LEVEL SECURITY;

-- Política para leer eventos (todos pueden ver)
CREATE POLICY "Eventos visibles para todos" ON "eventos"
  FOR SELECT USING (true);

-- Política para crear eventos (solo autenticados)
CREATE POLICY "Solo usuarios autenticados pueden crear eventos" ON "eventos"
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Política para actualizar eventos (solo el autor)
CREATE POLICY "Solo el autor puede actualizar eventos" ON "eventos"
  FOR UPDATE USING (auth.uid() = autor_id);

-- Política para eliminar eventos (solo el autor)
CREATE POLICY "Solo el autor puede eliminar eventos" ON "eventos"
  FOR DELETE USING (auth.uid() = autor_id);

-- Política para ver inscripciones
CREATE POLICY "Usuarios pueden ver sus propias inscripciones" ON "inscripciones_eventos"
  FOR SELECT USING (auth.uid() = usuario_id);

-- Política para crear inscripciones
CREATE POLICY "Usuarios pueden inscribirse a eventos" ON "inscripciones_eventos"
  FOR INSERT WITH CHECK (auth.uid() = usuario_id);

-- Política para eliminar inscripciones
CREATE POLICY "Usuarios pueden cancelar sus inscripciones" ON "inscripciones_eventos"
  FOR DELETE USING (auth.uid() = usuario_id);
```

## Paso 3: Agregar datos de ejemplo (opcional)

Para agregar algunos eventos de ejemplo, ejecuta el siguiente script SQL:

```sql
-- Insertar evento 1
INSERT INTO "eventos" (
  "titulo",
  "descripcion",
  "fecha_evento",
  "fecha_fin_evento",
  "lugar",
  "autor_id",
  "destacado",
  "imagen_url",
  "capacidad_maxima",
  "requiere_inscripcion"
) VALUES (
  'Torneo de Fútbol Sala',
  'Gran torneo de fútbol sala con equipos de todas las categorías. ¡Inscribe a tu equipo y participa por grandes premios!',
  (NOW() + INTERVAL '10 days')::timestamp,
  (NOW() + INTERVAL '12 days')::timestamp,
  'Pista Polideportiva Central',
  (SELECT id FROM auth.users LIMIT 1),
  true,
  'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?q=80&w=1000',
  50,
  true
);

-- Insertar evento 2
INSERT INTO "eventos" (
  "titulo",
  "descripcion",
  "fecha_evento",
  "lugar",
  "autor_id",
  "destacado",
  "imagen_url",
  "requiere_inscripcion"
) VALUES (
  'Masterclass de Yoga',
  'Clase especial de yoga impartida por el reconocido instructor internacional Marc Johnson. Abierto a todos los niveles.',
  (NOW() + INTERVAL '5 days')::timestamp,
  'Sala de Actividades Dirigidas 2',
  (SELECT id FROM auth.users LIMIT 1),
  false,
  'https://images.unsplash.com/photo-1575052814086-f385e2e2ad1b?q=80&w=1000',
  true
);

-- Insertar evento 3
INSERT INTO "eventos" (
  "titulo",
  "descripcion",
  "fecha_evento",
  "fecha_fin_evento",
  "lugar",
  "autor_id",
  "destacado",
  "imagen_url",
  "capacidad_maxima",
  "requiere_inscripcion"
) VALUES (
  'Exhibición de Natación Sincronizada',
  'El equipo olímpico realizará una exhibición especial en nuestras instalaciones. No te pierdas este espectáculo único.',
  (NOW() + INTERVAL '15 days')::timestamp,
  (NOW() + INTERVAL '15 days')::timestamp,
  'Piscina Olímpica',
  (SELECT id FROM auth.users LIMIT 1),
  true,
  'https://images.unsplash.com/photo-1519315901367-f34ff9154487?q=80&w=1000',
  200,
  false
);
```

> **Nota:** Este script utiliza `(SELECT id FROM auth.users LIMIT 1)` para seleccionar automáticamente un ID de usuario existente. Si no tienes usuarios en tu sistema, primero debes crear al menos un usuario antes de ejecutar este script.

## Paso 4: Verificar la configuración

Para verificar que todo está configurado correctamente:

1. Ve a **Table Editor** en Supabase
2. Deberías ver las tablas `eventos` e `inscripciones_eventos`
3. Verifica que los datos de ejemplo se hayan insertado correctamente en la tabla `eventos`

## Paso 5: Probar la aplicación

Ahora, cuando ejecutes la aplicación, deberías ver la sección de "Próximos eventos" en la pantalla de inicio con los eventos que acabas de añadir.
