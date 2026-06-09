# PlaySmart

## Overview

Play Smart is a talent discovery platform for athletes across Uganda and the wider region. Athletes create profiles, upload highlight videos, and post content to get noticed by recruiters, scouts, and clubs. The platform acts as a discovery bridge — not a hiring system. Real evaluation happens off-platform through trials and direct contact. Recruiters use Play Smart to find and shortlist candidates; athletes use it to access opportunities they might not otherwise reach.

## Goals

1. Give grassroots athletes a professional online presence to be discovered by verified recruiters and clubs
2. Give recruiters and clubs powerful search, filtering, and shortlisting tools to find the right athletes efficiently
3. Build a trust model that works at the grassroots level where formal verification is impractical — using tiered badges (Self-Reported, Coach-Endorsed, Club-Verified) rather than hard verification
4. Generate sustainable revenue through tiered subscription plans and one-off boosts for athletes, recruiters, and clubs

## User Roles

- **Athletes** — primary users; create profiles, upload content, receive opportunities
- **Recruiters and Scouts** — verified professionals; browse, shortlist, contact, post trials
- **Clubs and Organisations** — verified institutional accounts; confirm rosters, post opportunities, assign scouts
- **Guests** — unauthenticated visitors; browse public profiles and content only

## Core User Flow

### Athlete
1. Athlete signs up and creates a profile (sport, position, age, location, availability status)
2. Athlete uploads match highlights, training clips, photos, and posts with moment tags
3. Athlete lists achievements (Self-Reported); coaches or clubs endorse/confirm them
4. Recruiter finds the athlete via search or the recommended feed
5. Recruiter sends an expression of interest or trial opportunity match notification
6. Athlete receives and accepts or declines message request
7. Conversation opens and off-platform contact follows

### Recruiter
1. Recruiter signs up and submits credentials for verification
2. Recruiter searches and filters athletes by sport, position, age, location, availability, and trust badge
3. Recruiter shortlists athletes into organised lists and adds private notes
4. Recruiter sends expressions of interest or posts trial opportunities
5. Recruiter exports athlete profiles as PDFs and tracks outreach history

## Features

### Athlete Profiles
- Sport(s), position(s), age, height, weight, dominant foot/hand, current team, location, bio, availability status
- Upload match highlights, training clips, photos, and short posts
- Content tagged with moment types: Goal, Assist, Sprint, Tackle, Save
- Self-Reported achievements with Coach-Endorsed and Club-Verified trust badges
- Availability status: Open to Trials / Currently Contracted / Not Available

### Athlete Analytics and Visibility
- Free tier: see that someone viewed your profile (not who)
- Premium tier: see exactly who viewed, which org, when shortlisted, post performance, overall reach
- Post Boost: promotes a single post to the top of recruiter feeds for 7 days

### Recruiter Tools
- Search and filter by sport, position, age range, location, availability, and trust badge level
- Map-based view to find athletes in a geographic area
- Recommended athletes feed based on saved preferences and history
- Shortlisting into organised lists with private notes
- Export athlete profiles as PDFs
- Send expressions of interest; initiate direct messaging after athlete accepts
- Post trial opportunities with eligibility criteria and capacity limits

### Club Tools
- All recruiter search and filter tools
- Roster confirmation: confirm current and past players (grants Club-Verified badge)
- Assign internal scouts operating under the club account
- Post trials, open days, and scholarship opportunities
- Broadcast announcements to followers
- Manage incoming applications with eligibility criteria and capacity controls

### Messaging and Notifications
- Athlete-controlled message requests: athletes must accept before a conversation opens
- Notifications: profile views, shortlisting, trial matches, endorsement requests, message requests

### Payments
- Athlete: Free tier, Premium Monthly/Annual subscription, individual Post Boosts
- Recruiter: Free (browse only), Basic Plan, Pro Plan
- Club: Grassroots Plan, Professional Plan, custom enterprise pricing
- Payment methods: MTN Mobile Money, Airtel Money, Visa/Mastercard (via Pesapal or Flutterwave), Stripe for international cards
- Automatic receipts and invoices by email; 3-day grace period on failed payments

## Scope

### In Scope
- Athlete, recruiter, club, and guest account types
- Profile creation and content management (video, photos, posts)
- Tiered trust badge system (Self-Reported, Coach-Endorsed, Club-Verified)
- Search, filtering, shortlisting, and recommended feeds
- Direct messaging with athlete-controlled accept/decline
- Trial and opportunity posting with eligibility criteria and capacity limits
- Analytics and visibility features (free and premium)
- Post Boost feature
- Subscription and one-off payment flows via Pesapal, Flutterwave, and Stripe
- Mobile-first (Android and iOS), with video compression for low-bandwidth environments
- Privacy controls (hide location, restrict content visibility)
- Safeguards for users under 18
- Public browsable profiles for organic discovery

### Out of Scope
- Formal verification of athlete claims (by design — replaced by the trust badge model)
- In-platform trial scheduling or hiring workflows
- Match or performance data integrations with external sports databases
- Live streaming

## Success Criteria

1. An athlete can create a full profile, upload a highlight video, and receive a message request from a recruiter
2. A recruiter can filter athletes by sport, position, and location, shortlist candidates, and send an expression of interest
3. A club can confirm a player on their roster and the Club-Verified badge appears on the athlete's profile
4. A payment completes successfully via MTN Mobile Money or Flutterwave and the correct tier is activated
5. A guest can browse public athlete profiles and is prompted to register when attempting to interact
6. Video uploads are compressed on upload and playback is acceptable on a typical Ugandan mobile data connection
