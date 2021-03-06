DROP TABLE IF EXISTS Accounts CASCADE;
DROP TABLE IF EXISTS Customers CASCADE;
DROP TABLE IF EXISTS CreditCards CASCADE;
DROP TABLE IF EXISTS Promos CASCADE;
DROP TABLE IF EXISTS Given CASCADE;
DROP TABLE IF EXISTS CustomerPromo CASCADE;
DROP TABLE IF EXISTS Riders CASCADE;
DROP TABLE IF EXISTS FTRiders CASCADE;
DROP TABLE IF EXISTS PTRiders CASCADE;

DROP TABLE IF EXISTS WWS CASCADE;
DROP TABLE IF EXISTS MWS CASCADE;
DROP TABLE IF EXISTS Contains CASCADE;
DROP TABLE IF ExISTS Has CASCADE;
DROP TABLE IF EXISTS Describes CASCADE;

DROP TABLE IF EXISTS Shift CASCADE;
DROP TABLE IF EXISTS ShiftInfo CASCADE;
DROP TABLE IF EXISTS PTWorks CASCADE;
DROP TABLE IF EXISTS FTWorks CASCADE;
DROP TABLE IF EXISTS FDSManagers CASCADE;
DROP TABLE IF EXISTS Rates CASCADE;
DROP TABLE IF EXISTS Salaries CASCADE;
DROP TABLE IF EXISTS Orders CASCADE;
DROP TABLE IF EXISTS Uses CASCADE;
DROP TABLE IF EXISTS Restaurants CASCADE;
DROP TABLE IF EXISTS RestaurantStaffs CASCADE;
DROP TABLE IF EXISTS Foods CASCADE;
DROP TABLE IF EXISTS Consists CASCADE;
DROP TABLE IF EXISTS Places CASCADE;
DROP TABLE IF EXISTS Reviews CASCADE;



CREATE TABLE Accounts (
	account_id varchar(255) primary key,
	account_pass varchar(50) not null,
	date_created date not null,
	account_type varchar(255) not null
);

-- Customers relation here--
CREATE TABLE Customers (
	cid varchar(255) references Accounts(account_id) on delete cascade on update cascade,
	name varchar(255) not null,
	reward_points double precision default 0,
	primary key (cid)
);

CREATE TABLE CreditCards (
	cid varchar(255) references Accounts(account_id) on delete cascade on update cascade,
	card_number varchar(19),
	primary key (cid, card_number),
	unique(card_number)
);

-- Promotion --
CREATE TABLE Promos (
	promo_id serial unique,
	creator_id varchar(255) not null,
	use_limit integer,
	details text not null,
	category varchar(255) not null,
	promo_type varchar(255) not null,
	discount_value integer DEFAULT 0 not null,
	trigger_value money DEFAULT 0 not null,
	start_time timestamp not null, 
	end_time timestamp not null,
	primary key (promo_id),
	foreign key (creator_id) references Accounts 
		on delete cascade
		on update cascade
);

CREATE TABLE Given (
	promo_id integer references Promos(promo_id) on delete cascade on update cascade,
	cid varchar(255) references Customers(cid) on delete cascade on update cascade,
	primary key(promo_id, cid)
);

-- Riders relation here --
CREATE TABLE Riders (
	rid varchar(255) references Accounts(account_id) on delete cascade on update cascade,
	name varchar(255) not null,
	primary key (rid)
);

CREATE TABLE FTRiders (
	rid varchar(255) references Accounts(account_id) on delete cascade on update cascade,
	name varchar(255) not null,
	avg_rating real,
    primary key (rid), 
    foreign key (rid) references Riders on delete cascade on update cascade
);

CREATE TABLE PTRiders (
	rid varchar(255) references Accounts(account_id) on delete cascade on update cascade,
	name varchar(255) not null,
	avg_rating real,
    primary key (rid)
);

-- combination of DWS and Shift together into one entity
CREATE TABLE Shift (
	shift_id serial,
	actual_date date,
	primary key(shift_id)
);


CREATE TABLE ShiftInfo (
	iid serial,
	start_time time not null,
	end_time time not null,
	primary key(iid)
);

CREATE TABLE Describes (
	shift_id integer,
	iid integer,
	working_interval integer,
	primary key(shift_id, working_interval),
	foreign key(iid) references ShiftInfo 
		on delete cascade
		on update cascade,
	foreign key(shift_id) references Shift
		on delete cascade
		on update cascade
);

-- wk_no can use EXTRACT method in postgres to store if not change datatype to not double precision
-- wk_no with respect to the start_date
-- abstract view, defining what is a week
CREATE TABLE WWS (
	wid serial,
	-- 0 = sunday
	start_day integer,
	primary key(wid)
);

CREATE TABLE Contains (
	wid integer,
	working_day integer check (working_day IN (0,1,2,3,4,5,6)),
	shift_id integer,
	primary key(wid, working_day),
	foreign key(wid) references WWS
		on delete cascade
		on update cascade,
	foreign key(shift_id) references Shift
		on delete cascade
		on update cascade
);

-- Start_wk and end_wk can use the EXTRACT method to extract week base of year
-- month wrt to the start_wk
-- abstract view defining what is a month (4 consecutive weeks)
CREATE TABLE MWS (
	mid serial,
	-- With respect to the year which week the person start
	start_week integer,
	primary key(mid)
);

CREATE TABLE Has (
	mid integer,
	wid integer unique,
	working_week integer check (working_week IN (1,2,3,4)),
	primary key(mid, working_week),
	foreign key(mid) references MWS(mid)
		on delete cascade
		on update cascade,
	foreign key(wid) references WWS(wid)
		on delete cascade
		on update cascade
);

-- total hours put at this table is because if put at WWS, cannot ensure that every week different riders same hour however putting at here can ensure that. 
-- As every rider only participate in on uniquee PTWorks table 
CREATE TABLE PTWorks (
	rid varchar(255) references PTRiders(rid) on delete cascade on update cascade,
	working_week integer,
	total_hours integer,
	wid integer,
	primary key (rid, working_week),
	foreign key(wid) references WWS
		on update cascade
		on delete cascade
);

CREATE TABLE FTWorks(
	rid varchar(255) references FTRiders(rid) on delete cascade on update cascade,
	working_month integer,
	total_hours integer,
	mid integer,
	primary key (rid, working_month),
	foreign key(mid) references MWS
		on delete cascade
		on update cascade
);

CREATE TABLE FDSManagers (
	fds_id varchar(255) references Accounts(account_id) on delete cascade on update cascade,
	name varchar(255) not null,
	primary key(fds_id)
); 

CREATE TABLE Restaurants (
	rest_id serial,
	name varchar(255) not null,
    order_threshold money not null,
	address varchar(255) not null,
    primary key(rest_id)
);

CREATE TABLE Orders (
	oid serial,
	rid varchar(255),
	rest_id integer not null,
	order_status varchar(50) not null,
	rating integer,
	points_used double precision default 0,
	delivery_fee money,
	total_price money,
	order_placed timestamp,
	depart_for_rest timestamp,
	arrive_at_rest timestamp,
	depart_for_delivery timestamp,
	deliver_to_cust timestamp,
	primary key (oid),
	foreign key (rest_id) references Restaurants(rest_id),
	foreign key (rid) references Riders
		on delete cascade
		on update cascade
);

CREATE TABLE Places (
	oid integer references Orders(oid) on delete cascade,
	cid varchar(255) references Customers(cid),
	address varchar(255),
	payment_method varchar(255),
	card_number varchar(255),
	primary key(oid),
	foreign key (card_number) references CreditCards (card_number) 
		on delete cascade
		on update cascade
);

CREATE TABLE Uses (
	oid integer NOT NULL,
	promo_id integer NOT NULL,
	amount money NOT NULL,
	primary key (oid, promo_id),
	foreign key (oid) references Places(oid)
		on delete cascade
		on update cascade,
	foreign key (promo_id) references Promos(promo_id)
		on delete cascade
		on update cascade
);

CREATE TABLE Salaries (
	sid serial primary key,
	rid varchar(255) references Riders,
	start_date date not null,
   	end_date date not null,
	amount money not null
);

CREATE TABLE RestaurantStaffs (
	staff_id varchar(255) references Accounts(account_id) on delete cascade on update cascade,
    rest_id integer references Restaurants(rest_id),
    primary key(staff_id, rest_id)
);

CREATE TABLE Foods (
    fid serial primary key,
    rest_id serial,
    name varchar(255) not null,
    price money not null,
    food_limit integer not null,
    quantity integer not null,
    category varchar(255) not null,
	availability boolean default true,
    foreign key (rest_id) references Restaurants on delete cascade on update cascade
);

CREATE TABLE Consists (
	oid integer references Orders(oid) on delete cascade,
	fid integer references Foods(fid) on delete cascade,
	review varchar(255),
	quantity integer not null,
	total_price money not null,
	primary key(oid, fid)
);

-- Triggers
CREATE OR REPLACE FUNCTION check_max_shift_hour()
   RETURNS trigger AS $$
BEGIN
   If EXTRACT(HOUR FROM (SELECT NEW.end_time - NEW.start_time)) > 4 THEN
RAISE exception 'Given start(%) and end time(%) are more than 4 hours.', NEW.start_time, NEW.end_time;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS max_shift_interval ON ShiftInfo;
CREATE TRIGGER max_shift_interval
BEFORE UPDATE OR INSERT
ON ShiftInfo
FOR EACH ROW
EXECUTE FUNCTION check_max_shift_hour();

-- Need a trigger to reject those orders less than threshold
CREATE OR REPLACE FUNCTION reject_order_below_threshold()
	RETURNS trigger AS $$
DECLARE
	threshold Restaurants.order_threshold%TYPE;
BEGIN
	SELECT R.order_threshold INTO threshold FROM Restaurants as R WHERE R.rest_id = NEW.rest_id;
	If NEW.total_price < threshold THEN
	RAISE exception 'Total price of the order - % are less than the threshold - %', NEW.total_price, threshold; 
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS check_order_meets_threshold ON ORDERS;
CREATE TRIGGER check_order_meets_threshold
BEFORE UPDATE OR INSERT
ON Orders
FOR EACH ROW 
EXECUTE FUNCTION reject_order_below_threshold();

CREATE OR REPLACE FUNCTION reject_above_food_limit()
	RETURNS trigger AS $$
DECLARE
	food_limit Foods.food_limit%TYPE;
BEGIN
	SELECT F.food_limit INTO food_limit FROM Foods AS F WHERE F.fid = NEW.fid;
	If NEW.quantity > food_limit THEN
	RAISE exception 'The quantity of the food ordered (%) is more than the food limit (%)', NEW.quantity, food_limit; 
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS check_food_quantity_below_limit ON ORDERS;
CREATE TRIGGER check_food_quantity_below_limit
BEFORE UPDATE OR INSERT 
ON Consists
FOR EACH ROW 
EXECUTE FUNCTION reject_above_food_limit();

CREATE OR REPLACE FUNCTION update_food_quantity()
	RETURNS trigger AS $$
DECLARE 
	checkCursor CURSOR FOR SELECT C.fid, C.quantity FROM Consists as C WHERE C.oid = NEW.oid;
	checkRow RECORD;
BEGIN
	If NEW.order_status = 'paid' AND OLD.order_status = 'cart' THEN
		OPEN checkCursor;
		
		LOOP
			FETCH checkCursor INTO checkRow;
			EXIT WHEN NOT FOUND;

			UPDATE Foods 
			SET quantity = quantity - checkRow.quantity
			WHERE fid = checkRow.fid;
		END LOOP;
		CLOSE checkCursor;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_quantity_after_place_order ON ORDERS;
CREATE TRIGGER update_quantity_after_place_order
BEFORE UPDATE 
ON Orders
FOR EACH ROW 
EXECUTE FUNCTION update_food_quantity();

CREATE OR REPLACE FUNCTION reject_negative_food_quantity()
	RETURNS trigger AS $$
BEGIN
	If NEW.quantity < 0 THEN
	RAISE exception 'The quantity of the food ordered (%) cannot be negative', NEW.quantity; 
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS check_negative_food_quantity ON Foods;
CREATE TRIGGER check_negative_food_quantity
BEFORE UPDATE OR INSERT 
ON Foods
FOR EACH ROW 
EXECUTE FUNCTION reject_negative_food_quantity();

CREATE OR REPLACE FUNCTION zero_quantity_set_food_unavailable()
	RETURNS trigger AS $$
BEGIN
	If NEW.quantity = 0 AND OLD.availability = true THEN
		UPDATE Foods 
		SET availability = false
		WHERE fid = NEW.fid; 
	END IF;
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS check_food_availability ON Foods;
CREATE TRIGGER check_food_availability
AFTER UPDATE OR INSERT 
ON Foods
FOR EACH ROW 
EXECUTE FUNCTION zero_quantity_set_food_unavailable();

CREATE OR REPLACE FUNCTION reject_same_duration()
	RETURNS trigger AS $$
BEGIN
	IF EXISTS(SELECT * FROM ShiftInfo WHERE start_time = NEW.start_time AND end_time = NEW.end_time) THEN 
	RETURN null;
	END IF;
	RETURN NEW;	
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS reject_if_exists_same_duration ON ShiftInfo;
CREATE TRIGGER reject_if_exists_same_duration
BEFORE INSERT 
ON ShiftInfo
FOR EACH ROW 
EXECUTE FUNCTION reject_same_duration();

-- Check promo category: All, First Order, Restaurant
-- Check if the promo is within time limit
CREATE OR REPLACE FUNCTION add_customer_promotion() RETURNS TRIGGER
    AS $$
DECLARE
    valid_promo CURSOR FOR SELECT promo_id, category FROM Promos WHERE (now() > start_time) AND (end_time > now()) AND category IN ('All', 'First Order', 'Restaurant');
    table_row     RECORD;
BEGIN
    OPEN valid_promo;
    LOOP
        FETCH valid_promo INTO table_row;
        EXIT WHEN NOT FOUND;
        INSERT INTO Given(promo_id, cid)
        VALUES(table_row.promo_id, NEW.cid);
    END LOOP;
    CLOSE valid_promo;
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS add_customer_promotion_trigger ON Customers CASCADE;
CREATE TRIGGER add_customer_promotion_trigger
    AFTER INSERT 
    ON Customers
    FOR EACH ROW
    EXECUTE FUNCTION add_customer_promotion();

CREATE OR REPLACE FUNCTION add_promo() RETURNS TRIGGER
	AS $$
DECLARE
	all_cust 	CURSOR FOR SELECT cid, name, date_created FROM Customers join Accounts on (Accounts.account_id = Customers.cid);
	first_order	CURSOR FOR SELECT distinct C.cid FROM Customers C
				WHERE NOT EXISTS (SELECT 1 FROM Places P WHERE c.cid = P.cid);
	inactive	CURSOR FOR SELECT DISTINCT cid FROM places P1
						WHERE NOT EXISTS(
							SELECT 1 FROM customers JOIN places USING (cid)
								JOIN orders USING (oid)
							WHERE extract(month from age(current_timestamp, order_placed)) > 3);
	loyal_cust 	CURSOR FOR select distinct cid, money from
					(select cid, order_placed,(select coalesce(total_price, 0::money) + coalesce(delivery_fee, 0::money)) as money
					from Orders join Places using(oid)
					where extract(month from age('now'::timestamp - '1 month'::interval,  order_placed)) <= 1) as L
					where money >= 100::money;
	category	promos.category%TYPE;
	table_row 	RECORD;
BEGIN
	SELECT P.category INTO category
		FROM Promos P
		WHERE P.category = NEW.category;
	IF category = 'All' THEN
		OPEN all_cust;
		LOOP
		FETCH all_cust INTO table_row;
		EXIT WHEN NOT FOUND;
		INSERT INTO Given(promo_id, cid)
		VALUES(NEW.promo_id, table_row.cid);
		END LOOP;
		CLOSE all_cust;
	ELSIF category = 'First Order' THEN
		OPEN first_order;
		LOOP
		FETCH first_order INTO table_row;
		EXIT WHEN NOT FOUND;
		INSERT INTO Given(promo_id, cid)
		VALUES(NEW.promo_id, table_row.cid);
		END LOOP;
		CLOSE first_order;
	ELSIF category = 'Inactive Customers' THEN
		OPEN inactive;
		LOOP
		FETCH inactive INTO table_row;
		EXIT WHEN NOT FOUND;
		INSERT INTO Given(promo_id, cid)
		VALUES(NEW.promo_id, table_row.cid);
		END LOOP;
		CLOSE inactive;
	ELSIF category = 'Loyal Customers' THEN
		OPEN loyal_cust;
		LOOP
		FETCH loyal_cust INTO table_row;
		EXIT WHEN NOT FOUND;
		INSERT INTO Given(promo_id, cid)
		VALUES(NEW.promo_id, table_row.cid);
		END LOOP;
		CLOSE loyal_cust;
	ELSIF category = 'Restaurant' THEN
		OPEN all_cust;
		LOOP
		FETCH all_cust INTO table_row;
		EXIT WHEN NOT FOUND;
		INSERT INTO Given(promo_id, cid)
		VALUES(NEW.promo_id, table_row.cid);
		END LOOP;
		CLOSE all_cust;
	ELSE
		RAISE exception 'Invalid category';
	END IF;
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS add_promo_trigger ON Promos CASCADE;
CREATE TRIGGER add_promo_trigger
	AFTER INSERT 
	ON Promos
	FOR EACH ROW
	EXECUTE FUNCTION add_promo();

-- Data insertions
-- Accounts
insert into Accounts (account_id, account_pass, date_created, account_type) values ('c861493b-c7ee-4b6a-9d88-3a80da5686f0', 'NI7pkLaD', to_date('1/10/2019', 'dd/mm/yyyy'), 'FDSManager'),
('1b39d987-c6b0-4493-bb95-96e51af734b2', '3d2DMKr5PrT', to_date('10/6/2019', 'dd/mm/yyyy'), 'Customer'),
('e954e29a-40c7-42f0-8567-39ecf6705ffe', '0yktWzL7', to_date('24/2/2020', 'dd/mm/yyyy'), 'Customer'),
('c5b9026c-77a9-4977-9c30-5656e6b463c9', 'Fs1xGBE', to_date('2/8/2020', 'dd/mm/yyyy'), 'Customer'),
('15f6f4f8-42db-428a-949c-98fee850eefa', 'ymcqme3At', to_date('30/3/2020', 'dd/mm/yyyy'), 'Customer'),
('2fa0d23c-c53d-484a-90af-88dfce9e4d90', 'q66zcDrm5a', to_date('5/9/2019', 'dd/mm/yyyy'), 'Customer'),
('20f57096-5a09-4f4a-aa42-d32306752ddd', 'kIecjK03sQYZ', to_date('30/1/2020', 'dd/mm/yyyy'), 'Customer'),
('a805a76a-b8d6-4422-98e9-4f83ab58b1e8', 'wIB1JM', to_date('3/4/2020', 'dd/mm/yyyy'), 'Customer'),
('2dfd8ff6-9a23-47ac-b192-560f2ce98424', 'jUSkstY9HQUl', to_date('26/9/2019', 'dd/mm/yyyy'), 'Customer'),
('327b2555-f8d2-4f01-966e-e468b4cea5b0', 'uKELoF', to_date('3/10/2019', 'dd/mm/yyyy'), 'Customer'),
('3911899e-8fb4-4ad0-85d3-8b1d4b334a40', 'v2LCrbUvLg', to_date('6/4/2019', 'dd/mm/yyyy'), 'Customer'),
('66e51190-c8fc-4b5b-805d-b23cdb3f1ade', 'E9GxvyFbdtjS', to_date('1/10/2019', 'dd/mm/yyyy'), 'RestaurantStaff'),
('36f8a429-c338-4bc3-a54a-6a7ca0780e41', 'yrEEYmGcn', to_date('5/1/2020', 'dd/mm/yyyy'), 'RestaurantStaff'),
('bf4f405e-84ef-458c-b825-63d47379c374', '9a9z2H', to_date('9/6/2019', 'dd/mm/yyyy'), 'RestaurantStaff'),
('16a72b31-db4d-40bb-9ae6-4aa858cdb406', 'almLfEIRrj3T', to_date('2/10/2020', 'dd/mm/yyyy'), 'RestaurantStaff'),
('f47e6d61-62d2-4775-bf8d-81bafc4eb67f', 'yyXdSlH', to_date('4/12/2019', 'dd/mm/yyyy'), 'RestaurantStaff'),
('8299a5b8-2c49-485c-9fe5-2fe7cb154478', 'us3Xhu', to_date('6/2/2019', 'dd/mm/yyyy'), 'RestaurantStaff'),
('6cbc7c7a-cab1-4aec-bfaf-a4b74ca8c818', 'z28nCgK9SWYb', to_date('12/2/2020', 'dd/mm/yyyy'), 'RestaurantStaff'),
('5365e90e-6617-4f17-9607-89b25407e2f5', 'icIkX2ay5Ar', to_date('11/3/2019', 'dd/mm/yyyy'), 'RestaurantStaff'),
('2c3acca1-cc14-498a-b80a-889cb3fee4b5', 'NSvRBsMQ7z4', to_date('18/2/2019', 'dd/mm/yyyy'), 'RestaurantStaff'),
('fd1001b8-2503-4685-9661-fff922fa7798', 'Rx6d5HKor', to_date('2/11/2019', 'dd/mm/yyyy'), 'RestaurantStaff'),
('0486583b-01d0-4c03-95d1-5e11d75a9efd', 'ksswfSyZo', to_date('12/5/2019', 'dd/mm/yyyy'), 'FTRider'),
('f016b0e5-e404-4abf-a824-de805c3e122d', '1F4mKCrVx', to_date('12/5/2019', 'dd/mm/yyyy'), 'FTRider'),
('056b3388-4088-44e1-91a1-9fa128ab4ba3', '87ndxRALrBeO', to_date('12/5/2019', 'dd/mm/yyyy'), 'FTRider'),
('e9160f72-2094-413c-9764-e39a5d9e5038', 'byyLVU3', to_date('12/5/2019', 'dd/mm/yyyy'), 'FTRider'),
('c9e75699-4da2-4411-9e59-71d4b81856c0', '7V0T7KKEKFXq', to_date('12/5/2019', 'dd/mm/yyyy'), 'FTRider'),
('1e9736bd-78ab-4dbd-9adc-40622a2f7223', 'LYwVleS', to_date('12/5/2019', 'dd/mm/yyyy'), 'FTRider'),
('f0e9ac85-9aaf-415c-87bb-160dc74ac6e4', 'j7iF5AaiP', to_date('12/5/2019', 'dd/mm/yyyy'), 'FTRider'),
('de4b5419-eed5-4829-b013-36d87e28b4ec', '00t2HuvUplb', to_date('12/5/2019', 'dd/mm/yyyy'), 'FTRider'),
('06c7cf9a-cdfe-411d-93f4-5f6ad5d770bb', 'LAhF6AVml', to_date('1/12/2019', 'dd/mm/yyyy'), 'FTRider'),
('3267e8b9-110c-44fb-a817-2c0b243b21d6', 'BcDUMyc5lI', to_date('5/12/2019', 'dd/mm/yyyy'), 'FTRider'),
('03667134-3ab1-41e2-bff4-e1e6e14d3035', 'U2UE8YnAf', to_date('5/12/2019', 'dd/mm/yyyy'), 'FTRider'),
('58f57fcf-ee9d-4c16-94b4-ab3d945c83aa', 'yG9MDVTYdlP', to_date('5/12/2019', 'dd/mm/yyyy'), 'FTRider'),
('ccd9673a-c725-46bd-9577-0d26b4564d3f', 'H33yBh', to_date('6/12/2019', 'dd/mm/yyyy'), 'FTRider'),
('149ff060-8b44-4e1c-a56e-c8e6bff22096', 'mQEhePtZrQ', to_date('7/12/2019', 'dd/mm/yyyy'), 'FTRider'),
('b6ff623a-1568-42f5-9f8e-91d24e4123a6', 'yt9UfI', to_date('8/12/2019', 'dd/mm/yyyy'), 'FTRider'),
('0161cded-c664-4f1b-ad3f-7766dc48fecb', 'CylPtRE4ju', to_date('2/5/2019', 'dd/mm/yyyy'), 'FTRider'),
('b758096a-3183-4de0-9260-dbfce3bdbb28', 'QTswbLcY', to_date('2/5/2019', 'dd/mm/yyyy'), 'FTRider'),
('94bd068e-1a5c-4a73-92a0-81c64b499dc9', 'xJbueX7H', to_date('2/5/2019', 'dd/mm/yyyy'), 'FTRider'),
('c69ffc8f-ab47-46f5-a36d-58406ce626af', 'PQYoS6uP', to_date('12/5/2019', 'dd/mm/yyyy'), 'FTRider'),
('3c30a803-6834-41a9-b81e-6d54b6d5512d', 'I78qgG', to_date('12/5/2019', 'dd/mm/yyyy'), 'FTRider'),
('e6115a43-b3b7-4b45-9014-5f2ac0f913e2', 'qsfX5Ru', to_date('7/10/2019', 'dd/mm/yyyy'), 'PTRider'),
('5bc3951b-9388-4af0-9bf5-ce435acc14f3', '49h9jXB', to_date('7/10/2019', 'dd/mm/yyyy'), 'PTRider'),
('30dbce76-1e3a-4ca1-9b8f-751f8e0db1d9', 'x5BpVKoIjiUX', to_date('2/10/2019', 'dd/mm/yyyy'), 'PTRider'),
('9c79e02d-14b7-4604-b5d3-2afae637bd0b', 'XgFgRDStIRa', to_date('9/4/2019', 'dd/mm/yyyy'), 'PTRider'),
('2534042c-6526-44b1-abd5-532d7b7b281a', 'u0PxpGApRTmO', to_date('7/5/2019', 'dd/mm/yyyy'), 'PTRider'),
('ce80388a-d0cc-4096-9a01-7e8ef8d8017b', 'vvTjNg', to_date('15/1/2019', 'dd/mm/yyyy'), 'PTRider'),
('68973b78-642a-4ad9-ad0c-8f46977e6bf0', 'VN4c7SJc', to_date('30/7/2019', 'dd/mm/yyyy'), 'PTRider'),
('16710734-c5dc-460c-a7ad-54a7d3c92a63', 'S3LpbBAcSbM', to_date('12/5/2019', 'dd/mm/yyyy'), 'PTRider'),
('0dfbf360-7152-4c6a-b460-e103aa1ed4d6', 'LA2aqb4x', to_date('12/5/2019', 'dd/mm/yyyy'), 'PTRider');

-- Customers
insert into Customers (cid, name, reward_points) values ('1b39d987-c6b0-4493-bb95-96e51af734b2', 'Florida', 30),
('e954e29a-40c7-42f0-8567-39ecf6705ffe', 'Liesa', 15),
('c5b9026c-77a9-4977-9c30-5656e6b463c9', 'Fae', 84),
('15f6f4f8-42db-428a-949c-98fee850eefa', 'Florentia', 84),
('2fa0d23c-c53d-484a-90af-88dfce9e4d90', 'Deni', 17),
('20f57096-5a09-4f4a-aa42-d32306752ddd', 'Meriel', 11),
('a805a76a-b8d6-4422-98e9-4f83ab58b1e8', 'Ripley', 56),
('2dfd8ff6-9a23-47ac-b192-560f2ce98424', 'Merry', 71),
('327b2555-f8d2-4f01-966e-e468b4cea5b0', 'Mendie', 24),
('3911899e-8fb4-4ad0-85d3-8b1d4b334a40', 'Lilyan', 49);

-- FDS Managers
insert into FDSManagers (fds_id, name) values ('c861493b-c7ee-4b6a-9d88-3a80da5686f0', 'Claudetta');

-- Riders
insert into Riders (rid, name) values ('06c7cf9a-cdfe-411d-93f4-5f6ad5d770bb', 'Jonie'),
('3267e8b9-110c-44fb-a817-2c0b243b21d6', 'Everard'),
('03667134-3ab1-41e2-bff4-e1e6e14d3035', 'Henrie'),
('58f57fcf-ee9d-4c16-94b4-ab3d945c83aa', 'Orin'),
('ccd9673a-c725-46bd-9577-0d26b4564d3f', 'Sidnee'),
('149ff060-8b44-4e1c-a56e-c8e6bff22096', 'Ardene'),
('b6ff623a-1568-42f5-9f8e-91d24e4123a6', 'Lynna'),
('0161cded-c664-4f1b-ad3f-7766dc48fecb', 'Steffane'),
('b758096a-3183-4de0-9260-dbfce3bdbb28', 'Felicdad'),
('94bd068e-1a5c-4a73-92a0-81c64b499dc9', 'Katya'),
('c69ffc8f-ab47-46f5-a36d-58406ce626af', 'Bowie'),
('3c30a803-6834-41a9-b81e-6d54b6d5512d', 'Everett'),
('0486583b-01d0-4c03-95d1-5e11d75a9efd', 'Nerty'),
('f016b0e5-e404-4abf-a824-de805c3e122d', 'Tait'),
('056b3388-4088-44e1-91a1-9fa128ab4ba3', 'Josie'),
('e9160f72-2094-413c-9764-e39a5d9e5038', 'Adrea'),
('c9e75699-4da2-4411-9e59-71d4b81856c0', 'Antonie'),
('1e9736bd-78ab-4dbd-9adc-40622a2f7223', 'Kare'),
('f0e9ac85-9aaf-415c-87bb-160dc74ac6e4', 'Coriss'),
('de4b5419-eed5-4829-b013-36d87e28b4ec', 'Zita'),
('e6115a43-b3b7-4b45-9014-5f2ac0f913e2', 'Travers'),
('5bc3951b-9388-4af0-9bf5-ce435acc14f3', 'Lemuel'),
('30dbce76-1e3a-4ca1-9b8f-751f8e0db1d9', 'Mireielle'),
('9c79e02d-14b7-4604-b5d3-2afae637bd0b', 'Eda'),
('2534042c-6526-44b1-abd5-532d7b7b281a', 'Vic'),
('ce80388a-d0cc-4096-9a01-7e8ef8d8017b', 'Crosby'),
('68973b78-642a-4ad9-ad0c-8f46977e6bf0', 'Lambert'),
('16710734-c5dc-460c-a7ad-54a7d3c92a63', 'Ring'),
('0dfbf360-7152-4c6a-b460-e103aa1ed4d6', 'Elena');

-- FT Riders
insert into FTRiders (rid, name) values ('06c7cf9a-cdfe-411d-93f4-5f6ad5d770bb', 'Jonie'),
('3267e8b9-110c-44fb-a817-2c0b243b21d6', 'Everard'),
('03667134-3ab1-41e2-bff4-e1e6e14d3035', 'Henrie'),
('58f57fcf-ee9d-4c16-94b4-ab3d945c83aa', 'Orin'),
('ccd9673a-c725-46bd-9577-0d26b4564d3f', 'Sidnee'),
('149ff060-8b44-4e1c-a56e-c8e6bff22096', 'Ardene'),
('b6ff623a-1568-42f5-9f8e-91d24e4123a6', 'Lynna'),
('0161cded-c664-4f1b-ad3f-7766dc48fecb', 'Steffane'),
('b758096a-3183-4de0-9260-dbfce3bdbb28', 'Felicdad'),
('94bd068e-1a5c-4a73-92a0-81c64b499dc9', 'Katya'),
('c69ffc8f-ab47-46f5-a36d-58406ce626af', 'Bowie'),
('3c30a803-6834-41a9-b81e-6d54b6d5512d', 'Everett'),
('0486583b-01d0-4c03-95d1-5e11d75a9efd', 'Nerty'),
('f016b0e5-e404-4abf-a824-de805c3e122d', 'Tait'),
('056b3388-4088-44e1-91a1-9fa128ab4ba3', 'Josie'),
('e9160f72-2094-413c-9764-e39a5d9e5038', 'Adrea'),
('c9e75699-4da2-4411-9e59-71d4b81856c0', 'Antonie'),
('1e9736bd-78ab-4dbd-9adc-40622a2f7223', 'Kare'),
('f0e9ac85-9aaf-415c-87bb-160dc74ac6e4', 'Coriss'),
('de4b5419-eed5-4829-b013-36d87e28b4ec', 'Zita');

-- PT Riders
insert into PTRiders (rid, name) values ('e6115a43-b3b7-4b45-9014-5f2ac0f913e2', 'Travers'),
('5bc3951b-9388-4af0-9bf5-ce435acc14f3', 'Lemuel'),
('30dbce76-1e3a-4ca1-9b8f-751f8e0db1d9', 'Mireielle'),
('9c79e02d-14b7-4604-b5d3-2afae637bd0b', 'Eda'),
('2534042c-6526-44b1-abd5-532d7b7b281a', 'Vic'),
('ce80388a-d0cc-4096-9a01-7e8ef8d8017b', 'Crosby'),
('68973b78-642a-4ad9-ad0c-8f46977e6bf0', 'Lambert'),
('16710734-c5dc-460c-a7ad-54a7d3c92a63', 'Ring'),
('0dfbf360-7152-4c6a-b460-e103aa1ed4d6', 'Elena');

-- Restaurants
insert into Restaurants (name, order_threshold, address) values ('Exeexe-Restaurant', '$11.47', '10 Dempsey Rd, #01-23, S247700'),
	('Simonis and Sons', '$12.24', '#01-07 Alexis Condominium, 356 Alexandra Rd, S159948'),
	('Vandervort, Rice and Lehner', '$12.62', '1 Cuscaden Rd, Level 2 Regent Singapore, Cuscaden Rd, S249715'),
	('Bergnaum LLC', '$14.06', '260 Upper Bukit Timah Rd, #01-01, S588190'),
	('Abbott-Harris', '$11.18', '374 Bukit Batok Street 31, HDB, S650374'),
	('Streich-Predovic', '$11.94', '#01-01 Orchard Rendezvous Hotel, 1 Tanglin Rd, S247905'),
	('Streich, Brekke and Bednar', '$11.18', '118 Commonwealth Cres, #01-29, S140118'),
	('Blick, Boyer and Schroeder', '$11.84', 'Faber Peak Singapore, Level 2, 109 Mount Faber Road, 099203'),
	('Kirlin-Jacobson', '$10.36', '421 River Valley Rd, S248320'),
	('Ziemann-Halvorson', '$10.20', '#01, 10 Dempsey Rd, 21, S247700');

-- Restaurant staffs
insert into RestaurantStaffs (staff_id, rest_id) values ('66e51190-c8fc-4b5b-805d-b23cdb3f1ade', 1),
	('36f8a429-c338-4bc3-a54a-6a7ca0780e41', 2),
	('bf4f405e-84ef-458c-b825-63d47379c374', 3),
	('16a72b31-db4d-40bb-9ae6-4aa858cdb406', 4),
	('f47e6d61-62d2-4775-bf8d-81bafc4eb67f', 5),
	('8299a5b8-2c49-485c-9fe5-2fe7cb154478', 6),
	('6cbc7c7a-cab1-4aec-bfaf-a4b74ca8c818', 7),
	('5365e90e-6617-4f17-9607-89b25407e2f5', 8),
	('2c3acca1-cc14-498a-b80a-889cb3fee4b5', 9),
	('fd1001b8-2503-4685-9661-fff922fa7798', 10);

-- WWS
INSERT into WWS (start_day) values 
-- first ft
	(0),
	(0),
	(0),
	(0),
	(2),
	(3);

-- MWS
INSERT into MWS (start_week) values 
-- first rider
	(14);

-- Has
INSERT INTO Has(mid, wid, working_week) values 
-- First ft
	(1, 1, 1),
	(1, 2, 2),
	(1, 3, 3),
	(1, 4, 4);

-- PTWorks
INSERT into PTWorks (rid, working_week, total_hours, wid) VALUES ('e6115a43-b3b7-4b45-9014-5f2ac0f913e2', 1, 40, 5),
	('e6115a43-b3b7-4b45-9014-5f2ac0f913e2', 2, 40, 6);

-- FTWorks, total_hours
insert into FTWorks (rid, working_month, total_hours, mid) values 
	('06c7cf9a-cdfe-411d-93f4-5f6ad5d770bb', 1, 160, 1);

INSERT into Shift (actual_date) values 
-- pt
	('2020-04-02'),
	('2020-04-03'),
	('2020-04-04'),
	('2020-04-05'),
	('2020-04-06'),

-- ftr 1
	('2020-04-02'),
	('2020-04-03'),
	('2020-04-04'),
	('2020-04-05'),
	('2020-04-06'),

	('2020-04-09'),
	('2020-04-10'),
	('2020-04-11'),
	('2020-04-12'),
	('2020-04-13'),

	('2020-04-16'),
	('2020-04-17'),
	('2020-04-18'),
	('2020-04-19'),
	('2020-04-20'),

	('2020-04-23'),
	('2020-04-24'),
	('2020-04-25'),
	('2020-04-26'),
	('2020-04-27'),

-- pt 2nd wk
	('2020-04-09'),
	('2020-04-10'),
	('2020-04-11'),
	('2020-04-12'),
	('2020-04-13');

INSERT into ShiftInfo (start_time, end_time) values 
-- Shift 1
	('10:00:00', '14:00:00'),
	('15:00:00', '19:00:00'),
-- Shift 2
	('11:00:00', '15:00:00'),
	('16:00:00', '20:00:00'),
-- Shift 3
	('12:00:00', '16:00:00'),
	('17:00:00', '21:00:00'),
-- Shift 4
	('13:00:00', '17:00:00'),
	('18:00:00', '22:00:00');

-- Describes
INSERT into Describes (shift_id, iid, working_interval) values
-- 4/2 do shift 1
	(1, 1, 1),
	(1, 2, 2),
-- 4/3 do shift 2
	(2, 3, 1),
	(2, 4, 2),
-- 4/4 do shift 3
	(3, 5, 1),
	(3, 6, 2),
-- 4/5 do shift 4
	(4, 7, 1),
	(4, 8, 2),
-- 4/6 do shift 1
	(5, 1, 1),
	(5, 2, 2);

-- Contains
INSERT into Contains (wid, working_day, shift_id) values 
-- Part time 1
	(5, 1, 1), 
	(5, 2, 2),
	(5, 3, 3),
	(5, 4, 4),
	(5, 5, 5),

	(6, 1, 26), 
	(6, 2, 27),
	(6, 3, 28),
	(6, 4, 29),
	(6, 5, 30),	
-- ft 1
	(1, 1, 6), 
	(1, 2, 7),
	(1, 3, 8),
	(1, 4, 9),
	(1, 5, 10),

	(2, 1, 11), 
	(2, 2, 12),
	(2, 3, 13),
	(2, 4, 14),
	(2, 5, 15),

	(3, 1, 16), 
	(3, 2, 17),
	(3, 3, 18),
	(3, 4, 19),
	(3, 5, 20),

	(4, 1, 21), 
	(4, 2, 22),
	(4, 3, 23),
	(4, 4, 24),
	(4, 5, 25);

-- Salaries
insert into Salaries (rid, start_date, end_date, amount) values ('06c7cf9a-cdfe-411d-93f4-5f6ad5d770bb', '2020-02-01 01:12:21', '2020-03-01 03:31:20', '$2674.36'),
('3267e8b9-110c-44fb-a817-2c0b243b21d6', '2020-02-01 03:40:48', '2020-03-01 05:14:34', '$2996.84'),
('03667134-3ab1-41e2-bff4-e1e6e14d3035', '2020-02-01 18:08:39', '2020-03-01 23:25:53', '$2835.60'),
('58f57fcf-ee9d-4c16-94b4-ab3d945c83aa', '2020-02-01 20:49:56', '2020-03-01 20:12:25', '$2808.27'),
('ccd9673a-c725-46bd-9577-0d26b4564d3f', '2020-02-01 05:20:06', '2020-03-01 08:37:28', '$3788.22'),
('149ff060-8b44-4e1c-a56e-c8e6bff22096', '2020-02-01 02:07:09', '2020-03-01 07:17:09', '$2866.29'),
('b6ff623a-1568-42f5-9f8e-91d24e4123a6', '2020-02-01 01:27:23', '2020-03-01 15:24:51', '$3393.74'),
('0161cded-c664-4f1b-ad3f-7766dc48fecb', '2020-02-01 14:51:53', '2020-03-01 05:19:50', '$3927.33'),
('b758096a-3183-4de0-9260-dbfce3bdbb28', '2020-02-01 16:06:06', '2020-03-01 00:58:10', '$2655.22'),
('94bd068e-1a5c-4a73-92a0-81c64b499dc9', '2020-02-01 09:16:37', '2020-03-01 15:55:03', '$3828.91'),
('c69ffc8f-ab47-46f5-a36d-58406ce626af', '2020-02-01 00:20:46', '2020-03-01 13:33:13', '$2931.22'),
('3c30a803-6834-41a9-b81e-6d54b6d5512d', '2020-02-01 18:47:25', '2020-03-01 22:16:32', '$3217.69'),
('0486583b-01d0-4c03-95d1-5e11d75a9efd', '2020-02-01 03:46:16', '2020-03-01 01:29:18', '$3071.09'),
('f016b0e5-e404-4abf-a824-de805c3e122d', '2020-02-01 21:49:58', '2020-03-01 13:49:46', '$3259.96'),
('056b3388-4088-44e1-91a1-9fa128ab4ba3', '2020-02-01 14:00:23', '2020-03-01 07:42:35', '$3359.67'),
('e9160f72-2094-413c-9764-e39a5d9e5038', '2020-02-01 16:47:36', '2020-03-01 00:21:25', '$3220.97'),
('c9e75699-4da2-4411-9e59-71d4b81856c0', '2020-02-01 01:37:46', '2020-03-01 09:50:08', '$3091.61'),
('1e9736bd-78ab-4dbd-9adc-40622a2f7223', '2020-02-01 16:23:23', '2020-03-01 07:06:08', '$3927.92'),
('f0e9ac85-9aaf-415c-87bb-160dc74ac6e4', '2020-02-01 07:52:36', '2020-03-01 05:12:28', '$2564.14'),
('de4b5419-eed5-4829-b013-36d87e28b4ec', '2020-02-01 20:01:01', '2020-03-01 18:46:39', '$3788.71'),
('e6115a43-b3b7-4b45-9014-5f2ac0f913e2', '2020-02-01 10:31:46', '2020-03-01 18:13:39', '$3640.98'),
('5bc3951b-9388-4af0-9bf5-ce435acc14f3', '2020-02-01 16:59:18', '2020-03-01 14:30:32', '$2594.38'),
('30dbce76-1e3a-4ca1-9b8f-751f8e0db1d9', '2020-02-01 11:21:53', '2020-03-01 23:25:51', '$2779.52'),
('9c79e02d-14b7-4604-b5d3-2afae637bd0b', '2020-02-01 00:57:41', '2020-03-01 07:18:13', '$2556.39'),
('2534042c-6526-44b1-abd5-532d7b7b281a', '2020-02-01 01:43:29', '2020-03-01 15:58:20', '$2930.18'),
('ce80388a-d0cc-4096-9a01-7e8ef8d8017b', '2020-02-01 10:53:38', '2020-03-01 20:49:54', '$2950.20'),
('68973b78-642a-4ad9-ad0c-8f46977e6bf0', '2020-02-01 02:50:08', '2020-03-01 20:06:09', '$3222.47'),
('16710734-c5dc-460c-a7ad-54a7d3c92a63', '2020-02-01 15:51:25', '2020-03-01 16:15:50', '$3947.52'),
('0dfbf360-7152-4c6a-b460-e103aa1ed4d6', '2020-02-01 07:42:42', '2020-03-01 07:34:57', '$3729.79');

-- Orders
insert into Orders (rid, rest_id, order_status, delivery_fee, total_price, order_placed, depart_for_rest, arrive_at_rest, depart_for_delivery, deliver_to_cust, rating) values ('3267e8b9-110c-44fb-a817-2c0b243b21d6', 1, 'paid', '$0.08', '$16.70', '2020-04-15 12:00:00', '2020-04-15 12:00:00', '2020-04-15 12:05:00', '2020-04-15 12:15:00', '2020-04-15 12:40:00', 4),
('3c30a803-6834-41a9-b81e-6d54b6d5512d', 1, 'paid', '$1.01', '$20.20', '2020-04-15 12:10:00', '2020-04-15 12:10:00', '2020-04-15 12:15:00', '2020-04-15 13:00:00', '2020-04-15 14:00:00', 5);
insert into Orders (rid, rest_id, order_status, delivery_fee, total_price, order_placed, depart_for_rest, arrive_at_rest, depart_for_delivery, deliver_to_cust) values ('1e9736bd-78ab-4dbd-9adc-40622a2f7223', 1, 'paid', '$4.45', '$89.00', '2020-04-15 12:05:00', '2020-04-15 12:05:00', '2020-04-15 12:15:00', '2020-04-15 12:25:00', '2020-04-15 12:35:00');
insert into Orders (rid, rest_id, order_status, delivery_fee, total_price, order_placed, depart_for_rest, arrive_at_rest, depart_for_delivery, deliver_to_cust, rating) values ('2534042c-6526-44b1-abd5-532d7b7b281a', 2, 'paid', '$1.39', '$27.93', '2020-04-15 20:00:00', '2020-04-15 20:00:00', '2020-04-15 20:05:00', '2020-04-15 20:07:00', '2020-04-15 20:15:00', 4),
('0486583b-01d0-4c03-95d1-5e11d75a9efd', 2, 'paid', '$3.84', '$76.89', '2020-04-15 12:20:00', '2020-04-15 12:20:00', '2020-04-15 12:30:00', '2020-04-15 12:40:00', '2020-04-15 13:00:00', 5),
('0486583b-01d0-4c03-95d1-5e11d75a9efd', 3, 'paid', '$4.62', '$92.51', '2020-04-15 12:30:00', '2020-04-15 12:30:00', '2020-04-15 12:40:00', '2020-04-15 12:45:00', '2020-04-15 13:00:00', 4),
('0161cded-c664-4f1b-ad3f-7766dc48fecb', 3, 'paid', '$1.19', '$23.82', '2020-04-15 12:25:00', '2020-04-15 12:25:00', '2020-04-15 12:35:00', '2020-04-15 12:45:00', '2020-04-15 13:00:00', 3),
('03667134-3ab1-41e2-bff4-e1e6e14d3035', 3, 'paid', '$2.41', '$48.28', '2020-04-15 12:35:00', '2020-04-15 12:35:00', '2020-04-15 12:45:00', '2020-04-15 12:55:00', '2020-04-15 13:00:00', 4),
('68973b78-642a-4ad9-ad0c-8f46977e6bf0', 4, 'paid', '$2.46', '$49.22', '2020-04-15 12:40:00', '2020-04-15 12:40:00', '2020-04-15 12:50:00', '2020-04-15 12:50:00', '2020-04-15 13:00:00', 5),
('06c7cf9a-cdfe-411d-93f4-5f6ad5d770bb', 4, 'paid', '$4.63', '$98.67', '2020-04-15 12:45:00', '2020-04-15 12:45:00', '2020-04-15 13:00:00', '2020-04-15 13:10:00', '2020-04-15 13:15:00', 5);

-- Places
insert into Places (oid, cid, address, payment_method) values (1, '1b39d987-c6b0-4493-bb95-96e51af734b2', 'Blk 760 Yishun Ring rd #08-18 S760760', 'credit-card'),
(2, '1b39d987-c6b0-4493-bb95-96e51af734b2', 'Blk 761 Yishun Ring rd #08-18 S760761', 'credit-card'),
(3, '1b39d987-c6b0-4493-bb95-96e51af734b2', 'Blk 762 Yishun Ring rd #08-18 S760762', 'credit-card'),
(4, 'e954e29a-40c7-42f0-8567-39ecf6705ffe', 'Blk 763 Yishun Ring rd #08-18 S760763', 'credit-card'),
(5, 'c5b9026c-77a9-4977-9c30-5656e6b463c9', 'Blk 764 Yishun Ring rd #08-18 S760764', 'credit-card'),
(6, 'c5b9026c-77a9-4977-9c30-5656e6b463c9', 'Blk 765 Yishun Ring rd #08-18 S760765', 'credit-card'),
(7, 'a805a76a-b8d6-4422-98e9-4f83ab58b1e8', 'Blk 766 Yishun Ring rd #08-18 S760766', 'credit-card'),
(8, '2dfd8ff6-9a23-47ac-b192-560f2ce98424', 'Blk 767 Yishun Ring rd #08-18 S760767', 'credit-card'),
(9, '327b2555-f8d2-4f01-966e-e468b4cea5b0', 'Blk 768 Yishun Ring rd #08-18 S760768', 'credit-card'),
(10, '3911899e-8fb4-4ad0-85d3-8b1d4b334a40', 'Blk 769 Bishan Ring rd #08-18 S760769', 'credit-card');

-- Foods
insert into Foods (rest_id, name, price, food_limit, quantity, category) values (1, 'exeexe pancake', '$1.20', 20, 20, 'Main Dish'),
	(1, 'exeexe hotcake', '$1.50', 20, 20, 'Main Dish'),
	(1, 'exeexe ice-cream cake', '$10.10', 15, 15, 'Dessert'),
	(1, 'exeexe chocolate cake', '$5.10', 12, 12, 'Dessert'),
	(1, 'exeexe bubble tea', '$2.10', 16, 16, 'Drink'),
	(1, 'exeexe brown sugar milk tea', '$5.10', 50, 50, 'Drink'),
	(1, 'exeexe milo', '$1.10', 100, 100, 'Drink'),
	(1, 'exeexe chicken rice', '$3.50', 16, 16, 'Main Dish'),
	(1, 'exeexe duck rice', '$3.50', 16, 16, 'Main Dish'),
	(1, 'exeexe chicken drumstick', '$1.50', 16, 16, 'Side Dish');
insert into Foods (rest_id, name, price, food_limit, quantity, category) values 
	(2, 'Vanilla ice cream', '$3.00', 100, 100, 'Dessert'),
	(2, 'Chocolate lava cake', '$5.00', 50, 50, 'Dessert'),
	(2, 'Coke zero', '$2.10', 10, 50, 'Drink'),
	(2, 'Sprite', '$5.10', 20, 20, 'Drink'),
	(2, '7-ups', '$1.10', 20, 20, 'Drink'),
	(2, 'Aglio Aglio', '$3.50', 10, 10, 'Main Dish'),
	(2, 'Spaghetti', '$5.50', 10, 10, 'Main Dish'),
	(2, 'Beef steak', '$10.50', 10, 10, 'Side Dish');
insert into Foods (rest_id, name, price, food_limit, quantity, category) values 
	(3, 'Chocolate ice cream', '$3.00', 100, 100, 'Dessert'),
	(3, 'Chocolate lava cake', '$5.00', 500, 500, 'Dessert'),
	(3, 'Coke zero', '$2.10', 100, 500, 'Drink'),
	(3, 'Sprite', '$5.10', 200, 200, 'Drink'),
	(3, '7-ups', '$1.10', 200, 200, 'Drink'),
	(3, 'Chicken chop', '$7.50', 100, 100, 'Main Dish'),
	(3, 'Lamb chop', '$15.50', 100, 100, 'Main Dish'),
	(3, 'Beef steak', '$10.50', 100, 100, 'Side Dish');
insert into Foods (rest_id, name, price, food_limit, quantity, category) values 
	(4, 'Coke zero', '$2.10', 100, 500, 'Drink'),
	(4, '7-ups', '$1.10', 200, 200, 'Drink'),
	(4, 'Chicken chop', '$7.50', 100, 100, 'Main Dish'),
	(4, 'NAMA Lamb chop', '$15.50', 100, 100, 'Main Dish'),
	(4, 'NAMA Beef steak', '$10.50', 100, 100, 'Side Dish');
insert into Foods (rest_id, name, price, food_limit, quantity, category) values 
	(5, 'Chocolate ice cream', '$3.00', 100, 100, 'Dessert'),
	(5, 'Chocolate lava cake', '$5.00', 500, 500, 'Dessert'),
	(5, 'Coke zero', '$2.10', 100, 500, 'Drink'),
	(5, 'Sprite', '$5.10', 200, 200, 'Drink'),
	(5, 'Chicken chop', '$7.50', 100, 100, 'Main Dish'),
	(5, 'Fiery Lamb chop', '$15.50', 100, 100, 'Main Dish'),
	(5, 'Wagyu Beef steak', '$50.50', 100, 100, 'Side Dish');
insert into Foods (rest_id, name, price, food_limit, quantity, category) values 
	(6, 'Chocolate ice cream', '$3.00', 100, 100, 'Dessert'),
	(6, 'Chocolate lava cake', '$5.00', 500, 500, 'Dessert'),
	(6, 'Coke zero', '$2.10', 100, 500, 'Drink'),
	(6, 'Sprite', '$5.10', 200, 200, 'Drink'),
	(6, 'Black pepper Chicken chop', '$7.50', 100, 100, 'Main Dish'),
	(6, 'Fiery Lamb chop', '$15.50', 100, 100, 'Main Dish'),
	(6, 'Beef steak', '$10.50', 100, 100, 'Side Dish');
insert into Foods (rest_id, name, price, food_limit, quantity, category) values 
	(7, 'Chocolate ice cream', '$3.00', 100, 100, 'Dessert'),
	(7, 'Chocolate lava', '$5.00', 500, 500, 'Dessert'),
	(7, 'Coke zero', '$2.10', 100, 500, 'Drink'),
	(7, 'Sprite', '$5.10', 200, 200, 'Drink'),
	(7, 'Chicken chop', '$7.50', 100, 100, 'Main Dish'),
	(7, 'Soury Lamb chop', '$15.50', 100, 100, 'Main Dish'),
	(7, 'Wagyu Beef steak', '$50.50', 100, 100, 'Side Dish');
insert into Foods (rest_id, name, price, food_limit, quantity, category) values 
	(8, 'Chocolate ice cream', '$3.00', 100, 100, 'Dessert'),
	(8, 'Chocolate lava', '$5.00', 500, 500, 'Dessert'),
	(8, 'Coke zero', '$2.10', 100, 500, 'Drink'),
	(8, 'Sprite', '$5.10', 200, 200, 'Drink'),
	(8, 'Chicken chop', '$7.50', 100, 100, 'Main Dish'),
	(8, 'Fiery Lamb chop', '$15.50', 100, 100, 'Main Dish'),
	(8, 'Wagyu Beef steak', '$50.50', 100, 100, 'Side Dish');
insert into Foods (rest_id, name, price, food_limit, quantity, category) values 
	(9, 'Chocolate ice cream', '$3.00', 100, 100, 'Dessert'),
	(9, 'Chocolate lava', '$5.00', 500, 500, 'Dessert'),
	(9, 'Coke zero', '$2.10', 100, 500, 'Drink'),
	(9, 'Sprite', '$5.10', 200, 200, 'Drink'),
	(9, 'Chicken chop', '$7.50', 100, 100, 'Main Dish'),
	(9, 'Fiery Lamb chop', '$15.50', 100, 100, 'Main Dish'),
	(9, 'Wagyu Beef steak', '$50.50', 100, 100, 'Side Dish');
insert into Foods (rest_id, name, price, food_limit, quantity, category) values 
	(10, 'Chocolate Foundae', '$7.00', 100, 100, 'Dessert'),
	(10, 'Chocolate lava cake', '$5.00', 500, 500, 'Dessert'),
	(10, 'Coke', '$2.10', 100, 500, 'Drink'),
	(10, 'Sprite', '$5.10', 200, 200, 'Drink'),
	(10, 'Chicken chop', '$7.50', 100, 100, 'Main Dish'),
	(10, 'Fiery Lamb chop', '$15.50', 100, 100, 'Main Dish'),
	(10, 'Beef Cubes', '$10.50', 100, 100, 'Side Dish');

-- Consists
insert into Consists (oid, fid, quantity, total_price, review) values (1, 1, 2, '$2.40', 'Taste not bad! Can consider buy again.'),
(1, 5, 2, '$4.20', 'Worth the price!! Recommend this food!'),
(1, 3, 1, '$10.10', 'Bad taste. Not worth the price!'),
(2, 4, 1, '$5.10', 'No comment!');
insert into Consists (oid, fid, quantity, total_price) values (3, 8, 5, '$17.50'),
(3, 9, 5, '$17.50'),
(3, 10, 2, '$3.00'),
(3, 6, 10, '$51.00');

-- CreditCards
insert into CreditCards (cid, card_number) values ('1b39d987-c6b0-4493-bb95-96e51af734b2', '4000-1523-1652-4534'),
('1b39d987-c6b0-4493-bb95-96e51af734b2', '1543-4894-1561-1564'),
('1b39d987-c6b0-4493-bb95-96e51af734b2', '1565-3158-1564-1945'),
('1b39d987-c6b0-4493-bb95-96e51af734b2', '1596-1345-1894-1564'),
('1b39d987-c6b0-4493-bb95-96e51af734b2', '5434-4565-5270-0457');

-- Promos
insert into Promos (creator_id, details, category, promo_type, discount_value, trigger_value, start_time, end_time) values ('66e51190-c8fc-4b5b-805d-b23cdb3f1ade', 'Order $20 and above this month to get a $3 discount on your total order.', 'Restaurant', 'Flat Rate', '3', '20', '03/04/2020', '02/05/2020');
insert into Promos (creator_id, details, category, promo_type, discount_value, trigger_value, start_time, end_time) values ('66e51190-c8fc-4b5b-805d-b23cdb3f1ade', 'Order $80 and above to qualify for a 20% discount on your total order.', 'Restaurant', 'Percent', '20', '80', '03/04/2020', '02/05/2020');
-- Uses
insert into Uses (oid, promo_id, amount) values (2, 1, '$3.00');
insert into Uses (oid, promo_id, amount) values (3, 2, '$17.80');
