# UI Context

## Theme

Mobile-first. The design language should feel energetic and professional — suited to a sports talent platform. Use a light blue primary surface with vivid accent colors to highlight key actions (shortlist, send interest, boost post). Keep the UI clean and scannable: recruiters are browsing many profiles quickly and athletes want their content front and center.

---

## Colors

All components must use these CSS custom property tokens. No hardcoded hex values anywhere in the codebase.

| Role              | CSS Variable         | Value    |
| ----------------- | -------------------- | -------- |
| Page background   | `--bg-base`          | `#F0F8FF` |
| Surface           | `--bg-surface`       | `#FFFFFF` |
| Surface alt       | `--bg-surface-alt`   | `#E8F2FB` |
| Primary text      | `--text-primary`     | `#1A2332` |
| Muted text        | `--text-muted`       | `#6B7B8D` |
| Primary accent    | `--accent-primary`   | `#4A90D9` |
| Accent light      | `--accent-light`     | `#7AB3E8` |
| Accent dark       | `--accent-dark`      | `#2B6CB0` |
| Border            | `--border-default`   | `#D0DAE5` |
| Border focus      | `--border-focus`     | `#4A90D9` |
| Error             | `--state-error`      | `#E74C3C` |
| Success           | `--state-success`    | `#2ECC71` |
| Warning           | `--state-warning`    | `#F39C12` |
| Badge: self-reported   | `--badge-self`  | `#F39C12` |
| Badge: coach-endorsed  | `--badge-coach` | `#1ABC9C` |
| Badge: club-verified   | `--badge-club`  | `#F1C40F` |
| Badge: verified account | `--badge-verified` | `#27AE60` |

---

## Typography

| Role      | Font              | CSS Variable  |
| --------- | ----------------- | ------------- |
| UI text   | Inter              | `--font-sans` |

---

## Border Radius

| Context           | Class            |
| ----------------- | ---------------- |
| Inline / small UI | `rounded-md`     |
| Cards / panels    | `rounded-xl`     |
| Modals / overlays | `rounded-2xl`    |
| Avatar / badges   | `rounded-full`   |

---

## Component Library

Custom Flutter widgets in `lib/shared/widgets/` — TrustBadge, AthleteCard, OpportunityCard, VideoPlayer.

---

## Icons

Material Design icons via Flutter's built-in `Icons` class. Sizes: `sm` for inline, `md` for buttons and nav items.

---

## Navigation Structure

### Top-Level Navigation (mobile bottom tab bar)

| Tab         | Route            | Visible to              |
| ----------- | ---------------- | ----------------------- |
| Discover    | `/discover`      | All authenticated       |
| Opportunities | `/opportunities` | All authenticated      |
| Notifications | `/notifications` | All authenticated      |
| Profile     | `/profile`       | All authenticated       |
| Search      | `/search`        | Recruiters, Clubs       |

### Auth Flow

Unauthenticated users land on a public home/landing screen. After sign-up they complete role-specific onboarding (athlete profile setup, or recruiter/club verification submission). After sign-in they are redirected to `/discover`. Guests browsing public profiles are shown a registration prompt when they attempt any interaction.

---

## Pages / Screens

> This is a mobile-first app. All views below are mobile screens unless noted.

---

### Landing / Home — `/`

**Purpose:** Public-facing entry point. Explains what Play Smart is and drives sign-up.

**Key UI Elements:**
- Hero with tagline and CTA buttons (Sign Up as Athlete / Sign Up as Recruiter or Club)
- Brief platform explanation (discovery bridge concept)
- Trust badge explanation section
- Footer with links

**States:**
- Default: marketing content shown
- Authenticated: redirect to `/discover`

---

### Sign Up — `/signup`

**Purpose:** Account creation with role selection.

**Key UI Elements:**
- Role selector: Athlete / Recruiter or Scout / Club or Organisation
- Standard fields: name, email, password
- For recruiters: prompt to upload credentials after sign-up
- For clubs: prompt to upload registration documents after sign-up
- Under-18 age gate (date of birth field)

**States:**
- Default: role selector shown first, then form
- Submitting: loading state on submit button
- Error: inline field validation errors

---

### Sign In — `/signin`

**Purpose:** Login for all account types.

**Key UI Elements:**
- Email and password fields
- Forgot password link
- Sign up prompt

---

### Athlete Profile Setup — `/onboarding/athlete`

**Purpose:** First-time athlete profile creation after sign-up.

**Key UI Elements:**
- Sport(s) selector (multi-select)
- Position(s) selector
- Age, height, weight, dominant foot/hand
- Current or most recent team / academy
- Location: country and city
- Short bio text field
- Availability status selector: Open to Trials / Currently Contracted / Not Available
- Profile photo upload

**States:**
- Multi-step flow with progress indicator
- Incomplete: can save draft and return

---

### Recruiter / Club Verification — `/onboarding/verification`

**Purpose:** Credential or document submission for verification approval.

**Key UI Elements:**
- File upload for credentials (recruiters) or registration documents (clubs)
- Status indicator: Pending Review / Approved / Rejected
- Explanation of what features unlock after approval

**States:**
- Pending: features locked, status message shown
- Approved: redirected to full experience
- Rejected: re-submission prompt with reason

---

### Discover Feed — `/discover`

**Purpose:** Main feed for all authenticated users. Shows athlete content and highlights.

**Key UI Elements:**
- Content cards: video/photo thumbnails, moment type tag, athlete name and sport, trust badges
- Quick shortlist button (recruiters/clubs)
- Tap to open full athlete profile

**States:**
- Default: feed of content
- Empty: prompt to complete profile or adjust preferences
- Loading: skeleton cards

---

### Athlete Search — `/search` (Recruiters and Clubs only)

**Purpose:** Advanced search and filtering of athlete profiles.

**Key UI Elements:**
- Filter panel: sport, position, age range, location, availability status, trust badge level
- Map-based view toggle
- Athlete cards in results: photo, name, sport, position, key attributes, trust badges
- Quick shortlist button
- Recommended athletes feed (based on saved preferences)

**States:**
- Default: recommended feed shown before first search
- Results: filtered list
- Empty results: no match message with filter adjustment suggestions
- Map view: pins on map, tap to open athlete card

---

### Athlete Profile (Public View) — `/athlete/[id]`

**Purpose:** Full athlete profile as seen by recruiters, clubs, and guests.

**Key UI Elements:**
- Header: photo, name, sport, position, availability badge, location
- Trust badges (Self-Reported / Coach-Endorsed / Club-Verified)
- Highlight video reel (if available)
- Content feed: videos and photos with moment type tags
- Achievements section with trust badge state per achievement
- Stats: height, weight, dominant foot/hand, team
- Shortlist button (recruiters/clubs on paid tier)
- Send Expression of Interest button (recruiters/clubs on paid tier)
- Message Request button (after expression of interest)

**States:**
- Default: full profile shown
- Guest: contact and shortlist actions replaced with sign-up prompt
- Free recruiter: contact and shortlist actions locked with upgrade prompt

---

### Athlete Own Profile — `/profile`

**Purpose:** Athlete's view of their own profile. Edit and content management.

**Key UI Elements:**
- Profile completeness indicator
- Edit profile button
- Upload content button (video, photo, post)
- Achievements list with add/edit
- Analytics section (free: aggregate views; premium: full viewer identity)
- Availability status quick-edit

**States:**
- Default: profile as others see it, with edit controls overlaid
- Premium: full analytics visible
- Free: analytics teased with upgrade prompt

---

### Content Upload — `/upload`

**Purpose:** Athlete uploads a video, photo, or post.

**Key UI Elements:**
- Media type selector: Video / Photo / Post
- File picker or camera
- Title and description fields
- Moment type tag selector: Goal / Assist / Sprint / Tackle / Save
- Upload progress indicator

**States:**
- Uploading: progress bar, compression note for video
- Complete: preview of uploaded content
- Error: retry option with error message

---

### Shortlists — `/shortlists` (Recruiters and Clubs)

**Purpose:** Manage shortlisted athletes.

**Key UI Elements:**
- Multiple named lists (e.g. by sport or trial batch)
- Create / rename / delete list
- Athlete cards within each list
- Private notes per athlete
- Export to PDF button (Pro and Club Professional tier)
- Contacted / not contacted status indicator

**States:**
- Empty: prompt to search and shortlist
- List selected: athlete cards shown
- Free recruiter: shortlist locked past limit with upgrade prompt

---

### Opportunities — `/opportunities`

**Purpose:** Browse and post trial and open day listings.

**Key UI Elements (athletes):**
- Trial cards: sport, position, location, date, organiser, eligibility criteria
- Apply button (opens message request flow)
- Filter by sport and location

**Key UI Elements (recruiters/clubs):**
- My Postings tab: active and closed postings
- Create Posting button
- Posting form: title, sport, position, age range, location, date, description, capacity limit
- Applicant list per posting with accept/decline

**States:**
- No postings: empty state with create prompt (for recruiters/clubs)
- Capacity reached: posting marked closed automatically

---

### Messaging — `/messages`

**Purpose:** Direct messaging between athletes and recruiters/clubs.

**Key UI Elements:**
- Message request queue (athlete view): pending requests with accept/decline
- Conversation list
- Conversation thread: messages, timestamps, read indicators

**States:**
- Pending request (athlete): accept/decline prompt shown before thread opens
- Empty: no messages yet

---

### Notifications — `/notifications`

**Purpose:** All notification events in one place.

**Key UI Elements:**
- Notification list: type icon, description, timestamp, unread indicator
- Types: Profile view, Shortlisted, Trial match, Endorsement request, Message request

**States:**
- Empty: no notifications yet
- Unread: badge count on tab icon

---

### Payments and Subscription — `/account/billing`

**Purpose:** Manage subscription tier and purchases.

**Key UI Elements:**
- Current plan and renewal date
- Upgrade / downgrade options with feature comparison
- Post Boost purchase (athletes)
- Payment method selector: MTN Mobile Money, Airtel Money, Visa/Mastercard
- Transaction history and invoice download

**States:**
- Free tier: upgrade CTA prominent
- Active subscription: manage and cancel options
- Payment in progress: loading state
- Failed payment: grace period warning with retry option

---

## Key Components

---

### TrustBadge

**Used on:** Athlete profile (public and own view), athlete cards in search results and shortlists

**Purpose:** Displays the trust level of an achievement or the overall profile

**Props / Inputs:**
- `level` — `"self-reported" | "coach-endorsed" | "club-verified"`
- `size` — `"sm" | "md"`

**States:**
- Renders different icon, label, and color per level using badge CSS tokens

---

### AthleteCard

**Used on:** Discover feed, search results, shortlists, recommended feed

**Purpose:** Summary card for an athlete — used anywhere profiles are listed

**Props / Inputs:**
- `athlete` — name, photo, sport, position, availability, top trust badge level
- `showShortlistAction` — boolean (only on recruiter/club views)

**States:**
- Default, Shortlisted (filled icon), Locked (free tier)

---

### OpportunityCard

**Used on:** Opportunities feed

**Purpose:** Summary of a trial or open day posting

**Props / Inputs:**
- `opportunity` — title, sport, position, location, date, organiser, eligibility, capacity remaining
- `showApplyAction` — boolean (athletes only)

**States:**
- Open, Closed (capacity reached or expired)

---

### VideoPlayer

**Used on:** Athlete profile, discover feed

**Purpose:** In-app video playback for highlight clips and training videos

**Props / Inputs:**
- `url` — file storage URL
- `momentTag` — optional label overlay
- `thumbnail` — poster image

**States:**
- Idle (poster shown), Playing, Error (failed to load)

---

## Layout Patterns

| Pattern              | Description                                                               |
| -------------------- | ------------------------------------------------------------------------- |
| Mobile bottom tabs   | Primary navigation: Discover, Opportunities, Notifications, Profile       |
| Full-screen card     | Athlete profile: full-width photo header, scrollable content below        |
| Filter sheet         | Bottom sheet on mobile for search filter options                          |
| Modal overlay        | Message request accept/decline, post boost purchase, opportunity creation |
| Toast notifications  | Brief feedback for actions: shortlisted, message sent, upload complete    |
| Empty state panel    | Centered illustration + heading + CTA for all empty states                |