CREATE TABLE articles (
    article_id INTEGER PRIMARY KEY,
    product_code INTEGER,
    prod_name VARCHAR(255),
    product_type_no INTEGER,
    product_type_name VARCHAR(100),
    product_group_name VARCHAR(100),
    graphical_appearance_no INTEGER,
    graphical_appearance_name VARCHAR(100),
    colour_group_code INTEGER,
    colour_group_name VARCHAR(100),
    perceived_colour_value_id INTEGER,
    perceived_colour_value_name VARCHAR(100),
    perceived_colour_master_id INTEGER,
    perceived_colour_master_name VARCHAR(100),
    department_no INTEGER,
    department_name VARCHAR(150),
    index_code VARCHAR(10),
    index_name VARCHAR(100),
    index_group_no INTEGER,
    index_group_name VARCHAR(100),
    section_no INTEGER,
    section_name VARCHAR(150),
    garment_group_no INTEGER,
    garment_group_name VARCHAR(100),
    detail_desc TEXT
);

CREATE TABLE customers (
    customer_id TEXT PRIMARY KEY,
    "FN" NUMERIC,
    "Active" NUMERIC,
    club_member_status VARCHAR(50),
    fashion_news_frequency VARCHAR(50),
    age NUMERIC,
    postal_code TEXT
);

CREATE TABLE transactions (
    t_dat DATE,
    customer_id TEXT REFERENCES customers(customer_id),
    article_id INTEGER REFERENCES articles(article_id),
    price NUMERIC,
    sales_channel_id INTEGER
);