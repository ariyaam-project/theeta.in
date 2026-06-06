-- Local-only seed data so restaurant/search/surprise endpoints return real rows.
-- Run: npm run db:seed:local

INSERT OR IGNORE INTO creators (id, ig_user_id, username, full_name, is_verified)
VALUES ('seed_creator_1', 'ig_1', 'kozhikode_foodie', 'Kozhikode Foodie', 0);

INSERT OR IGNORE INTO reels (id, ig_shortcode, url, caption, thumbnail_url, creator_id, like_count, comment_count, status)
VALUES ('seed_reel_1', 'Cxyz123', 'https://www.instagram.com/reel/Cxyz123/',
        'Best shawarma in Kozhikode', 'https://media.theta.in/seed/thumb1.jpg',
        'seed_creator_1', 12400, 318, 'complete');

INSERT OR IGNORE INTO transcripts (id, reel_id, language, text, model_used)
VALUES ('seed_tr_1', 'seed_reel_1', 'en',
        'This hidden shawarma spot near South Beach serves one of the best chicken shawarmas in Kozhikode.',
        'whisper-large-v3');

INSERT OR IGNORE INTO restaurants
  (id, name, slug, google_place_id, address, area, city, lat, lng, google_maps_url, phone, cuisine, price_level, status)
VALUES ('seed_rest_1', 'Al Reem Kuzhi Mandi', 'al-reem-kuzhi-mandi', 'gpid_seed_1',
        'South Beach Rd, Kozhikode, Kerala', 'South Beach', 'Kozhikode',
        11.2519, 75.7682, 'https://maps.google.com/?cid=seed', '+910000000000',
        '["Arabic","Mandi"]', 2, 'active');

INSERT OR IGNORE INTO restaurant_reels (id, restaurant_id, reel_id, confidence)
VALUES ('seed_rr_1', 'seed_rest_1', 'seed_reel_1', 0.94);

INSERT OR IGNORE INTO restaurant_photos (id, restaurant_id, r2_key, source, source_reel_id)
VALUES ('seed_ph_1', 'seed_rest_1', 'seed/thumb1.jpg', 'reel', 'seed_reel_1');

INSERT OR IGNORE INTO comments (id, reel_id, ig_comment_id, author_username, text, like_count)
VALUES ('seed_cm_1', 'seed_reel_1', 'igc_1', 'foodlover', 'Huge portions, great value!', 22),
       ('seed_cm_2', 'seed_reel_1', 'igc_2', 'hungrymalu', 'Long wait on weekends though', 8);

INSERT OR IGNORE INTO comment_analysis (id, comment_id, sentiment, score, topics)
VALUES ('seed_ca_1', 'seed_cm_1', 'positive', 0.91, '["portion","value"]'),
       ('seed_ca_2', 'seed_cm_2', 'negative', 0.40, '["wait"]');

INSERT OR IGNORE INTO trust_scores (id, restaurant_id, score, audience_signal, historical_signal)
VALUES ('seed_ts_1', 'seed_rest_1', 87,
        '{"positive":0.82,"negative":0.18}', '{"creators":4,"reels":6}');

INSERT OR IGNORE INTO ai_summaries
  (id, restaurant_id, trust_score, common_praise, common_complaints, best_dishes, verdict, model_used)
VALUES ('seed_sum_1', 'seed_rest_1', 87,
        '["Large portions","Good value"]',
        '["Weekend waiting time","Parking issues"]',
        '["Chicken Kuzhi Mandi","Mutton Mandi"]',
        'Recommended for groups and families.', 'claude-opus-4-8');
