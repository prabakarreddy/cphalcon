
#ifdef HAVE_CONFIG_H
#include "../../../ext_config.h"
#endif

#include <php.h>
#include "../../../php_ext.h"
#include "../../../ext.h"

#include <Zend/zend_operators.h>
#include <Zend/zend_exceptions.h>
#include <Zend/zend_interfaces.h>

#include "kernel/main.h"
#include "kernel/exception.h"
#include "kernel/object.h"
#include "kernel/memory.h"
#include "kernel/operators.h"
#include "kernel/string.h"
#include "kernel/fcall.h"
#include "ext/spl/spl_exceptions.h"
#include "kernel/array.h"


/*
 +------------------------------------------------------------------------+
 | Phalcon Framework                                                      |
 +------------------------------------------------------------------------+
 | Copyright (c) 2011-2014 Phalcon Team (http://www.phalconphp.com)       |
 +------------------------------------------------------------------------+
 | This source file is subject to the New BSD License that is bundled     |
 | with this package in the file docs/LICENSE.txt.                        |
 |                                                                        |
 | If you did not receive a copy of the license and are unable to         |
 | obtain it through the world-wide-web, please send an email             |
 | to license@phalconphp.com so we can send you a copy immediately.       |
 +------------------------------------------------------------------------+
 | Authors: Andres Gutierrez <andres@phalconphp.com>                      |
 |          Eduar Carvajal <eduar@phalconphp.com>                         |
 +------------------------------------------------------------------------+
 */
/**
 * Phalcon\Mvc\Model\Validator
 *
 * This is a base class for Phalcon\Mvc\Model validators
 */
ZEPHIR_INIT_CLASS(Phalcon_Mvc_Model_Validator) {

	ZEPHIR_REGISTER_CLASS(Phalcon\\Mvc\\Model, Validator, phalcon, mvc_model_validator, phalcon_mvc_model_validator_method_entry, ZEND_ACC_EXPLICIT_ABSTRACT_CLASS);

	zend_declare_property_null(phalcon_mvc_model_validator_ce, SL("_options"), ZEND_ACC_PROTECTED TSRMLS_CC);

	zend_declare_property_null(phalcon_mvc_model_validator_ce, SL("_messages"), ZEND_ACC_PROTECTED TSRMLS_CC);

	return SUCCESS;

}

/**
 * Phalcon\Mvc\Model\Validator constructor
 *
 * @param array options
 */
PHP_METHOD(Phalcon_Mvc_Model_Validator, __construct) {

	zval *options;

	zephir_fetch_params(0, 1, 0, &options);



	if (Z_TYPE_P(options) != IS_ARRAY) {
		ZEPHIR_THROW_EXCEPTION_DEBUG_STRW(phalcon_mvc_model_exception_ce, "options argument must be an Array", "phalcon/mvc/model/validator.zep", 42);
		return;
	}
	zephir_update_property_this(this_ptr, SL("_options"), options TSRMLS_CC);

}

/**
 * Appends a message to the validator
 *
 * @param string message
 * @param string field
 * @param string type
 */
PHP_METHOD(Phalcon_Mvc_Model_Validator, appendMessage) {

	int ZEPHIR_LAST_CALL_STATUS;
	zval *message_param = NULL, *field = NULL, *type = NULL, *_0, _1, _2, *_3;
	zval *message = NULL;

	ZEPHIR_MM_GROW();
	zephir_fetch_params(1, 1, 2, &message_param, &field, &type);

	if (Z_TYPE_P(message_param) != IS_STRING && Z_TYPE_P(message_param) != IS_NULL) {
		zephir_throw_exception_string(spl_ce_InvalidArgumentException, SL("Parameter 'message' must be a string") TSRMLS_CC);
		RETURN_MM_NULL();
	}

	if (Z_TYPE_P(message_param) == IS_STRING) {
		message = message_param;
	} else {
		ZEPHIR_INIT_VAR(message);
		ZVAL_EMPTY_STRING(message);
	}
	if (!field) {
		field = ZEPHIR_GLOBAL(global_null);
	}
	if (!type) {
		ZEPHIR_CPY_WRT(type, ZEPHIR_GLOBAL(global_null));
	} else {
		ZEPHIR_SEPARATE_PARAM(type);
	}


	if (!(zephir_is_true(type))) {
		ZEPHIR_INIT_NVAR(type);
		ZEPHIR_INIT_VAR(_0);
		zephir_get_class(_0, this_ptr, 0 TSRMLS_CC);
		ZEPHIR_SINIT_VAR(_1);
		ZVAL_STRING(&_1, "Validator", 0);
		ZEPHIR_SINIT_VAR(_2);
		ZVAL_STRING(&_2, "", 0);
		zephir_fast_str_replace(type, &_1, &_2, _0);
	}
	ZEPHIR_INIT_VAR(_3);
	object_init_ex(_3, phalcon_mvc_model_message_ce);
	ZEPHIR_CALL_METHOD(NULL, _3, "__construct", NULL, message, field, type);
	zephir_check_call_status();
	zephir_update_property_array_append(this_ptr, SL("_messages"), _3 TSRMLS_CC);
	ZEPHIR_MM_RESTORE();

}

/**
 * Returns messages generated by the validator
 *
 * @return array
 */
PHP_METHOD(Phalcon_Mvc_Model_Validator, getMessages) {


	RETURN_MEMBER(this_ptr, "_messages");

}

/**
 * Returns all the options from the validator
 *
 * @return array
 */
PHP_METHOD(Phalcon_Mvc_Model_Validator, getOptions) {


	RETURN_MEMBER(this_ptr, "_options");

}

/**
 * Returns an option
 *
 * @param	string option
 * @return	mixed
 */
PHP_METHOD(Phalcon_Mvc_Model_Validator, getOption) {

	zval *option_param = NULL, *options, *value;
	zval *option = NULL;

	ZEPHIR_MM_GROW();
	zephir_fetch_params(1, 1, 0, &option_param);

	if (Z_TYPE_P(option_param) != IS_STRING && Z_TYPE_P(option_param) != IS_NULL) {
		zephir_throw_exception_string(spl_ce_InvalidArgumentException, SL("Parameter 'option' must be a string") TSRMLS_CC);
		RETURN_MM_NULL();
	}

	if (Z_TYPE_P(option_param) == IS_STRING) {
		option = option_param;
	} else {
		ZEPHIR_INIT_VAR(option);
		ZVAL_EMPTY_STRING(option);
	}


	options = zephir_fetch_nproperty_this(this_ptr, SL("_options"), PH_NOISY_CC);
	if (zephir_array_isset_fetch(&value, options, option, 1 TSRMLS_CC)) {
		RETURN_CTOR(value);
	}
	RETURN_MM_STRING("", 1);

}

/**
 * Check whether a option has been defined in the validator options
 *
 * @param	string option
 * @return	boolean
 */
PHP_METHOD(Phalcon_Mvc_Model_Validator, isSetOption) {

	zval *option_param = NULL, *_0;
	zval *option = NULL;

	ZEPHIR_MM_GROW();
	zephir_fetch_params(1, 1, 0, &option_param);

	if (Z_TYPE_P(option_param) != IS_STRING && Z_TYPE_P(option_param) != IS_NULL) {
		zephir_throw_exception_string(spl_ce_InvalidArgumentException, SL("Parameter 'option' must be a string") TSRMLS_CC);
		RETURN_MM_NULL();
	}

	if (Z_TYPE_P(option_param) == IS_STRING) {
		option = option_param;
	} else {
		ZEPHIR_INIT_VAR(option);
		ZVAL_EMPTY_STRING(option);
	}


	_0 = zephir_fetch_nproperty_this(this_ptr, SL("_options"), PH_NOISY_CC);
	RETURN_MM_BOOL(zephir_array_isset(_0, option));

}

