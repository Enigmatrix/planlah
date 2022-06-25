-- the irony of putting power-keg political features in one place and doing nothing on conflict ;)
insert into users (id, username, name, firebase_uid, gender, town, attractions, food, image_link) values (1, 'maga', 'Donald Trump', 'firebaseUid1', 'Male', 'Bukit Batok', '{0.0}', '{0.0}', 'https://ichef.bbci.co.uk/news/976/cpsprodpb/41FB/production/_113919861_hi045965426.jpg') ON CONFLICT DO NOTHING;
insert into users (id, username, name, firebase_uid, gender, town, attractions, food, image_link) values (2, 'dukenukem', 'Kim Jong-un', 'firebaseUid2', 'Male', 'Choa Chu Kang', '{0.0}', '{0.0}', 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTLONqKXoKjoGjX94QFDoqwW7Jk8xFfy8x3RA&usqp=CAU') ON CONFLICT DO NOTHING;
insert into users (id, username, name, firebase_uid, gender, town, attractions, food, image_link) values (3, 'winnie', 'Xi Jinping', 'firebaseUid3', 'Male', 'Clementi', '{0.0}', '{0.0}', 'https://external-preview.redd.it/lqDFDXXvfqMs7kyQ9y1FrGcQzdCE23uMPlcxFqo_oYE.png?auto=webp&s=02b97678eaaa104d58af8e3a5b59563113d7a5b9') ON CONFLICT DO NOTHING;
insert into users (id, username, name, firebase_uid, gender, town, attractions, food, image_link) values (4, 'merkel', 'Angela Merkel', 'firebaseUid4', 'Female', 'Geylang', '{0.0}', '{0.0}', 'https://assets.weforum.org/sf_account/image/-Iz2VwsxPVkx3GQrc5m3oWD1mI2d4yD2liRq60jnV04.jpg') ON CONFLICT DO NOTHING;
insert into users (id, username, name, firebase_uid, gender, town, attractions, food, image_link) values (5, 'moneybags', 'Mohammed bin Rashid Al Maktoum', 'firebaseUid5', 'Male', 'Kallang', '{0.0}', '{0.0}', 'https://upload.wikimedia.org/wikipedia/commons/d/da/Mohammed_bin_Rashid_Al_Maktoum_%2815-02-2021%29_%28cropped%29.jpg') ON CONFLICT DO NOTHING;
insert into users (id, username, name, firebase_uid, gender, town, attractions, food, image_link) values (6, 'modi', 'Narendra Modi', 'firebaseUid6', 'Male', 'Bedok', '{0.0}', '{0.0}', 'https://upload.wikimedia.org/wikipedia/commons/c/c0/Official_Photograph_of_Prime_Minister_Narendra_Modi_Potrait.png') ON CONFLICT DO NOTHING;
insert into users (id, username, name, firebase_uid, gender, town, attractions, food, image_link) values (7, 'daddy_vlady', 'Vladimir Putin', 'firebaseUid7', 'Male', 'Outram', '{0.0}', '{0.0}', 'https://wompampsupport.azureedge.net/fetchimage?siteId=7575&v=2&jpgQuality=100&width=700&url=https%3A%2F%2Fi.kym-cdn.com%2Fphotos%2Fimages%2Fnewsfeed%2F001%2F240%2F339%2Ffa1.jpg') ON CONFLICT DO NOTHING;

insert into groups (id, name, description, owner_id, image_link) values (1, 'food wars', '''make food not war'' said no one ever.', NULL, 'https://www.kindpng.com/picc/m/411-4117993_food-wars-shokugeki-no-soma-logo-hd-png.png') ON CONFLICT DO NOTHING;
insert into groups (id, name, description, owner_id, image_link) values (2, 'meet to eat meet', 'MEAT ONLY NO VEGGIES MUMMY CAN''T CATCH ME', NULL, 'https://image.cnbcfm.com/api/v1/image/105914693-1557930882448olivewagyu2.jpeg?v=1558105293&w=740&h=416&ffmt=webp') ON CONFLICT DO NOTHING;
insert into groups (id, name, description, owner_id, image_link) values (3, 'adventurers!', 'exploring the world, united!', NULL, 'https://www.looper.com/img/gallery/25-shows-like-adventure-time-you-should-watch-next/l-intro-1644627512.jpg') ON CONFLICT DO NOTHING;

insert into group_members (id, user_id, group_id, last_seen_message_id) values (1, 1, 1, NULL) ON CONFLICT DO NOTHING;
insert into group_members (id, user_id, group_id, last_seen_message_id) values (2, 2, 1, NULL) ON CONFLICT DO NOTHING;
insert into group_members (id, user_id, group_id, last_seen_message_id) values (3, 3, 1, NULL) ON CONFLICT DO NOTHING;
insert into group_members (id, user_id, group_id, last_seen_message_id) values (4, 7, 1, NULL) ON CONFLICT DO NOTHING;
insert into group_members (id, user_id, group_id, last_seen_message_id) values (5, 1, 2, NULL) ON CONFLICT DO NOTHING;
insert into group_members (id, user_id, group_id, last_seen_message_id) values (6, 4, 2, NULL) ON CONFLICT DO NOTHING;
insert into group_members (id, user_id, group_id, last_seen_message_id) values (7, 5, 2, NULL) ON CONFLICT DO NOTHING;
insert into group_members (id, user_id, group_id, last_seen_message_id) values (8, 6, 2, NULL) ON CONFLICT DO NOTHING;
insert into group_members (id, user_id, group_id, last_seen_message_id) values ( 9, 1, 3, NULL) ON CONFLICT DO NOTHING;
insert into group_members (id, user_id, group_id, last_seen_message_id) values (10, 2, 3, NULL) ON CONFLICT DO NOTHING;
insert into group_members (id, user_id, group_id, last_seen_message_id) values (11, 3, 3, NULL) ON CONFLICT DO NOTHING;
insert into group_members (id, user_id, group_id, last_seen_message_id) values (12, 4, 3, NULL) ON CONFLICT DO NOTHING;
insert into group_members (id, user_id, group_id, last_seen_message_id) values (13, 5, 3, NULL) ON CONFLICT DO NOTHING;
insert into group_members (id, user_id, group_id, last_seen_message_id) values (14, 6, 3, NULL) ON CONFLICT DO NOTHING;
insert into group_members (id, user_id, group_id, last_seen_message_id) values (15, 7, 3, NULL) ON CONFLICT DO NOTHING;

update groups set owner_id = 1 where id = 1;
update groups set owner_id = 5 where id = 2;
update groups set owner_id = 4 where id = 3;

insert into messages(id, content, sent_at, by_id) values (1, 'i wanna go mexico and build a wall!', now(), 1) ON CONFLICT DO NOTHING;
insert into messages(id, content, sent_at, by_id) values (2, 'message 2!', now(), 2) ON CONFLICT DO NOTHING;
insert into messages(id, content, sent_at, by_id) values (3, 'message 3!', now(), 3) ON CONFLICT DO NOTHING;
insert into messages(id, content, sent_at, by_id) values (4, 'message 4!', now(), 4) ON CONFLICT DO NOTHING;
insert into messages(id, content, sent_at, by_id) values (5, 'message 5!', now(), 5) ON CONFLICT DO NOTHING;
insert into messages(id, content, sent_at, by_id) values (6, 'message 6!', now(), 6) ON CONFLICT DO NOTHING;
insert into messages(id, content, sent_at, by_id) values (7, 'message 7!', now(), 7) ON CONFLICT DO NOTHING;
insert into messages(id, content, sent_at, by_id) values (8, 'message 8!', now(), 8) ON CONFLICT DO NOTHING;
insert into messages(id, content, sent_at, by_id) values (9, 'message 9!', now(), 9) ON CONFLICT DO NOTHING;
insert into messages(id, content, sent_at, by_id) values (10, 'message 10!', now(), 10) ON CONFLICT DO NOTHING;
insert into messages(id, content, sent_at, by_id) values (11, 'message 11!', now(), 11) ON CONFLICT DO NOTHING;
insert into messages(id, content, sent_at, by_id) values (12, 'message 12!', now(), 12) ON CONFLICT DO NOTHING;
insert into messages(id, content, sent_at, by_id) values (13, 'message 13!', now(), 13) ON CONFLICT DO NOTHING;
insert into messages(id, content, sent_at, by_id) values (14, 'message 14!', now(), 14) ON CONFLICT DO NOTHING;
insert into messages(id, content, sent_at, by_id) values (15, 'message 15!', now(), 15) ON CONFLICT DO NOTHING;

-- reset the primary key sequences for the tables
SELECT setval('users_id_seq', (SELECT MAX(id) FROM users)+1);
SELECT setval('groups_id_seq', (SELECT MAX(id) FROM groups)+1);
SELECT setval('group_members_id_seq', (SELECT MAX(id) FROM group_members)+1);
SELECT setval('messages_id_seq', (SELECT MAX(id) FROM messages)+1);