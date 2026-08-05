# Publicar el APK en una URL propia del servidor

## Contexto

`dipalza_mobile` ya construye un APK firmado en cada release (`release.config.js`, hook `publishCmd` de `@semantic-release/exec`: `flutter build apk --release`) y lo adjunta automáticamente como asset a la GitHub Release (`@semantic-release/github`, patrón `dipalza-release-*.apk`). Hoy la única forma de obtenerlo es descargándolo desde esa GitHub Release.

`dipalza_server` ya tiene un mecanismo equivalente para su propio artefacto (el jar): un workflow **manual** (`deploy.yml`, `workflow_dispatch` con input `version`) que descarga el jar de una GitHub Release y lo copia por SSH a `/opt/dipalza-app/releases/<version>/dipalza.jar` en el servidor de producción, actualizando un symlink `current` que usa `systemd` para ejecutar el proceso. Los detalles de la llave SSH, el usuario dedicado (`deploy-dipalza`) y los permisos `sudo` acotados están documentados en `docs/deploy/server-setup.md` (repo `dipalza_server`).

El usuario quiere el mismo tipo de mecanismo para el APK, pero para servirlo como **archivo descargable** en una URL propia y estable del mismo servidor (no para ejecutarlo) — confirmado: no hay ningún proxy (nginx u otro) delante del servidor, todo el tráfico HTTP llega directo al proceso Java de `dipalza_server` (puerto 8080), así que exponer el archivo requiere una configuración nueva en ese Spring Boot.

## Objetivo

1. Un workflow manual (`workflow_dispatch`) en `dipalza_mobile`, análogo a `deploy.yml` de `dipalza_server`, que reciba una versión (tag de GitHub Release) y copie ese APK por SSH al servidor de producción.
2. El servidor guarda cada versión copiada en una carpeta propia (`/opt/dipalza-app/downloads/releases/<version>/dipalza.apk`) y mantiene un symlink `/opt/dipalza-app/downloads/dipalza.apk` apuntando siempre a la última copiada — la URL pública de descarga nunca cambia: `http://ventas.dynalias.net:8080/downloads/dipalza.apk`.
3. `dipalza_server` sirve ese directorio externo (`/opt/dipalza-app/downloads/`) bajo la ruta `/downloads/**`, sumado a los recursos estáticos embebidos que ya sirve (el frontend web, en `/`).
4. Se reutiliza el mismo usuario/llave SSH (`deploy-dipalza`) que ya usa el deploy del jar — sin permisos `sudo` nuevos, porque copiar un archivo estático no requiere reiniciar ningún servicio.
5. Se documenta el paso manual único de setup del servidor (crear la carpeta `downloads/`, copiar el script remoto), igual que existe hoy para el jar.

## Enfoque

### `dipalza_mobile`: nuevo workflow `deploy.yml`

Calca la estructura de `deploy.yml` de `dipalza_server` (mismos pasos, mismo orden):

```yaml
name: Deploy

on:
  workflow_dispatch:
    inputs:
      version:
        description: 'Versión (tag de la GitHub Release) a desplegar, ej. v2.5.2'
        required: true
        type: string

permissions:
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    env:
      DEPLOY_VERSION: ${{ inputs.version }}
      SSH_HOST: ${{ secrets.DEPLOY_SSH_HOST }}
      SSH_USER: ${{ secrets.DEPLOY_SSH_USER }}
      SSH_PORT: ${{ secrets.DEPLOY_SSH_PORT || '22' }}
    steps:
      - name: Validar formato de la versión
        run: |
          if ! [[ "$DEPLOY_VERSION" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+(-[A-Za-z0-9.]+)?$ ]]; then
            echo "ERROR: version '$DEPLOY_VERSION' no tiene un formato válido (esperado algo como v2.5.2, opcionalmente con sufijo -algo)" >&2
            exit 1
          fi
          echo "Versión '$DEPLOY_VERSION' tiene formato válido."

      - name: Verificar que la release existe y descargar el apk
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          gh release download "$DEPLOY_VERSION" \
            --repo "${{ github.repository }}" \
            --pattern "dipalza-release-*.apk" \
            --dir /tmp/deploy-artifact \
            --clobber

      - name: Configurar agente SSH
        uses: webfactory/ssh-agent@v0.9.0
        with:
          ssh-private-key: ${{ secrets.DEPLOY_SSH_KEY }}

      - name: Agregar el host a known_hosts
        run: |
          mkdir -p ~/.ssh
          ssh-keyscan -p "$SSH_PORT" -H "$SSH_HOST" >> ~/.ssh/known_hosts

      - name: Crear carpeta de la versión en el servidor
        run: |
          ssh -p "$SSH_PORT" "$SSH_USER@$SSH_HOST" \
            "mkdir -p /opt/dipalza-app/downloads/releases/$DEPLOY_VERSION"

      - name: Copiar el apk al servidor
        run: |
          APK_FILE=$(ls /tmp/deploy-artifact/dipalza-release-*.apk)
          scp -P "$SSH_PORT" "$APK_FILE" \
            "$SSH_USER@$SSH_HOST:/opt/dipalza-app/downloads/releases/$DEPLOY_VERSION/dipalza.apk"

      - name: Ejecutar el deploy remoto (actualiza el symlink)
        run: |
          ssh -p "$SSH_PORT" "$SSH_USER@$SSH_HOST" \
            "/opt/dipalza-app/scripts/deploy-apk-remote.sh $DEPLOY_VERSION"
```

Diferencias deliberadas respecto al `deploy.yml` del jar: el patrón del asset (`dipalza-release-*.apk` en vez de `dipalza-*.jar`, el nombre real que produce `release.config.js` de este repo), la carpeta base (`/opt/dipalza-app/downloads/releases/` en vez de `/opt/dipalza-app/releases/`), y el script remoto invocado (`deploy-apk-remote.sh`, no reinicia ningún servicio — a diferencia de `deploy-remote.sh` del jar). Los secrets (`DEPLOY_SSH_HOST/USER/PORT/KEY`) son los mismos valores que ya existen en `dipalza_server`; el usuario los agrega manualmente a los secrets de este repo (no es algo que se automatice ni algo que el asistente deba ver).

### `dipalza_mobile`: nuevo script `scripts/deploy-apk-remote.sh`

Vive commiteado en el repo (para que quede versionado y revisable), pero — igual que `deploy-remote.sh`/`rollback-remote.sh` de `dipalza_server` — **no viaja en cada deploy**: se copia a mano al servidor una sola vez como parte del setup inicial (ver más abajo). Si cambia en el repo, hay que repetir la copia a mano.

```bash
#!/bin/bash
set -euo pipefail

VERSION="${1:?Uso: deploy-apk-remote.sh <version>}"
DOWNLOADS_DIR="/opt/dipalza-app/downloads"
APK_PATH="$DOWNLOADS_DIR/releases/$VERSION/dipalza.apk"

if [[ ! -f "$APK_PATH" ]]; then
  echo "ERROR: no existe $APK_PATH — ¿se copió el apk antes de llamar a este script?" >&2
  exit 1
fi

ln -sfn "$APK_PATH" "$DOWNLOADS_DIR/dipalza.apk"
echo "Symlink actualizado: $DOWNLOADS_DIR/dipalza.apk -> $APK_PATH"
```

Sin `sudo`, sin `systemctl`: el usuario `deploy-dipalza` ya es dueño de `/opt/dipalza-app` (heredado del setup del jar), así que puede escribir ahí directamente.

### `dipalza_server`: nueva clase `DownloadsStaticConfig`

Nuevo archivo `dipalza/src/main/java/cl/eos/dipalza/config/DownloadsStaticConfig.java`, mismo paquete y mismo estilo que `CorsConfig.java` (una sola responsabilidad, sin externalizar la ruta a `application.yml` — se sigue el patrón ya usado en `CorsConfig`, que también hardcodea su valor):

```java
package cl.eos.dipalza.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class DownloadsStaticConfig implements WebMvcConfigurer {

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        registry.addResourceHandler("/downloads/**")
                .addResourceLocations("file:/opt/dipalza-app/downloads/");
    }
}
```

Spring Boot no falla si `/opt/dipalza-app/downloads/` no existe todavía al arrancar (ni en local ni en CI) — el resource handler simplemente responde 404 hasta que el archivo exista. No afecta a los tests existentes ni al entorno de desarrollo local.

### `dipalza_server`: actualizar `docs/deploy/server-setup.md`

Agregar una sección nueva ("11. Setup para el deploy del APK") con los pasos manuales de una sola vez, análoga a los pasos 5 y 8 ya existentes para el jar:

```bash
sudo -u deploy-dipalza mkdir -p /opt/dipalza-app/downloads/releases
```

```bash
scp -P <puerto> scripts/deploy-apk-remote.sh \
  deploy-dipalza@<host>:/opt/dipalza-app/scripts/
ssh -p <puerto> deploy-dipalza@<host> \
  "chmod +x /opt/dipalza-app/scripts/deploy-apk-remote.sh"
```

Y una nota indicando que los secrets `DEPLOY_SSH_*` deben agregarse también en `dipalza_mobile` (Settings → Secrets and variables → Actions), con los mismos valores ya usados en `dipalza_server`.

### Qué NO cambia

- El build y adjunto automático del APK a cada GitHub Release (`release.config.js` de `dipalza_mobile`) sigue igual — este spec solo agrega el paso de copiarlo al servidor propio, manual y aparte.
- El deploy del jar (`deploy.yml`, `deploy-remote.sh`, `rollback-remote.sh` de `dipalza_server`) no se toca.
- El frontend web embebido (`src/main/resources/static/`) sigue sirviéndose igual, sin relación con este cambio.
- No hay limpieza automática de versiones viejas en `downloads/releases/` — a diferencia del jar, un archivo estático sin proceso corriendo no necesita rollback; si el directorio crece demasiado con el tiempo, es una limpieza manual ocasional, fuera de alcance de este spec.

## Fuera de alcance

- Página HTML de descarga (landing page) — la URL sirve el `.apk` crudo directamente.
- Automatizar el disparo de este deploy en cada release (el usuario pidió explícitamente que sea manual, como el del jar).
- HTTPS/dominio propio para la descarga — se usa la misma URL/puerto que ya expone `dipalza_server` hoy (`ventas.dynalias.net:8080`).
- Limpieza automática de versiones antiguas en el servidor.
