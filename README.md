# Café de turno

Microapp HTML para Juan Pablo, Moises, Jesus, Alejandro y Daniel. Café a precio fijo de **0,50 €**.

- Acceso individual mediante contraseña.
- Cuentas compartidas entre móviles con Supabase Auth y PostgreSQL.
- Registro de cafés, pagos y compras de café, leche y azúcar.
- Saldo a favor cuando una aportación supera la deuda.
- Historial con anulación de movimientos propios.
- Exportación de movimientos en JSON.
- Diseño adaptable al móvil y cierre por inactividad.

## Estado

Código preparado. **La versión compartida requiere configurar Supabase y activar GitHub Pages.** Hasta entonces no registra movimientos. Sigue [CONFIGURACION.md](CONFIGURACION.md).

`index.html` es la app compartida; `config.js` contiene solo los parámetros públicos de conexión; `supabase.sql` define las tablas y permisos. `demo.html` permite probar una versión local que no sincroniza las cuentas.

No hay contraseñas ni claves privadas en este repositorio. No se han creado usuarios ni probado operaciones contra una base de datos real. Se ha comprobado la sintaxis JavaScript; las pruebas de aceptación de la instalación están descritas en la guía.
