--
-- Name: organization; Type: ACL; Schema: carpoolvote; Owner: carpool_admins
--
REVOKE ALL ON TABLE organization FROM PUBLIC;
REVOKE ALL ON TABLE organization FROM carpool_admins;
GRANT SELECT ON TABLE organization TO carpool_web_role;
GRANT ALL ON TABLE organization TO carpool_admins;
GRANT ALL ON TABLE organization TO carpool_role;

INSERT INTO carpoolvote.organization("OrganizationName") VALUES ('None');
INSERT INTO carpoolvote.organization("OrganizationName") VALUES ('NAACP');
INSERT INTO carpoolvote.organization("OrganizationName") VALUES ('AAPD');
INSERT INTO carpoolvote.organization("OrganizationName") VALUES ('PPC');
INSERT INTO carpoolvote.organization("OrganizationName") VALUES ('MDCC');
