# Manual de Instalación y Uso: LiteLLM + Pi Coding Agent


## ¿Qué es cada componente?

| Componente | Rol |
|---|---|
| **LiteLLM** | Proxy local que unifica múltiples proveedores de LLM bajo una API compatible con OpenAI |
| **OpenRouter** | Servicio que agrega cientos de modelos (Gemini, Claude, GPT, etc.) con una sola API key |
| **Pi Coding Agent** | Agente de codificación (pi.dev) que acepta endpoints OpenAI-compatibles personalizados |

La arquitectura es: **Pi → LiteLLM (localhost) → OpenRouter → Modelo (Gemini Flash, etc.)**

---

## 1. Prerrequisitos

- Python 3.8+
- Node.js (para el provider de Pi, si aplica)
- Una API key de OpenRouter: https://openrouter.ai/keys

---

## 2. Instalación de LiteLLM

### 2.1 Instalar el proxy de LiteLLM

```bash
pip install "litellm[proxy]"
```

---

## 3. Configuración

### 3.1 Crear el archivo `config.yaml`

Crea un archivo `config.yaml` en tu directorio de trabajo:

```yaml
model_list:
  - model_name: gemini-flash
    litellm_params:
      model: openrouter/google/gemini-3.5-flash-lite
      api_key: os.environ/OPENROUTER_API_KEY
      api_base: https://openrouter.ai/api/v1
```

**Explicación de los campos:**

| Campo | Descripción |
|---|---|
| `model_name` | Alias local con el que llamarás al modelo |
| `model` | Identificador del modelo en OpenRouter (formato `openrouter/<proveedor>/<modelo>`) |
| `api_key` | Lee la variable de entorno `OPENROUTER_API_KEY` automáticamente |
| `api_base` | Endpoint de OpenRouter |

### 3.2 Agregar más modelos (opcional)

Puedes agregar tantos modelos como necesites:

```yaml
model_list:
  - model_name: gemini-flash
    litellm_params:
      model: openrouter/google/gemini-3.5-flash-lite
      api_key: os.environ/OPENROUTER_API_KEY
      api_base: https://openrouter.ai/api/v1

  - model_name: claude-haiku
    litellm_params:
      model: openrouter/anthropic/claude-haiku
      api_key: os.environ/OPENROUTER_API_KEY
      api_base: https://openrouter.ai/api/v1
```

---

## 4. Iniciar el proxy

### 4.1 Exportar la API key

**Linux / macOS:**
```bash
export OPENROUTER_API_KEY=sk-or-v1-xxxxxxxxxxxxxxxx
```

**Windows (CMD):**
```cmd
set OPENROUTER_API_KEY=sk-or-v1-xxxxxxxxxxxxxxxx
```

**Windows (PowerShell):**
```powershell
$env:OPENROUTER_API_KEY="sk-or-v1-xxxxxxxxxxxxxxxx"
```

### 4.2 Lanzar LiteLLM

```bash
litellm --config config.yaml
```

Por defecto, el proxy escucha en **`http://localhost:4000`**.

Salida esperada:
```
INFO: Started server process
INFO: Uvicorn running on http://0.0.0.0:4000
```

### 4.3 Verificar que funciona

```bash
curl http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemini-flash",
    "messages": [{"role": "user", "content": "Hola, ¿funcionas?"}]
  }'
```

---

## 5. Conectar Pi Coding Agent con LiteLLM

En Pi (pi.dev), puedes configurar un endpoint personalizado compatible con OpenAI. Los parámetros son:

| Parámetro | Valor |
|---|---|
| **API Base URL** | `http://localhost:4000` |
| **API Key** | Cualquier string (LiteLLM no la valida por defecto, ej: `dummy`) |
| **Model** | `gemini-flash` (o el alias que definiste en `config.yaml`) |

> Consulta la documentación de Pi en https://pi.dev/docs para ver dónde exactamente se configura el endpoint personalizado, ya que la interfaz puede variar por versión.

---

## 6. Opciones avanzadas del proxy

### Cambiar el puerto

```bash
litellm --config config.yaml --port 8080
```

### Agregar autenticación al proxy

```yaml
# En config.yaml
general_settings:
  master_key: "sk-mi-clave-secreta"
```

Luego en Pi, usa esa clave como API Key.

### Logging de requests

```yaml
general_settings:
  log_requests: true
```

---

## 7. Solución de problemas

| Problema | Posible causa | Solución |
|---|---|---|
| `Connection refused` en puerto 4000 | El proxy no está corriendo | Ejecuta `litellm --config config.yaml` |
| `AuthenticationError` | API key de OpenRouter incorrecta | Verifica la variable de entorno |
| `Model not found` | El alias del modelo no coincide | Verifica que el `model_name` en `config.yaml` coincida con el que usas en Pi |
| Respuestas lentas | Latencia de OpenRouter | Normal en modelos remotos; considera caché con `litellm --config config.yaml --cache` |

---

## 8. Referencias

- LiteLLM Docs: https://docs.litellm.ai
- OpenRouter Models: https://openrouter.ai/models
- Pi Coding Agent: https://pi.dev
- Repositorio LiteLLM: https://github.com/BerriAI/litellm

