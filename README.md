# Depos Action

GitHub Action для обновления версий зависимостей пакетов OneScript в файле _packagedef_ и автоматизации Pull Request’ов.

## 📦 Action: `upgrade`

### Описание

Action выполняет команду [`depos upgrade`](https://github.com/Stivo182/depos?tab=readme-ov-file#upgrade), которая обновляет зависимости в файле _packagedef_ до целевых версий.

### Входные параметры

| Параметр | Описание | Значение по умолчанию |
| --- | --- | --- |
| `packagedef` | Путь к файлу `packagedef` или его каталогу. | Текущая директория |
| `filter`     | Фильтр пакетов по именам (через запятую или пробел), шаблону (`*`, `?`) или регулярному выражению. | |
| `target`     | Тип целевой версии: <br>- `latest` - последняя доступная версия пакета.<br>- `minor` - последняя минорная или патч-версия в пределах основной версии.<br>- `patch` - последняя патч-версия в пределах минорной версии. | `latest` |
| `output`     | Экспорт отчёта об обновлениях в JSON. | |

### Пример использования

```yaml
name: Обновление зависимостей

on:
  workflow_dispatch:
    inputs:
      filter:
        description: 'Фильтр пакетов'
      target:
        description: 'Тип версии'
        default: 'latest'
        type: choice
        options:
          - latest
          - minor
          - patch

jobs:
  deps-upgrade:
    runs-on: ubuntu-latest
    steps:
      - name: Актуализация
        uses: actions/checkout@v5.0.0

      - name: Установка OneScript
        uses: otymko/setup-onescript@v1.5.1
        with:
          version: stable
          
      - name: Обновление зависимостей
        uses: Stivo182/depos-action/upgrade@main
        with:
          filter: ${{ inputs.filter }}
          target: ${{ inputs.target }}
```

## 🤖 Workflow: `deps-upgrade-pr`

### Описание

Workflow запускает обновление зависимостей и автоматически создаёт Pull Request с изменениями.

### Входные параметры

| Параметр | Описание | Значение по умолчанию |
| --- | --- | --- |
| `filter`         | Фильтр пакетов по именам (через запятую или пробел), шаблону (`*`, `?`) или регулярному выражению.   | |
| `target`         | Тип целевой версии: <br>- `latest` - последняя доступная версия пакета.<br>- `minor` - последняя минорная или патч-версия в пределах основной версии.<br>- `patch` - последняя патч-версия в пределах минорной версии. | `latest` |
| `message-prefix` | Префикс для сообщения коммита и заголовка PR | |

### Пример использования

```yaml
name: Обновление зависимостей и создание PR

on:
  schedule:
    - cron: '0 8 * * *'

permissions:
  contents: write
  pull-requests: write

jobs:
  deps-upgrade-pr:
    uses: Stivo182/depos-action/.github/workflows/deps-upgrade-pr.yml@main
    with:
      filter: "autumn-*"
      target: "patch"
      message-prefix: "build(deps)"
```