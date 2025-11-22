Creador: Alexis Geovanni Sanchez Hernandez

Controles
Movimiento: WASD
Interacción: E (por implementar)
Salto: SPACE
Agacharse: CTRL (por mejorar)
Correr: SHIFT
Girar cámara: MOUSE
Alejar/Acercar cámara: RUEDA DEL MOUSE

1.  El Jugador (jugador.tscn) Es un CharacterBody3D instanciado
    directamente en el mundo (no es Autoload). Movimiento: Sistema
    completo con caminar, correr (gasta energía), agacharse (modifica la
    CollisionShape con lerp) y salto. Cámara: SpringArm3D orbital con
    zoom. Estadísticas: Vida: Si llega a 0 → Se pierde una vida → Se
    reinicia la escena. Si las vidas llegan a 0 → Game Over. Energía
    (Stamina): Se gasta al correr y se regenera automáticamente.
    Monedas: Se acumulan. Al llegar a 10 (o una variable exportada) →
    Victoria. Audio: Pasos sincronizados con la animación usando “Call
    Method Tracks”. Señales: Emite alertas (health_updated,
    coins_updated, player_died, etc.) para que el HUD actualice la
    visualización.

2.  El “Cerebro” Global (GameManager.gd) Es el único Autoload y persiste
    entre cambios de escena. Función: Gestionar los datos que no deben
    reiniciarse al recargar un nivel. Variables Clave:

-   load_requested: Indica al mundo si debe cargar datos al iniciar.
-   player_lives: Guarda las vidas (3) para evitar que se reinicien al
    morir. Sistema de Archivos: Se encarga de escribir y leer el archivo
    user://save.dat.

3.  Los Enemigos (IA) Existen dos tipos de inteligencia artificial:
    Terrestres (Piggy, Skeleton, Rata): Utilizan NavigationAgent3D para
    recorrer el mapa mediante NavMesh. Máquina de Estados: Idle →
    Perseguir (si el jugador entra al Área) → Atacar (si está cerca).
    Ataque: Daño directo sincronizado con animación. Volador (Ojo): Usa
    un nodo Pivot para rotar y mantener al jugador en la mira. Dispara
    proyectiles físicos (laser_bullet.tscn) que causan daño al impactar.
    Seguridad: Todos incluyen verificación (is_inside_tree) para evitar
    errores cuando el jugador muere y el mundo se reinicia.

4.  Interfaz de Usuario (HUD y Menús) Construida con Nodos de Control
    (Control, VBoxContainer, TextureProgressBar). HUD (HUD.tscn): Se
    conecta al jugador mediante la función connect_to_player. Muestra
    barras de vida/energía y contadores de monedas/vidas. Incluye
    paneles de Pausa, Victoria, Game Over y Niebla. Menú Principal
    (MainMenu.tscn): Permite iniciar una nueva partida (reinicia vidas)
    o cargar datos (usa la bandera del GameManager). Incluye un Menú de
    Opciones para control de audio. Menú de Pausa: Se activa con ESC.
    Detiene el juego (get_tree().paused = true) pero mantiene operativos
    los botones (Process Mode: When Paused). Permite guardar, ajustar
    volumen o salir.

5.  Sistema de Audio Buses de Audio: Dos canales separados (Music y
    GameMusic) para controlar volúmenes de forma independiente. Sliders:
    Los sliders del menú leen el volumen real
    (AudioServer.get_bus_volume_db) para mantenerse sincronizados.
    Pasos: Sonidos 3D (AudioStreamPlayer3D) activados mediante eventos
    en la línea de tiempo de la animación.

6.  Mecánicas de Entorno Niebla Mortal: Un área que activa un
    temporizador en pantalla. Si no se abandona en 10 segundos, provoca
    muerte instantánea. Vehículo (Bocho): Un CharacterBody3D que avanza
    en línea recta con animación de llantas vía AnimationPlayer.
    Monedas: Áreas 3D rotatorias que incrementan el contador y
    desaparecen al recogerse.

Flujo General del Proyecto: Menú Principal: Selección de Nueva Partida.
Mundo: Se instancia el Jugador y el HUD se conecta a este. Gameplay:
Interacción con enemigos, recolección de monedas y reacciones dinámicas
de audio. Guardado: El menú de pausa permite guardar posición, vida,
monedas y vidas. Estados Finales: Muerte: Se pierde una vida → Se
reinicia la zona → Si las vidas llegan a 0 → Panel Game Over. Victoria:
Se alcanzan 10 monedas → Panel de Victoria.
