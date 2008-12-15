/* This is the postgresql schema for FormBuilder */

-- 
-- form_data_sequence
--
create sequence "form_data_sequence";

-- 
-- form_data
--
-- This is the form itself
create table "form_data" (
	"id" integer primary key not null default nextval( 'form_data_sequence' ),
	"active" boolean,
	"send_email" boolean,
	"page_count" integer,
	"number_of_elements" integer default '0',
	"created" timestamp with time zone,
	"modified" timestamp with time zone,
	"start_date" timestamp with time zone,
	"stop_date" timestamp with time zone,
	"ident" varchar not null, -- name of form and uri 
	"name" varchar, -- display name of form (pretty)
	"email_address" varchar not null, -- to send results to
	"email_subject" varchar,
	"redirect_cancel" varchar not null, -- for cancel and conclusion
	"redirect_confirm" varchar,
	"confirm_page"	varchar,
	"frame" varchar,
	"store_as" varchar,
	"send_as" varchar,
	"dir" varchar, -- Delete field
	"filename" varchar,
	"xcel_templ" text, -- Delete field
	"txt_templ" text, -- Delete field
	"html_templ" text, -- Delete field
	"description" text,
	"pre_text" text, -- Delete field
	"text" text, -- Delete field
	"post_text" text -- Delete field
);

--
-- form_element_sequence
--
create sequence "form_element_sequence";

--
-- form_element
--
-- This is an element of a form - a question
create table "form_element" (
	"id" integer primary key not null default nextval( 'form_element_sequence' ),
	"required" boolean default 'false',
	"checked" boolean default 'false',
	"readonly" boolean default 'false',
	"multiple" boolean default 'false',
	"form_data_id" integer,
	"form_types_id" integer,
	"form_requirements_id" integer,
	"max_length" integer,
	"tab_index" integer,
	"row_count" integer, 
	"col_count" integer,
	"size_count" integer,
	"page_number" integer,
	"created" timestamp with time zone,
	"modified" timestamp with time zone,
	"question_number" real,
	"name" varchar not null,
	"value" varchar,
	"css_class" varchar,
	"src" varchar,
	"addition_params" text,
	"alt" text,
	"pre_text" text,
	"post_text" text,
	"error_msg" text
);

--
-- form_default_elements_sequence
--
create sequence "form_default_elements_sequence";

--
-- form_default_elements
--
create table "form_default_elements" (
	"id" integer primary key not null default nextval( 'form_default_elements_sequence' ),
	"form_element_id" integer,
	"name" varchar
);

--
-- form_types_sequence
--
create sequence "form_types_sequence";

--
-- form_types
--
-- Available types of elements
--
create table "form_types" (
	"id" integer primary key not null default nextval( 'form_types_sequence' ),
	"type" varchar,
	"name" varchar default '0',
	"value" varchar default '0',
	"row" varchar default '0',
	"col" varchar default '0',
	"size" varchar default '0',
	"max" varchar default '0',
	"checkd" varchar default '0',
	"read" varchar default '0',
	"mult" varchar default '0',
	"tab" varchar default '0',
	"css" varchar default '0',
	"src" varchar default '0',
	"alt" varchar default '0' 
);

--
-- form_validate_sequence
--
create sequence "form_validate_sequence";

--
-- form_validate
--
-- Available forms of validation
create table "form_validate" (
	"id" integer primary key not null default nextval( 'form_validate_sequence' ),
	"name" varchar not null,
	"regex" varchar,
	"func" varchar
);

