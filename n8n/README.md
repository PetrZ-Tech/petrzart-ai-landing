# n8n — форма заявки ai.petrzart.ru

Workflow: [`ai-petrzart-lead-form.workflow.json`](ai-petrzart-lead-form.workflow.json)

Цепочка: **Webhook → Normalize → Validate → NocoDB → Telegram → Respond**

Форма на сайте отправляет данные как `application/x-www-form-urlencoded` через `URLSearchParams` **без ручной установки `Content-Type`** — это simple POST без CORS preflight.

---

## 1. Таблица NocoDB

Создайте таблицу **`ai_petrzart_leads`** со столбцами:

| Столбец | Тип | Примечание |
|---------|-----|------------|
| `lead_id` | Single Line Text | Уникальный ID заявки |
| `name` | Single Line Text | Имя |
| `contact` | Single Line Text | Telegram / телефон / email |
| `task` | Long Text | Описание задачи |
| `source` | Single Line Text | Источник (ai.petrzart.ru) |
| `created_at1` | DateTime | В NocoDB колонка называется `created_at1` (конфликт с системным полем) |
| `status` | Single Select | Значения: `new`, `in_progress`, `done` |

Запишите **Base ID**, **Workspace ID** и **Table ID** — понадобятся в n8n.

**Production (настроено):**
- Base CRM: `p1q5bmonff6jjq8`
- Workspace: `wa8r1wc2`
- Таблица `ai_petrzart_leads`: `mplrv8zv563kiy4`
- Workflow в n8n: **AI Petrzart - Lead Form PROD** (id `43iY5KzcZcFm7GTK`)
- Webhook: `https://n8n.petrzart.ru/webhook/ai-petrzart-lead-prod-final`

> В n8n узле NocoDB укажите **Table ID**, не имя таблицы. Поле даты — `created_at1`.

---

## 2. Credentials в n8n

### NocoDB API Token

1. NocoDB → Account / API Tokens → создать токен.
2. n8n → Credentials → **NocoDB API Token**.
3. Указать Host URL (например `https://nocodb.example.com`) и Token.

3. **Telegram Bot** — в production workflow уведомление идёт через HTTP Request (токен бота в узле n8n). Рекомендуется позже перенести в **Credentials → Telegram API** в UI n8n.

---

## 3. Импорт workflow

1. n8n → Workflows → Import from File → выбрать `ai-petrzart-lead-form.workflow.json`.
2. Открыть узел **NocoDB — Create Row**:
   - привязать credential NocoDB;
   - указать Base ID и Table (`ai_petrzart_leads` или Table ID).
3. Открыть узел **Telegram — Notify**:
   - привязать credential Telegram;
   - заменить `YOUR_TELEGRAM_CHAT_ID` на реальный Chat ID.
4. Проверить узел **Webhook — Lead Form**:
   - Path: `ai-petrzart-lead`;
   - **Allowed Origins (CORS)**: `https://ai.petrzart.ru`.
5. **Activate** workflow.
6. Скопировать **Production URL** (вид: `https://<ваш-n8n>/webhook/ai-petrzart-lead`).

---

## 4. Подключение сайта

В [`index.html`](../index.html) заменить placeholder:

```js
const webhookUrl = 'ВАША_ССЫЛКА_ИЗ_N8N';
```

на Production URL из n8n. Redeploy сайта в Dokploy.

---

## 5. Тестирование

### curl (form-urlencoded, как браузер)

```bash
curl -X POST "https://<ваш-n8n>/webhook/ai-petrzart-lead" \
  -d "name=Тест" \
  -d "contact=@testuser" \
  -d "task=Проверка формы" \
  -d "source=ai.petrzart.ru" \
  -d "created_at=2026-05-23T12:00:00.000Z"
```

Ожидание: HTTP 200, запись в NocoDB, сообщение в Telegram.

### Браузер

1. Открыть https://ai.petrzart.ru
2. «Обсудить задачу» → заполнить форму → Отправить
3. Alert «Заявка успешно отправлена», запись в NocoDB

---

## Старые / тестовые workflow

При настройке могли остаться неактивные или конфликтующие workflow (`AI Petrzart - Lead Form`, `...-v2`, `...-Test` и т.д.). В n8n UI **деактивируйте или удалите** лишние, оставьте только **AI Petrzart - Lead Form PROD**.

---

## Если CORS ошибка

Симптом в DevTools (Console / Network): `Access to fetch ... has been blocked by CORS policy` или failed preflight (OPTIONS).

### 1. Webhook node — Allowed Origins

- Открыть узел **Webhook — Lead Form**.
- **Allowed Origins (CORS)**: точно `https://ai.petrzart.ru` (без слэша в конце, без `http://` если сайт на HTTPS).
- Сохранить и **переактивировать** workflow.

### 2. Respond to Webhook — headers

- Узлы **Respond — Success** и **Respond — Error** должны возвращать:
  - `Access-Control-Allow-Origin: https://ai.petrzart.ru`
  - `Access-Control-Allow-Methods: POST, OPTIONS`
- После правки — снова Activate workflow.

### 3. Reverse proxy / Dokploy / Traefik

- Убедиться, что OPTIONS-запросы доходят до n8n (не блокируются на прокси).
- Проверить, что n8n доступен по HTTPS с валидным сертификатом.
- В Traefik/Nginx не должно быть правил, отрезающих CORS-заголовки ответа n8n.

### 4. Формат отправки с сайта

- Форма должна использовать **URLSearchParams** или **FormData**.
- **Не** задавать вручную `Content-Type: application/json` — это вызывает CORS preflight.
- В `fetch` достаточно: `{ method: 'POST', body: params }` без блока `headers`.

Если после всех проверок preflight всё ещё падает — временно протестируйте curl (раздел 5) и убедитесь, что проблема именно в браузере/CORS, а не в самом workflow.

---

## Поля формы → workflow

| Поле формы | Параметр POST |
|------------|---------------|
| Имя | `name` |
| Контакт | `contact` |
| Задача | `task` |
| (авто) | `source` = `ai.petrzart.ru` |
| (авто) | `created_at` = ISO datetime |

Поле `consent` проверяется только на клиенте и в webhook не отправляется.
