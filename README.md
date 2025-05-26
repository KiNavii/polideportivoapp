# Aplicación Polideportivo

Aplicación móvil para la gestión de un polideportivo, desarrollada con Flutter y Supabase.

## Características

- Sistema de autenticación completo (registro, inicio de sesión)
- Perfil de usuario editable
- Vista de actividades deportivas
- Sistema de reservas de instalaciones
- Dashboard personalizado

## Requisitos previos

- Flutter SDK 3.7.0 o superior
- Cuenta de Supabase
- Editor de código (VS Code, Android Studio, etc.)

## Configuración

1. Clona este repositorio:

   ```
   git clone <URL_DEL_REPOSITORIO>
   cd deportivov1
   ```

2. Instala las dependencias:

   ```
   flutter pub get
   ```

3. Configura Supabase:

   - Abre el archivo `lib/constants/supabase_constants.dart`
   - Reemplaza `tu-clave-anonima-aqui` con tu clave anónima real de Supabase
   - La clave anónima se puede obtener en el dashboard de Supabase > Configuración del Proyecto > API

4. Asegúrate de tener configurada correctamente la base de datos en Supabase:
   - Tablas necesarias: usuarios, actividades, instalaciones, reservas, etc.
   - Políticas de RLS para controlar el acceso a los datos

## Ejecución

Para ejecutar la aplicación en modo de desarrollo:

```
flutter run
```

## Estructura del proyecto

- `lib/constants`: Constantes y configuraciones
- `lib/models`: Modelos de datos
- `lib/screens`: Pantallas de la aplicación
- `lib/services`: Servicios para interactuar con APIs
- `lib/utils`: Utilidades y helpers
- `lib/widgets`: Widgets reutilizables

## Tecnologías utilizadas

- Flutter
- Supabase (autenticación y base de datos)
- Provider (gestión de estado)
- Intl (internacionalización y formato)

## Contribución

Para contribuir a este proyecto:

1. Fork el repositorio
2. Crea una nueva rama (`git checkout -b feature/nueva-funcionalidad`)
3. Realiza tus cambios y haz commit (`git commit -m 'Añade nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Abre un Pull Request

## Licencia

Este proyecto está licenciado bajo la Licencia MIT - ver el archivo LICENSE para más detalles.
