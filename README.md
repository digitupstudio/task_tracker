# Task Tracker

macOS menu bar app. Each button is a task: click it and it counts until you switch, pause, or stop.

Apple Silicon only, macOS 14 or later. The Xcode command line tools are required (`xcode-select --install`).

## Install

```bash
git clone <repo-url>
cd task_tracker
bash scripts/build-app.sh
```

That builds `TaskTracker.app` in this folder. Copy it to Applications, or open it from here.

The first launch may be blocked. Right-click the app and choose **Open**.

## Use

1. Click the clock icon in the menu bar.
2. Under **Botones**, type a name and press **Añadir**.
3. Click a task button to start. Clicking another one closes the current task and starts the new one.
4. **Pausa** freezes the timer. **Seguir** continues the same task. Paused time is not counted.
5. **Stop** ends the task.
6. **Quitar** hides the button. Time already recorded stays.
7. **Registro** shows today.
8. **Exportar** saves a JSON file for today, the current week (Monday to Sunday), or a date range. It includes the name, start, end, and totals.

History is not inside the app. It is stored at:

`~/Library/Application Support/TaskTracker/store.json`

## Update

In the repo folder:

```bash
git pull
bash scripts/build-app.sh
```

Replace the `TaskTracker.app` you use, including the one in Applications. Do not delete `store.json`. History is kept.

---

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
