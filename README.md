# Task Tracker

App de macOS para la barra de menú. Cada botón es una tarea: al pulsarlo empieza a contar hasta que cambias, pausas o paras.

Solo funciona en Mac con Apple Silicon y macOS 14 o posterior. Hace falta tener instaladas las herramientas de línea de comandos de Xcode (`xcode-select --install`).

## Instalar

```bash
git clone <url-del-repo>
cd task_tracker
bash scripts/build-app.sh
```

Eso genera `TaskTracker.app` en esta carpeta. Cópiala a Aplicaciones, o ábrela desde aquí.

La primera vez macOS puede bloquearla. Clic derecho sobre la app y **Abrir**.

## Usar

1. Clic en el icono del reloj, en la barra de menú.
2. En **Botones**, escribe un nombre y pulsa **Añadir**.
3. Pulsa el botón de la tarea para empezar. Si pulsas otra, la anterior se cierra y empieza la nueva.
4. **Pausa** congela el tiempo. **Seguir** continúa la misma tarea. El rato en pausa no cuenta.
5. **Stop** termina la tarea.
6. **Quitar** oculta el botón. Las horas ya contadas se quedan.
7. **Registro** muestra lo de hoy.
8. **Exportar** guarda un JSON del día, de la semana (lunes a domingo) o de un intervalo. Incluye nombre, inicio, fin y totales ya calculados.

El historial no va dentro de la app. Está en:

`~/Library/Application Support/TaskTracker/store.json`

## Actualizar

En la carpeta del repo:

```bash
git pull
bash scripts/build-app.sh
```

Sustituye la `TaskTracker.app` que uses (también la de Aplicaciones) por la nueva. No borres `store.json`: el historial se conserva.
