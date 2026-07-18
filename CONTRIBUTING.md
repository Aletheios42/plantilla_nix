# Contribuir

Gracias por tu interés en contribuir a este proyecto.

## Flujo de trabajo

1. Crea una rama desde `master` con un nombre descriptivo:
   ```bash
   git checkout -b feat/mi-funcionalidad
   ```
   ```
2. Haz tus cambios siguiendo las convenciones del proyecto.
3. Ejecuta la pipeline local completa:
   ```bash
   make ci
   ```
   Simula GitHub Actions con el mismo contenedor y pasos:
   ```bash
   make ci-act
   ```
   (Requiere Docker/Podman + act.
4. Asegúrate de que todo pasa antes de abrir la PR.
5. Abre una Pull Request usando la plantilla proporcionada.

## Commits

Seguimos [Conventional Commits](https://www.conventionalcommits.org/):

| Tipo | Descripción |
|---|---|
| `feat` | Nueva funcionalidad |
| `fix` | Corrección de bug |
| `refactor` | Refactorización sin cambios funcionales |
| `docs` | Solo documentación |
| `test` | Añadir o actualizar pruebas |
| `chore` | Mantenimiento, CI, dependencias |

## Revisión

- Los revisores se asignan automáticamente según `.github/CODEOWNERS`.
- Todas las PRs deben pasar el CI de GitHub antes de mergear.
- Se requiere al menos una aprobación.

## Antes de pushear

- [ ] Haz `fetch` y `rebase` de la rama base.
- [ ] `make ci` pasa en local.
- [ ] No hay secretos ni credenciales en el código.
- [ ] La documentación está actualizada si aplica.

