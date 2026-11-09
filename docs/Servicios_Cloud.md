# Propuesta de Infraestructura Cloud para el Sistema de Lectura y Monitoreo de Contadores de Agua

## Justificación de AWS

Para el desarrollo del Sistema de Lectura y Monitoreo de Contadores de Agua se evaluaron las plataformas Amazon Web Services (AWS) y Google Cloud Platform (GCP). Se decidió utilizar AWS debido a que ofrece una arquitectura robusta, escalable y preparada para futuras ampliaciones del sistema.

Uno de los factores más importantes en la elección fue la disponibilidad de servicios especializados para Internet de las Cosas (IoT), lo que permitiría en el futuro integrar contadores inteligentes capaces de enviar lecturas automáticamente al sistema. De esta manera, la solución no solo cubre los requerimientos actuales del proyecto, sino que también facilita una evolución tecnológica sin necesidad de rediseñar la arquitectura principal.

Además, AWS proporciona servicios administrados para almacenamiento, bases de datos, autenticación, notificaciones e inteligencia artificial, permitiendo desarrollar una solución moderna con alta disponibilidad y seguridad.

---

# Servicios AWS Propuestos

## Amazon EC2

Amazon EC2 (Elastic Compute Cloud) es un servicio que permite desplegar servidores virtuales en la nube.

En este proyecto se utilizará para alojar el backend de la aplicación, donde se ejecutará la lógica de negocio, el procesamiento de las lecturas, la gestión de usuarios y la comunicación con la base de datos.

### En la práctica

Cuando un trabajador registre una nueva lectura desde la aplicación móvil, la información será enviada al servidor alojado en EC2.

**Ejemplo:**

1. El trabajador toma una fotografía del contador.
2. La aplicación envía la información al servidor.
3. El servidor valida los datos.
4. El servidor almacena la información en la base de datos.
5. El sistema genera la notificación correspondiente.

---

## Amazon RDS (PostgreSQL)

Amazon RDS es un servicio administrado de bases de datos relacionales.

Se utilizará PostgreSQL como motor de base de datos para almacenar toda la información del sistema.

### Información almacenada

- Usuarios
- Residentes
- Administradores
- Condominios
- Lecturas de agua
- Historial de consumo
- Alertas generadas
- Registros de actividad

### En la práctica

Cada vez que se registre una nueva lectura, el sistema almacenará:

- Fecha
- Valor del contador
- Usuario que realizó la lectura
- Fotografía asociada
- Consumo calculado

---

## Amazon S3

Amazon S3 (Simple Storage Service) es un servicio de almacenamiento de objetos.

Su función será almacenar todas las fotografías tomadas durante el proceso de lectura de los contadores.

### Ventajas

- Alta disponibilidad
- Bajo costo
- Escalabilidad prácticamente ilimitada
- Durabilidad extremadamente alta

### En la práctica

Cuando el personal de mantenimiento tome una fotografía del contador:

1. La imagen será enviada a Amazon S3.
2. AWS devolverá una dirección única del archivo.
3. Dicha dirección será almacenada en la base de datos.
4. Los administradores podrán consultar la evidencia fotográfica en cualquier momento.

Esto proporciona trazabilidad y respaldo ante posibles reclamos sobre una lectura registrada.

---

## Amazon Cognito

Amazon Cognito es un servicio de autenticación y administración de usuarios.

Se utilizará para gestionar el acceso seguro al sistema.

### Funciones

- Inicio de sesión
- Recuperación de contraseña
- Administración de perfiles
- Control de acceso según el rol

### Roles del sistema

- Administrador
- Personal de mantenimiento
- Residente

### En la práctica

Cuando un usuario intente ingresar al sistema, Cognito verificará sus credenciales y determinará qué funcionalidades puede utilizar según su rol.

---

## Amazon SNS

Amazon Simple Notification Service es un servicio de mensajería y notificaciones.

Permitirá enviar avisos automáticos a los residentes y administradores.

### Tipos de notificaciones

- Lectura registrada
- Consumo mensual
- Consumo superior al promedio
- Lectura pendiente
- Posible fuga de agua

### En la práctica

Si el sistema detecta que el consumo de una vivienda aumentó significativamente respecto a meses anteriores, SNS enviará automáticamente una notificación al residente para advertir sobre una posible fuga o uso excesivo.

---

## Amazon CloudWatch

Amazon CloudWatch es un servicio de monitoreo y registro de eventos.

Se utilizará para supervisar el funcionamiento de toda la infraestructura.

### Funciones

- Registro de errores
- Monitoreo del servidor
- Seguimiento del rendimiento
- Auditoría de eventos

### En la práctica

Si el servidor deja de responder o se produce un error en alguna operación, CloudWatch registrará el incidente y permitirá identificar rápidamente la causa del problema.

---

# Funcionalidad Avanzada: Amazon Textract

Amazon Textract es un servicio de inteligencia artificial especializado en la extracción de texto desde imágenes.

Su incorporación permitiría automatizar parcialmente el proceso de lectura de contadores.

### Funcionamiento

1. El trabajador toma una fotografía del contador.
2. La imagen se almacena en Amazon S3.
3. Amazon Textract analiza la fotografía.
4. El sistema extrae automáticamente el valor mostrado en el contador.
5. La lectura es almacenada en la base de datos.

### Beneficios

- Reducción de errores humanos
- Mayor rapidez en el proceso de captura
- Validación automática de lecturas

Esta funcionalidad puede implementarse como una mejora futura del sistema.

---

# Funcionalidad Estratégica: AWS IoT Core

AWS IoT Core es una plataforma diseñada para conectar dispositivos físicos a aplicaciones en la nube.

Aunque la primera versión del proyecto utilizará fotografías tomadas por personal de mantenimiento, AWS IoT Core permitiría una futura integración con contadores inteligentes.

### Funcionamiento futuro

1. El contador inteligente registra el consumo.
2. El dispositivo envía la información directamente a AWS IoT Core.
3. AWS procesa los datos recibidos.
4. La información se almacena automáticamente en la base de datos.
5. Los usuarios pueden visualizar el consumo en tiempo real.

### Beneficios

- Eliminación de lecturas manuales
- Monitoreo en tiempo real
- Detección temprana de fugas
- Escalabilidad para grandes condominios

La existencia de este servicio fue uno de los principales motivos para seleccionar AWS, ya que permite que el proyecto evolucione hacia una solución inteligente sin necesidad de cambiar la plataforma tecnológica.

---

# Conclusión

La arquitectura propuesta utiliza Amazon EC2, Amazon RDS, Amazon S3, Amazon Cognito, Amazon SNS y Amazon CloudWatch como servicios principales para cubrir los requerimientos actuales del sistema. Adicionalmente, Amazon Textract y AWS IoT Core representan oportunidades de crecimiento futuro mediante la incorporación de inteligencia artificial y dispositivos inteligentes.

La elección de AWS se fundamenta no solo en satisfacer las necesidades actuales del proyecto, sino también en proporcionar una plataforma escalable y preparada para futuras mejoras tecnológicas relacionadas con automatización, análisis de datos e Internet de las Cosas (IoT).