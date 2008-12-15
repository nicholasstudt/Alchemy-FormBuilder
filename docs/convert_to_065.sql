-- Add form_element.isdefault bool default false
alter table add column isdefault boolean default 'false';

-- Rename form_requirements_id
alter table form_element rename form_requirements_id to form_validate_id;


-- Fix sequence names.
alter sequence form_data_sequence rename to form_data_seq;
alter table form_data alter column id set default nextval('form_data_seq');

alter sequence form_element_sequence rename to form_element_seq;
alter table form_element alter column id set default nextval('form_element_seq');

alter sequence form_types_sequence rename to form_types_seq;
alter table form_types alter column id set default nextval('form_types_seq');

alter sequence form_validate_sequence rename to form_validate_seq;
alter table form_validate alter column id set default nextval('form_validate_seq');

-- Delete form_data.pre_text, form_data.post_text, form_data.xcel_templ, form_data.txt_templ, form_data.html_templ
alter table form_data drop column dir;
alter table form_data drop column xcel_templ;
alter table form_data drop column txt_templ;
alter table form_data drop column html_templ;
alter table form_data drop column pre_text;
alter table form_data drop column text;
alter table form_data drop column post_text;

-- Add table constraints.
alter table form_element add CONSTRAINT form_element_form_data_id_fkey FOREIGN KEY(form_data_id) REFERENCES form_data (id);
alter table form_element add CONSTRAINT form_element_form_types_id_fkey FOREIGN KEY(form_types_id) REFERENCES form_types (id);

update form_element set form_validate_id = null where form_validate_id = 0;
alter table form_element add CONSTRAINT form_element_form_validate_id_fkey FOREIGN KEY(form_validate_id) REFERENCES form_validate (id);

-- Move form_data.text content to the first element in a form. 
-- Move form_data.pre_text content to the first element in a form. 
-- Move form_data.post_text content to the last element in a form. 
-- Remove form_default_elements.
