create table accounts(
    active boolean not null,
    account_id bigserial not null,
    customer_id bigint not null,
    service_plan_id bigint not null,
    address varchar(255) not null,
    city varchar(255) not null,
    primary key (account_id)
);

create table customers(
    customer_id bigserial not null,
    email_address varchar(255) not null,
    first_name varchar(255) not null,
    last_name varchar(255) not null,
    phone_number varchar(255) not null,
    primary key (customer_id)
);

create table service_plans(
    installation_price integer,
    is_default boolean,
    monthly_price integer,
    service_plan_id bigserial not null,
    description varchar(255),
    name varchar(255) not null unique,
    primary key (service_plan_id)
);

create table support_case_activities(
    activity_id bigserial not null,
    creation_date timestamp not null,
    support_case_id bigint not null,
    activity_type varchar(255) check (activity_type in ('AUTOMATION','HOME_VISIT','INBOUND_CALL','INBOUND_EMAIL','OUTBOUND_CALL','OUTBOUND_EMAIL','NOTE')),
    notes varchar(255) not null,
    primary key (activity_id)
);

create table support_case_activity_types(
    activity_type_id bigserial not null,
    name varchar(255) not null,
    primary key (activity_type_id)
);

create table support_cases(
    account_id bigint not null,
    creation_date timestamp not null,
    support_case_id bigserial not null,
    description varchar(255) not null,
    queue varchar(255) check (queue in ('L1','L2','SITE_VISIT','CLOSED')),
    assigned_to varchar(255),
    primary key (support_case_id)
);

alter table if exists accounts add constraint FKn6x8pdp50os8bq5rbb792upse foreign key (customer_id) references customers;
alter table if exists accounts add constraint FKsg2thy1goee6btcyg70g2ntxo foreign key (service_plan_id) references service_plans;
alter table if exists support_case_activities add constraint FK95qvin16lo31qeipqtel624rh foreign key (support_case_id) references support_cases;
alter table if exists support_cases add constraint FK4f2fmlc6tvoyxecn1lx2oqbp foreign key (account_id) references accounts;
