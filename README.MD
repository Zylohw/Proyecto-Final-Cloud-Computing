# 🍃 Leaf

**Digitaliza la lectura de contadores de agua en condominios — sin papel, sin Excel, sin disputas.**

---

## ¿Qué es Leaf?

En la mayoría de los condominios de Guatemala, la lectura de contadores de agua todavía se hace a mano: alguien recorre casa por casa anotando números en papel, calcula el consumo en un Excel y luego avisa a cada residente. El proceso es lento, propenso a errores, y cuando un residente no está de acuerdo con su factura, no hay forma de comprobar la lectura.

**Leaf** resuelve esto digitalizando todo el proceso: el personal de mantenimiento registra cada lectura con evidencia fotográfica desde su celular, el sistema calcula el consumo automáticamente, y cada residente puede ver su historial y recibir notificaciones sobre su consumo — todo desde una sola app.

---

## Así funciona

Leaf tiene tres roles, cada uno con su propia vista:

### 🔧 Personal de mantenimiento
Recorre las unidades del condominio y registra cada lectura tomando una foto del contador directamente desde la app. El sistema le indica qué casas tiene pendientes y cuáles ya completó.

### 🏠 Residente
Consulta su consumo actual y el del mes pasado, revisa su historial de reportes mes a mes, y recibe notificaciones apenas su lectura está lista.

### 📊 Administración
Tiene una vista general del estado de todo el condominio: cuántas lecturas van completadas, reportes generados, y las rutas de escaneo asignadas al personal de mantenimiento.

---

## Cómo está organizado el proyecto

```
leaf-app/
├── frontend/     → App móvil (Flutter)
├── backend/      → API y lógica del servidor
├── web/          → Versión web (landing o dashboard, por definir)
└── docs/         → Propuesta, diseños y documentación de apoyo
```

---

## Equipo

Proyecto desarrollado para el curso de Ingeniería de Software — FISICC.

- **Pablo Daniel Vásquez Aldana** — Frontend
- **Mario Daniel Blanco Estrada** — Backend