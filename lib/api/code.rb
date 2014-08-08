module Api::Code
  SUCCESS                  =  1
  UNKNOWN                  =  -1
  ARGUMENT_MISSING         =  -2
  VALIDATION_ERROR         =  -3
  RECORD_NOT_FOUND         =  -4
  AUTHORIZATION_ERROR      =  -5
  SAML_ERROR               =  -6
  ARGUMENT_UNSUPPORTED     =  -7
  OWNERSHIP_INVALID        =  -8
  INVOICE_INVALID          =  -9
  INVALID_UTF8             =  -10
  ARGUMENT_INVALID         =  -11
  INVALID_REGION           =  -12
  DELETION_ERROR           =  -13
  OAUTH2_ERROR             =  -14
  BILLING_ERROR            =  -15
  INVALID_STATE_TRANSITION =  -16
  DEVICE_LIMIT             =  -17
  FORMAT_UNSUPPORTED       =  -18
  ACTION_UNSUPPORTED       =  -19
  BATCH_LIMIT              =  -20
  MISMATCH_FORMAT          =  -21
  DEVICE_LIMIT_PERIOD      =  -22
  CLIENT_ERROR             =  -23 

  #to have translation of messages we need to split codes from actual message implementation
  # HTTP codes refer to 
  # http://en.wikipedia.org/wiki/List_of_HTTP_status_codes#4xx_Client_Error
  # and
  # http://msdn.microsoft.com/en-us/library/windowsazure/dd179357.aspx
  @@error_codes = {

    '1'   => {:http => 200, :message => I18n.t('api.error_code.success')},
    '-1'  => {:http => 400, :message => I18n.t('api.error_code.unknown')},
    '-2'  => {:http => 422, :message => I18n.t('api.error_code.argument_missing'), :class => "ArgumentError"},
    '-3'  => {:http => 400, :message => I18n.t('api.error_code.validation_error')},
    '-4'  => {:http => 404, :message => I18n.t('api.error_code.record_not_found'), :class => "ActiveRecord::RecordNotFound"},
    '-5'  => {:http => 401, :message => I18n.t('api.error_code.authorization_error.generic')},
    '-6'  => {:http => 403, :message => I18n.t('api.error_code.saml_error')},
    '-7'  => {:http => 422, :message => I18n.t('api.error_code.argument_unsupported')},
    '-8'  => {:http => 422, :message => I18n.t('api.error_code.ownership_invalid')},
    '-9'  => {:http => 422, :message => I18n.t('api.error_code.invoice_invalid')},
    '-10' => {:http => 400, :message => I18n.t('api.error_code.invalid_utf8')},
    '-11' => {:http => 400, :message => I18n.t('api.error_code.argument_invalid')},
    '-12' => {:http => 401, :message => I18n.t('api.error_code.invalid_region')},
    '-13' => {:http => 422, :message => I18n.t('api.error_code.deletion_error')},
    '-14' => {:http => 400, :message => I18n.t('api.error_code.oauth2.error')},
    '-15' => {:http => 400, :message => I18n.t('api.error_code.billing_error')},
    '-16' => {:http => 400, :message => I18n.t('api.error_code.invalid_state_transition')},
    '-17' => {:http => 403, :message => I18n.t('api.error_code.device_limit')},
    '-18' => {:http => 400, :message => I18n.t('api.error_code.format_unsupported')},
    '-19' => {:http => 400, :message => I18n.t('api.error_code.action_unsupported')},
    '-20' => {:http => 400, :message => I18n.t('api.error_code.batch_limit')},
    '-21' => {:http => 400, :message => I18n.t('api.error_code.mismatch_format')},
    '-22' => {:http => 403, :message => I18n.t('api.error_code.device_limit_period')},
    '-23' => {:http => 403, :message => I18n.t('api.error_code.client_error')},
  }

  def self.get_message(code)
    @@error_codes[code.to_s][:message] || "Unkown error code"
  end
  
  def self.get_http_status(code)
    @@error_codes[code.to_s][:http] || 200
  end
  
  def self.code_for(exception)
    result = select_error_codes_for(exception)
    unless result.empty?
      result.first[0].to_i
    end
  end
  
  def self.http_status_for(exception)
    result = select_error_codes_for(exception)
    unless result.empty?
      result.first[1][:http]
    end
  end

  def self.message_for(exception)
    result = select_error_codes_for(exception)
    unless result.empty?
      result.first[1][:message]
    else
      exception.message
    end
  end
  
  def self.select_error_codes_for(exception)
    @@error_codes.select {|key, value|
      value[:class] && Array.wrap(value[:class]).any? {|name| name == exception.class.name}
    }
  end
end