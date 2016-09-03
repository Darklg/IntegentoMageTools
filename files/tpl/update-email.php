<?php
try {
    /** @var Mage_Core_Model_Resource_Setup $installer */
    $installer = $this;
    $storeId = Mage::app()->getStore()->getStoreId();
    $localeCode = 'fr_FR';
    $mailModel = Mage::getModel('core/email_template');
    $_core = Mage::getSingleton('core/resource');
    $_write = $_core->getConnection('core_write');
    $_tableTemplates = $_core->getTableName('core_email_template');
    $_tableConfig = $_core->getTableName('core_config_data');

    $email_templates = array(
        /* Newsletter */
        'newsletter_subscription_confirm_email_template' => array(
            'name' => '[Project] Confirmation newsletter',
            'path' => 'newsletter_subscr_confirm.html',
            'conf' => 'newsletter/subscription/confirm_email_template'
        ),
        'newsletter_subscription_success_email_template' => array(
            'name' => '[Project] Abonnement newsletter',
            'path' => 'newsletter_subscr_success.html',
            'conf' => 'newsletter/subscription/success_email_template'
        ),
        'newsletter_subscription_un_email_template' => array(
            'name' => '[Project] Désabonnement newsletter',
            'path' => 'newsletter_unsub_success.html',
            'conf' => 'newsletter/subscription/un_email_template'
        ),
        /* Customer */
        'customer_create_account_email_template' => array(
            'name' => '[Project] Nouveau compte',
            'path' => 'account_new.html',
            'conf' => 'customer/create_account/email_template'
        ),
        'customer_password_forgot_email_template' => array(
            'name' => '[Project] Nouveau mot de passe',
            'path' => 'account_password_reset_confirmation.html',
            'conf' => 'customer/password/forgot_email_template'
        ),
        /* Sales */
        'sales_email_order_comment_template' => array(
            'name' => '[Project] Commentaire commande',
            'path' => 'sales/order_update.html',
            'conf' => 'sales_email/order_comment/template',
        ),
        'sales_email_order_template' => array(
            'name' => '[Project] Nouvelle commande',
            'path' => 'sales/order_new.html',
            'conf' => 'sales_email/order/template',
        ),
        'sales_email_shipment_comment_template' => array(
            'name' => '[Project] Commentaire livraison',
            'path' => 'sales/shipment_update.html',
            'conf' => 'sales_email/shipment_comment/template',
        ),
        'sales_email_shipment_template' => array(
            'name' => '[Project] Nouvelle livraison',
            'path' => 'sales/shipment_new.html',
            'conf' => 'sales_email/shipment/template',
        ),
        'sales_email_invoice_comment_template' => array(
            'name' => '[Project] Commentaire Facture',
            'path' => 'sales/invoice_update.html',
            'conf' => 'sales_email/invoice_comment/template',
        ),
        'sales_email_invoice_template' => array(
            'name' => '[Project] Nouvelle facture',
            'path' => 'sales/invoice_new.html',
            'conf' => 'sales_email/invoice/template',
        )
    );

    foreach ($email_templates as $key => $template) {

        // Load template
        $mailTemplate = $mailModel->loadDefault($key, $localeCode);
        $mailTemplate->setDesignConfig(array(
            'area' => 'frontend'
        ));

        // Set mail template
        $_tpl = array(
            'template_code' => $template['name'],
            'orig_template_code' => $key,
            'template_text' => Mage::app()->getTranslator()->getTemplateFile($template['path'], 'email', $localeCode),
            'template_type' => $mailTemplate->getData('template_type'),
            'template_subject' => $mailTemplate->getData('template_subject')
        );

        // Delete old template with the same name
        $_write->delete($_tableTemplates, array(
            'orig_template_code = ?' => $key
        ));

        // Insert new template in db
        $_write->insert($_tableTemplates, $_tpl);
        $_lastInsertId = $_write->lastInsertId();

        // Delete old conf for template
        $_write->delete($_tableConfig, array(
            "path = ?" => $template['conf']
        ));

        // Save new template id in conf
        Mage::getConfig()->saveConfig($template['conf'], intval($_lastInsertId), 'stores', $storeId)->cleanCache();

    }

} catch (Exception $e) {
    Mage::logException($e);
    if (Mage::getIsDeveloperMode()) {
        Mage::throwException($e->getMessage());
    }
}