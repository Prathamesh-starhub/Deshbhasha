-- DEV ONLY: drops and rebuilds the database so the script is re-runnable.
-- Load with:  mysql --default-character-set=utf8mb4 -u root -p < db.sql
SET NAMES utf8mb4;
DROP DATABASE IF EXISTS tourism_db;
CREATE DATABASE tourism_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE tourism_db;

CREATE TABLE states (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    capital VARCHAR(100) NOT NULL,
    best_season VARCHAR(100) NOT NULL,
    quick_tip VARCHAR(255) NOT NULL,
    overview TEXT NOT NULL
) ENGINE=InnoDB;

-- tts_locale is the BCP-47 tag handed to speechSynthesis; it may differ from the
-- language itself when no voice exists (Marwari and Konkani borrow a neighbour's voice).
CREATE TABLE languages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(8) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL UNIQUE,
    script VARCHAR(50) NOT NULL,
    tts_locale VARCHAR(10) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE state_languages (
    state_id INT NOT NULL,
    language_id INT NOT NULL,
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    PRIMARY KEY (state_id, language_id),
    FOREIGN KEY (state_id) REFERENCES states(id) ON DELETE CASCADE,
    FOREIGN KEY (language_id) REFERENCES languages(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Tourism content per state: heritage, nature, food, culture, local business.
CREATE TABLE places (
    id INT AUTO_INCREMENT PRIMARY KEY,
    state_id INT NOT NULL,
    category ENUM('heritage','nature','food','culture','business') NOT NULL,
    name VARCHAR(150) NOT NULL,
    location VARCHAR(150) NOT NULL,
    description TEXT NOT NULL,
    importance VARCHAR(255) NOT NULL,
    is_hidden_gem BOOLEAN NOT NULL DEFAULT FALSE,
    image_slug VARCHAR(150) NULL,      -- file name without extension in static/images/places/
    image_credit VARCHAR(255) NULL,    -- photographer / licence line shown under the photo
    FOREIGN KEY (state_id) REFERENCES states(id) ON DELETE CASCADE,
    INDEX idx_places_state_cat (state_id, category)
) ENGINE=InnoDB;

CREATE TABLE greetings (
    language_id INT PRIMARY KEY,
    native_text VARCHAR(100) NOT NULL,
    english_text VARCHAR(150) NOT NULL,
    phonetic VARCHAR(100) NOT NULL,
    FOREIGN KEY (language_id) REFERENCES languages(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE phrase_categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    slug VARCHAR(40) NOT NULL UNIQUE,
    name VARCHAR(80) NOT NULL,
    sort_order TINYINT NOT NULL DEFAULT 0
) ENGINE=InnoDB;

CREATE TABLE phrases (
    id INT AUTO_INCREMENT PRIMARY KEY,
    category_id INT NOT NULL,
    english_text VARCHAR(200) NOT NULL,
    FOREIGN KEY (category_id) REFERENCES phrase_categories(id) ON DELETE CASCADE,
    INDEX idx_phrase_category (category_id)
) ENGINE=InnoDB;

CREATE TABLE phrase_translations (
    phrase_id INT NOT NULL,
    language_id INT NOT NULL,
    native_text VARCHAR(255) NOT NULL,
    phonetic VARCHAR(255) NOT NULL,
    PRIMARY KEY (phrase_id, language_id),
    FOREIGN KEY (phrase_id) REFERENCES phrases(id) ON DELETE CASCADE,
    FOREIGN KEY (language_id) REFERENCES languages(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ================= Seed data =================
INSERT INTO states (id, name, capital, best_season, quick_tip, overview) VALUES
(1,'Maharashtra','Mumbai','Nov – Feb','Avoid Mumbai local trains during peak hours (8–11 am, 5–8 pm).','Home to India''s financial capital, UNESCO-listed Buddhist caves, Maratha forts and a long Konkan coastline.'),
(2,'Kerala','Thiruvananthapuram','Oct – Mar','Book backwater houseboats through licensed operators and carry light cotton clothes.','Known for backwaters, hill plantations, Ayurveda and a celebrated vegetarian and seafood cuisine.'),
(3,'Rajasthan','Jaipur','Oct – Mar','Desert nights get cold in winter; carry a jacket for evening dune visits.','The land of kings: hill forts, palaces, desert culture and some of India''s richest craft traditions.'),
(4,'Tamil Nadu','Chennai','Oct – Mar','Dress modestly and remove footwear before entering temples.','Heart of Dravidian temple architecture, classical dance and music, with hill stations and a long coast.'),
(5,'Karnataka','Bengaluru','Oct – Mar','Explore Hampi early in the morning or late afternoon to avoid the midday heat.','Combines Vijayanagara ruins, royal Mysuru, coffee hills and India''s technology capital.'),
(6,'West Bengal','Kolkata','Oct – Mar','Book Durga Puja stays months ahead; the festival falls in autumn.','A literary and artistic hub spanning colonial Kolkata, Himalayan tea country and the Sundarbans mangroves.'),
(7,'Gujarat','Gandhinagar','Nov – Feb','Book Rann of Kutch tent stays early; the Rann Utsav runs in the cooler months.','Offers Indus-era and stepwell heritage, Asiatic lions, vivid festivals and renowned textile crafts.'),
(8,'Goa','Panaji','Nov – Feb','Old Goa churches are active places of worship; dress modestly when visiting.','Beyond its beaches, Goa blends Konkani and Portuguese heritage in its churches, food and festivals.'),
(9,'Uttar Pradesh','Lucknow','Oct – Mar','The Taj Mahal is closed on Fridays; visit at sunrise to beat the crowds.','Home to the Taj Mahal, the spiritual city of Varanasi and the refined Nawabi culture of Lucknow.'),
(10,'Punjab','Chandigarh','Oct – Mar','Cover your head and remove shoes at gurdwaras; tobacco is not allowed on the premises.','The heartland of Sikh heritage, bountiful farmland, exuberant festivals and famously generous hospitality.');

INSERT INTO languages (id, code, name, script, tts_locale) VALUES
(1,'mr','Marathi','Devanagari','mr-IN'),
(2,'hi','Hindi','Devanagari','hi-IN'),
(3,'ml','Malayalam','Malayalam','ml-IN'),
(4,'mwr','Marwari','Devanagari','hi-IN'),
(5,'ta','Tamil','Tamil','ta-IN'),
(6,'kn','Kannada','Kannada','kn-IN'),
(7,'bn','Bengali','Bengali','bn-IN'),
(8,'gu','Gujarati','Gujarati','gu-IN'),
(9,'kok','Konkani','Devanagari','mr-IN'),
(10,'pa','Punjabi','Gurmukhi','pa-IN'),
(11,'ur','Urdu','Perso-Arabic','ur-IN');

INSERT INTO state_languages (state_id, language_id, is_primary) VALUES
(1,1,TRUE),(1,2,FALSE),
(2,3,TRUE),
(3,2,TRUE),(3,4,FALSE),
(4,5,TRUE),
(5,6,TRUE),
(6,7,TRUE),(6,2,FALSE),
(7,8,TRUE),(7,2,FALSE),
(8,9,TRUE),(8,1,FALSE),(8,2,FALSE),
(9,2,TRUE),(9,11,FALSE),
(10,10,TRUE),(10,2,FALSE);

INSERT INTO greetings (language_id, native_text, english_text, phonetic) VALUES
(1,'नमस्कार','Hello / Welcome','namaskaar'),
(2,'नमस्ते','Hello / Greetings','namaste'),
(3,'നമസ്കാരം','Hello / Welcome','namaskaaram'),
(4,'खम्मा घणी','Warm greetings (a respectful Rajasthani welcome)','khammaa ghani'),
(5,'வணக்கம்','Hello / Welcome','vanakkam'),
(6,'ನಮಸ್ಕಾರ','Hello / Greetings','namaskaara'),
(7,'নমস্কার','Hello / Greetings','nomoshkar'),
(8,'કેમ છો?','Hello — how are you?','kem chho?'),
(9,'देव बरें दीस दिवं','Have a good day','dev borem dis divm'),
(10,'ਸਤ ਸ੍ਰੀ ਅਕਾਲ','Hello (a traditional Punjabi Sikh greeting)','sat sri akaal'),
(11,'السلام علیکم','Peace be upon you (Hello)','assalaam alaikum');

INSERT INTO places (state_id, category, name, location, description, importance, is_hidden_gem, image_slug) VALUES
-- Maharashtra
(1,'heritage','Ajanta & Ellora Caves','Chhatrapati Sambhajinagar','Rock-cut Buddhist, Hindu and Jain cave temples with ancient murals and the monolithic Kailasa temple.','UNESCO World Heritage Sites and a high point of Indian rock-cut art.',FALSE,'ajanta-ellora-caves'),
(1,'nature','Kaas Plateau','Satara','A high plateau that carpets itself in wildflowers after the monsoon (roughly Aug–Oct).','Part of the UNESCO-listed Western Ghats; a quieter alternative to crowded hill stations.',TRUE,'kaas-plateau'),
(1,'food','Misal Pav','Pune, Nashik & Kolhapur','Spicy sprouted-lentil curry topped with farsan and served with soft bread rolls.','A staple Maharashtrian breakfast with sharp regional variations in heat.',FALSE,'misal-pav'),
(1,'culture','Ganesh Chaturthi','Mumbai & Pune','Ten-day festival with grand public pandals and immersion processions.','Became a large public festival in the late 19th century; the state''s biggest cultural event.',FALSE,'ganesh-chaturthi'),
(1,'business','Kolhapuri Chappals','Kolhapur','Handcrafted leather sandals made by local artisan families.','A GI-tagged craft that sustains traditional artisans.',FALSE,'kolhapuri-chappals'),
-- Kerala
(2,'heritage','Mattancherry Palace & Jew Town','Kochi','A 16th-century palace with Kerala murals, beside antique shops and the Paradesi Synagogue (1568).','Shows centuries of Portuguese, Dutch, Jewish and Arab trade in a single lane.',FALSE,'mattancherry-palace-jew-town'),
(2,'nature','Alleppey Backwaters','Alappuzha','Slow cruises through palm-lined canals and lagoons, often on a traditional kettuvallam houseboat.','The signature Kerala experience; much of Kuttanad lies below sea level.',FALSE,'alleppey-backwaters'),
(2,'food','Kerala Sadya','Statewide','A vegetarian feast of many dishes served on a banana leaf.','Eaten by hand and central to Onam celebrations.',FALSE,'kerala-sadya'),
(2,'culture','Theyyam','Kannur & Kasaragod','Ritual performances where costumed dancers embody deities, mainly in winter and spring.','A living folk tradition of North Malabar that few tourists see.',TRUE,'theyyam'),
(2,'business','Spice Markets & Ayurveda','Kochi & Munnar','Cardamom, pepper and cinnamon markets alongside Ayurvedic wellness centres.','Spices drew traders for centuries; choose certified Ayurvedic centres.',FALSE,'spice-markets-ayurveda'),
-- Rajasthan
(3,'heritage','Amer Fort','Jaipur','Hilltop palace-fort of red sandstone and marble with the mirrored Sheesh Mahal.','Part of the UNESCO-listed Hill Forts of Rajasthan.',FALSE,'amer-fort'),
(3,'nature','Khuri Sand Dunes','Jaisalmer','A calm desert village with camel rides and quiet sunsets.','Generally less crowded than the more famous Sam dunes.',TRUE,'khuri-sand-dunes'),
(3,'food','Dal Baati Churma','Statewide','Baked wheat balls dunked in ghee, served with lentils and sweet crumbled churma.','Classic Rajasthani comfort food suited to a desert climate.',FALSE,'dal-baati-churma'),
(3,'culture','Pushkar Camel Fair','Pushkar','Annual livestock fair with folk music, games and pilgrims around Kartik Purnima (Oct–Nov).','One of India''s most colourful fairs, tied to a major pilgrimage.',FALSE,'pushkar-camel-fair'),
(3,'business','Block Printing & Blue Pottery','Sanganer, Bagru & Jaipur','Hand block-printed textiles and glazed blue pottery made in artisan workshops.','Heritage crafts you can watch being made and buy directly from makers.',FALSE,'block-printing-blue-pottery'),
-- Tamil Nadu
(4,'heritage','Brihadisvara Temple','Thanjavur','An 11th-century Chola temple crowned by a towering granite vimana.','Part of the UNESCO-listed Great Living Chola Temples.',FALSE,'brihadisvara-temple'),
(4,'nature','Nilgiri Hills','Ooty & Coonoor','Tea estates, viewpoints and the heritage Nilgiri Mountain Railway.','The railway is part of UNESCO''s Mountain Railways of India.',FALSE,'nilgiri-hills'),
(4,'food','Chettinad Cuisine & Filter Coffee','Karaikudi & Chennai','Fiery Chettinad curries made with freshly ground spice blends, plus South Indian filter coffee.','One of South India''s most distinctive regional cuisines.',FALSE,'chettinad-cuisine-filter-coffee'),
(4,'culture','Pongal & Bharatanatyam','Statewide','Pongal is the four-day January harvest festival; Bharatanatyam is the classical dance rooted in Tamil temples.','Both express Tamil identity; catch recitals in Chennai''s December music season.',FALSE,'pongal-bharatanatyam'),
(4,'business','Kanchipuram Silk Sarees','Kanchipuram','Handwoven silk sarees with temple-border designs.','A GI-tagged weaving tradition; buy from cooperative societies for authenticity.',FALSE,'kanchipuram-silk-sarees'),
-- Karnataka
(5,'heritage','Hampi','Vijayanagara district','Ruins of the Vijayanagara Empire capital: temples, bazaars and boulder-strewn landscapes.','A UNESCO World Heritage Site and a vast open-air archaeological landscape.',FALSE,'hampi'),
(5,'nature','Coorg (Kodagu)','Madikeri','Misty hills of coffee and spice plantations, waterfalls and homestays.','Karnataka''s coffee heartland, ideal for plantation stays.',FALSE,'coorg-kodagu'),
(5,'food','Mysore Pak & Bisi Bele Bath','Mysuru & Bengaluru','Mysore Pak is a ghee-rich gram-flour sweet; bisi bele bath is a spiced rice-and-lentil dish.','Both are signature dishes of Karnataka.',FALSE,'mysore-pak-bisi-bele-bath'),
(5,'culture','Mysuru Dasara','Mysuru','Ten-day festival with an illuminated palace and a grand procession.','The state''s best-known festival, rooted in royal tradition.',FALSE,'mysuru-dasara'),
(5,'business','Channapatna Toys','Channapatna','Lacquered wooden toys turned by local artisans.','A GI-tagged craft that has earned the town the nickname "toy town".',TRUE,'channapatna-toys'),
-- West Bengal
(6,'heritage','Victoria Memorial','Kolkata','Marble museum and gardens built in the early 20th century, holding colonial-era art and artefacts.','An icon of Kolkata, once the capital of British India.',FALSE,'victoria-memorial'),
(6,'nature','Sundarbans','South 24 Parganas','Mangrove delta explored by boat, home to the Bengal tiger.','A UNESCO World Heritage Site shared with Bangladesh.',FALSE,'sundarbans'),
(6,'food','Rosogolla & Mishti Doi','Kolkata','Spongy cottage-cheese sweets in syrup and sweet set yoghurt.','West Bengal holds a GI tag for its rosogolla.',FALSE,'rosogolla-mishti-doi'),
(6,'culture','Durga Puja','Kolkata','Autumn festival of elaborate pandals, art installations and idol immersion.','Inscribed on UNESCO''s Intangible Cultural Heritage list in 2021.',FALSE,'durga-puja'),
(6,'business','Darjeeling Tea','Darjeeling','Estate tours and tastings of the famous Himalayan tea.','Darjeeling tea was among India''s first GI-tagged products.',FALSE,'darjeeling-tea'),
-- Gujarat
(7,'heritage','Rani ki Vav','Patan','An 11th-century stepwell covered in intricately carved sculptural panels.','A UNESCO World Heritage Site.',FALSE,'rani-ki-vav'),
(7,'nature','Gir National Park','Junagadh district','Safaris through dry deciduous forest.','The only natural habitat of the Asiatic lion.',FALSE,'gir-national-park'),
(7,'food','Gujarati Thali, Dhokla & Fafda','Ahmedabad & Surat','A sweet-and-savoury vegetarian platter, steamed dhokla and a crisp fafda-jalebi breakfast.','Showcases Gujarat''s vegetarian food culture.',FALSE,'gujarati-thali-dhokla-fafda'),
(7,'culture','Navratri & Garba','Statewide','Nine nights of community garba and dandiya dance in autumn.','Known as one of the world''s longest dance festivals.',FALSE,'navratri-garba'),
(7,'business','Kutch Handicrafts','Bhuj & Kutch villages','Bandhani tie-dye, embroidery and Ajrakh block printing sold by artisan communities.','Buying direct supports village artisans; the Rann Utsav adds to a winter visit.',FALSE,'kutch-handicrafts'),
-- Goa
(8,'heritage','Churches and Convents of Goa','Old Goa','Baroque churches including the Basilica of Bom Jesus, which holds the remains of St Francis Xavier.','A UNESCO World Heritage Site and a pilgrimage centre.',FALSE,'churches-and-convents-of-goa'),
(8,'nature','Dudhsagar Falls','Mollem','A four-tiered waterfall reached by jeep through forest, best after the monsoon.','Among India''s tallest waterfalls.',FALSE,'dudhsagar-falls'),
(8,'food','Goan Fish Curry & Bebinca','Statewide','Coconut-and-kokum fish curry with rice, and the layered bebinca dessert.','Reflects Goa''s Konkani and Portuguese influences.',FALSE,'goan-fish-curry-bebinca'),
(8,'culture','Goa Carnival','Panaji','Pre-Lent parades with floats, music and street dance, usually in Feb–Mar.','A Portuguese-era tradition still celebrated today.',FALSE,'goa-carnival'),
(8,'business','Spice Plantation Tours','Ponda','Guided walks among pepper, cardamom, vanilla and cashew trees, often with a local lunch.','Agri-tourism that sends income to farming families.',TRUE,'spice-plantation-tours'),
-- Uttar Pradesh
(9,'heritage','Taj Mahal','Agra','White-marble mausoleum built by Shah Jahan in the 17th century.','A UNESCO World Heritage Site and one of the world''s best-known monuments.',FALSE,'taj-mahal'),
(9,'nature','Dudhwa National Park','Lakhimpur Kheri','Terai grassland and forest with tigers, swamp deer and rhinos.','A quiet wildlife escape in the Terai belt.',TRUE,'dudhwa-national-park'),
(9,'food','Awadhi Cuisine','Lucknow','Tunday kebabs, slow-cooked biryani and dum dishes.','Shaped by the royal Nawabi kitchens of Awadh.',FALSE,'awadhi-cuisine'),
(9,'culture','Ganga Aarti','Varanasi','Evening fire ritual performed on the ghats of the Ganges.','Varanasi is among the world''s oldest continuously inhabited cities.',FALSE,'ganga-aarti'),
(9,'business','Chikankari Embroidery','Lucknow','Delicate hand-embroidered garments sold in the Chowk and Aminabad markets.','A GI-tagged craft with a long Lucknow tradition.',FALSE,'chikankari-embroidery'),
-- Punjab
(10,'heritage','Golden Temple (Harmandir Sahib)','Amritsar','The holiest Sikh shrine, set in a sacred pool; its community kitchen serves free meals daily.','Open to people of all faiths; cover your head and remove shoes.',FALSE,'golden-temple-harmandir-sahib'),
(10,'nature','Harike Wetland','Tarn Taran','Large wetland at the confluence of the Beas and Sutlej, rich in migratory birds in winter.','A Ramsar-listed wetland.',TRUE,'harike-wetland'),
(10,'food','Amritsari Kulcha & Sarson da Saag','Amritsar & statewide','Stuffed tandoor-baked kulcha with chole; mustard greens served with makki di roti.','Hearty harvest-season staples of Punjabi cooking.',FALSE,'amritsari-kulcha-sarson-da-saag'),
(10,'culture','Baisakhi & Bhangra','Statewide','Spring harvest festival (mid-April) with Bhangra dance and village fairs.','Also marks the founding of the Khalsa in 1699.',FALSE,'baisakhi-bhangra'),
(10,'business','Phulkari & Punjabi Juttis','Patiala & Amritsar','Brightly embroidered textiles and handcrafted leather shoes.','Traditional crafts and popular souvenirs.',FALSE,'phulkari-punjabi-juttis');

INSERT INTO phrase_categories (id, slug, name, sort_order) VALUES
(1,'essentials','Essentials',1),
(2,'food','Food & Dining',2),
(3,'directions','Directions',3),
(4,'shopping','Shopping',4);

INSERT INTO phrases (id, category_id, english_text) VALUES
(1,1,'Thank you'),
(2,1,'Excuse me'),
(3,1,'I do not understand'),
(4,1,'Please help me'),
(5,2,'Water, please'),
(6,2,'Is this vegetarian?'),
(7,2,'The food is delicious'),
(8,3,'Where is the bus station?'),
(9,4,'How much is this?');

-- Marathi
INSERT INTO phrase_translations (phrase_id, language_id, native_text, phonetic) VALUES
(1,1,'धन्यवाद','dhanyavaad'),
(2,1,'माफ करा','maaf karaa'),
(3,1,'मला समजत नाही','malaa samajat naahi'),
(4,1,'कृपया मला मदत करा','kripayaa malaa madat karaa'),
(5,1,'कृपया पाणी द्या','kripayaa paani dyaa'),
(6,1,'हे शाकाहारी आहे का?','he shaakaahaari aahe kaa?'),
(7,1,'जेवण खूप छान आहे','jevan khoop chhaan aahe'),
(8,1,'बस स्थानक कुठे आहे?','bas sthaanak kuthe aahe?'),
(9,1,'हे कितीला आहे?','he kitilaa aahe?');

-- Hindi
INSERT INTO phrase_translations (phrase_id, language_id, native_text, phonetic) VALUES
(1,2,'धन्यवाद','dhanyavaad'),
(2,2,'माफ़ कीजिए','maaf keejiye'),
(3,2,'मुझे समझ नहीं आया','mujhe samajh nahin aaya'),
(4,2,'कृपया मेरी मदद कीजिए','kripayaa meri madad keejiye'),
(5,2,'कृपया पानी दीजिए','kripayaa paani deejiye'),
(6,2,'क्या यह शाकाहारी है?','kyaa yah shaakaahaari hai?'),
(7,2,'खाना बहुत स्वादिष्ट है','khaanaa bahut svaadisht hai'),
(8,2,'बस स्टेशन कहाँ है?','bas steshan kahaan hai?'),
(9,2,'यह कितने का है?','yah kitne kaa hai?');

-- Malayalam
INSERT INTO phrase_translations (phrase_id, language_id, native_text, phonetic) VALUES
(1,3,'നന്ദി','nandi'),
(2,3,'ക്ഷമിക്കണം','kshamikkanam'),
(3,3,'എനിക്ക് മനസ്സിലായില്ല','enikku manassilaayilla'),
(4,3,'ദയവായി എന്നെ സഹായിക്കൂ','dayavaayi enne sahaayikkoo'),
(5,3,'ദയവായി വെള്ളം തരൂ','dayavaayi vellam tharoo'),
(6,3,'ഇത് വെജിറ്റേറിയൻ ആണോ?','ithu vejitteriyan aano?'),
(7,3,'ഭക്ഷണം വളരെ രുചികരമാണ്','bhakshanam valare ruchikaramaanu'),
(8,3,'ബസ് സ്റ്റേഷൻ എവിടെയാണ്?','bas steshan evideyaanu?'),
(9,3,'ഇതിന് എത്രയാണ് വില?','ithinu ethrayaanu vila?');
-- Marwari (language 4; Devanagari. Lowest-confidence set: have a native speaker review.)
INSERT INTO phrase_translations (phrase_id, language_id, native_text, phonetic) VALUES
(1,4,'घणो धन्यवाद','ghano dhanyavaad'),
(2,4,'माफ करजो','maaf karjo'),
(3,4,'म्हनै समझ कोनी आई','mhane samajh koni aai'),
(4,4,'म्हारी मदद करो सा','mhaari madad karo saa'),
(5,4,'पाणी द्यो सा','paani dyo saa'),
(6,4,'ओ शाकाहारी है कांई?','o shaakaahaari hai kaani?'),
(7,4,'खाणो घणो स्वादिष्ट है','khaano ghano svaadisht hai'),
(8,4,'बस स्टेशन कठै है?','bas steshan kathai hai?'),
(9,4,'ओ कितरै रो है?','o kitre ro hai?');

-- Tamil (language 5)
INSERT INTO phrase_translations (phrase_id, language_id, native_text, phonetic) VALUES
(1,5,'நன்றி','nandri'),
(2,5,'மன்னிக்கவும்','mannikkavum'),
(3,5,'எனக்குப் புரியவில்லை','enakku puriyavillai'),
(4,5,'தயவுசெய்து எனக்கு உதவுங்கள்','dayavuseydhu enakku udhavungal'),
(5,5,'தயவுசெய்து தண்ணீர் கொடுங்கள்','dayavuseydhu thanneer kodungal'),
(6,5,'இது சைவமா?','idhu saivamaa?'),
(7,5,'உணவு மிகவும் சுவையாக உள்ளது','unavu migavum suvaiyaaga ullathu'),
(8,5,'பேருந்து நிலையம் எங்கே உள்ளது?','perundhu nilaiyam enge ullathu?'),
(9,5,'இது எவ்வளவு?','idhu evvalavu?');

-- Kannada (language 6)
INSERT INTO phrase_translations (phrase_id, language_id, native_text, phonetic) VALUES
(1,6,'ಧನ್ಯವಾದಗಳು','dhanyavaadagalu'),
(2,6,'ಕ್ಷಮಿಸಿ','kshamisi'),
(3,6,'ನನಗೆ ಅರ್ಥವಾಗುತ್ತಿಲ್ಲ','nanage arthavaagutthilla'),
(4,6,'ದಯವಿಟ್ಟು ನನಗೆ ಸಹಾಯ ಮಾಡಿ','dayavittu nanage sahaaya maadi'),
(5,6,'ದಯವಿಟ್ಟು ನೀರು ಕೊಡಿ','dayavittu neeru kodi'),
(6,6,'ಇದು ಸಸ್ಯಾಹಾರಿಯೇ?','idu sasyaahaariye?'),
(7,6,'ಊಟ ತುಂಬಾ ರುಚಿಯಾಗಿದೆ','oota tumba ruchiyaagide'),
(8,6,'ಬಸ್ ನಿಲ್ದಾಣ ಎಲ್ಲಿದೆ?','bas nildaana ellide?'),
(9,6,'ಇದರ ಬೆಲೆ ಎಷ್ಟು?','idara bele eshtu?');

-- Bengali (language 7)
INSERT INTO phrase_translations (phrase_id, language_id, native_text, phonetic) VALUES
(1,7,'ধন্যবাদ','dhonnobaad'),
(2,7,'মাফ করবেন','maaf korben'),
(3,7,'আমি বুঝতে পারছি না','aami bujhte paarchhi naa'),
(4,7,'দয়া করে আমাকে সাহায্য করুন','doya kore aamaake shahajyo korun'),
(5,7,'দয়া করে একটু জল দিন','doya kore ektu jol din'),
(6,7,'এটা কি নিরামিষ?','eta ki niraamish?'),
(7,7,'খাবারটা খুব সুস্বাদু','khaabaarta khub sushwaadu'),
(8,7,'বাস স্টেশন কোথায়?','baas steshon kothaay?'),
(9,7,'এটার দাম কত?','etar daam koto?');

-- Gujarati (language 8)
INSERT INTO phrase_translations (phrase_id, language_id, native_text, phonetic) VALUES
(1,8,'આભાર','aabhaar'),
(2,8,'માફ કરજો','maaf karjo'),
(3,8,'મને સમજાતું નથી','mane samjaatu nathi'),
(4,8,'કૃપા કરીને મને મદદ કરો','krupa karine mane madad karo'),
(5,8,'કૃપા કરીને પાણી આપો','krupa karine paani aapo'),
(6,8,'શું આ શાકાહારી છે?','shu aa shaakaahaari chhe?'),
(7,8,'ખાવાનું ખૂબ સ્વાદિષ્ટ છે','khaavaanu khoob svaadisht chhe'),
(8,8,'બસ સ્ટેશન ક્યાં છે?','bas steshan kyaa chhe?'),
(9,8,'આની કિંમત કેટલી છે?','aani kimmat ketli chhe?');

-- Konkani (language 9; Devanagari. Lower-confidence set: have a native speaker review.)
INSERT INTO phrase_translations (phrase_id, language_id, native_text, phonetic) VALUES
(1,9,'देव बरें करूं','dev borem korum'),
(2,9,'माफ करात','maaf karaat'),
(3,9,'म्हाका कळना','mhaaka kalnaa'),
(4,9,'म्हाका मदत करात','mhaaka madat karaat'),
(5,9,'उदक दियात','udak diyaat'),
(6,9,'हें शाकाहारी आसा?','hem shaakaahaari aasa?'),
(7,9,'जेवण भोव रुचीक आसा','jevan bhov ruchik aasa'),
(8,9,'बस स्थानक खंय आसा?','bas sthaanak khaim aasa?'),
(9,9,'हें कितल्याक?','hem kitlyaak?');

-- Punjabi (language 10; Gurmukhi)
INSERT INTO phrase_translations (phrase_id, language_id, native_text, phonetic) VALUES
(1,10,'ਧੰਨਵਾਦ','dhannvaad'),
(2,10,'ਮਾਫ਼ ਕਰਨਾ','maaf karnaa'),
(3,10,'ਮੈਨੂੰ ਸਮਝ ਨਹੀਂ ਆਇਆ','mainu samajh nahin aayaa'),
(4,10,'ਕਿਰਪਾ ਕਰਕੇ ਮੇਰੀ ਮਦਦ ਕਰੋ','kirpaa karke meri madad karo'),
(5,10,'ਕਿਰਪਾ ਕਰਕੇ ਪਾਣੀ ਦਿਓ','kirpaa karke paani dio'),
(6,10,'ਕੀ ਇਹ ਸ਼ਾਕਾਹਾਰੀ ਹੈ?','ki ih shaakaahaari hai?'),
(7,10,'ਖਾਣਾ ਬਹੁਤ ਸੁਆਦ ਹੈ','khaanaa bahut suaad hai'),
(8,10,'ਬੱਸ ਅੱਡਾ ਕਿੱਥੇ ਹੈ?','bass addaa kitthe hai?'),
(9,10,'ਇਹ ਕਿੰਨੇ ਦਾ ਹੈ?','ih kinne daa hai?');

-- Urdu (language 11; Perso-Arabic, right-to-left)
INSERT INTO phrase_translations (phrase_id, language_id, native_text, phonetic) VALUES
(1,11,'شکریہ','shukriya'),
(2,11,'معاف کیجیے','maaf keejiye'),
(3,11,'مجھے سمجھ نہیں آیا','mujhe samajh nahin aaya'),
(4,11,'براہِ کرم میری مدد کیجیے','baraah-e-karam meri madad keejiye'),
(5,11,'براہِ کرم پانی دیجیے','baraah-e-karam paani deejiye'),
(6,11,'کیا یہ ویجیٹیرین ہے؟','kya yeh vegetarian hai?'),
(7,11,'کھانا بہت لذیذ ہے','khaana bahut lazeez hai'),
(8,11,'بس اسٹیشن کہاں ہے؟','bas steshan kahaan hai?'),
(9,11,'یہ کتنے کا ہے؟','yeh kitne ka hai?');

