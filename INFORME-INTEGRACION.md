# Informe de integración: backend Spring Boot y frontend Flutter

## Resumen

Se conectó la pantalla de empleados con `GET /api/employees`. El backend ahora consulta el repositorio JPA y responde con empleados guardados en H2; Flutter interpreta los objetos JSON y muestra carga, errores con opción de reintento y el estado vacío.

## Problemas encontrados

| Problema | Efecto | Corrección |
|---|---|---|
| El repositorio declaraba `existsBynombreAndapellido`, pero la entidad tiene el campo `name`, no `nombre`. | Spring Data no podía derivar esa consulta al iniciar la aplicación. | Se retiraron los métodos derivados innecesarios; se conserva `JpaRepository`. |
| El controlador respondía una lista fija de nombres y no usaba el repositorio. | La pantalla no mostraba los datos almacenados en la base de datos. | Se conectó el controlador al servicio y este a `EmployeeRepository`. |
| Flutter usaba `10.0.2.2`, dirección válida para el emulador Android, incluso al ejecutar en web/escritorio. | La URL no apuntaba al backend desde esas plataformas; en un teléfono físico tampoco apunta al equipo anfitrión. | Se usa `localhost` en web/escritorio y `10.0.2.2` en Android. Se puede reemplazar con `API_BASE_URL`. |
| El permiso `INTERNET` solo estaba en los manifiestos debug/profile. Además, el backend local usa HTTP. | El build Android release no tenía permiso de red; HTTP sin cifrar puede bloquearse en Android. | Se añadió el permiso al manifiesto principal y se habilitó HTTP solo en debug/profile. |
| El frontend no tenía una estructura tipada para la respuesta ni una vista útil ante fallos o una lista vacía. | Los errores de red quedaban solo en consola y la respuesta JSON no coincidía con la estructura del backend. | Se agregó el modelo `Employee`, validación de JSON, mensajes visibles y reintento. |
| La prueba Flutter existente comprobaba un contador que no existe en esta aplicación. | La prueba no correspondía a la pantalla actual. | Se sustituyó por una prueba de la pantalla de empleados. |

## Contrato de la API

`GET http://localhost:8080/api/employees` devuelve HTTP 200 y una lista JSON con objetos como:

```json
[
  {
    "id": 1,
    "name": "Ana",
    "apellido": "Pérez"
  }
]
```

La base de datos configurada es H2 en memoria. Por eso, al iniciar desde cero, la respuesta actual es `[]`; no hay registros de ejemplo ni se implementó una operación para crearlos desde la pantalla.

## Cómo ejecutar

1. Inicia el backend desde `Backend-SpringBot\employee-database`:

   ```powershell
   .\mvnw.cmd spring-boot:run
   ```

2. Desde `Frontend-Flutter\flutter_application_1`, inicia Flutter:

   ```powershell
   flutter run -d chrome
   ```

   Chrome, Windows y los simuladores iOS usan `http://localhost:8080`. El emulador Android usa `http://10.0.2.2:8080`.

3. Para un teléfono físico, usa la IP local del equipo que ejecuta Spring Boot y deja que Flutter acceda a ella:

   ```powershell
   flutter run --dart-define=API_BASE_URL=http://<IP-DEL-EQUIPO>:8080
   ```

   El teléfono y el equipo deben estar en la misma red, y el firewall debe permitir el puerto 8080. Para producción, configura HTTPS y una URL accesible desde el dispositivo.

## Verificación realizada

- `.\mvnw.cmd test`: correcto; 1 prueba ejecutada, sin fallos.
- `flutter analyze`: sin problemas.
- `flutter test`: prueba de la pantalla aprobada.
- Petición HTTP local a `GET /api/employees`: HTTP 200 y `[]`.
- Ejecución en Chrome: la pantalla recibió la respuesta y mostró “No hay empleados registrados.”
- Hot reload de Flutter: terminó y la pantalla siguió mostrando la respuesta; el runtime web también registró `Trying to render a disposed EngineFlutterView` durante el reload. No aparece en `flutter analyze` ni en `flutter test`; conviene revisar si se repite al ejecutar normalmente, fuera del ciclo de recarga.

## Archivos principales

- [Controlador de empleados](Backend-SpringBot/employee-database/src/main/java/com/example/employee_database/controller/EmployeeConytoller.java)
- [Servicio de empleados](Backend-SpringBot/employee-database/src/main/java/com/example/employee_database/service/EmployeeService.java)
- [Repositorio](Backend-SpringBot/employee-database/src/main/java/com/example/employee_database/repository/EmployeeRepository.java)
- [Pantalla Flutter](Frontend-Flutter/flutter_application_1/lib/ejemplo_screen.dart)
