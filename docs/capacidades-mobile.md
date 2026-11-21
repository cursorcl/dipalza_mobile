# Capacidades del Sistema — Aplicación Móvil

Catálogo de las capacidades disponibles en la aplicación móvil (`dipalza_mobile`), usada por los vendedores en terreno. Para cada una se describe para qué sirve, no cómo se usa paso a paso.

## Cuenta y acceso

### Inicio de sesión
Autenticación del vendedor con usuario y clave. La sesión se mantiene activa renovando el token automáticamente en segundo plano, sin pedirle la clave de nuevo mientras el token de renovación siga válido.

### Configuración inicial de servidor
La primera vez que la app corre en un dispositivo (o después de borrar sus datos), pide indicar a qué servidor conectarse (dirección y puerto). Evita que la app quede apuntando en silencio a un servidor por defecto sin que el vendedor lo note.

### Cambio de clave (normal y obligatorio)
Permite al vendedor cambiar su propia contraseña. En ciertos casos el sistema puede exigir el cambio antes de dejarlo seguir usando la app (p. ej. clave provisoria).

### Clave olvidada
Permite solicitar la recuperación de la clave cuando el vendedor no la recuerda.

## Ventas

### Listado de Ventas
Pantalla principal del vendedor: muestra sus ventas (en curso, cerradas, etc.) y permite iniciar una venta nueva o continuar/modificar una existente.

### Creación y edición de una venta
Armado de una venta: datos del encabezado (cliente, ruta, condición de venta) y las líneas de detalle (producto, cantidad, precio, descuento). Permite agregar, editar o quitar productos antes de cerrar la venta.

### Asignación de piezas numeradas
Para productos que se venden por pieza individual pesada y numerada (p. ej. carne), permite elegir exactamente qué piezas componen la cantidad vendida en una línea de la venta.

### Resumen de Ventas
Muestra los totales y estadísticas de las ventas del vendedor, a modo de vista consolidada en lugar del listado línea por línea.

### Últimas Ventas por Cliente
El vendedor elige un cliente y ve sus ventas más recientes, útil para repetir un pedido anterior o verificar qué precios se usaron la última vez.

### Confirmación de última venta
Vista de sólo lectura de la venta que se acaba de cerrar, a modo de comprobante en pantalla.

## Catálogos

### Catálogo de Productos
Búsqueda y consulta de los productos disponibles, tanto de forma independiente como en modo selección al agregar una línea a una venta.

### Catálogo de Clientes
Búsqueda y consulta de los clientes, tanto de forma independiente como en modo selección al armar una venta.

### Selección de Rutas
Permite al vendedor indicar la ruta o rutas de trabajo asignadas para la jornada.

## Seguimiento y soporte

### Seguimiento GPS en segundo plano
Envía periódicamente (cada 30 segundos) la ubicación del dispositivo al servidor, incluso con la app minimizada, para que el equipo de logística pueda ver el recorrido del vendedor en el mapa de la plataforma web. Si el permiso de ubicación "siempre" queda desactivado, la app lo detecta y avisa al vendedor.

### Configuración / Ajustes
Datos de conexión al servidor, cambio de clave y cierre de sesión, entre otras preferencias de la app.

### Verificación de actualización
Revisa si existe una versión más nueva de la app disponible y lo informa al vendedor.

### Registro de logs local
Consola de logs técnicos guardados en el propio dispositivo (SQLite), pensada para diagnóstico en terreno cuando algo falla y no hay forma rápida de revisar el servidor.
