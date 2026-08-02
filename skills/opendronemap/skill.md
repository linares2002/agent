---
name: opendronemap
description: >
  Procesa imágenes de dron con OpenDroneMap (ODM) usando Docker para generar ortofotos,
  nubes de puntos y modelos 3D. Usa este skill siempre que el usuario mencione ODM,
  OpenDroneMap, procesar imágenes de dron, generar ortofoto, fotogrametría, o quiera
  lanzar un contenedor Docker de ODM. También úsalo cuando el usuario especifique una
  carpeta de imágenes aéreas o de dron y quiera obtener algún producto cartográfico.
---

# OpenDroneMap Skill

Este skill guía el procesamiento de imágenes de dron con OpenDroneMap (ODM) vía Docker,
generando ortofotos y productos derivados directamente desde la línea de comandos.

---

## Flujo de trabajo

### 1. Obtener la ruta del proyecto

Pregunta al usuario la ruta absoluta de la carpeta que contiene las imágenes.
Esa carpeta debe tener una subcarpeta `images/` con los JPG/TIFF del vuelo:

```
/ruta/al/proyecto/
└── images/
    ├── IMG_0001.JPG
    ├── IMG_0002.JPG
    └── ...
```

Si la carpeta no tiene subcarpeta `images/`, indícaselo al usuario y ofrece crear
la estructura correcta con:

```bash
mkdir -p /ruta/al/proyecto/images
# mover imágenes si es necesario
mv /ruta/al/proyecto/*.JPG /ruta/al/proyecto/images/
```

### 2. Verificar Docker

Antes de lanzar, comprueba que Docker está disponible:

```bash
docker info > /dev/null 2>&1 && echo "Docker OK" || echo "Docker no disponible"
```

Si Docker no está disponible, indica al usuario que debe tenerlo instalado y en marcha.

### 3. Construir el comando Docker

#### Comando base (ortofoto con opciones por defecto)

```bash
docker run -ti --rm \
  -v /ruta/al/proyecto:/datasets/code \
  opendronemap/odm \
  --project-path /datasets
```

Reemplaza `/ruta/al/proyecto` con la ruta real que indicó el usuario.

#### Parámetros opcionales útiles

Añade solo los que el usuario solicite explícitamente:

| Parámetro | Descripción |
|---|---|
| `--dsm` | Genera Modelo Digital de Superficie |
| `--dtm` | Genera Modelo Digital del Terreno |
| `--orthophoto-resolution 2` | Resolución de la ortofoto en cm/pixel (defecto: 5) |
| `--mesh-size 200000` | Número de caras del modelo 3D |
| `--min-num-features 10000` | Más características para mayor precisión (más lento) |
| `--fast-orthophoto` | Ortofoto rápida, menor calidad |
| `--skip-3dmodel` | Omite el modelo 3D para mayor velocidad |
| `--max-concurrency 4` | Limita el número de núcleos de CPU usados |

### 4. Mostrar el comando al usuario

Presenta siempre el comando completo y listo para copiar/pegar antes de ejecutarlo.
Explica brevemente qué hace cada parte:

- `-v /ruta/proyecto:/datasets/code` → monta la carpeta local dentro del contenedor
- `--project-path /datasets` → indica a ODM dónde buscar el proyecto

### 5. Salidas esperadas

ODM guarda los resultados en `/ruta/al/proyecto/odm_orthophoto/`:

```
/ruta/al/proyecto/
├── images/                    ← imágenes originales
├── odm_orthophoto/
│   └── odm_orthophoto.tif     ← ortofoto georreferenciada (GeoTIFF)
├── odm_dem/                   ← DSM/DTM si se solicitaron
├── odm_meshing/               ← malla 3D
├── odm_pointcloud/
│   └── cloud.laz              ← nube de puntos
└── opensfm/                   ← datos intermedios de fotogrametría
```

Informa al usuario dónde encontrar el resultado principal (`odm_orthophoto.tif`).

### 6. Tiempos estimados (CPU, sin GPU)

| Nº imágenes | Tiempo aprox. |
|---|---|
| < 50 | 15–30 min |
| 50–200 | 1–3 horas |
| 200–500 | 3–8 horas |
| > 500 | 8+ horas |

Advierte siempre que el procesamiento puede ser largo dependiendo de la RAM y CPU disponibles.

---

## Errores comunes

### Error: `No images found`
La carpeta `images/` no existe o está vacía. Verificar estructura del proyecto.

### Error: `Cannot connect to Docker daemon`
Docker no está en marcha. Ejecutar `sudo systemctl start docker` (Linux) o iniciar Docker Desktop.

### Error: `Killed` / proceso terminado
Falta de RAM. ODM necesita al menos 8 GB para proyectos pequeños, 16+ GB recomendados.
Sugerir reducir `--resize-to 1500` para redimensionar imágenes antes de procesar.

### La ortofoto no está georreferenciada
Las imágenes no tienen GPS en los metadatos EXIF. Informar al usuario que necesita
imágenes con coordenadas GPS o un archivo GCP (Ground Control Points).

---

## Notas

- ODM descargará la imagen Docker (`opendronemap/odm`) la primera vez (~3 GB). Informar al usuario.
- Para proyectos grandes, considerar WebODM (interfaz web) o NodeODM (API REST).
- La imagen Docker se actualiza frecuentemente; usar `docker pull opendronemap/odm` para actualizar.