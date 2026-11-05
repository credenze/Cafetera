# Activar las cuentas compartidas

El código está preparado, pero hasta configurar Supabase no se pueden apuntar cafés. No hay contraseñas predefinidas ni credenciales dentro del repositorio.

## 1. Crear el servicio de datos

Crea un proyecto en https://supabase.com/dashboard. Revisa las condiciones y el plan antes de contratar; este proyecto no necesita funciones de pago específicas. No se ha creado ningún servicio ni suscripción automáticamente.

En Authentication, desactiva el registro de usuarios nuevos (Allow new users to sign up). Solo el administrador dará de alta las cinco cuentas.

En SQL Editor ejecuta el archivo `supabase.sql` una sola vez en el proyecto nuevo.

## 2. Crear las cinco cuentas

En Authentication → Users → Add user → Create new user, crea estas cuentas con contraseñas distintas de al menos 12 caracteres y Auto Confirm User activado. Son identificadores internos, no buzones de correo; no uses invitaciones ni recuperación por email.

| Compañero | Identificador interno |
| --- | --- |
| Juan Pablo | juanpablo@cafetera.example.com |
| Moises | moises@cafetera.example.com |
| Jesus | jesus@cafetera.example.com |
| Alejandro | alejandro@cafetera.example.com |
| Daniel | daniel@cafetera.example.com |

Entrega cada contraseña en privado. No la escribas en GitHub ni en este archivo. Para cambiar una contraseña, el administrador puede hacerlo desde Authentication → Users. La app no ofrece recuperación por correo porque estos identificadores no son buzones reales.

Una vez creadas las cinco cuentas, ejecuta en SQL Editor:

```sql
insert into public.members(id,name)
select u.id, v.name
from auth.users u
join (values
 ('juanpablo@cafetera.example.com','Juan Pablo'),
 ('moises@cafetera.example.com','Moises'),
 ('jesus@cafetera.example.com','Jesus'),
 ('alejandro@cafetera.example.com','Alejandro'),
 ('daniel@cafetera.example.com','Daniel')
) as v(email,name) on lower(u.email)=v.email;
select name from public.members order by name;
```

La última consulta debe mostrar exactamente cinco compañeros. Solo el administrador puede modificar esta vinculación.

## 3. Conectar la app

Copia la Project URL y la clave **publishable** del proyecto, desde su configuración de API. También se admite la antigua clave **anon**. Edita `config.js`:

```js
window.CAFETERA_CONFIG = {
  url: "https://IDENTIFICADOR.supabase.co",
  publishableKey: "CLAVE_PUBLICABLE"
};
```

Estos dos valores son públicos por diseño. **Nunca uses una clave secret ni service_role**: permitiría saltarse los permisos de datos. Las contraseñas y los tokens personales no van en el código.

## 4. Publicar el HTML

En el repositorio GitHub abre Settings → Pages → Build and deployment → Source: Deploy from a branch. Selecciona `main`, carpeta `/ (root)`, y guarda. GitHub mostrará la URL cuando termine.

La página y el código serán públicos, pero las cuentas y movimientos se consultan solamente después de iniciar sesión como uno de los cinco miembros. No pongas información privada en los archivos publicados.

## 5. Comprobación antes de usarlo

- Sin sesión: los importes y el historial deben quedar ocultos.
- Entra como Juan Pablo y apunta un café: deuda 0,50 €.
- Entra como Moises en otro navegador: debe ver ese apunte tras actualizar.
- Moises no debe poder anular el café de Juan Pablo.
- Juan Pablo registra una compra de leche de 1,50 €: saldo 1,00 € a su favor.
- Anula los apuntes de prueba desde su cuenta. Quedarán identificados como anulados.
- Exporta movimientos periódicamente. El JSON no contiene contraseñas. Para recuperación completa utiliza también las herramientas de copia de la base de datos; el JSON exportado no se restaura desde la app.

La app actualiza las cuentas cada 30 segundos mientras la sesión está abierta y permite refrescarlas manualmente. Bloquea la sesión tras 5 minutos sin actividad. No permite apuntes sin conexión: si una petición tarda o falla, actualiza antes de repetir para comprobar si llegó a guardarse.

## Cómo se calculan las cuentas

Deuda = cafés × 0,50 € − pagos a caja − compras. Se admiten saldos a favor. Los pagos representan dinero entregado, las compras representan gastos pagados por el compañero. No registres una misma aportación como pago y como compra, porque se descontaría dos veces.

El neto de caja es pagos menos compras, sin saldo inicial. No sustituye el recuento del dinero físico.

## Alternativa de un solo dispositivo

`demo.html` es una versión independiente con datos solo en el navegador. NO sincroniza con Supabase ni con otros dispositivos y sus contraseñas solo bloquean la interfaz local. No mezcles datos reales entre ambas versiones. Está disponible para probar la experiencia mientras configuras la app principal.
