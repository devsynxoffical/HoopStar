# BallChart Flow Document

## 1) Product Flow Overview

BallChart is a role-based basketball management app with 3 core personas:

- `admin` (academy owner)
- `coach` / `head_coach` / `assistant_coach` (staff)
- `player`

Main system flow:

1. Authentication and profile loading
2. Role-based dashboard routing
3. Team/staff/player management (admin + permitted staff)
4. Battle management (staff create, players join)
5. Strategy management (staff publish video strategy, players watch)

---

## 2) Entry and Routing Flow

### App start

1. `SplashScreen` checks token/session.
2. If logged in, app fetches fresh profile (`/auth/profile`).
3. App routes by role:
   - `admin` -> `AcademyDashboardScreen`
   - others -> `AppNavigator` tabs
4. If no valid session -> `LoginScreen`.

### Why role mix is prevented

- Profile is force-refreshed at startup/navigation.
- Screen tabs are rebuilt from resolved backend role.
- Cross-role email reuse is blocked in backend for create/update paths.

---

## 3) Authentication Flow

### Login

- Screen: `LoginScreen`
- ViewModel: `AuthViewmodel`
- Repository: `AuthRepository`
- Backend endpoints attempted by auth repository:
  - `/auth/admin/login`
  - `/auth/coach/login`
  - `/auth/player/login`
- On success:
  - token saved
  - profile loaded
  - role-based navigation applied

### Signup

- Current app signup screen is academy-oriented (`admin` registration flow).

### Forgot password

- `EnterEmailScreen` -> `EnterOtpScreen` -> `EnterNewPasswordScreen`
- UI flow exists and routes correctly.

---

## 4) Role-Based Screen Flow

## Admin Flow (`admin`)

Primary screen: `AcademyDashboardScreen`

Tabs/sections inside dashboard:

- Dashboard overview
- Teams
- Staff
- Admin profile

Admin can:

- Create/edit/delete teams
- Assign coach and assistant coach to teams
- Create/edit/delete staff
- Configure staff permissions
- Create/edit/delete players
- Update academy profile/logo

Key API usage:

- `/auth/admin/overview`
- `/auth/team/create`
- `/auth/team/:id` (PUT/DELETE)
- `/auth/team/:id/leads`
- `/auth/staff/create`
- `/auth/staff/:id` (PUT/DELETE)
- `/auth/player/create`
- `/auth/player/:id` (PUT/DELETE)
- `/auth/admin/profile`

---

## Staff Flow (`coach`, `head_coach`, `assistant_coach`)

Primary container: `AppNavigator`

Main tabs:

- Home (`CoachHomeScreen`)
- Battle (`BattleScreen`)
- Strategy (`StrategyScreen`)
- Profile (`ProfileScreen`)
- plus `Manage` tab for `head_coach`

Staff capabilities:

- Battle create (all staff roles)
- Strategy publish (all staff roles)
- Player actions only if assigned permissions allow
- Team visibility scoped by team assignment

---

## Player Flow (`player`)

Primary container: `AppNavigator`

Main tabs:

- Home (`HomeScreen`)
- Battle (`BattleScreen`)
- Strategy (`StrategyScreen`)
- Profile (`ProfileScreen`)

Player capabilities:

- Join battles from same academy scope
- View/watch strategies
- View own team, coaches, teammates, profile/stats

No create access for battle/strategy/player-management actions.

---

## 5) Battle Feature Flow

Screen: `BattleScreen`

### Data lifecycle

1. Load battles from `/battles` (protected).
2. Show filtered live list (all/upcoming/joined/hosting).
3. Auto refresh via polling.

### Action rules

- Create battle: `admin/head_coach/coach/assistant_coach`
- Join battle: allowed for same academy and pending status only
- Host cannot re-join own battle

### Backend protections

- Academy scope validation on read/join/create
- Role-based create control

---

## 6) Strategy Feature Flow

Screen: `StrategyScreen`

### Data lifecycle

1. Load strategy feed from `/strategies` (protected).
2. Filter by category (`all/offense/defense/drills/general`).
3. Auto refresh via polling.

### Action rules

- Publish strategy: `admin/head_coach/coach/assistant_coach`
- Player: watch-only

### Strategy payload

- title
- category
- source type (`text` or `voice`)
- source text/transcript
- `videoUrl`

### Playback

- In-app video dialog using `video_player`.

---

## 7) Team and Staff Management Flow

## Team lifecycle

1. Create team
2. Edit team details (name, age group, color, logo)
3. Assign leads (coach/assistant)
4. Delete team (with confirmation)

### Delete behavior

- Team is removed from academy list.
- Team assignment references in staff are cleaned.

## Staff lifecycle

1. Create staff with role + permissions + team assignments
2. Update profile/role/teams/permissions
3. Delete staff and cleanup team lead bindings

---

## 8) Player Management Flow

Player lifecycle:

1. Create player (optionally attach to team)
2. Update player details (username, email, position, age range, password reset)
3. Delete player (also removed from team rosters)

Permission gates:

- `createPlayer`
- `updatePlayer`
- `deletePlayer`

Admin/head coach have full access; coach/assistant depend on granted permissions.

---

## 9) Data Integrity and Security Rules

- Token-based protected APIs.
- Role-based endpoint guards.
- Academy-scope filtering on battle/strategy/dashboard data.
- Email uniqueness enforced across role collections to avoid profile crossover.
- Timeout handling added in API service for unstable network conditions.

---

## 10) Known Operational Notes

- On Windows builds, Kotlin incremental cache can fail with cross-drive root issue.
- Workaround is configured in `android/gradle.properties`:
  - `kotlin.incremental=false`
  - `kotlin.incremental.useClasspathSnapshot=false`
  - `kotlin.compiler.execution.strategy=in-process`

---

## 11) Suggested UAT Checklist (Final Validation)

1. Login as `admin` -> verify academy dashboard actions.
2. Create coach + assistant with different permissions.
3. Login as coach/assistant -> verify only allowed actions show/work.
4. Create player and confirm:
   - player sees player home/profile
   - no coach/assistant profile mixing
5. Staff creates battle -> player joins successfully.
6. Staff publishes strategy -> player watches video.
7. Delete team/staff/player and verify cleanup on UI + backend data.

---

## 12) Current Project Completion Status

- Core role flows: implemented
- Team/staff/player management: implemented
- Battle live flow: implemented
- Strategy live flow with video playback: implemented
- Role-mix and overflow fixes: implemented

If needed, next phase can include:

- push notifications
- real OTP backend integration
- analytics dashboards
- CI/CD + automated regression tests
