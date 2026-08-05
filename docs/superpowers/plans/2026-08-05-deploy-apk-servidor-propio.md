# Publicar el APK en una URL propia del servidor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Agregar un mecanismo manual para copiar el APK de una GitHub Release de `dipalza_mobile` al servidor de producción (el mismo que ya sirve `dipalza_server`), quedando disponible en una URL fija y estable, sin autenticación.

**Architecture:** Dos repos, dos tareas independientes que se integran vía un directorio y una URL compartidos en el mismo servidor. `dipalza_mobile` gana un workflow `deploy.yml` (calcado de `deploy.yml` de `dipalza_server`) que copia el `.apk` por SSH a `/opt/dipalza-app/downloads/releases/<version>/dipalza.apk` y actualiza un symlink `dipalza.apk` vía un script remoto. `dipalza_server` gana una clase `@Configuration` que expone ese directorio externo bajo `/downloads/**`, más el permiso correspondiente en Spring Security (sin el cual la descarga devolvería 401).

**Tech Stack:** GitHub Actions (`workflow_dispatch`, `gh release download`, `webfactory/ssh-agent`), Bash, Spring Boot 3 / Spring MVC (`WebMvcConfigurer`), Spring Security (`SecurityFilterChain`), JUnit 5 + `@WebMvcTest` (Java 21, Maven).

## Global Constraints

- Sin `sudo` nuevo en el servidor: copiar el APK no reinicia ningún servicio, a diferencia del deploy del jar.
- Se reutilizan los secrets `DEPLOY_SSH_HOST`/`DEPLOY_SSH_USER`/`DEPLOY_SSH_PORT`/`DEPLOY_SSH_KEY` ya existentes en `dipalza_server`, agregados por el usuario (no por el agente) a los secrets de `dipalza_mobile` con los mismos valores.
- URL de descarga final y estable: `http://ventas.dynalias.net:8080/downloads/dipalza.apk` (no cambia entre versiones).
- El patrón del asset a descargar de la GitHub Release es `dipalza-release-*.apk` (definido en `release.config.js` de `dipalza_mobile`, ya existente — no confundir con el patrón `dipalza-*.jar` de `dipalza_server`).
- Trigger manual (`workflow_dispatch` con input `version`), nunca automático en cada release — decisión explícita del usuario, igual que el deploy del jar.
- Sin limpieza automática de versiones viejas en `/opt/dipalza-app/downloads/releases/` — fuera de alcance de este spec.
- La ruta externa del directorio de descargas se externaliza vía `@Value("${app.downloads.location:file:/opt/dipalza-app/downloads/}")` en `dipalza_server` (no hardcodeada), para poder testearla sin escribir en `/opt`.

---

### Task 1: Workflow y script de deploy del APK (`dipalza_mobile`)

**Files:**
- Create: `.github/workflows/deploy.yml`
- Create: `scripts/deploy-apk-remote.sh`

**Interfaces:**
- Consumes: secrets `DEPLOY_SSH_HOST`, `DEPLOY_SSH_USER`, `DEPLOY_SSH_PORT` (opcional, default `22`), `DEPLOY_SSH_KEY` — deben existir en los secrets de Actions de este repo antes de poder disparar el workflow (paso manual del usuario, fuera de este plan).
- Produces: en el servidor, `/opt/dipalza-app/downloads/releases/<version>/dipalza.apk` y el symlink `/opt/dipalza-app/downloads/dipalza.apk` actualizado — consumido por la Task 2 (que sirve ese mismo directorio vía HTTP).

No hay framework de tests para workflows YAML ni scripts bash en este repo — la verificación es sintáctica (parseo YAML, `bash -n`) más revisión manual del contenido, siguiendo el mismo criterio que ya se usó para `deploy.yml`/`deploy-remote.sh` de `dipalza_server` (tampoco tienen tests automatizados).

- [ ] **Step 1: Crear el workflow `.github/workflows/deploy.yml`**

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

- [ ] **Step 2: Verificar que el YAML es válido**

Run: `python3 -c "import yaml,sys; yaml.safe_load(open('.github/workflows/deploy.yml'))" && echo "YAML válido"`
Expected: imprime `YAML válido`, sin excepciones.

- [ ] **Step 3: Crear el script remoto `scripts/deploy-apk-remote.sh`**

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

Dale permisos de ejecución en el repo (se pierden en algunos checkouts si no se marcan explícitamente):

```bash
chmod +x scripts/deploy-apk-remote.sh
```

- [ ] **Step 4: Verificar la sintaxis del script**

Run: `bash -n scripts/deploy-apk-remote.sh && echo "Sintaxis válida"`
Expected: imprime `Sintaxis válida`, sin errores.

- [ ] **Step 5: Probar el script localmente con un caso simulado**

```bash
mkdir -p /tmp/downloads-test/releases/v9.9.9
echo "contenido-apk-de-prueba" > /tmp/downloads-test/releases/v9.9.9/dipalza.apk
DOWNLOADS_DIR_ORIGINAL=$(grep -o '/opt/dipalza-app/downloads' scripts/deploy-apk-remote.sh | head -1)
sed 's#/opt/dipalza-app/downloads#/tmp/downloads-test#' scripts/deploy-apk-remote.sh > /tmp/deploy-apk-remote-test.sh
bash /tmp/deploy-apk-remote-test.sh v9.9.9
readlink /tmp/downloads-test/dipalza.apk
rm -rf /tmp/downloads-test /tmp/deploy-apk-remote-test.sh
```

Expected: `readlink` imprime `/tmp/downloads-test/releases/v9.9.9/dipalza.apk`, sin errores en ningún paso.

- [ ] **Step 6: Commit**

```bash
git add .github/workflows/deploy.yml scripts/deploy-apk-remote.sh
git commit -m "feat: agrega deploy manual del APK al servidor propio

Workflow calcado de deploy.yml de dipalza_server: copia el APK de la
GitHub Release por SSH y actualiza un symlink en el servidor, sin
reiniciar ningún servicio."
```

---

### Task 2: Servir el APK como archivo estático (`dipalza_server`)

**Files:**
- Create: `dipalza/src/main/java/cl/eos/dipalza/config/DownloadsStaticConfig.java`
- Test: `dipalza/src/test/java/cl/eos/dipalza/config/DownloadsStaticConfigTest.java`
- Modify: `dipalza/src/main/java/cl/eos/dipalza/config/SecurityConfigProdSec.java`
- Modify: `dipalza/src/main/java/cl/eos/dipalza/config/SecurityConfigDevSec.java`
- Modify: `docs/deploy/server-setup.md`

**Interfaces:**
- Consumes: el archivo `/opt/dipalza-app/downloads/dipalza.apk` que produce la Task 1 (o, en el test, un archivo equivalente en un directorio temporal).
- Produces: `GET /downloads/dipalza.apk` públicamente accesible sin autenticación en el servidor real — nada de este repo es consumido por otra Task de este plan (es la última pieza).

- [ ] **Step 1: Escribir el test que falla, sirviendo un archivo real desde un directorio temporal**

Archivo `dipalza/src/test/java/cl/eos/dipalza/config/DownloadsStaticConfigTest.java`:

```java
package cl.eos.dipalza.config;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest
@Import(DownloadsStaticConfig.class)
@AutoConfigureMockMvc(addFilters = false)
class DownloadsStaticConfigTest {

    @TempDir
    static Path tempDownloadsDir;

    @DynamicPropertySource
    static void configurarRutaDeDescargas(DynamicPropertyRegistry registry) {
        registry.add("app.downloads.location", () -> "file:" + tempDownloadsDir + "/");
    }

    @Autowired
    MockMvc mockMvc;

    @BeforeEach
    void crearArchivoDePrueba() throws IOException {
        Files.writeString(tempDownloadsDir.resolve("dipalza.apk"), "contenido-apk-de-prueba");
    }

    @Test
    void sirveElArchivoDesdeElDirectorioConfigurado() throws Exception {
        mockMvc.perform(get("/downloads/dipalza.apk"))
                .andExpect(status().isOk())
                .andExpect(content().string("contenido-apk-de-prueba"));
    }

    @Test
    void respondeNotFoundParaUnArchivoQueNoExiste() throws Exception {
        mockMvc.perform(get("/downloads/inexistente.apk"))
                .andExpect(status().isNotFound());
    }
}
```

- [ ] **Step 2: Correr el test y verificar que falla**

Run: `cd dipalza && ./mvnw test -Dtest=DownloadsStaticConfigTest`
Expected: FAIL — no compila (`DownloadsStaticConfig` no existe todavía).

- [ ] **Step 3: Implementar `DownloadsStaticConfig`**

Archivo `dipalza/src/main/java/cl/eos/dipalza/config/DownloadsStaticConfig.java`:

```java
package cl.eos.dipalza.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class DownloadsStaticConfig implements WebMvcConfigurer {

    @Value("${app.downloads.location:file:/opt/dipalza-app/downloads/}")
    private String downloadsLocation;

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        registry.addResourceHandler("/downloads/**")
                .addResourceLocations(downloadsLocation);
    }
}
```

- [ ] **Step 4: Correr el test y verificar que pasa**

Run: `cd dipalza && ./mvnw test -Dtest=DownloadsStaticConfigTest`
Expected: PASS — los 2 tests de `DownloadsStaticConfigTest` en verde.

Si `@WebMvcTest` sin controladores explícitos falla por no encontrar ningún `@Controller` en el contexto, o si `@DynamicPropertySource` con un campo `static Path` no se resuelve en el orden esperado (se evalúa antes que `@TempDir` inyecte el valor en algunas versiones de JUnit5/Spring), es una desviación esperada del código exacto de este plan — la especificación de comportamiento a lograr es la que importa: un `GET /downloads/<archivo-existente>` debe devolver 200 con el contenido del archivo, y un archivo inexistente debe devolver 404, sirviendo desde una ruta configurable por propiedad (no hardcodeada), sin pasar por los filtros de seguridad reales.

- [ ] **Step 5: Agregar la regla de Spring Security en `SecurityConfigProdSec.java`**

En `dipalza/src/main/java/cl/eos/dipalza/config/SecurityConfigProdSec.java`, dentro de `authorizeHttpRequests`, agregar la línea (junto a las demás reglas de recursos estáticos, antes de `.anyRequest().authenticated()`):

```java
                    .requestMatchers("/downloads/**").permitAll()
```

- [ ] **Step 6: Agregar la misma regla en `SecurityConfigDevSec.java`**

En `dipalza/src/main/java/cl/eos/dipalza/config/SecurityConfigDevSec.java`, mismo cambio, en el mismo lugar relativo dentro de su `authorizeHttpRequests` (junto a las reglas de recursos estáticos ya existentes ahí).

- [ ] **Step 7: Correr la suite completa y verificar que no hay regresiones**

Run: `cd dipalza && ./mvnw test`
Expected: PASS — todos los tests existentes más los 2 nuevos de `DownloadsStaticConfigTest`, sin fallas.

No existe en este repo infraestructura de test para verificar reglas de `SecurityFilterChain` con `MockMvc` + perfil de seguridad real activo (no hay precedente, ver `⚠️` más abajo) — la verificación de que `/downloads/**` efectivamente responde sin 401 con el perfil `dev-sec` activo es manual (Step 8).

- [ ] **Step 8: Verificación manual del permiso de seguridad**

Run: `cd dipalza && ./mvnw spring-boot:run -Dspring-boot.run.profiles=dev-sec` (en una terminal aparte; requiere que el resto de la configuración de `dev-sec` — típicamente BD — esté disponible; si no lo está, dejar este paso para cuando el usuario lo pruebe con su entorno real).

En otra terminal, con el proceso corriendo:

```bash
mkdir -p /opt/dipalza-app/downloads
echo "prueba" | sudo tee /opt/dipalza-app/downloads/dipalza.apk
curl -i http://localhost:8080/downloads/dipalza.apk
```

Expected: `HTTP/1.1 200` con el cuerpo `prueba` — no `401`.

- [ ] **Step 9: Actualizar `docs/deploy/server-setup.md`**

Agregar al final del archivo una nueva sección:

```markdown
## 11. Setup para el deploy del APK (dipalza_mobile)

Pasos manuales de una sola vez, adicionales a los anteriores, para que
el workflow `deploy.yml` de `dipalza_mobile` pueda copiar el APK a este
mismo servidor.

### Crear la carpeta de descargas

```bash
sudo -u deploy-dipalza mkdir -p /opt/dipalza-app/downloads/releases
```

### Copiar el script de deploy remoto del APK

```bash
scp -P <puerto> scripts/deploy-apk-remote.sh \
  deploy-dipalza@<host>:/opt/dipalza-app/scripts/
ssh -p <puerto> deploy-dipalza@<host> \
  "chmod +x /opt/dipalza-app/scripts/deploy-apk-remote.sh"
```

(`scripts/deploy-apk-remote.sh` vive en el repo `dipalza_mobile`, no en
este repo — mismo criterio que `deploy-remote.sh`/`rollback-remote.sh`:
no viaja versionado en cada deploy, se copia a mano cuando cambia.)

### Agregar los secrets en `dipalza_mobile`

En el repo `dipalza_mobile` → Settings → Secrets and variables →
Actions, agregar los mismos 4 secrets que ya existen en este repo, con
los mismos valores: `DEPLOY_SSH_HOST`, `DEPLOY_SSH_USER`,
`DEPLOY_SSH_PORT` (si aplica), `DEPLOY_SSH_KEY`.
```

- [ ] **Step 10: Commit**

```bash
git add dipalza/src/main/java/cl/eos/dipalza/config/DownloadsStaticConfig.java \
        dipalza/src/test/java/cl/eos/dipalza/config/DownloadsStaticConfigTest.java \
        dipalza/src/main/java/cl/eos/dipalza/config/SecurityConfigProdSec.java \
        dipalza/src/main/java/cl/eos/dipalza/config/SecurityConfigDevSec.java \
        docs/deploy/server-setup.md
git commit -m "feat: sirve el APK como archivo estático en /downloads/**

Nueva configuración de recursos estáticos apuntando a un directorio
externo configurable (no embebido en el jar), más el permiso de
Spring Security necesario para que la descarga funcione sin login.
Documenta el setup único del servidor."
```

---

## Spec Coverage Check

- Objetivo 1 (workflow manual en `dipalza_mobile`) → Task 1.
- Objetivo 2 (symlink estable, URL que no cambia) → Task 1, Step 3 (`deploy-apk-remote.sh`).
- Objetivo 3 (`dipalza_server` sirve el directorio externo) → Task 2, Steps 1-4.
- Objetivo 4 (reusar `deploy-dipalza`, sin sudo nuevo) → Task 1 (workflow no usa `sudo` en ningún paso remoto).
- Objetivo 5 (documentar el setup único del servidor) → Task 2, Step 9.
- Hallazgo de Spring Security (`/downloads/**` sin `permitAll` devuelve 401) → Task 2, Steps 5-6 y 8.
