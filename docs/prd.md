# Theta.in - Product Requirements Document (V1)

## Overview

Theta is a food discovery platform that converts Instagram food reels into trustworthy restaurant recommendations.

Users can submit Instagram reel links, and Theta analyses the reel, extracts restaurant information, understands creator sentiment, analyses audience comments, and generates an evidence-based summary of whether the place is genuinely worth visiting.

The goal is to help users discover good food spots without spending hours scrolling through Instagram.

---

# Problem Statement

Food discovery today happens largely on Instagram.

However:

* Users need to scroll through hundreds of reels.
* Many food reels are sponsored promotions.
* It is difficult to identify genuine recommendations.
* Valuable information is scattered across captions, videos, audio, and comments.
* There is no structured database of food recommendations extracted from social content.

Users want a quick answer:

> Is this place actually worth visiting?

---

# Vision

Build the most trusted food discovery platform powered by social content and community validation.

Instead of showing reels, Theta shows insights.

---

# Target Users

## Primary

Food enthusiasts who discover restaurants through Instagram.

## Secondary

* Travellers
* Students
* Friends deciding where to eat
* Food bloggers
* Local communities

---

# MVP Goals

### Goal 1

Convert Instagram food reels into structured restaurant information.

### Goal 2

Generate trust signals from community comments.

### Goal 3

Create a searchable database of restaurants.

### Goal 4

Allow users to save and organise discoveries.

---

# User Flow

## Submit Reel

1. User pastes Instagram Reel URL.
2. Theta processes the reel.
3. Theta extracts information.
4. Restaurant page is generated.

---

## Processing Pipeline

### Step 1 - Reel Extraction

Extract:

* Reel URL
* Caption
* Thumbnail
* Audio
* Creator information

---

### Step 2 - Audio Analysis

Generate transcript from reel audio.

Example:

> "This hidden shawarma spot near South Beach serves one of the best chicken shawarmas in Kozhikode."

Store transcript.

---

### Step 3 - Restaurant Detection

Extract:

* Restaurant name
* Area
* Cuisine
* Mentioned dishes

Sources:

* Caption
* Transcript
* OCR from video frames
* Creator tags
* Location tags

---

### Step 4 - Place Resolution

Search existing Theta database.

If restaurant does not exist:

Use Google Places API.

Store:

* Name
* Address
* Coordinates
* Google Maps link
* Phone number if available

---

### Step 5 - Comment Analysis

Fetch top comments.

Analyse:

* Positive sentiment
* Negative sentiment
* Common complaints
* Common praise

Examples:

Positive:

* Great food
* Affordable
* Consistent quality

Negative:

* Overpriced
* Long waiting time
* Sponsored review
* Poor service

---

### Step 6 - AI Summary

Generate structured summary.

Example:

## Al Reem Kuzhi Mandi

Trust Score: 87/100

Common Praise:

* Large portions
* Good value

Common Complaints:

* Weekend waiting time
* Parking issues

Overall Verdict:
Recommended for groups and families.

---

# Restaurant Page

Each restaurant page contains:

## Basic Information

* Name
* Photos
* Address
* Google Maps link

## Social Insights

* Number of reels analysed
* Number of creators mentioning restaurant

## Sentiment

* Positive score
* Negative score

## Highlights

* Best dishes
* Common complaints

## Source Reels

List of analysed reels.

---

# Saved Lists

Users can create lists.

Examples:

* Best Shawarmas
* Kozhikode Food Trip
* Places To Try
* Budget Eats

Users can:

* Save restaurants
* Share lists
* Collaborate later

---

# Surprise Me Feature

User selects:

* Location
* Cuisine
* Budget

Theta recommends a random restaurant from trusted places.

Purpose:

Reduce decision fatigue.

---

# Community Features (Phase 2)

Users can:

* Mark restaurant as visited
* Add quick feedback
* Add photos
* Confirm recommendations

Not intended to become a social network.

Focus remains food discovery.

---

# Trust Engine

The core differentiator.

Signals:

## Creator Signals

* Paid partnership labels
* Sponsored hashtags
* Promotional wording

## Audience Signals

* Negative comments
* Complaints
* Authentic user experiences

## Historical Signals

* Multiple creators recommending same place
* Consistent sentiment across reels

Generate:

Trust Score

Range:

0-100

---

# Success Metrics

## First 90 Days

* 1,000 restaurants indexed
* 5,000 reels analysed
* 1,000 registered users
* 30% returning users

---

# Technical Architecture

## Frontend

* Next.js
* Tailwind
* Mobile-first

## Backend

* Django
* PostgreSQL

## Processing

* Cloudflare Workers
* Queue-based processing

## AI

* Audio transcription
* Sentiment analysis
* Entity extraction

## External Services

* Google Places API
* Instagram scraping provider
* Maps integration

---

# Future Features

## Creator Credibility Score

Measure how often creator recommendations match community sentiment.

## Food Trails

Curated food routes.

Example:

* Kozhikode Shawarma Trail
* Kochi Cafe Trail

## AI Food Assistant

Ask:

> "Suggest a good mandi place near Kakkanad under ₹500."

## Trend Detection

Detect restaurants gaining popularity before they become mainstream.

---

# Non Goals

Theta is not:

* A social media platform
* A food delivery app
* A restaurant reservation platform
* A creator monetisation platform

Theta focuses on trusted food discovery.
