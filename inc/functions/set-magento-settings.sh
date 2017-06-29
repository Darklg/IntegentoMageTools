#!/bin/bash

###################################
## Magento settings
###################################

echo "-- Setting base URL";
magetools_setting_init_or_update "web/unsecure/base_url" "{{base_url}}";
magetools_setting_init_or_update "web/unsecure/base_link_url" "{{base_url}}";
magetools_setting_init_or_update "web/unsecure/base_skin_url" "{{base_url}}skin/";
magetools_setting_init_or_update "web/unsecure/base_media_url" "{{base_url}}media/";
magetools_setting_init_or_update "web/unsecure/base_js_url" "{{base_url}}js/";

read -p "Set secure base URL ? [y/N]: " mysql__securebaseurl;
if [[ $mysql__securebaseurl == 'y' ]]; then
    echo "-- Setting secure base URL";
    magetools_setting_init_or_update "web/secure/base_url" "{{secure_base_url}}";
    magetools_setting_init_or_update "web/secure/base_link_url" "{{secure_base_url}}";
    magetools_setting_init_or_update "web/secure/base_skin_url" "{{secure_base_url}}skin/";
    magetools_setting_init_or_update "web/secure/base_media_url" "{{secure_base_url}}media/";
    magetools_setting_init_or_update "web/secure/base_js_url" "{{secure_base_url}}js/";
fi;

echo "-- Add checkmo payment method";
magetools_setting_init_or_update "payment/checkmo/active" 1;

echo "-- Setting watermark adapter to GD";
magetools_setting_init_or_update "design/watermark_adapter/adapter" 'GD2';

echo "-- Disable Google Analytics";
magetools_setting_init_or_update "google/analytics/active" 0;

echo "-- Delete Cookie Domain";
mysql --defaults-extra-file=my-magetools.cnf -e "use ${mysql_base};DELETE FROM core_config_data WHERE 'path' = 'web/cookie/cookie_domain';";

# - Anonymize user database
read -p "Anonymize user database ? [y/N]: " mysql__anonymize_db;
if [[ $mysql__anonymize_db == 'y' ]]; then
    mysql --defaults-extra-file=my-magetools.cnf -e "use ${mysql_base};UPDATE sales_flat_order SET customer_email = CONCAT('fake___', customer_email) WHERE customer_email NOT LIKE 'fake___%';";
    mysql --defaults-extra-file=my-magetools.cnf -e "use ${mysql_base};UPDATE customer_entity SET email = CONCAT('fake___', email) WHERE email NOT LIKE 'fake___%';";
    echo "-- Database is now anonymized";
fi;

# - Anonymize admin emails
read -p "Anonymize admin emails ? [Y/n]: " mysql__anonymize_admin_mails;
if [[ $mysql__anonymize_admin_mails != 'n' ]]; then
    magetools_setting_init_or_update "trans_email/ident_general/email" 'owner@example.com';
    magetools_setting_init_or_update "trans_email/ident_sales/email" 'sales@example.com';
    magetools_setting_init_or_update "trans_email/ident_support/email" 'support@example.com';
    magetools_setting_init_or_update "trans_email/ident_custom1/email" 'custom1@example.com';
    magetools_setting_init_or_update "trans_email/ident_custom2/email" 'custom2@example.com';
    magetools_setting_init_or_update "sales_email/order/copy_to" 'sales+copy@example.com';
    magetools_setting_init_or_update "awrma/contacts/depemail" 'support+awrma@example.com';
    echo "-- Admin email are now anonymized";
fi;

# - Merge Assets
read -p "Disable JS/CSS merge ? [Y/n]: " mysql__disable_merge;
if [[ $mysql__disable_merge != 'n' ]]; then
    magetools_setting_init_or_update "dev/js/merge_files" '0';
    magetools_setting_init_or_update "dev/css/merge_css_files" '0';
    echo "-- JS/CSS merge is now disabled";
fi;

# - Default admin URL
magetools_setting_delete "admin/url/custom";
magetools_setting_delete "admin/url/custom_path";
magetools_setting_delete "admin/url/use_custom";
magetools_setting_delete "admin/url/use_custom_path";

# - Default admin pass
read -p "Set password value to 'password' for all admin users [Y/n]: " mysql__password_pass;
if [[ $mysql__password_pass != 'n' ]]; then
    mysql --defaults-extra-file=my-magetools.cnf -e "use ${mysql_base};UPDATE admin_user SET password=CONCAT(MD5('qXpassword'), ':qX')";
    adminid=$(echo "use ${mysql_base};SELECT username FROM admin_user LIMIT 0,1" | mysql --defaults-extra-file=my-magetools.cnf)
    adminid=$(echo $adminid | cut -d " " -f 2);
    echo -e "-- Admin ids are now ${CLR_GREEN}'${adminid}:password'${CLR_DEF}";
fi;

# - Cache
read -p "Set a cache config optimized for Front-End [Y/n]: " mysql__set_cache_config;
if [[ $mysql__set_cache_config != 'n' ]]; then
    mysql --defaults-extra-file=my-magetools.cnf -e "use ${mysql_base};update core_cache_option set value=0;update core_cache_option set value=1 WHERE code IN('config','config_api','config_api2','eav','translate','collections');";
    echo "-- Setting cache config";
fi;
